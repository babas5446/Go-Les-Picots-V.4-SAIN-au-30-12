//
//  JournalViewModel.swift
//  Go les Picots V.4 — Journal de sorties
//
//  ViewModel principal du Journal de sorties.
//
//  Responsabilités :
//  - CRUD des Sortie via ModelContext SwiftData
//  - Cycle de vie d'une sortie (démarrer / terminer)
//  - Pré-remplissage des conditions depuis UserDefaults
//  - Ajout / suppression de Prise sur une Sortie
//  - Délégation trace GPS à TraceGPSService
//
//  Convention :
//  - @Query délégué aux vues (même pattern que BoiteLeurresViewModel)
//  - ModelContext injecté à l'init
//  - Clé UserDefaults partagée avec SuggestionInputView
//

import Foundation
import SwiftUI
import SwiftData
import Combine

// MARK: - Clé UserDefaults partagée

enum JournalConstants {
    static let dernieresConditionsKey = "dernieresConditionsPeche"
}

// MARK: - JournalViewModel

@MainActor
final class JournalViewModel: ObservableObject {

    // MARK: - Contexte SwiftData

    private let context: ModelContext

    // MARK: - Services

    let traceGPS: TraceGPSService

    // MARK: - État UI

    @Published var sortieEnCours: Sortie?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Initialisation

    init(context: ModelContext) {
        self.context    = context
        self.traceGPS   = TraceGPSService()
    }

    @MainActor
    convenience init() {
        self.init(context: LeurreStorageService.shared.mainContext)
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

    /// Crée une nouvelle Sortie avec pré-remplissage des conditions.
    /// Retourne la Sortie créée pour navigation immédiate vers le formulaire.
    @discardableResult
    func creerSortie(nomSpot: String = "") -> Sortie {
        let conditions = dernieresConditions()
        let sortie = Sortie(
            date:        Date(),
            heureDepart: Date(),
            nomSpot:     nomSpot,
            conditions:  conditions
        )
        context.insert(sortie)
        sauvegarder()
        return sortie
    }

    // MARK: - Modification de sortie

    /// Met à jour les champs d'une sortie existante et sauvegarde.
    func modifierSortie(_ sortie: Sortie) {
        sauvegarder()
    }

    // MARK: - Cycle de vie

    /// Démarre la trace GPS et marque l'heure de départ.
    func demarrerSortie(_ sortie: Sortie) {
        sortie.heureDepart = Date()
        sortieEnCours = sortie
        traceGPS.demarrerTrace(sortie: sortie, context: context)
        sauvegarder()
    }

    /// Termine la sortie : arrête la trace GPS et enregistre l'heure de retour.
    func terminerSortie(_ sortie: Sortie) {
        sortie.heureRetour = Date()
        traceGPS.arreterTrace()
        sortieEnCours = nil
        sauvegarder()
    }

    // MARK: - Suppression de sortie

    /// Supprime une sortie et toutes ses prises / points GPS (cascade SwiftData).
    func supprimerSortie(_ sortie: Sortie) {
        if sortieEnCours?.id == sortie.id {
            traceGPS.arreterTrace()
            sortieEnCours = nil
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
    /// Les conditions sont pré-remplies depuis les dernières conditions connues.
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
        return prise
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

    /// Exporte la trace GPS d'une sortie au format GPX.
    /// Retourne l'URL du fichier temporaire pour UIActivityViewController.
    func exporterGPX(sortie: Sortie) -> URL? {
        guard !sortie.pointsGPS.isEmpty else {
            signalerErreur("Aucun point GPS enregistré pour cette sortie")
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
    /// Utilisé par JournalView via @Query + appliquerTri().
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
