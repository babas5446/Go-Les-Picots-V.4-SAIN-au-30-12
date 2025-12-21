//
//  LeurreStorageService.swift
//  Go les Picots - Module 1 Phase 2
//
//  Service de stockage et persistance des leurres
//  - Chargement/sauvegarde JSON
//  - Gestion des photos
//  - Migration automatique depuis le bundle
//
//  Created: 2024-12-16
//

import Foundation
import UIKit

// MARK: - Erreurs

enum StorageError: LocalizedError {
    case fichierIntrouvable
    case decodageEchoue(String)
    case encodageEchoue
    case sauvegardeEchouee(String)
    case photoIntrouvable
    case photoInvalide
    
    var errorDescription: String? {
        switch self {
        case .fichierIntrouvable:
            return "Fichier de base de données introuvable"
        case .decodageEchoue(let detail):
            return "Erreur de lecture : \(detail)"
        case .encodageEchoue:
            return "Erreur d'encodage des données"
        case .sauvegardeEchouee(let detail):
            return "Erreur de sauvegarde : \(detail)"
        case .photoIntrouvable:
            return "Photo introuvable"
        case .photoInvalide:
            return "Format de photo invalide"
        }
    }
}

// MARK: - Wrapper JSON

struct LeureDatabase: Codable {
    let metadata: Metadata?
    let leurres: [Leurre]
    
    struct Metadata: Codable {
        let version: String?
        let dateCreation: String?
        let nombreTotal: Int?
        let description: String?
        let proprietaire: String?
        let source: String?
    }
}

// MARK: - Service Principal

class LeurreStorageService {
    
    static let shared = LeurreStorageService()
    
    // MARK: - Chemins de fichiers
    
    private let nomFichierJSON = "leurres_database_COMPLET.json"
    private let nomDossierPhotos = "photos_leurres"
    
    private var urlDocuments: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var urlFichierJSON: URL {
        urlDocuments.appendingPathComponent(nomFichierJSON)
    }
    
    private var urlDossierPhotos: URL {
        let url = urlDocuments.appendingPathComponent(nomDossierPhotos)
        
        // Créer le dossier s'il n'existe pas
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            print("📁 Dossier photos créé : \(url.path)")
        }
        
