//
//  JournalViewModel.swift
//  Go les Picots V.4 — Journal de sorties
//
//  ViewModel principal du Journal de sorties.
//
//  Responsabilités :
//  - CRUD des Sortie via ModelContext SwiftData
//  - Cycle de vie d'une sortie : démarrer / pause / reprendre / terminer
//  - Restauration d'une sortie restée ouverte après fermeture de l'application
//  - Pré-remplissage des conditions depuis UserDefaults
//  - Ajout / suppression de Prise sur une Sortie, avec pointage GPS opportuniste
//  - Délégation trace GPS à TraceGPSService
//
//  Convention :
//  - @Query délégué aux vues (même pattern que BoiteLeurresViewModel)
//  - ModelContext injecté à l'init
//  - Clé UserDefaults partagée avec SuggestionInputView
//
//  V4.2 :
//  - creerSortie insère la Sortie immédiatement et laisse heureDepart à nil.
//    L'objet est persisté avant que la vue ne s'ouvre : son identité ne dépend
//    plus du cycle de vie de la vue, ce qui règle la cause commune des symptômes
//    relevés en sessions 3 et 4.
//  - Quatre transitions au lieu de deux, avec comptabilité des pauses.
//  - restaurerSortieOuverte() : une sortie interrompue par la fermeture de
//    l'application repasse en pause plutôt que de rester faussement active.
//  - supprimerSiBrouillonVide() : une sortie créée puis abandonnée sans aucune
//    saisie disparaît, le journal reste propre.
//  - Le pointage GPS d'une prise est opportuniste et asynchrone : la signature
//    de ajouterPrise reste inchangée, les vues existantes compilent sans retouche.
//

import Foundation
import SwiftUI
import SwiftData
import Combine
import CoreLocation

// MARK: - Clé UserDefaults partagée

enum JournalConstants {
    static let dernieresConditionsKey = "dernieresConditionsPeche"
}

// MARK: - JournalViewModel

@MainActor
final class JournalViewModel: ObservableObject {
    
    // MARK: - Garde de restauration

    /// La restauration ne doit s'exécuter qu'une fois par lancement de
    /// l'application, non à chaque naissance du ViewModel.
    ///
    /// Le ViewModel est détruit et recréé dès que l'on quitte le Journal pour
    /// un autre module. Sans cette garde, une sortie active y était vue comme
    /// une sortie interrompue et repassait en pause à chaque retour.
    ///
    /// Une propriété statique vit aussi longtemps que le processus : elle n'est
    /// remise à false qu'au relancement de l'application, ce qui est exactement
    /// la portée recherchée.
    

    // MARK: - Contexte SwiftData

    private let context: ModelContext

    // MARK: - Services

    let traceGPS : TraceGPSService

    // MARK: - État UI

    /// Sortie active — en cours ou en pause. nil sinon.
    @Published var sortieEnCours: Sortie?

    /// Sortie retrouvée en état actif au lancement, dont la trace ne tournait
    /// plus. Renseignée une seule fois par restaurerSortieOuverte().
    @Published var sortieRestauree: Sortie?

    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Initialisation

    init(context: ModelContext) {
        self.context  = context
        self.traceGPS = TraceGPSService.shared
        restaurerSortieOuverte()
    }

    @MainActor
    convenience init() {
        self.init(context: LeurreStorageService.shared.mainContext)
    }

    // MARK: - Restauration au lancement

