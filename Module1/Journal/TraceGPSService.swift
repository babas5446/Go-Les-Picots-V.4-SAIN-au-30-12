//
//  TraceGPSService.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Gestion de la trace GPS pendant une sortie de pêche.
//
//  Responsabilités :
//  - Demande d'autorisation localisation (whenInUse puis élévation en always)
//  - Enregistrement d'un PointGPS toutes les 60 secondes
//  - Pause et reprise de la trace, avec segmentation
//  - Relevé ponctuel de position pour une prise, trace armée ou non
//  - Diagnostic de santé de la trace, lisible par le bandeau d'état
//  - Export GPX : waypoints des prises puis trace en segments multiples
//
//  Usage :
//  - Instance unique : TraceGPSService.shared. Ne jamais construire le service
//    ailleurs, sous peine de retrouver le défaut que le singleton corrige.
//  - Déclenchement manuel via demarrerTrace(sortie:context:) / arreterTrace()
//  - mettreEnPause() suspend l'écriture sans perdre la cible
//  - reprendre() ouvre un nouveau segment
//
//  V4.2 :
//  - Intervalle porté de 30 à 60 secondes. À 8 nœuds, deux points sont séparés
//    d'environ 250 mètres : les virages serrés seront lissés sur le tracé.
//  - Pause : arreterTrace() remettait sortie et contexte à nil, ce qui interdisait
//    toute reprise. mettreEnPause() conserve la cible et coupe le récepteur,
//    ce qui économise réellement la batterie sur un arrêt prolongé.
//  - Segmentation : chaque reprise incrémente le compteur de segment. L'export
//    écrit un <trkseg> par segment, sinon Boating tirerait une droite entre le
//    dernier point avant l'arrêt et le premier après.
//  - Vitesse : CLLocation.speed est relevée à chaque point. Le récepteur mesure
//    mieux que ne le ferait une dérivée de deux positions espacées d'une minute.
//  - Localisation en arrière-plan : requiert dans les réglages du projet la clé
//    NSLocationAlwaysAndWhenInUseUsageDescription en plus de
//    NSLocationWhenInUseUsageDescription, et le mode d'arrière-plan « Location
//    updates » dans Signing & Capabilities. Sans ces trois réglages, la trace
//    s'interrompt à l'extinction de l'écran.
//  - Relevé ponctuel : requestLocation() et didUpdateLocations, pour pointer une
//    prise alors qu'aucune trace ne tourne.
//
//  V4.2, session 7 :
//  - Instance partagée (static let shared). Le service était construit dans
//    l'init du ViewModel, donc détruit en quittant le Journal : la trace
//    s'interrompait réellement au milieu d'une sortie, et reprendreSortie()
//    masquait le trou en réarmant un segment. Le contexte reçu vient déjà de
//    LeurreStorageService.shared.mainContext, dont la durée de vie est celle du
//    processus : le conserver dans un singleton ne prolonge rien de nouveau.
//  - Santé de la trace (SanteTrace). Une clé Info.plist mal orthographiée
//    (NSLoccation… avec deux « c », relevé du 20/08) fait ignorer la demande
//    d'autorisation par iOS sans le moindre signal : ni erreur, ni refus, ni
//    callback. Le statut reste indéfiniment .notDetermined et le service attend
//    une réponse qui ne viendra jamais. Le diagnostic distingue désormais ce cas
//    d'un simple problème de réception.
//

import Foundation
import CoreLocation
import SwiftData
import Combine

// MARK: - Santé de la trace

/// État de santé de l'enregistrement, destiné au bandeau d'état.
///
/// Deux causes de silence, deux messages : une autorisation défaillante relève
/// des réglages, une absence de points relève du ciel. Les confondre dans un
/// avertissement unique n'aiderait ni à diagnostiquer ni à décider.
enum SanteTrace: Equatable {

    /// Rien à signaler, ou trace non armée.
    case normale

    /// Autorisation demandée, statut toujours indéterminé passé le délai.
    /// Symptôme caractéristique d'une clé d'usage absente ou mal orthographiée
    /// dans les réglages du projet.
    case autorisationIndeterminee

