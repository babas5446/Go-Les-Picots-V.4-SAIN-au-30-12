//
//  JournalModels.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Modèles SwiftData du Journal de sorties.
//  Container partagé avec Module 1 via LeurreStorageService.
//
//  Modèles :
//  - Sortie      : entité principale (session de pêche)
//  - Prise       : rattachée à une Sortie (un poisson capturé)
//  - PointGPS    : point de trace, rattaché à une Sortie
//
//  Convention d'encodage :
//  - ConditionsPeche (struct Codable) → stocké en Data via propriété backing privée
//  - [Int] leurresSessionIDs         → stocké en Data via propriété backing privée
//  - [SpreadSnapshot]                → stocké en Data via propriété backing privée
//  - Photos                          → @Attribute(.externalStorage)
//
//  V4.1 :
//  - Ajout de spreadsData : historique des configurations montées pendant la sortie
//    (plusieurs spreads possibles par sortie). leurresSessionIDs en devient dérivé.
//  - Prise.especeAffichee résout le rawValue de l'enum Espece en libellé lisible
//
//  V4.2 — cycle de vie de la sortie :
//  - Sortie.nomSortie : titre de la sortie, distinct du nom du spot.
//    Le journal affiche « nomSortie à nomSpot ».
//  - Sortie.etat : quatre états (non démarrée / en cours / en pause / terminée),
//    persisté en rawValue String, convention identique à Prise.especeNom.
//  - Sortie.cumulPausesSecondes et debutPauseCourante : comptabilité des pauses.
//    La durée de sortie couvre l'amplitude complète, départ à retour.
//    La vitesse moyenne et la consommation horaire n'utilisent que le temps
//    de navigation, pauses déduites.
//  - Sortie.carburantLitres : plein effectué au retour, saisi après refill.
//  - PointGPS.segment : incrémenté à chaque reprise après pause. L'export GPX
//    écrit un <trkseg> par segment, ce qui évite de tracer une droite à travers
//    un arrêt au mouillage.
//  - PointGPS.vitesseMS : CLLocation.speed au moment du relevé, en m/s.
//    Mesure fournie par le récepteur, plus juste qu'une dérivée de positions
//    espacées d'une minute. Valeur négative = mesure invalide, à écarter.
//
//  Toutes les propriétés ajoutées portent une valeur par défaut ou sont
//  optionnelles : la migration légère SwiftData les absorbe sans perte.
//

import Foundation
import SwiftData

// MARK: - État du cycle de vie d'une sortie

/// États successifs d'une sortie de pêche.
///
/// L'heure de retour reste la marque de la clôture ; cet état précise ce que
/// les seules dates ne peuvent pas dire, à savoir la distinction entre une
/// sortie qui tourne et une sortie suspendue.
enum EtatSortie: String, Codable, CaseIterable {
    case nonDemarree = "nonDemarree"
    case enCours     = "enCours"
    case enPause     = "enPause"
    case terminee    = "terminee"

    var displayName: String {
        switch self {
        case .nonDemarree: return "Non démarrée"
        case .enCours:     return "En cours"
        case .enPause:     return "En pause"
        case .terminee:    return "Terminée"
        }
    }

    /// La trace GPS doit-elle écrire des points dans cet état ?
    var traceActive: Bool {
        self == .enCours
    }
}

// MARK: - Sortie

@Model
final class Sortie {

    // MARK: Identification
    var id: UUID

    /// Titre de la sortie. Pré-rempli à la création (« Sortie du 18/08/2026 »),
    /// librement modifiable ensuite.
    var nomSortie: String = ""

    // MARK: Temporel
    var date: Date
    var heureDepart: Date?
    var heureRetour: Date?

    // MARK: Cycle de vie — backing privé
    /// rawValue de EtatSortie. Accès via la propriété calculée `etat`.
    private var etatRaw: String = EtatSortie.nonDemarree.rawValue

    /// Cumul des pauses déjà terminées, en secondes.
    var cumulPausesSecondes: Double = 0

