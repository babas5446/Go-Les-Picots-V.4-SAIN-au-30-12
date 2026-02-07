//
//  SpotStorageService.swift
//  Go Les Picots V.4
//
//  Service de persistance des spots de pêche avec SwiftData
//

import Foundation
import SwiftData
import CoreLocation
import Combine

@MainActor
final class SpotStorageService: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Liste de tous les spots
    @Published var spots: [FishingSpot] = []
    
    /// Indicateur de chargement
    @Published var isLoading: Bool = false
    
    /// Erreur éventuelle
    @Published var error: SpotStorageError?
    
    // MARK: - Private Properties
    
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext
    
    // MARK: - Initialisation
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = ModelContext(modelContainer)
        
        // Chargement initial
        Task {
            await loadSpots()
        }
    }
    
    /// Initialisation avec configuration par défaut
    convenience init() {
        do {
            let schema = Schema([FishingSpot.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            let container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            self.init(modelContainer: container)
        } catch {
            fatalError("Impossible d'initialiser ModelContainer: \(error)")
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Charge tous les spots depuis SwiftData
    func loadSpots() async {
        isLoading = true
        error = nil
        
        do {
            let descriptor = FetchDescriptor<FishingSpot>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            spots = try modelContext.fetch(descriptor)
            isLoading = false
        } catch {
            self.error = .fetchFailed(error.localizedDescription)
            isLoading = false
        }
    }
    
    /// Ajoute un nouveau spot
    func addSpot(_ spot: FishingSpot) async throws {
        modelContext.insert(spot)
        try saveContext()
        await loadSpots()
    }
    
    /// Crée et ajoute un spot depuis des coordonnées
    func createSpot(
        name: String,
        coordinate: CLLocationCoordinate2D,
        notes: String? = nil
    ) async throws -> FishingSpot {
        let spot = FishingSpot(
            name: name,
            coordinate: coordinate,
            notes: notes
        )
        try await addSpot(spot)
        return spot
    }
    
    /// Met à jour un spot existant
    func updateSpot(_ spot: FishingSpot) async throws {
        // SwiftData track automatiquement les modifications
        try saveContext()
        await loadSpots()
    }
    
    /// Supprime un spot
    func deleteSpot(_ spot: FishingSpot) async throws {
        modelContext.delete(spot)
        try saveContext()
        await loadSpots()
    }
    
    /// Supprime plusieurs spots
    func deleteSpots(_ spots: [FishingSpot]) async throws {
        for spot in spots {
            modelContext.delete(spot)
        }
        try saveContext()
        await loadSpots()
    }
    
    /// Supprime tous les spots
    func deleteAllSpots() async throws {
        for spot in self.spots {
            modelContext.delete(spot)
        }
        try saveContext()
        await loadSpots()
    }
    
    // MARK: - Query Methods
    
    /// Récupère un spot par son ID
    func getSpot(by id: UUID) -> FishingSpot? {
        spots.first { $0.id == id }
    }
    
    /// Recherche spots par nom
    func searchSpots(query: String) -> [FishingSpot] {
        guard !query.isEmpty else { return spots }
        
        let lowercasedQuery = query.lowercased()
        return spots.filter { spot in
            spot.name.lowercased().contains(lowercasedQuery) ||
            (spot.notes?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
    
    /// Filtre spots par catégorie
    func filterSpots(by category: SpotCategory) -> [FishingSpot] {
        spots.filter { $0.category == category }
    }
    
    /// Récupère spots récents (< 30 jours)
    func getRecentSpots(days: Int = 30) -> [FishingSpot] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return spots.filter { $0.createdAt >= cutoffDate }
    }
    
    /// Tri spots par distance depuis une position
    func sortedByDistance(from location: CLLocation) -> [FishingSpot] {
        spots.sorted { spot1, spot2 in
            spot1.distance(from: location) < spot2.distance(from: location)
        }
    }
    
    /// Tri spots par nom (A-Z)
    func sortedByName() -> [FishingSpot] {
        spots.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Tri spots par date (récent → ancien)
    func sortedByDate() -> [FishingSpot] {
        spots.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Statistics
    
    /// Nombre total de spots
    var totalSpots: Int {
        spots.count
    }
    
    /// Nombre de spots récents
    var recentSpotsCount: Int {
        spots.filter { $0.isRecent }.count
    }
    
    /// Spots en Nouvelle-Calédonie
    var spotsInNewCaledonia: [FishingSpot] {
        spots.filter { $0.isInNewCaledonia }
    }
    
    /// Spots hors Nouvelle-Calédonie
    var spotsOutsideNewCaledonia: [FishingSpot] {
        spots.filter { !$0.isInNewCaledonia }
    }
    
    // MARK: - Private Helpers
    
    private func saveContext() throws {
        do {
            try modelContext.save()
        } catch {
            self.error = .saveFailed(error.localizedDescription)
            throw error
        }
    }
}

// MARK: - SpotStorageError

enum SpotStorageError: LocalizedError {
    case fetchFailed(String)
    case saveFailed(String)
    case deleteFailed(String)
    case spotNotFound
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Échec du chargement des spots: \(message)"
        case .saveFailed(let message):
            return "Échec de l'enregistrement: \(message)"
        case .deleteFailed(let message):
            return "Échec de la suppression: \(message)"
        case .spotNotFound:
            return "Spot introuvable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .fetchFailed, .saveFailed, .deleteFailed:
            return "Réessayez dans quelques instants"
        case .spotNotFound:
            return "Le spot a peut-être été supprimé"
        }
    }
}

// MARK: - Preview Helper

#if DEBUG
extension SpotStorageService {
    /// Service de test pour previews (en mémoire)
    static var preview: SpotStorageService {
        let schema = Schema([FishingSpot.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        let container = try! ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        let service = SpotStorageService(modelContainer: container)
        
        // Ajout de spots de test
        Task { @MainActor in
            for spot in FishingSpot.previews {
                try? await service.addSpot(spot)
            }
        }
        
        return service
    }
}
#endif