    /// Retrouve une sortie laissée en cours ou en pause par une fermeture de
    /// l'application.
    ///
    /// Une sortie marquée « en cours » alors que plus rien n'enregistre est un
    /// mensonge : elle repasse en pause. Le début de pause est daté du dernier
    /// point relevé, faute de savoir quand l'application s'est arrêtée. La durée
    /// de navigation reste ainsi proche de la réalité plutôt que de compter comme
    /// navigation une nuit entière.
    private func restaurerSortieOuverte() {
        // Le service de trace est partagé et vit aussi longtemps que le
        // processus. S'il enregistre encore, ou s'il est en pause armée, c'est
        // qu'aucun redémarrage n'a eu lieu : le ViewModel a simplement été
        // recréé en quittant le Journal, et il n'y a rien à restaurer. Un
        // service vierge en regard d'une sortie marquée active en base, en
        // revanche, signe un vrai relancement de l'application.
        guard !traceGPS.enregistrement, !traceGPS.enPause else { return }
        
        let descriptor = FetchDescriptor<Sortie>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        guard let toutes = try? context.fetch(descriptor) else { return }

        guard let sortie = toutes.first(where: {
            $0.etat == .enCours || $0.etat == .enPause
        }) else { return }

        if sortie.etat == .enCours {
            let dernierReleve = sortie.pointsGPS.map(\.timestamp).max() ?? Date()
            sortie.debutPauseCourante = dernierReleve
            sortie.etat = .enPause
            sauvegarder()
        }

        sortieEnCours   = sortie
        sortieRestauree = sortie
    }

    // MARK: - Conditions pré-remplies

    /// Lit les dernières conditions saisies dans SuggestionInputView.
    /// Retourne nil si aucune suggestion n'a encore été lancée.
    func dernieresConditions() -> ConditionsPeche? {
        guard let data = UserDefaults.standard.data(forKey: JournalConstants.dernieresConditionsKey),
              let conditions = try? JSONDecoder().decode(ConditionsPeche.self, from: data)
        else { return nil }
        return conditions
    }

    // MARK: - Création de sortie

    /// Crée une Sortie, l'insère immédiatement et la retourne.
    ///
    /// L'insertion immédiate est le point central de la correction : la vue
    /// reçoit un objet déjà persisté, dont l'identité ne change plus. heureDepart
    /// reste nil, faute de quoi la sortie serait « partie » avant d'avoir été
    /// démarrée.
    @discardableResult
    func creerSortie(nomSpot: String = "") -> Sortie {
        let maintenant = Date()
        let sortie = Sortie(
            nomSortie:   Self.titreParDefaut(pour: maintenant),
            date:        maintenant,
            heureDepart: nil,
            etat:        .nonDemarree,
            nomSpot:     nomSpot,
            conditions:  dernieresConditions()
        )
        context.insert(sortie)
        // Enregistrée tout de suite : une insertion en attente est validée
        // au premier fetch venu (ouverture de la fiche de prise), ce qui
        // déclenchait une recomposition de toute la pile du journal.
        sauvegarder()
        return sortie
    }

    /// Titre pré-rempli : « Sortie du 18/08/2026 ».
    private static func titreParDefaut(pour date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale     = Locale(identifier: "fr_FR")
        return "Sortie du \(f.string(from: date))"
    }

    // MARK: - Modification de sortie

    /// Met à jour les champs d'une sortie existante et sauvegarde.
    func modifierSortie(_ sortie: Sortie) {
        sauvegarder()
    }

    /// Enregistre le plein effectué au retour. La consommation horaire s'en
    /// déduit sans autre saisie.
    func enregistrerCarburant(_ litres: Double?, pour sortie: Sortie) {
        sortie.carburantLitres = (litres ?? 0) > 0 ? litres : nil
        sauvegarder()
    }

    // MARK: - Cycle de vie

    /// Démarre la sortie : heure de départ, état actif, trace GPS armée.
    func demarrerSortie(_ sortie: Sortie) {
        guard sortie.etat == .nonDemarree else { return }

        sortie.heureDepart         = Date()
        sortie.heureRetour         = nil
        sortie.cumulPausesSecondes = 0
        sortie.debutPauseCourante  = nil
        sortie.etat                = .enCours

        sortieEnCours   = sortie
        sortieRestauree = nil

        traceGPS.demarrerTrace(sortie: sortie, context: context)
        sauvegarder()
    }

    /// Suspend la sortie. Le chronomètre se fige, la trace cesse d'écrire.
    func mettreEnPause(_ sortie: Sortie) {
        guard sortie.etat == .enCours else { return }

        sortie.debutPauseCourante = Date()
        sortie.etat               = .enPause

        traceGPS.mettreEnPause()
        sauvegarder()
    }

