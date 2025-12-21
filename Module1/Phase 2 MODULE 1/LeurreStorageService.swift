//
//  LeurreStorageService.swift
//  Go les Picots - Module 1 Phase 2
//
//  Service de persistance pour les leurres
//  - Gestion du JSON (bundle → Documents)
//  - Stockage des photos en fichiers séparés
//  - Sauvegarde automatique
//
//  Created: 2024-12-10
//

import Foundation
import SwiftUI

// MARK: - Erreurs du service

enum StorageError: Error, LocalizedError {
    case fichierIntrouvable
    case ecritureImpossible
    case lectureImpossible
    case decodageEchoue(String)
    case encodageEchoue
    case photoNonTrouvee
    case urlInvalide
    
    var errorDescription: String? {
        switch self {
        case .fichierIntrouvable:
            return "Fichier de base de données introuvable"
        case .ecritureImpossible:
            return "Impossible d'écrire dans le fichier"
        case .lectureImpossible:
            return "Impossible de lire le fichier"
        case .decodageEchoue(let detail):
            return "Erreur de décodage JSON : \(detail)"
        case .encodageEchoue:
            return "Erreur d'encodage JSON"
        case .photoNonTrouvee:
            return "Photo non trouvée"
        case .urlInvalide:
            return "URL invalide"
        }
    }
}

// MARK: - Service de stockage