    /// Horodatage du début de la pause en cours. nil hors pause.
    var debutPauseCourante: Date?

    // MARK: Carburant
    /// Litres embarqués au refill du retour. Base du calcul de consommation.
    var carburantLitres: Double?

    // MARK: Localisation
    var nomSpot: String
    var latitude: Double?
    var longitude: Double?

    // MARK: Conditions — backing privé
    /// ConditionsPeche encodé en JSON. Accès via la propriété calculée `conditions`.
    private var conditionsData: Data?

    // MARK: Spread de la session — backing privé
    /// [Int] des IDs de leurres de la boîte. Accès via `leurresSessionIDs`.
    /// Dérivé de `spreads` : maintenu automatiquement, conservé pour les statistiques.
    private var leurresSessionIDsData: Data?

    // MARK: Historique des spreads — backing privé
    /// [SpreadSnapshot] encodé en JSON. Accès via la propriété calculée `spreads`.
    private var spreadsData: Data?

    // MARK: Relations SwiftData
    @Relationship(deleteRule: .cascade, inverse: \Prise.sortie)
    var prises: [Prise]

    @Relationship(deleteRule: .cascade, inverse: \PointGPS.sortie)
    var pointsGPS: [PointGPS]

    // MARK: Notes et photo
    var notes: String

