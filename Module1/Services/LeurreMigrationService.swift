//
//  LeurreMigrationService.swift
//  Go les Picots V.4 — Module 1
//
//  Migration one-shot : ancien format JSON + photos disque → SwiftData.
//
//  Déclenchement : au premier lancement de l'app depuis Go_Les_Picots_V_4App.init()
//  Stratégie doublons : les leurres dont l'id existe déjà dans SwiftData sont ignorés.
//  Sécurité : leurres.json est archivé en leurres.json.bak, jamais supprimé.
//  Idempotence : flag UserDefaults "migration_v4_effectuee" — sans effet après le premier run.
//

import Foundation
import SwiftData
import UIKit

// MARK: - LeurreMigrationService

enum LeurreMigrationService {

    // MARK: - Constantes

    private static let flagMigration = "migration_v4_effectuee"
    private static let nomFichierJSON = "leurres.json"
    private static let nomFichierBackup = "leurres.json.bak"
    private static let nomDossierPhotos = "photos"

    // MARK: - Point d'entrée public

    /// Déclenche la migration si elle n'a jamais été effectuée.
    /// Appelé depuis Go_Les_Picots_V_4App.init() — silencieux en cas d'erreur.
    static func migrerSiNecessaire(dans context: ModelContext) {
        guard !UserDefaults.standard.bool(forKey: flagMigration) else {
            print("✅ Migration V4 déjà effectuée — aucune action")
            return
        }

        do {
            try effectuerMigration(dans: context)
        } catch StorageError.fichierIntrouvable {
            // App neuve — aucun JSON à migrer, on pose le flag et on continue
            print("ℹ️ Aucun leurres.json trouvé — app neuve, migration inutile")
            UserDefaults.standard.set(true, forKey: flagMigration)
        } catch {
            // Échec non bloquant — l'utilisateur repart avec une boîte vide
            // Il peut réimporter via ZIP
            print("⚠️ Migration V4 échouée : \(error.localizedDescription)")
            print("⚠️ L'utilisateur peut réimporter ses leurres via le ZIP de sauvegarde")
        }
    }

    // MARK: - Migration principale

    private static func effectuerMigration(dans context: ModelContext) throws {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        )[0]

        let jsonURL    = documentsURL.appendingPathComponent(nomFichierJSON)
        let backupURL  = documentsURL.appendingPathComponent(nomFichierBackup)
        let photosURL  = documentsURL.appendingPathComponent(nomDossierPhotos)

        // 1. Vérifier la présence du fichier JSON
        guard FileManager.default.fileExists(atPath: jsonURL.path) else {
            throw StorageError.fichierIntrouvable
        }

        // 2. Décoder le JSON
        let data = try Data(contentsOf: jsonURL)
        let dtos = try decoderJSON(data: data)

        print("📦 Migration V4 — \(dtos.count) leurres à traiter")

        // 3. Récupérer les IDs déjà présents dans SwiftData (éviter les doublons)
        let idsExistants = try recupererIDsExistants(dans: context)
        print("🗂️ \(idsExistants.count) leurres déjà présents dans SwiftData")

        // 4. Insérer les leurres absents
        var compteurCrees  = 0
        var compteurIgnores = 0

        for dto in dtos {
            if idsExistants.contains(dto.id) {
                compteurIgnores += 1
                continue
            }

            // Créer l'entité SwiftData
            let leurre = dto.toLeurre()

            // Charger la photo depuis le disque si disponible
            leurre.photoData = chargerPhoto(
                dtoPhotoPath: extrairePhotoPath(depuis: data, pourID: dto.id),
                photosURL: photosURL
            )

            context.insert(leurre)
            compteurCrees += 1
        }

        // 5. Persister
        try context.save()
        print("💾 Migration V4 — \(compteurCrees) leurres créés, \(compteurIgnores) ignorés")

        // 6. Archiver le JSON original (ne jamais supprimer)
        archiverJSON(source: jsonURL, destination: backupURL)

        // 7. Poser le flag — migration terminée
        UserDefaults.standard.set(true, forKey: flagMigration)
        print("✅ Migration V4 terminée avec succès")
    }

    // MARK: - Décodage JSON

    /// Tente le nouveau format (LeurreDatabase), puis l'ancien format (array direct).
    private static func decoderJSON(data: Data) throws -> [LeurreDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Nouveau format V2 avec metadata
        if let database = try? decoder.decode(LeurreDatabase.self, from: data) {
            print("📄 Format JSON détecté : V2 (avec metadata)")
            return database.leurres
        }

        // Ancien format — array direct de LeurreDTO
        if let dtos = try? decoder.decode([LeurreDTO].self, from: data) {
            print("📄 Format JSON détecté : legacy (array direct)")
            return dtos
        }

        throw StorageError.decodageEchoue(detail: "Format JSON non reconnu")
    }

    // MARK: - IDs existants

    private static func recupererIDsExistants(dans context: ModelContext) throws -> Set<Int> {
        let descriptor = FetchDescriptor<Leurre>()
        let leurres = try context.fetch(descriptor)
        return Set(leurres.map { $0.id })
    }

    // MARK: - Extraction photoPath depuis le JSON brut

    /// Extrait le champ photoPath depuis le JSON brut pour un id donné.
    /// On reparse le JSON brut pour récupérer ce champ ignoré par LeurreDTO.
    private static func extrairePhotoPath(depuis data: Data, pourID id: Int) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let leurresArray = json["leurres"] as? [[String: Any]] else {
            // Tentative format legacy (array direct)
            guard let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return nil
            }
            return array.first { $0["id"] as? Int == id }?["photoPath"] as? String
        }
        return leurresArray.first { $0["id"] as? Int == id }?["photoPath"] as? String
    }

    // MARK: - Chargement photo

    /// Charge la photo depuis le dossier photos/ sur disque.
    /// Retourne nil si le chemin est absent ou le fichier introuvable.
    private static func chargerPhoto(dtoPhotoPath: String?, photosURL: URL) -> Data? {
        guard let chemin = dtoPhotoPath, !chemin.isEmpty else { return nil }

        let fileURL = photosURL.appendingPathComponent(chemin)

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("⚠️ Photo introuvable sur disque : \(chemin)")
            return nil
        }

        guard let image = UIImage(contentsOfFile: fileURL.path),
              let data = image.jpegData(compressionQuality: 0.8) else {
            print("⚠️ Photo illisible : \(chemin)")
            return nil
        }

        return data
    }

    // MARK: - Archivage JSON

    /// Copie leurres.json vers leurres.json.bak — ne supprime jamais l'original.
    private static func archiverJSON(source: URL, destination: URL) {
        do {
            // Remplacer un éventuel backup précédent
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: source, to: destination)
            print("📁 JSON archivé : \(destination.lastPathComponent)")
        } catch {
            // Non bloquant — la migration est déjà réussie
            print("⚠️ Archivage JSON échoué (non bloquant) : \(error.localizedDescription)")
        }
    }
}