class LeurreStorageService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LeurreStorageService()
    
    // MARK: - Constantes
    private let nomFichierJSON = "leurres_database.json"
    private let nomFichierBundle = "leurres_database_COMPLET"
    private let dossierPhotos = "photos_leurres"
    
    // MARK: - File Manager
    private let fileManager = FileManager.default
    
    // MARK: - Chemins
    
    /// Dossier Documents de l'app
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// Chemin du fichier JSON dans Documents
    private var jsonFileURL: URL {
        documentsDirectory.appendingPathComponent(nomFichierJSON)
    }
    
    /// Dossier pour les photos
    private var photosDirectory: URL {
        documentsDirectory.appendingPathComponent(dossierPhotos)
    }
    
    // MARK: - Initialisation
    
    private init() {
        creerDossierPhotos()
        migrerBundleVersDocumentsSiNecessaire()
    }
    
    /// Crée le dossier photos s'il n'existe pas
    private func creerDossierPhotos() {
        if !fileManager.fileExists(atPath: photosDirectory.path) {
            do {
                try fileManager.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
                print("📁 Dossier photos créé : \(photosDirectory.path)")
            } catch {
                print("❌ Erreur création dossier photos : \(error)")
            }
        }
    }
    
    /// Copie le JSON du bundle vers Documents au premier lancement
    private func migrerBundleVersDocumentsSiNecessaire() {
        // Si le fichier existe déjà dans Documents, on ne fait rien
        if fileManager.fileExists(atPath: jsonFileURL.path) {
            print("✅ Base de données existante dans Documents")
            return
        }
        
        // Chercher le fichier dans le bundle
        guard let bundleURL = Bundle.main.url(forResource: nomFichierBundle, withExtension: "json") else {
            print("⚠️ Fichier JSON non trouvé dans le bundle, création d'une base vide")
            creerBaseVide()
            return
        }
        
        // Copier vers Documents
        do {
            try fileManager.copyItem(at: bundleURL, to: jsonFileURL)
            print("✅ Base de données migrée du bundle vers Documents")
        } catch {
            print("❌ Erreur migration : \(error)")
            creerBaseVide()
        }
    }
    
    /// Crée une base de données vide
    private func creerBaseVide() {
        let baseVide = LeurreDatabase(
            metadata: DatabaseMetadata(
                version: "1.0",
                dateCreation: ISO8601DateFormatter().string(from: Date()),
                derniereMiseAJour: ISO8601DateFormatter().string(from: Date()),
                nombreTotal: 0,
                proprietaire: "Utilisateur"
            ),
            leurres: []
        )
        
        do {
            try sauvegarderDatabase(baseVide)
            print("✅ Base de données vide créée")
        } catch {
            print("❌ Erreur création base vide : \(error)")
        }
    }
    
    // MARK: - Chargement
    
    /// Charge la base de données complète
    func chargerDatabase() throws -> LeurreDatabase {
        guard fileManager.fileExists(atPath: jsonFileURL.path) else {
            throw StorageError.fichierIntrouvable
        }
        
        do {
            let data = try Data(contentsOf: jsonFileURL)
            let decoder = JSONDecoder()
            let database = try decoder.decode(LeurreDatabase.self, from: data)
            print("✅ Base chargée : \(database.leurres.count) leurres")
            return database
        } catch let decodingError as DecodingError {
            throw StorageError.decodageEchoue(decodingError.localizedDescription)
        } catch {
            throw StorageError.lectureImpossible
        }
    }
    
    /// Charge uniquement les leurres
    func chargerLeurres() throws -> [Leurre] {
        let database = try chargerDatabase()
        return database.leurres
    }
    
    // MARK: - Sauvegarde
    
    /// Sauvegarde la base de données complète
    func sauvegarderDatabase(_ database: LeurreDatabase) throws {
        var dbMiseAJour = database
        dbMiseAJour.metadata.derniereMiseAJour = ISO8601DateFormatter().string(from: Date())
        dbMiseAJour.metadata.nombreTotal = database.leurres.count
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(dbMiseAJour)
            try data.write(to: jsonFileURL, options: .atomic)
            print("✅ Base sauvegardée : \(dbMiseAJour.leurres.count) leurres")
        } catch is EncodingError {
            throw StorageError.encodageEchoue
        } catch {
            throw StorageError.ecritureImpossible
        }
    }
    
    /// Sauvegarde les leurres (recharge les metadata existantes)
    func sauvegarderLeurres(_ leurres: [Leurre]) throws {
        var database: LeurreDatabase
        
        do {
            database = try chargerDatabase()
            database.leurres = leurres
        } catch {
            // Si pas de base existante, en créer une nouvelle
            database = LeurreDatabase(
                metadata: DatabaseMetadata(
                    version: "1.0",
                    dateCreation: ISO8601DateFormatter().string(from: Date()),
                    derniereMiseAJour: ISO8601DateFormatter().string(from: Date()),
                    nombreTotal: leurres.count,
                    proprietaire: "Utilisateur"
                ),
                leurres: leurres
            )
        }
        
        try sauvegarderDatabase(database)
    }
    
    // MARK: - Gestion des IDs
    
    /// Génère le prochain ID disponible
    func genererNouvelID() -> Int {
        do {
            let leurres = try chargerLeurres()
            let maxID = leurres.map { $0.id }.max() ?? 0
            return maxID + 1
        } catch {
            return 1
        }
    }
    
    // MARK: - CRUD Leurres
    
    /// Ajoute un nouveau leurre
    func ajouterLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.append(leurre)
        try sauvegarderLeurres(leurres)
    }
    
    /// Modifie un leurre existant
    func modifierLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        
        guard let index = leurres.firstIndex(where: { $0.id == leurre.id }) else {
            throw StorageError.fichierIntrouvable
        }
        
        leurres[index] = leurre
        try sauvegarderLeurres(leurres)
    }
    
    /// Supprime un leurre
    func supprimerLeurre(_ leurre: Leurre) throws {
        var leurres = try chargerLeurres()
        leurres.removeAll { $0.id == leurre.id }
        try sauvegarderLeurres(leurres)
        
        // Supprimer aussi la photo associée si elle existe
        if let photoPath = leurre.photoPath {
            supprimerPhoto(chemin: photoPath)
        }
    }
    
    // MARK: - Gestion des Photos
    
    /// Chemin complet d'une photo
    func cheminCompletPhoto(nomFichier: String) -> URL {
        return photosDirectory.appendingPathComponent(nomFichier)
    }
    
    /// Sauvegarde une photo depuis UIImage
    func sauvegarderPhoto(image: UIImage, pourLeurreID id: Int) throws -> String {
        // Compresser l'image en JPEG
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw StorageError.encodageEchoue
        }
        
        let nomFichier = "leurre_\(id)_\(UUID().uuidString.prefix(8)).jpg"
        let url = cheminCompletPhoto(nomFichier: nomFichier)
        
        do {
            try data.write(to: url)
            print("✅ Photo sauvegardée : \(nomFichier)")
            return nomFichier
        } catch {
            throw StorageError.ecritureImpossible
        }
    }
    
    /// Charge une photo depuis le chemin
    func chargerPhoto(chemin: String) -> UIImage? {
        let url = cheminCompletPhoto(nomFichier: chemin)
        
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
    
    /// Télécharge une image depuis une URL web
    func telechargerPhotoDepuisURL(_ urlString: String, pourLeurreID id: Int) async throws -> String {
        guard let url = URL(string: urlString) else {
            throw StorageError.urlInvalide
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw StorageError.lectureImpossible
        }
        
        guard let image = UIImage(data: data) else {
            throw StorageError.decodageEchoue("Impossible de décoder l'image")
        }
        
        return try sauvegarderPhoto(image: image, pourLeurreID: id)
    }
    
    /// Supprime une photo
    func supprimerPhoto(chemin: String) {
        let url = cheminCompletPhoto(nomFichier: chemin)
        
        if fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
                print("🗑️ Photo supprimée : \(chemin)")
            } catch {
                print("⚠️ Erreur suppression photo : \(error)")
            }
        }
    }
    
    // MARK: - Utilitaires
    
    /// Retourne des statistiques sur la base
    func statistiques() -> (nombreLeurres: Int, nombrePhotos: Int, tailleBase: String) {
        var nombreLeurres = 0
        var nombrePhotos = 0
        var tailleBase: Int64 = 0
        
        // Compter les leurres
        if let leurres = try? chargerLeurres() {
            nombreLeurres = leurres.count
        }
        
        // Compter les photos
        if let fichiers = try? fileManager.contentsOfDirectory(atPath: photosDirectory.path) {
            nombrePhotos = fichiers.filter { $0.hasSuffix(".jpg") || $0.hasSuffix(".png") }.count
        }
        
        // Taille du fichier JSON
        if let attrs = try? fileManager.attributesOfItem(atPath: jsonFileURL.path),
           let size = attrs[.size] as? Int64 {
            tailleBase = size
        }
        
        let tailleFormatee: String
        if tailleBase < 1024 {
            tailleFormatee = "\(tailleBase) octets"
        } else if tailleBase < 1024 * 1024 {
            tailleFormatee = String(format: "%.1f Ko", Double(tailleBase) / 1024)
        } else {
            tailleFormatee = String(format: "%.1f Mo", Double(tailleBase) / (1024 * 1024))
        }
        
        return (nombreLeurres, nombrePhotos, tailleFormatee)
    }
    
    /// Réinitialise la base (recopie depuis le bundle)
    func reinitialiserBase() throws {
        // Supprimer le fichier actuel
        if fileManager.fileExists(atPath: jsonFileURL.path) {
            try fileManager.removeItem(at: jsonFileURL)
        }
        
        // Supprimer les photos
        if fileManager.fileExists(atPath: photosDirectory.path) {
            try fileManager.removeItem(at: photosDirectory)
            creerDossierPhotos()
        }
        
        // Recopier depuis le bundle
        migrerBundleVersDocumentsSiNecessaire()
    }
}