    @Attribute(.externalStorage)
    var photoSpotData: Data?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        nomSortie: String = "",
        date: Date = Date(),
        heureDepart: Date? = nil,
        heureRetour: Date? = nil,
        etat: EtatSortie = .nonDemarree,
        cumulPausesSecondes: Double = 0,
        debutPauseCourante: Date? = nil,
        carburantLitres: Double? = nil,
        nomSpot: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        conditions: ConditionsPeche? = nil,
        leurresSessionIDs: [Int] = [],
        spreads: [SpreadSnapshot] = [],
        notes: String = "",
        photoSpotData: Data? = nil
    ) {
        self.id                    = id
        self.nomSortie             = nomSortie
        self.date                  = date
        self.heureDepart           = heureDepart
        self.heureRetour           = heureRetour
        self.etatRaw               = etat.rawValue
        self.cumulPausesSecondes   = cumulPausesSecondes
        self.debutPauseCourante    = debutPauseCourante
        self.carburantLitres       = carburantLitres
        self.nomSpot               = nomSpot
        self.latitude              = latitude
        self.longitude             = longitude
        self.conditionsData        = Self.encoder(conditions)
        self.leurresSessionIDsData = Self.encoderIDs(leurresSessionIDs)
        self.spreadsData           = SpreadSnapshotService.encoder(spreads)
        self.prises                = []
        self.pointsGPS             = []
        self.notes                 = notes
        self.photoSpotData         = photoSpotData
    }

    // MARK: - Cycle de vie

    /// État courant de la sortie.
    /// Repli sur `.nonDemarree` si la valeur persistée est inconnue —
    /// cas des sorties créées avant la V4.2, dont le champ est vide.
    var etat: EtatSortie {
        get { EtatSortie(rawValue: etatRaw) ?? .nonDemarree }
        set { etatRaw = newValue.rawValue }
    }

    /// La trace GPS doit-elle écrire pour cette sortie ?
    var traceActive: Bool { etat.traceActive }

    /// Sorties créées avant la V4.2 : le champ d'état est vide et la sortie
    /// passait pour « non démarrée », même avec un retour, des prises ou une
    /// trace. On lui donne un état réel, une fois pour toutes.
    /// Retourne true si l'état a été corrigé.
    @discardableResult
    func normaliserEtatAncien() -> Bool {
        guard EtatSortie(rawValue: etatRaw) == nil else { return false }
        let aEuLieu = heureRetour != nil || heureDepart != nil
            || !prises.isEmpty || !pointsGPS.isEmpty
        etatRaw = (aEuLieu ? EtatSortie.terminee : EtatSortie.nonDemarree).rawValue
        if aEuLieu, heureRetour == nil {
            // Heure de retour inconnue : dernier point de trace, sinon dernière prise.
            heureRetour = pointsGPS.map(\.timestamp).max() ?? prises.map(\.heure).max()
        }
        return true
    }

    // MARK: - Propriétés calculées publiques

    /// Conditions de pêche de la session, décodées depuis conditionsData.
    var conditions: ConditionsPeche? {
        get { Self.decoder(conditionsData) }
        set { conditionsData = Self.encoder(newValue) }
    }

    /// Configurations de traîne montées pendant la sortie, dans l'ordre chronologique.
    /// L'écriture met à jour leurresSessionIDs, qui reste ainsi cohérent sans double saisie.
    var spreads: [SpreadSnapshot] {
        get { SpreadSnapshotService.decoder(spreadsData) }
        set {
            spreadsData = SpreadSnapshotService.encoder(newValue)
            let ids = newValue.flatMap(\.leurreIDs)
            leurresSessionIDs = Array(Set(ids)).sorted()
        }
    }

    /// IDs des leurres réellement montés pendant la sortie, toutes configurations confondues.
    var leurresSessionIDs: [Int] {
        get { Self.decoderIDs(leurresSessionIDsData) }
        set { leurresSessionIDsData = Self.encoderIDs(newValue) }
    }

    // MARK: - Libellés

    /// Titre de repli quand aucun nom n'a été saisi.
    var titreAffiche: String {
        nomSortie.isEmpty ? "Sortie du \(Self.formatDateCourte(date))" : nomSortie
    }

    /// Libellé du journal : « Passe de Boulari à DCP Tiaré ».
    /// Le segment « à … » disparaît quand aucun spot n'est renseigné.
    var libelleJournal: String {
        guard !nomSpot.isEmpty else { return titreAffiche }
        return "\(titreAffiche) à \(nomSpot)"
    }

    // MARK: - Durées

    /// Amplitude complète de la sortie, départ à retour, pauses comprises.
    /// Tant que la sortie n'est pas terminée, mesurée jusqu'à l'instant présent.
    var duree: TimeInterval? {
        guard let depart = heureDepart else { return nil }
        let fin = heureRetour ?? Date()
        let ecart = fin.timeIntervalSince(depart)
        return ecart > 0 ? ecart : 0
    }

    /// Total des pauses, pause en cours comprise.
    var dureePauses: TimeInterval {
        var total = cumulPausesSecondes
        if let debut = debutPauseCourante {
            total += Date().timeIntervalSince(debut)
        }
        return max(0, total)
    }

    /// Temps effectif de navigation, pauses déduites.
    /// Base de la vitesse moyenne et de la consommation horaire : une heure au
    /// mouillage ne doit pas écraser la moyenne d'une traîne.
    var dureeNavigation: TimeInterval? {
        guard let totale = duree else { return nil }
        return max(0, totale - dureePauses)
    }

    /// Durée formatée "Xh Ymin".
    var dureeFormatee: String? {
        Self.formatDuree(duree)
    }

    /// Temps de navigation formaté "Xh Ymin".
    var dureeNavigationFormatee: String? {
        Self.formatDuree(dureeNavigation)
    }

    /// Temps de pause formaté "Xh Ymin". nil si aucune pause.
    var dureePausesFormatee: String? {
        Self.formatDuree(dureePauses)
    }

    // MARK: - Trace et navigation

    /// Points de trace triés par segment puis par horodatage.
    /// L'ordre par segment garantit qu'aucune distance n'est calculée à cheval
    /// sur une pause.
    var pointsTries: [PointGPS] {
        pointsGPS.sorted {
            $0.segment == $1.segment
                ? $0.timestamp < $1.timestamp
                : $0.segment < $1.segment
        }
    }

    /// Distance parcourue en mètres, par formule de Haversine.
    /// Les sauts entre deux segments sont ignorés : le bateau a pu dériver ou
    /// être déplacé pendant la pause, cette distance n'est pas de la navigation.
    var distanceMetres: Double {
        let points = pointsTries
        guard points.count > 1 else { return 0 }

        var total: Double = 0
        for i in 1..<points.count {
            let precedent = points[i - 1]
            let courant   = points[i]
            guard precedent.segment == courant.segment else { continue }
            total += Self.haversine(
                lat1: precedent.latitude, lon1: precedent.longitude,
                lat2: courant.latitude,   lon2: courant.longitude
            )
        }
        return total
    }

    /// Distance parcourue en milles nautiques.
    var distanceMillesNautiques: Double {
        distanceMetres / 1852.0
    }

    /// Vitesse moyenne en nœuds, calculée sur le temps de navigation.
    /// nil tant que la sortie n'a pas de durée exploitable.
    var vitesseMoyenneNoeuds: Double? {
        guard let navigation = dureeNavigation, navigation > 0 else { return nil }
        let metresParSeconde = distanceMetres / navigation
        return metresParSeconde * Self.noeudsParMetreSeconde
    }

    /// Vitesse maximale relevée en nœuds, d'après les mesures du récepteur GPS.
    /// nil si aucun point ne porte de mesure valide.
    var vitesseMaxNoeuds: Double? {
        let vitesses = pointsGPS.compactMap(\.vitesseNoeuds)
        guard let maximum = vitesses.max() else { return nil }
        return maximum
    }

    /// Consommation horaire en litres par heure, rapportée au temps de navigation.
    /// nil tant que le plein du retour n'a pas été saisi.
    var consommationLitresParHeure: Double? {
        guard
            let litres = carburantLitres, litres > 0,
            let navigation = dureeNavigation, navigation > 0
        else { return nil }
        return litres / (navigation / 3600.0)
    }

    /// Consommation rapportée à la distance, en litres par mille nautique.
    var consommationLitresParMille: Double? {
        guard
            let litres = carburantLitres, litres > 0
        else { return nil }
        let milles = distanceMillesNautiques
        guard milles > 0 else { return nil }
        return litres / milles
    }

    // MARK: - Libellés du bilan

    /// Distance formatée « 12,4 MN ». nil tant qu'aucune distance n'a été parcourue.
    /// Le mille nautique plutôt que le kilomètre : c'est l'unité des cartes Navionics.
    var distanceFormatee: String? {
        let milles = distanceMillesNautiques
        guard milles > 0.05 else { return nil }
        return String(format: "%.1f MN", milles)
    }

    /// Vitesse moyenne formatée « 8,2 nds », calculée sur le temps de navigation.
    var vitesseMoyenneFormatee: String? {
        guard let noeuds = vitesseMoyenneNoeuds, noeuds > 0.1 else { return nil }
        return String(format: "%.1f nds", noeuds)
    }

    /// Vitesse maximale formatée « 24,7 nds ».
    var vitesseMaxFormatee: String? {
        guard let noeuds = vitesseMaxNoeuds, noeuds > 0.1 else { return nil }
        return String(format: "%.1f nds", noeuds)
    }

    /// Consommation horaire formatée « 11,3 L/h ».
    /// nil tant que le plein du retour n'a pas été saisi : rien ne s'affiche
    /// plutôt qu'un tiret, même parti pris que les segments vides de l'alerte
    /// de suppression.
    var consommationHoraireFormatee: String? {
        guard let litresHeure = consommationLitresParHeure, litresHeure > 0 else { return nil }
        return String(format: "%.1f L/h", litresHeure)
    }

    /// Consommation à la distance formatée « 1,4 L/MN ».
    var consommationParMilleFormatee: String? {
        guard let litresMille = consommationLitresParMille, litresMille > 0 else { return nil }
        return String(format: "%.1f L/MN", litresMille)
    }

    /// Trois indicateurs de la ligne de synthèse du journal, dans l'ordre
    /// d'affichage : navigation, distance, consommation. Les valeurs absentes
    /// sont omises, la ligne se réduit d'elle-même.
    var indicateursJournal: [String] {
        [dureeNavigationFormatee, distanceFormatee, consommationHoraireFormatee]
            .compactMap { $0 }
    }

    // MARK: - Propriétés calculées utilitaires

    /// Nombre de prises gardées.
    var nombrePrisesGardees: Int {
        prises.filter { !$0.relache }.count
    }

    /// Prises disposant de coordonnées, exportables en waypoints GPX.
    var prisesGeolocalisees: [Prise] {
        prises.filter { $0.latitude != nil && $0.longitude != nil }
    }

    /// L'export GPX a-t-il matière à produire un fichier ?
    /// Une sortie sans trace mais avec trois prises pointées reste exportable.
    var exportGPXPossible: Bool {
        !pointsGPS.isEmpty || !prisesGeolocalisees.isEmpty
    }

    // MARK: - Helpers de calcul (privés, statiques)

    private static let noeudsParMetreSeconde: Double = 1.943844

    /// Distance orthodromique entre deux positions, en mètres.
    private static func haversine(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        let rayonTerre = 6_371_000.0
        let phi1 = lat1 * .pi / 180
        let phi2 = lat2 * .pi / 180
        let deltaPhi = (lat2 - lat1) * .pi / 180
        let deltaLambda = (lon2 - lon1) * .pi / 180

        let a = sin(deltaPhi / 2) * sin(deltaPhi / 2)
            + cos(phi1) * cos(phi2) * sin(deltaLambda / 2) * sin(deltaLambda / 2)
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return rayonTerre * c
    }

    private static func formatDuree(_ intervalle: TimeInterval?) -> String? {
        guard let d = intervalle, d > 0 else { return nil }
        let heures  = Int(d) / 3600
        let minutes = (Int(d) % 3600) / 60
        if heures > 0 { return "\(heures)h \(minutes)min" }
        return "\(minutes)min"
    }

    private static func formatDateCourte(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale     = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }

    // MARK: - Helpers d'encodage (privés, statiques)

    private static func encoder(_ conditions: ConditionsPeche?) -> Data? {
        guard let c = conditions else { return nil }
        return try? JSONEncoder().encode(c)
    }

    private static func decoder(_ data: Data?) -> ConditionsPeche? {
        guard let d = data else { return nil }
        return try? JSONDecoder().decode(ConditionsPeche.self, from: d)
    }

    private static func encoderIDs(_ ids: [Int]) -> Data? {
        return try? JSONEncoder().encode(ids)
    }

    private static func decoderIDs(_ data: Data?) -> [Int] {
        guard let d = data else { return [] }
        return (try? JSONDecoder().decode([Int].self, from: d)) ?? []
    }
}