    /// Reprend la sortie après une pause, dans un nouveau segment de trace.
    ///
    /// Deux chemins : le service est encore en pause et reprend, ou bien
    /// l'application a redémarré entre-temps et il faut réarmer la trace.
    func reprendreSortie(_ sortie: Sortie) {
        guard sortie.etat == .enPause else { return }

        if let debut = sortie.debutPauseCourante {
            sortie.cumulPausesSecondes += max(0, Date().timeIntervalSince(debut))
        }
        sortie.debutPauseCourante = nil
        sortie.etat               = .enCours

        sortieEnCours   = sortie
        sortieRestauree = nil

        if traceGPS.enPause {
            traceGPS.reprendre()
        } else {
            traceGPS.demarrerTrace(sortie: sortie, context: context)
        }
        sauvegarder()
    }

    /// Termine la sortie. Accessible depuis l'état actif comme depuis la pause :
    /// il serait absurde d'imposer une reprise pour pouvoir clôturer.
    func terminerSortie(_ sortie: Sortie) {
        guard sortie.etat == .enCours || sortie.etat == .enPause else { return }

        // Une pause en cours au moment de la clôture est comptabilisée.
        if let debut = sortie.debutPauseCourante {
            sortie.cumulPausesSecondes += max(0, Date().timeIntervalSince(debut))
            sortie.debutPauseCourante = nil
        }

        sortie.heureRetour = Date()
        sortie.etat        = .terminee

        traceGPS.arreterTrace()
        sortieEnCours   = nil
        sortieRestauree = nil

        sauvegarder()
    }

    // MARK: - Brouillon abandonné

    /// Une sortie créée puis quittée sans la moindre saisie mérite-t-elle
    /// d'être conservée ?
    ///
    /// Le titre et les conditions sont pré-remplis automatiquement : les compter
    /// comme des saisies rendrait le critère inopérant. Seule une intervention
    /// réelle de l'utilisateur compte.
    func estBrouillonVide(_ sortie: Sortie) -> Bool {
        sortie.etat == .nonDemarree
            && sortie.nomSpot.isEmpty
            && sortie.notes.isEmpty
            && sortie.prises.isEmpty
            && sortie.pointsGPS.isEmpty
            && sortie.spreads.isEmpty
            && sortie.photoSpotData == nil
            && sortie.carburantLitres == nil
            && sortie.nomSortie == Self.titreParDefaut(pour: sortie.date)
    }

    /// Supprime la sortie si elle est restée un brouillon vide.
    /// Retourne true si la suppression a eu lieu.
    @discardableResult
    func supprimerSiBrouillonVide(_ sortie: Sortie) -> Bool {
        guard estBrouillonVide(sortie) else { return false }
        context.delete(sortie)
        sauvegarder()
        return true
    }

    // MARK: - Suppression de sortie

    /// Supprime une sortie et toutes ses prises / points GPS (cascade SwiftData).
    func supprimerSortie(_ sortie: Sortie) {
        if sortieEnCours?.id == sortie.id {
            traceGPS.arreterTrace()
            sortieEnCours   = nil
            sortieRestauree = nil
        }
        context.delete(sortie)
        sauvegarder()
    }

    /// Supprime les sorties aux indices fournis dans la liste passée en paramètre.
    func supprimerSorties(_ indices: IndexSet, dans sorties: [Sortie]) {
        for index in indices {
            guard index < sorties.count else { continue }
            supprimerSortie(sorties[index])
        }
    }

    // MARK: - Gestion des prises

