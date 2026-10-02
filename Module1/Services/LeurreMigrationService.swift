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
    private static let cleTentatives = "migration_v4_tentatives"
    private static let tentativesMax = 3

    /// Dernière erreur de migration, consultable par l'interface (nil si aucune).
    static let cleDerniereErreur = "migration_v4_derniere_erreur"

    // MARK: - Point d'entrée public

    /// Déclenche la migration si elle n'a jamais été effectuée.
    /// Appelé depuis Go_Les_Picots_V_4App.init() — silencieux en cas d'erreur.
    static func migrerSiNecessaire(dans context: ModelContext) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: flagMigration) else {
            print("✅ Migration V4 déjà effectuée — aucune action")
            return
        }

        // Garde-fou : une migration qui échoue à chaque lancement ne doit pas
        // ralentir indéfiniment le démarrage. Après 3 échecs, on s'arrête ;
        // le fichier d'origine reste intact et l'import ZIP reste possible.
        let tentatives = defaults.integer(forKey: cleTentatives)
        guard tentatives < tentativesMax else {
            print("⚠️ Migration V4 abandonnée après \(tentatives) échecs — import ZIP manuel requis")
            return
        }
        defaults.set(tentatives + 1, forKey: cleTentatives)

        do {
            try effectuerMigration(dans: context)
            defaults.removeObject(forKey: cleDerniereErreur)
        } catch StorageError.fichierIntrouvable {
            // App neuve — aucun JSON à migrer, on pose le flag et on continue
            print("ℹ️ Aucun leurres.json trouvé — app neuve, migration inutile")
            UserDefaults.standard.set(true, forKey: flagMigration)
        } catch {
            // Échec non bloquant — l'utilisateur repart avec une boîte vide
            // Il peut réimporter via ZIP
            defaults.set(error.localizedDescription, forKey: cleDerniereErreur)
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
        // Les chemins photo sont lus une seule fois (et non un reparsing
        // complet du JSON pour chaque leurre).
        let cheminsPhotos = extraireCheminsPhotos(depuis: data)
        var compteurCrees  = 0
        var compteurIgnores = 0

        for dto in dtos {
            if idsExistants.contains(dto.id) {
                compteurIgnores += 1
                continue
            }

            // Créer l'entité SwiftData
            let leurre = dto.toLeurre()

            // Photo : Base64 (format V4) en priorité, sinon fichier sur disque
            if let b64 = dto.photoBase64, let photo = Data(base64Encoded: b64) {
                leurre.photoData = photo
            } else {
                leurre.photoData = chargerPhoto(
                    dtoPhotoPath: cheminsPhotos[dto.id],
                    photosURL: photosURL
                )
            }

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

    /// Extrait en une passe la table id → photoPath depuis le JSON brut
    /// (champ ignoré par LeurreDTO). Gère le format V2 et le format legacy.
    private static func extraireCheminsPhotos(depuis data: Data) -> [Int: String] {
        let racine = try? JSONSerialization.jsonObject(with: data)
        let elements: [[String: Any]]
        if let objet = racine as? [String: Any], let liste = objet["leurres"] as? [[String: Any]] {
            elements = liste
        } else if let liste = racine as? [[String: Any]] {
            elements = liste
        } else {
            return [:]
        }
        var table: [Int: String] = [:]
        for element in elements {
            if let id = element["id"] as? Int,
               let chemin = element["photoPath"] as? String, !chemin.isEmpty {
                table[id] = chemin
            }
        }
        return table
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

        // Fichier d'origine conservé tel quel : pas de recompression JPEG
        // (perte de qualité et temps de démarrage inutiles).
        guard let data = try? Data(contentsOf: fileURL),
              UIImage(data: data) != nil else {
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