    /// Autorisation explicitement refusée ou restreinte.
    case autorisationRefusee

    /// Enregistrement actif, autorisation accordée, mais aucun point écrit
    /// depuis un long moment. Réception dégradée, ou récepteur muet.
    case silencieuse
}

@MainActor
final class TraceGPSService: NSObject, ObservableObject {

    // MARK: - Instance partagée

    /// Instance unique. Le service doit survivre à la navigation : une sortie
    /// continue d'enregistrer pendant que l'utilisateur consulte la boîte à
    /// leurres ou le module de suggestion.
    static let shared = TraceGPSService()

    // MARK: - État observable

    /// La trace écrit-elle des points en ce moment ?
    @Published var enregistrement: Bool = false

    /// Trace armée mais suspendue. La cible est conservée.
    @Published var enPause: Bool = false

    @Published var autorisationRefusee: Bool = false
    @Published var dernierPoint: CLLocationCoordinate2D?

    /// Nombre de points écrits pour la sortie courante, pour le bandeau.
    @Published var nombrePointsSession: Int = 0

    /// Diagnostic courant. Lu par le bandeau d'état.
    @Published private(set) var sante: SanteTrace = .normale

    // MARK: - Privé

    private let locationManager: CLLocationManager
    private var context: ModelContext?
    private var sortieCible: Sortie?

    /// Segment courant. Incrémenté à chaque reprise après pause.
    private var segmentCourant: Int = 0

    private var timer: Timer?

    /// Maintient la trace active écran éteint avec la seule autorisation
    /// « Lorsque l'app est active » (iOS 17+). Sans elle, la trace s'arrêtait
    /// dès le verrouillage de l'iPhone si l'utilisateur n'avait pas choisi « Toujours ».
    private var sessionArrierePlan: CLBackgroundActivitySession?