        return url
    }
    
    // MARK: - Chargement
    
    /// Charge tous les leurres depuis le JSON
    func chargerLeurres() throws -> [Leurre] {
        // 1. Vérifier si le fichier existe dans Documents
        if !FileManager.default.fileExists(atPath: urlFichierJSON.path) {
            print("📦 Fichier JSON introuvable dans Documents, migration depuis le bundle...")
            try migrerDepuisBundle()
        }
        
        // 2. Charger les données
        let data: Data
        do {
            // Vérifier la taille du fichier
            let attributes = try FileManager.default.attributesOfItem(atPath: urlFichierJSON.path)
            if let fileSize = attributes[.size] as? Int {
                print("✅ Base de données existante dans Documents (\(fileSize) bytes)")
            }
            
            data = try Data(contentsOf: urlFichierJSON)
            
            // Afficher un aperçu du JSON pour debug
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = String(jsonString.prefix(500))
                print("🔍 Début du JSON: \(preview)")
            }
            
        } catch {
            print("❌ Erreur lecture fichier : \(error)")
            throw StorageError.fichierIntrouvable
        }
        
        // 3. Vérifier que le JSON est valide syntaxiquement
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            print("✅ JSON syntaxiquement valide")
        } catch {
            print("❌ JSON syntaxiquement INVALIDE: \(error.localizedDescription)")
            throw StorageError.decodageEchoue("Le JSON n'est pas valide syntaxiquement")
        }
        
        // 4. Décoder avec le modèle Swift
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let database = try decoder.decode(LeureDatabase.self, from: data)
            
            print("✅ Base chargée : \(database.leurres.count) leurres")
            
            if let metadata = database.metadata {
                print("📊 Version: \(metadata.version ?? "N/A")")
                print("📊 Date: \(metadata.dateCreation ?? "N/A")")
            }
            
            return database.leurres
            
        } catch let DecodingError.keyNotFound(key, context) {
            let detail = "Clé manquante: \(key.stringValue)\nChemin: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))\nDescription: \(context.debugDescription)"
            print("❌ Erreur décodage détaillée:")
            print("   - Clé manquante: \(key.stringValue)")
            print("   - Chemin: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
            print("   - Description: \(context.debugDescription)")
            throw StorageError.decodageEchoue(detail)
            
        } catch let DecodingError.typeMismatch(type, context) {
            let detail = "Type incorrect: attendu \(type)\nChemin: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))\nDescription: \(context.debugDescription)"
            print("❌ Type mismatch: \(detail)")
            throw StorageError.decodageEchoue(detail)
            
        } catch let DecodingError.valueNotFound(type, context) {
            let detail = "Valeur manquante pour type: \(type)\nChemin: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))"
            print("❌ Valeur manquante: \(detail)")
            throw StorageError.decodageEchoue(detail)
            
        } catch {
            print("❌ Erreur décodage JSON: \(error)")
            throw StorageError.decodageEchoue(error.localizedDescription)
        }
    }
    
    // MARK: - Sauvegarde
    
    /// Sauvegarde tous les leurres dans le JSON
    func sauvegarderLeurres(_ leurres: [Leurre]) throws {
        let database = LeureDatabase(
            metadata: LeureDatabase.Metadata(
                version: "2.0",
                dateCreation: ISO8601DateFormatter().string(from: Date()),
                nombreTotal: leurres.count,
                description: "Base de données des leurres - Nouvelle-Calédonie",
                proprietaire: "Utilisateur",
                source: "Application Go Les Picots"
            ),
            leurres: leurres
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(database)
            try data.write(to: urlFichierJSON, options: .atomic)
            print("✅ Base sauvegardée : \(leurres.count) leurres")
        } catch {
            print("❌ Erreur sauvegarde : \(error)")
            throw StorageError.sauvegardeEchouee(error.localizedDescription)
        }
    }
    
    // MARK: - CRUD
    
    func ajouterLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.append(leurre)
        try sauvegarderLeurres(leurres)
    }
    
    func modifierLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        
        guard let index = leurres.firstIndex(where: { $0.id == leurre.id }) else {
            throw StorageError.fichierIntrouvable
        }
        
        leurres[index] = leurre
        try sauvegarderLeurres(leurres)
    }
    
    func supprimerLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.removeAll { $0.id == leurre.id }
        try sauvegarderLeurres(leurres)
        
        // Supprimer aussi la photo si elle existe
        if let photoPath = leurre.photoPath {
            supprimerPhoto(chemin: photoPath)
        }
    }
    
    // MARK: - Photos
    
    func sauvegarderPhoto(image: UIImage, pourLeurreID id: Int) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.photoInvalide
        }
        
        let nomFichier = "leurre_\(id)_\(Date().timeIntervalSince1970).jpg"
        let urlPhoto = urlDossierPhotos.appendingPathComponent(nomFichier)
        
        try data.write(to: urlPhoto)
        print("📸 Photo sauvegardée : \(nomFichier)")
        
        return nomFichier
    }
    
    func chargerPhoto(chemin: String) -> UIImage? {
        let urlPhoto = urlDossierPhotos.appendingPathComponent(chemin)
        
        guard FileManager.default.fileExists(atPath: urlPhoto.path),
              let data = try? Data(contentsOf: urlPhoto),
              let image = UIImage(data: data) else {
            print("⚠️ Photo introuvable : \(chemin)")
            return nil
        }
        
        return image
    }
    
    func supprimerPhoto(chemin: String) {
        let urlPhoto = urlDossierPhotos.appendingPathComponent(chemin)
        try? FileManager.default.removeItem(at: urlPhoto)
        print("🗑️ Photo supprimée : \(chemin)")
    }
    
    func telechargerPhotoDepuisURL(_ urlString: String, pourLeurreID id: Int) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw StorageError.photoInvalide
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.photoInvalide
        }
        
        return try sauvegarderPhoto(image: image, pourLeurreID: id)
    }
    
    // MARK: - Migration
    
    /// Migre le fichier JSON depuis le bundle vers Documents
    private func migrerDepuisBundle() throws {
        print("🔍 === DIAGNOSTIC MIGRATION ===")
        print("🔍 Recherche du fichier dans le bundle...")
        
        // Liste tous les fichiers JSON du bundle
        if let bundlePath = Bundle.main.resourcePath {
            print("📂 Chemin du bundle : \(bundlePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                let jsonFiles = contents.filter { $0.hasSuffix(".json") }
                print("📋 Fichiers JSON trouvés dans le bundle (\(jsonFiles.count)) :")
                jsonFiles.forEach { print("   - \($0)") }
            } catch {
                print("⚠️ Impossible de lister le contenu du bundle : \(error)")
            }
        }
        
        // Essayer de trouver le fichier dans le bundle
        guard let bundleURL = Bundle.main.url(forResource: "leurres_database_COMPLET", withExtension: "json") else {
            print("❌ Fichier 'leurres_database_COMPLET.json' introuvable dans le bundle")
            print("💡 Vérifie que le fichier est bien ajouté dans Build Phases > Copy Bundle Resources")
            print("💡 Création d'une base vide...")
            // Créer une base vide si aucun fichier n'est trouvé
            try sauvegarderLeurres([])
            return
        }
        
        print("✅ Fichier trouvé : \(bundleURL.path)")
        
        // Vérifier la taille du fichier
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: bundleURL.path)
            if let fileSize = attributes[.size] as? Int {
                print("📊 Taille du fichier : \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
            }
        } catch {
            print("⚠️ Impossible de lire les attributs : \(error)")
        }
        
        print("📦 Migration depuis le bundle vers Documents...")
        
        // Copier le fichier vers Documents
        do {
            let data = try Data(contentsOf: bundleURL)
            print("✅ Données chargées : \(data.count) bytes")
            
            try data.write(to: urlFichierJSON, options: .atomic)
            print("✅ Base de données migrée avec succès vers : \(urlFichierJSON.path)")
            
            // Vérifier que le fichier existe bien après la copie
            if FileManager.default.fileExists(atPath: urlFichierJSON.path) {
                print("✅ Vérification : Fichier bien présent dans Documents")
            } else {
                print("❌ ERREUR : Fichier absent après migration !")
            }
        } catch {
            print("❌ Erreur lors de la migration : \(error)")
            throw StorageError.sauvegardeEchouee(error.localizedDescription)
        }
        
        print("🔍 === FIN DIAGNOSTIC ===")
    }
    
    // MARK: - Utilitaires
    
    func reinitialiserBase() throws {
        // Supprimer le fichier existant
        if FileManager.default.fileExists(atPath: urlFichierJSON.path) {
            try FileManager.default.removeItem(at: urlFichierJSON)
            print("🗑️ Ancienne base supprimée")
        }
        
        // Créer une base vide
        print("📝 Création d'une base vide")
        try sauvegarderLeurres([])
    }
    
    func genererNouvelID() -> Int {
        guard let leurres = try? chargerLeurres() else { return 1 }
        return (leurres.map { $0.id }.max() ?? 0) + 1
    }
    
    func statistiques() -> (nombreLeurres: Int, nombrePhotos: Int, tailleBase: String) {
        let leurres = (try? chargerLeurres()) ?? []
        
        let nombrePhotos = leurres.compactMap { $0.photoPath }.count
        
        let taille: String
        if let attributes = try? FileManager.default.attributesOfItem(atPath: urlFichierJSON.path),
           let fileSize = attributes[.size] as? Int {
            taille = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        } else {
            taille = "N/A"
        }
        
        return (leurres.count, nombrePhotos, taille)
    }
}
