//
//  LeurreStorageService.swift
//  Go les Picots V.4 — Module 1
//
//  Fournit le ModelContainer SwiftData partagé pour l'ensemble de l'app.
//
//  V4 — Réécriture complète :
//  - Suppression du stack JSON/fichiers (Leurre n'est plus Codable)
//  - Suppression de la gestion des photos sur disque (photoData dans l'entité)
//  - Suppression du CRUD manuel (délégué à ModelContext dans le ViewModel)
//  - ModelContainer static, consommé via .modelContainer() dans App
//  - StorageError conservé : utilisé par LeurreMigrationService et LeurreExportService
//

import Foundation
import SwiftData

// MARK: - LeurreStorageService

enum LeurreStorageService {

    // MARK: - ModelContainer

    /// Container SwiftData partagé — injecté dans l'environnement depuis Go_Les_Picots_V_4App.
    /// Contient le schema complet de l'app (Leurre, Sortie, Prise, PointGPS).
    static let shared: ModelContainer = {
        do {
            let schema = Schema([Leurre.self, Sortie.self, Prise.self, PointGPS.self])
            let config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ LeurreStorageService — Impossible de créer le ModelContainer : \(error)")
        }
    }()
}

// MARK: - StorageError

/// Erreurs métier partagées entre LeurreStorageService, LeurreMigrationService et LeurreExportService.
enum StorageError: LocalizedError {
    case fichierIntrouvable
    case decodageEchoue(detail: String)
    case encodageEchoue(detail: String)
    case leurreIntrouvable(id: Int)
    case erreurPhoto(detail: String)
    case migrationDejaEffectuee
    case exportEchoue(detail: String)

    var errorDescription: String? {
        switch self {
        case .fichierIntrouvable:
            return "Fichier de données introuvable"
        case .decodageEchoue(let detail):
            return "Erreur de lecture des données : \(detail)"
        case .encodageEchoue(let detail):
            return "Erreur d'écriture des données : \(detail)"
        case .leurreIntrouvable(let id):
            return "Leurre #\(id) introuvable"
        case .erreurPhoto(let detail):
            return "Erreur photo : \(detail)"
        case .migrationDejaEffectuee:
            return "Migration déjà effectuée — aucune action requise"
        case .exportEchoue(let detail):
            return "Erreur d'export : \(detail)"
        }
    }
}