// MARK: - Prise

@Model
final class Prise {

    // MARK: Identification
    var id: UUID

    // MARK: Temporel
    var heure: Date

    // MARK: Espèce
    /// rawValue de l'enum Espece — saisie via picker, pas de saisie libre.
    var especeNom: String
    /// Espèce hors liste enum, saisie libre.
    var especeLibre: String?

    // MARK: Mensurations
    var tailleCm: Double?
    var poidsKg: Double?
    var relache: Bool

    // MARK: Leurre
    /// ID du leurre dans la boîte (Int, résolu à l'affichage via BoiteLeurresViewModel).
    var leurreID: Int?
    /// Nom libre si leurre hors boîte.
    var leurreLibre: String?
    /// Copie de la photo du leurre au moment de la prise — indépendante de la boîte.
    @Attribute(.externalStorage)
    var leurrePhotoData: Data?

    // MARK: Localisation
    /// Relevée par CoreLocation à l'enregistrement de la prise, y compris sans
    /// trace GPS armée. Alimente les waypoints de l'export GPX.
    var latitude: Double?
    var longitude: Double?

    // MARK: Conditions — backing privé
    /// ConditionsPeche encodé. Accès via la propriété calculée `conditions`.
    private var conditionsData: Data?

    // MARK: Photo du poisson
    @Attribute(.externalStorage)
    var photoData: Data?

