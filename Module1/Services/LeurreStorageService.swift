
//
//  LeurreStorageService.swift
//  Go les Picots V.4
//
//  Service de persistance des leurres
//  - Sauvegarde/chargement JSON
//  - Gestion des photos
//  - Gestion des IDs
//
//  Created: 2024-12-10
//

import Foundation
import UIKit

/// Service singleton pour la gestion du stockage des leurres
class LeurreStorageService {
    
    // MARK: - Singleton
    
    static let shared = LeurreStorageService()
    
    // MARK: - Properties
    
    /// URL du répertoire Documents de l'application
    let documentURL: URL
    
    /// URL du fichier JSON principal
    private let leurresURL: URL
    
    /// URL du dossier photos
    private let photosURL: URL
    
    // MARK: - Initialisation
    
    private init() {
        // Récupérer le dossier Documents
        self.documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Définir les URLs des fichiers
        self.leurresURL = documentURL.appendingPathComponent("leurres.json")
        self.photosURL = documentURL.appendingPathComponent("photos")
        
        // Créer le dossier photos si nécessaire
        try? FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        
        print("📁 Documents : \(documentURL.path)")
        print("📄 Base leurres : \(leurresURL.path)")
        print("📸 Photos : \(photosURL.path)")
    }
    
    // MARK: - Chargement
    