    /// Crée une Prise et l'attache à la Sortie.
    ///
    /// Le pointage GPS est opportuniste : si aucune coordonnée n'est fournie,
    /// une position est relevée en tâche de fond, trace armée ou non. La prise
    /// est enregistrée sans attendre, le relevé la complète ensuite. C'est ce qui
    /// permet de pointer les poissons sur Boating même sans trace.
    @discardableResult
    func ajouterPrise(
        a sortie: Sortie,
        especeNom: String,
        especeLibre: String? = nil,
        tailleCm: Double? = nil,
        poidsKg: Double? = nil,
        relache: Bool = false,
        leurreID: Int? = nil,
        leurreLibre: String? = nil,
        leurrePhotoData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        photoData: Data? = nil
    ) -> Prise {
        let conditions = dernieresConditions()
        let prise = Prise(
            heure:           Date(),
            especeNom:       especeNom,
            especeLibre:     especeLibre,
            tailleCm:        tailleCm,
            poidsKg:         poidsKg,
            relache:         relache,
            leurreID:        leurreID,
            leurreLibre:     leurreLibre,
            leurrePhotoData: leurrePhotoData,
            latitude:        latitude,
            longitude:       longitude,
            conditions:      conditions,
            photoData:       photoData
        )
        prise.sortie = sortie
        sortie.prises.append(prise)
        context.insert(prise)
        sauvegarder()

        if latitude == nil || longitude == nil {
            pointerPrise(prise)
        }

        return prise
    }

    /// Relève une position et la reporte sur la prise, sans bloquer la vue.
    func pointerPrise(_ prise: Prise) {
        Task { [weak self] in
            guard let self else { return }
            guard let coordonnee = await self.traceGPS.relevePositionPonctuelle() else { return }
            // La prise (ou sa sortie) a pu être supprimée pendant le relevé.
            guard !prise.isDeleted, prise.modelContext != nil else { return }
            prise.latitude  = coordonnee.latitude
            prise.longitude = coordonnee.longitude
            self.sauvegarder()
        }
    }

    /// Modifie une prise existante.
    func modifierPrise(_ prise: Prise) {
        sauvegarder()
    }

    /// Supprime une prise d'une sortie.
    func supprimerPrise(_ prise: Prise, de sortie: Sortie) {
        sortie.prises.removeAll { $0.id == prise.id }
        context.delete(prise)
        sauvegarder()
    }

    // MARK: - Photos

    /// Sauvegarde la photo d'une sortie (spot).
    func sauvegarderPhotoSpot(image: UIImage, pourSortie sortie: Sortie) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        sortie.photoSpotData = data
        sauvegarder()
    }

    /// Sauvegarde la photo d'un poisson capturé.
    func sauvegarderPhotoPrise(image: UIImage, pourPrise prise: Prise) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        prise.photoData = data
        sauvegarder()
    }

    /// Copie la photo d'un leurre depuis la boîte vers une prise.
    func copierPhotoLeurre(leurre: Leurre, versPrise prise: Prise) {
        prise.leurrePhotoData = leurre.photoData
        sauvegarder()
    }

    // MARK: - Export GPX

    /// Exporte la trace GPS et les prises pointées d'une sortie au format GPX.
    /// Retourne l'URL du fichier temporaire pour UIActivityViewController.
    func exporterGPX(sortie: Sortie) -> URL? {
        guard sortie.exportGPXPossible else {
            signalerErreur("Ni trace GPS ni prise géolocalisée pour cette sortie")
            return nil
        }
        do {
            return try traceGPS.exporterGPX(sortie: sortie)
        } catch {
            signalerErreur("Export GPX échoué : \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Requêtes utilitaires

    /// Toutes les sorties triées par date descendante.
    func sorties() -> [Sortie] {
        let descriptor = FetchDescriptor<Sortie>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Nombre total de prises gardées toutes sorties confondues.
    var totalPrisesGardees: Int {
        sorties().reduce(0) { $0 + $1.nombrePrisesGardees }
    }

    /// Nombre total de sorties.
    var nombreSorties: Int {
        let descriptor = FetchDescriptor<Sortie>()
        return (try? context.fetchCount(descriptor)) ?? 0
    }

    // MARK: - Persistance interne

    private func sauvegarder() {
        do {
            try context.save()
        } catch {
            signalerErreur("Erreur de sauvegarde : \(error.localizedDescription)")
        }
    }

    private func signalerErreur(_ message: String) {
        errorMessage = message
        showError    = true
        print("❌ JournalViewModel : \(message)")
    }
}