    // MARK: Relation inverse
    var sortie: Sortie?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        heure: Date = Date(),
        especeNom: String = "",
        especeLibre: String? = nil,
        tailleCm: Double? = nil,
        poidsKg: Double? = nil,
        relache: Bool = false,
        leurreID: Int? = nil,
        leurreLibre: String? = nil,
        leurrePhotoData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        conditions: ConditionsPeche? = nil,
        photoData: Data? = nil
    ) {
        self.id               = id
        self.heure            = heure
        self.especeNom        = especeNom
        self.especeLibre      = especeLibre
        self.tailleCm         = tailleCm
        self.poidsKg          = poidsKg
        self.relache          = relache
        self.leurreID         = leurreID
        self.leurreLibre      = leurreLibre
        self.leurrePhotoData  = leurrePhotoData
        self.latitude         = latitude
        self.longitude        = longitude
        self.conditionsData   = Self.encoder(conditions)
        self.photoData        = photoData
    }

    // MARK: - Propriété calculée publique

    /// Conditions au moment de la prise, décodées depuis conditionsData.
    var conditions: ConditionsPeche? {
        get { Self.decoder(conditionsData) }
        set { conditionsData = Self.encoder(newValue) }
    }

    // MARK: - Propriétés utilitaires

    /// Nom affiché : libellé de l'enum Espece si le rawValue est reconnu,
    /// sinon la saisie libre, sinon un libellé de repli.
    var especeAffichee: String {
        if !especeNom.isEmpty {
            return Espece(rawValue: especeNom)?.displayName ?? especeNom
        }
        if let libre = especeLibre, !libre.isEmpty { return libre }
        return "Espèce inconnue"
    }

    /// Description courte pour les listes.
    var descriptionCourte: String {
        var parts: [String] = [especeAffichee]
        if let t = tailleCm { parts.append("\(Int(t)) cm") }
        if let p = poidsKg  { parts.append(String(format: "%.1f kg", p)) }
        return parts.joined(separator: " • ")
    }

    /// La prise est-elle pointée sur la carte ?
    var estGeolocalisee: Bool {
        latitude != nil && longitude != nil
    }

    // MARK: - Helper d'encodage (privé, statique)

    private static func encoder(_ conditions: ConditionsPeche?) -> Data? {
        guard let c = conditions else { return nil }
        return try? JSONEncoder().encode(c)
    }

    private static func decoder(_ data: Data?) -> ConditionsPeche? {
        guard let d = data else { return nil }
        return try? JSONDecoder().decode(ConditionsPeche.self, from: d)
    }
}

// MARK: - PointGPS

@Model
final class PointGPS {

    // MARK: Identification
    var id: UUID

    // MARK: Données
    var timestamp: Date
    var latitude: Double
    var longitude: Double

    /// Numéro de segment de trace. Incrémenté à chaque reprise après pause.
    /// L'export GPX écrit un <trkseg> par segment : sans cela, Boating tracerait
    /// une droite entre le dernier point avant l'arrêt et le premier après.
    var segment: Int = 0

    /// Vitesse instantanée mesurée par le récepteur, en mètres par seconde.
    /// Valeur négative = mesure invalide, écartée des calculs.
    var vitesseMS: Double = -1

    // MARK: Relation inverse
    var sortie: Sortie?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double,
        segment: Int = 0,
        vitesseMS: Double = -1
    ) {
        self.id        = id
        self.timestamp = timestamp
        self.latitude  = latitude
        self.longitude = longitude
        self.segment   = segment
        self.vitesseMS = vitesseMS
    }

    // MARK: - Propriété utilitaire

    /// Vitesse en nœuds, nil si la mesure du récepteur était invalide.
    var vitesseNoeuds: Double? {
        guard vitesseMS >= 0 else { return nil }
        return vitesseMS * 1.943844
    }
}