    /// Charge tous les leurres depuis le fichier JSON
    func chargerLeurres() throws -> [Leurre] {
        // Vérifier si le fichier existe
        guard FileManager.default.fileExists(atPath: leurresURL.path) else {
            print("⚠️ Fichier leurres.json introuvable - création d'une base vide")
            
            // Créer une base vide
            let baseVide = LeureDatabase(
                metadata: LeureDatabase.Metadata(
                    version: "2.0",
                    dateCreation: ISO8601DateFormatter().string(from: Date()),
                    nombreTotal: 0,
                    description: "Base de données Go Les Picots",
                    proprietaire: "Utilisateur",
                    source: "Application Go Les Picots V.4"
                ),
                leurres: []
            )
            
            // Sauvegarder la base vide
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let data = try encoder.encode(baseVide)
            try data.write(to: leurresURL)
            
            return []
        }
        
        // Lire le fichier
        let data = try Data(contentsOf: leurresURL)
        
        // Décoder
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            // Essayer le nouveau format avec metadata
            let database = try decoder.decode(LeureDatabase.self, from: data)
            print("✅ \(database.leurres.count) leurres chargés (format v2.0)")
            return database.leurres
            
        } catch {
            // Essayer l'ancien format (array direct)
            do {
                let leurres = try decoder.decode([Leurre].self, from: data)
                print("✅ \(leurres.count) leurres chargés (format legacy)")
                
                // Migrer vers le nouveau format
                try sauvegarderLeurres(leurres)
                
                return leurres
            } catch let decodageError {
                print("❌ Erreur de décodage : \(decodageError)")
                throw StorageError.decodageEchoue(detail: decodageError.localizedDescription)
            }
        }
    }
    
    // MARK: - Sauvegarde
    
    /// Sauvegarde tous les leurres dans le fichier JSON
    func sauvegarderLeurres(_ leurres: [Leurre]) throws {
        let database = LeureDatabase(
            metadata: LeureDatabase.Metadata(
                version: "2.0",
                dateCreation: ISO8601DateFormatter().string(from: Date()),
                nombreTotal: leurres.count,
                description: "Base de données Go Les Picots",
                proprietaire: "Utilisateur",
                source: "Application Go Les Picots V.4"
            ),
            leurres: leurres
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(database)
        try data.write(to: leurresURL, options: [.atomic])
        
        print("💾 \(leurres.count) leurres sauvegardés")
    }
    
    // MARK: - CRUD
    
    /// Ajoute un leurre
    func ajouterLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.append(leurre)
        try sauvegarderLeurres(leurres)
    }
    
    /// Modifie un leurre existant
    func modifierLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        
        guard let index = leurres.firstIndex(where: { $0.id == leurre.id }) else {
            throw StorageError.leurreIntrouvable(id: leurre.id)
        }
        
        leurres[index] = leurre
        try sauvegarderLeurres(leurres)
    }
    
    /// Supprime un leurre
    func supprimerLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.removeAll { $0.id == leurre.id }
        
        // Supprimer la photo si elle existe
        if let photoPath = leurre.photoPath {
            let photoURL = photosURL.appendingPathComponent(photoPath)
            try? FileManager.default.removeItem(at: photoURL)
        }
        
        try sauvegarderLeurres(leurres)
    }
    
    // MARK: - Gestion des IDs
    
    /// Génère un nouvel ID unique
    func genererNouvelID() -> Int {
        guard let leurres = try? chargerLeurres(), !leurres.isEmpty else {
            return 1
        }
        
        let maxID = leurres.map { $0.id }.max() ?? 0
        return maxID + 1
    }
    
    // MARK: - Gestion des photos
    
    /// Sauvegarde une photo pour un leurre
    func sauvegarderPhoto(image: UIImage, pourLeurreID leurreID: Int) throws -> String {
        // Générer un nom de fichier unique
        let timestamp = Int(Date().timeIntervalSince1970)
        let fileName = "leurre_\(leurreID)_\(timestamp).jpg"
        let fileURL = photosURL.appendingPathComponent(fileName)
        
        // Compresser et sauvegarder
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.erreurPhoto(detail: "Impossible de compresser l'image")
        }
        
        try imageData.write(to: fileURL)
        
        print("📸 Photo sauvegardée : \(fileName)")
        return fileName
    }
    
    /// Charge une photo depuis son chemin
    func chargerPhoto(chemin: String) -> UIImage? {
        let fileURL = photosURL.appendingPathComponent(chemin)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ Photo introuvable : \(chemin)")
            return nil
        }
        
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    /// Retourne l'URL complète d'une photo
    func urlPhoto(chemin: String) -> URL? {
        return photosURL.appendingPathComponent(chemin)
    }
    
    /// Télécharge une photo depuis une URL
    func telechargerPhotoDepuisURL(_ urlString: String, pourLeurreID leurreID: Int) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw StorageError.erreurPhoto(detail: "URL invalide")
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.erreurPhoto(detail: "Image invalide")
        }
        
        return try sauvegarderPhoto(image: image, pourLeurreID: leurreID)
    }
    
    /// Supprime une photo
    func supprimerPhoto(chemin: String) {
        let fileURL = photosURL.appendingPathComponent(chemin)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.removeItem(at: fileURL)
            print("🗑️ Photo supprimée : \(chemin)")
        }
    }
    
    // MARK: - Utilitaires
    
    /// Réinitialise complètement la base de données
    func reinitialiserBase() throws {
        // Supprimer le fichier JSON
        try? FileManager.default.removeItem(at: leurresURL)
        
        // Supprimer toutes les photos
        try? FileManager.default.removeItem(at: photosURL)
        try? FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
        
        // Recréer une base vide
        try sauvegarderLeurres([])
        
        print("🔄 Base de données réinitialisée")
    }
    
    /// Retourne des statistiques sur la base
    func statistiques() -> (nombreLeurres: Int, nombrePhotos: Int, tailleBase: String) {
        let leurres = (try? chargerLeurres()) ?? []
        
        let photos = (try? FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil)) ?? []
        
        let tailleJSON = (try? FileManager.default.attributesOfItem(atPath: leurresURL.path)[.size] as? Int64) ?? 0
        let tailleFormatee = ByteCountFormatter.string(fromByteCount: tailleJSON, countStyle: .file)
        
        return (leurres.count, photos.count, tailleFormatee)
    }
}

// MARK: - Erreurs

enum StorageError: LocalizedError {
    case fichierIntrouvable
    case decodageEchoue(detail: String)
    case encodageEchoue(detail: String)
    case leurreIntrouvable(id: Int)
    case erreurPhoto(detail: String)
    
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
        }
    }
}