    /// Le mode d'arrière-plan « location » est-il déclaré dans l'Info.plist ?
    /// Sans lui, activer allowsBackgroundLocationUpdates lève une exception.
    private var modeArrierePlanDeclare: Bool {
        (Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String])?
            .contains("location") ?? false
    }

    /// Demandes de position ponctuelle en attente de réponse du récepteur.
    private var attentesPosition: [CheckedContinuation<CLLocationCoordinate2D?, Never>] = []

    /// Horodatage du dernier point effectivement écrit, et instant du démarrage.
    /// Le second sert de référence tant que le premier est nul : sans lui, une
    /// trace muette dès la première seconde ne serait jamais signalée.
    private var dernierPointHorodatage: Date?
    private var debutEnregistrement: Date?

    /// Surveillance du statut d'autorisation après une demande.
    private var surveillanceAutorisation: Task<Void, Never>?

    /// Intervalle entre deux points de trace, en secondes.
    private let intervalle: TimeInterval = 60

    /// Délai au-delà duquel un relevé ponctuel est abandonné.
    private let delaiRelevePonctuel: TimeInterval = 10

    /// Délai au-delà duquel un statut resté indéterminé devient suspect.
    /// Vingt secondes laissent le temps de lire la boîte de dialogue système :
    /// en deçà, l'avertissement se déclencherait sur un utilisateur qui hésite.
    private let delaiAutorisation: TimeInterval = 20

    /// Silence toléré pendant un enregistrement actif. Une première acquisition
    /// dépasse rarement la minute en zone couverte ; trois minutes évitent
    /// l'avertissement intempestif qui finirait par être ignoré.
    private let delaiSilence: TimeInterval = 180

    // MARK: - Initialisation

    /// Passer par `TraceGPSService.shared`. L'initialisation reste accessible au
    /// module : Swift interdit de restreindre l'accès d'un initialisateur hérité
    /// de NSObject.
    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
    }

    // MARK: - API publique — cycle de vie

    /// Démarre l'enregistrement de la trace GPS pour une sortie donnée.
    /// Le segment reprend après le plus haut segment déjà présent : une sortie
    /// restaurée après fermeture de l'application ne réécrit pas dans un segment
    /// clos.
    func demarrerTrace(sortie: Sortie, context: ModelContext) {

        // Le service étant désormais partagé, il peut être sollicité alors qu'il
        // enregistre déjà. Même cible : rien à faire. Cible différente : on
        // bascule, plutôt que de refuser en silence.
        if enregistrement {
            guard sortieCible?.id != sortie.id else { return }
            arreterTrace()
        }

        self.context     = context
        self.sortieCible = sortie
        self.enPause     = false

        let segmentMax = sortie.pointsGPS.map(\.segment).max() ?? -1
        self.segmentCourant = sortie.pointsGPS.isEmpty ? 0 : segmentMax + 1
        self.nombrePointsSession = sortie.pointsGPS.count

        demanderAutorisationPuisDemarrer()
    }

    /// Suspend l'écriture des points sans perdre la sortie ni le contexte.
    /// Le récepteur est arrêté : sur une heure au mouillage, l'économie de
    /// batterie n'est pas négligeable.
    func mettreEnPause() {
        guard enregistrement else { return }
        timer?.invalidate()
        timer = nil
        locationManager.stopUpdatingLocation()
        sessionArrierePlan?.invalidate()
        sessionArrierePlan = nil
        enregistrement = false
        enPause        = true

        // Une trace en pause n'écrit rien par construction : le silence cesse
        // d'être un symptôme.
        if sante == .silencieuse { sante = .normale }
        debutEnregistrement = nil
    }

    /// Reprend l'écriture dans un nouveau segment.
    func reprendre() {
        guard enPause, sortieCible != nil, context != nil else { return }
        segmentCourant += 1
        enPause = false
        demanderAutorisationPuisDemarrer()
    }

    /// Arrête définitivement l'enregistrement et libère la cible.
    func arreterTrace() {
        timer?.invalidate()
        timer = nil
        surveillanceAutorisation?.cancel()
        surveillanceAutorisation = nil
        locationManager.stopUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = false
        sessionArrierePlan?.invalidate()
        sessionArrierePlan = nil
        enregistrement = false
        enPause        = false
        sortieCible    = nil
        context        = nil
        segmentCourant = 0

        dernierPointHorodatage = nil
        debutEnregistrement    = nil

        // Le refus d'autorisation reste affiché : c'est une condition
        // persistante, que l'arrêt de la trace ne résout pas.
        if sante == .silencieuse || sante == .autorisationIndeterminee {
            sante = .normale
        }
    }

    // MARK: - API publique — relevé ponctuel

    /// Relève une position unique, pour pointer une prise.
    ///
    /// Fonctionne trace armée ou non : c'est le cas d'usage d'une sortie sans
    /// trace, où seules les prises sont géolocalisées. Retourne nil si
    /// l'autorisation manque ou si le récepteur ne répond pas dans le délai.
    func relevePositionPonctuelle() async -> CLLocationCoordinate2D? {

        let statut = locationManager.authorizationStatus
        guard statut == .authorizedWhenInUse || statut == .authorizedAlways else {
            if statut == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
                surveillerAutorisation()
            }
            return nil
        }

        // Trace en cours : la position du gestionnaire est fraîche, inutile
        // de solliciter une nouvelle acquisition.
        if enregistrement, let position = locationManager.location {
            return position.coordinate
        }

        return await withCheckedContinuation { continuation in
            attentesPosition.append(continuation)
            locationManager.requestLocation()

            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(self?.delaiRelevePonctuel ?? 10) * 1_000_000_000)
                await self?.abandonnerAttentes()
            }
        }
    }

    // MARK: - Export GPX

    /// Génère un fichier GPX depuis les prises et les points d'une Sortie.
    ///
    /// Ordre imposé par le schéma GPX 1.1 : metadata, puis waypoints, puis trace.
    /// Un fichier dont l'ordre est inversé est rejeté à l'ouverture.
    /// La trace est découpée en un <trkseg> par segment.
    func exporterGPX(sortie: Sortie) throws -> URL {

        let horodateur = ISO8601DateFormatter()
        horodateur.formatOptions = [.withInternetDateTime]

        let titre = echapper(sortie.titreAffiche)

        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1"
             creator="Go Les Picots V.4"
             xmlns="http://www.topografix.com/GPX/1/1">
          <metadata>
            <name>\(titre)</name>
            <time>\(horodateur.string(from: sortie.date))</time>
          </metadata>
        """

        // Waypoints : une marque par prise géolocalisée.
        for prise in sortie.prisesGeolocalisees.sorted(by: { $0.heure < $1.heure }) {
            guard let lat = prise.latitude, let lon = prise.longitude else { continue }
            let nom = echapper(prise.especeAffichee)
            let description = echapper(prise.descriptionCourte)

            gpx += """

          <wpt lat="\(coordonnee(lat))" lon="\(coordonnee(lon))">
            <time>\(horodateur.string(from: prise.heure))</time>
            <name>\(nom)</name>
            <desc>\(description)</desc>
            <sym>Fishing Hot Spot Facility</sym>
          </wpt>
        """
        }

        // Trace : un segment par période de navigation continue.
        let points = sortie.pointsTries
        if !points.isEmpty {
            gpx += """

          <trk>
            <name>\(titre)</name>
        """

            var segmentOuvert: Int? = nil

            for point in points {
                if segmentOuvert != point.segment {
                    if segmentOuvert != nil {
                        gpx += """

            </trkseg>
        """
                    }
                    gpx += """

            <trkseg>
        """
                    segmentOuvert = point.segment
                }

                gpx += """

              <trkpt lat="\(coordonnee(point.latitude))" lon="\(coordonnee(point.longitude))">
                <time>\(horodateur.string(from: point.timestamp))</time>
              </trkpt>
        """
            }

            if segmentOuvert != nil {
                gpx += """

            </trkseg>
        """
            }

            gpx += """

          </trk>
        """
        }

        gpx += """

        </gpx>
        """

        let nomFichier = "trace_\(formatDateFichier(sortie.date)).gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nomFichier)
        try gpx.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Privé — autorisation

    private func demanderAutorisationPuisDemarrer() {
        let statut = locationManager.authorizationStatus

        switch statut {
        case .notDetermined:
            // Le démarrage effectif se fera dans le delegate après réponse.
            locationManager.requestWhenInUseAuthorization()
            surveillerAutorisation()

        case .authorizedWhenInUse:
            // iOS impose cet enchaînement : une demande directe d'autorisation
            // permanente est ignorée si whenInUse n'a pas été accordée d'abord.
            locationManager.requestAlwaysAuthorization()
            demarrerEnregistrement()

        case .authorizedAlways:
            demarrerEnregistrement()

        default:
            autorisationRefusee = true
            sante = .autorisationRefusee
        }
    }

    /// Surveille le statut après une demande d'autorisation.
    ///
    /// Une clé d'usage absente ou mal orthographiée dans les réglages du projet
    /// fait ignorer la demande par iOS : aucune boîte de dialogue ne s'affiche,
    /// aucun callback n'est appelé, et le statut reste .notDetermined
    /// indéfiniment. Le service attendrait alors une réponse qui ne viendra pas.
    /// C'est exactement ce qui s'est produit le 20/08.
    private func surveillerAutorisation() {
        surveillanceAutorisation?.cancel()
        surveillanceAutorisation = Task { [weak self] in
            guard let delai = self?.delaiAutorisation else { return }
            try? await Task.sleep(nanoseconds: UInt64(delai) * 1_000_000_000)
            guard !Task.isCancelled else { return }
            await self?.verifierAutorisationIndeterminee()
        }
    }

    private func verifierAutorisationIndeterminee() {
        guard locationManager.authorizationStatus == .notDetermined else { return }
        sante = .autorisationIndeterminee
    }

    // MARK: - Privé — enregistrement

    private func demarrerEnregistrement() {
        // N'est accordé que si le mode d'arrière-plan « Location updates » est
        // activé dans les capacités du projet. L'affectation lève une exception
        // dans le cas contraire, d'où la vérification préalable.
        let statut = locationManager.authorizationStatus
        if (statut == .authorizedAlways || statut == .authorizedWhenInUse) && modeArrierePlanDeclare {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.showsBackgroundLocationIndicator = true
            sessionArrierePlan?.invalidate()
            sessionArrierePlan = CLBackgroundActivitySession()
        }

        surveillanceAutorisation?.cancel()
        surveillanceAutorisation = nil

        locationManager.startUpdatingLocation()
        enregistrement = true
        enPause        = false

        debutEnregistrement    = Date()
        dernierPointHorodatage = nil
        if sante != .autorisationRefusee { sante = .normale }

        // Premier point immédiat, pour que le compteur bouge sans attendre.
        enregistrerPoint()

        timer = Timer.scheduledTimer(
            withTimeInterval: intervalle,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.enregistrerPoint()
                self?.evaluerSilence()
            }
        }
    }

    private func enregistrerPoint() {
        guard
            let location = locationManager.location,
            let sortie   = sortieCible,
            let context  = context
        else { return }

        let point = PointGPS(
            timestamp: Date(),
            latitude:  location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            segment:   segmentCourant,
            vitesseMS: location.speed
        )
        point.sortie = sortie
        sortie.pointsGPS.append(point)
        context.insert(point)

        try? context.save()

        dernierPoint        = location.coordinate
        nombrePointsSession = sortie.pointsGPS.count

        dernierPointHorodatage = Date()
        if sante == .silencieuse { sante = .normale }
    }

    /// Signale une trace armée qui n'écrit rien.
    ///
    /// Le cas se produit réellement : enregistrerPoint() sort sans agir quand
    /// locationManager.location vaut nil, et ne laisse aucune trace de son
    /// abandon. Le compteur du bandeau reste figé sans que rien ne l'explique.
    private func evaluerSilence() {
        guard enregistrement else { return }

        let statut = locationManager.authorizationStatus
        guard statut == .authorizedWhenInUse || statut == .authorizedAlways else { return }

        guard let reference = dernierPointHorodatage ?? debutEnregistrement else { return }

        if Date().timeIntervalSince(reference) > delaiSilence {
            sante = .silencieuse
        }
    }

    // MARK: - Privé — relevé ponctuel

    private func resoudreAttentes(_ coordonnee: CLLocationCoordinate2D?) {
        guard !attentesPosition.isEmpty else { return }
        let attentes = attentesPosition
        attentesPosition.removeAll()
        for attente in attentes {
            attente.resume(returning: coordonnee)
        }
    }

    private func abandonnerAttentes() {
        resoudreAttentes(nil)
    }

    // MARK: - Privé — formatage

    /// Six décimales suffisent au décimètre et évitent la notation scientifique,
    /// que les lecteurs GPX n'acceptent pas.
    private func coordonnee(_ valeur: Double) -> String {
        String(format: "%.6f", valeur)
    }

    /// Échappe les caractères réservés du XML. Un nom de spot contenant une
    /// esperluette suffirait à rendre le fichier illisible.
    private func echapper(_ texte: String) -> String {
        texte
            .replacingOccurrences(of: "&",  with: "&amp;")
            .replacingOccurrences(of: "<",  with: "&lt;")
            .replacingOccurrences(of: ">",  with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'",  with: "&apos;")
    }

    private func formatDateFichier(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - CLLocationManagerDelegate

extension TraceGPSService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.autorisationRefusee = false
                if self.sante == .autorisationIndeterminee
                    || self.sante == .autorisationRefusee {
                    self.sante = .normale
                }
                // Démarre si une sortie attendait la réponse de l'utilisateur.
                if self.sortieCible != nil && !self.enregistrement && !self.enPause {
                    self.demarrerEnregistrement()
                }
            case .denied, .restricted:
                self.autorisationRefusee = true
                self.sante = .autorisationRefusee
                self.resoudreAttentes(nil)
                self.arreterTrace()
                // arreterTrace() ne remet pas un refus à zéro : la condition
                // persiste tant que l'utilisateur n'a pas changé ses réglages.
                self.sante = .autorisationRefusee
            default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let derniere = locations.last else { return }
        Task { @MainActor in
            self.dernierPoint = derniere.coordinate
            self.resoudreAttentes(derniere.coordinate)
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Échec silencieux — la trace continue avec les points déjà enregistrés.
        Task { @MainActor in
            self.resoudreAttentes(nil)
        }
        print("❌ TraceGPSService : \(error.localizedDescription)")
    }
}
