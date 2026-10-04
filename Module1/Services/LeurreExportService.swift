//
//  LeurreExportService.swift
//  Go les Picots V.4 — Module 1
//
//  Export et import de la boîte à leurres au format ZIP.
//
//  Format V4 :
//  - Un seul fichier JSON (leurres.json) dans le ZIP
//  - Photos encodées en Base64 dans le champ photoBase64 de chaque LeurreDTO
//  - Plus de dossier photos/ séparé — import/export atomiques et symétriques
//
//  Responsabilités :
//  - Conversion Leurre (@Model) → LeurreDTO (Codable)
//  - Assemblage LeurreDatabase + DatabaseMetadata
//  - Sérialisation JSON + compression ZIP
//  - Décompression ZIP + désérialisation JSON à l'import
//  - Insertion SwiftData à l'import (doublons ignorés par id)
//  - Remplacement complet de la boîte (lecture vérifiée, sauvegarde ZIP,
//    numéros et photos conservés, remise en état en cas d'échec)
//

import Foundation
import SwiftData
import UIKit
import ZIPFoundation

// MARK: - LeurreExportService

enum LeurreExportService {

    // MARK: - Export

    /// Exporte tous les leurres fournis dans un fichier ZIP.
    /// Retourne l'URL du ZIP dans le dossier temporaire, prête pour UIActivityViewController.
    static func exporterZIP(leurres: [Leurre]) throws -> URL {

        // 1. Convertir chaque Leurre en LeurreDTO (avec photo Base64)
        let dtos = leurres.map { leurreVersDTO($0) }

        // 2. Assembler le LeurreDatabase
        let database = LeurreDatabase(
            metadata: DatabaseMetadata(
                version: "4.0",
                dateCreation: ISO8601DateFormatter().string(from: Date()),
                derniereMiseAJour: ISO8601DateFormatter().string(from: Date()),
                nombreTotal: dtos.count,
                proprietaire: "Utilisateur",
                description: "Export Go Les Picots V.4 — Nouvelle-Calédonie",
                source: "Application Go Les Picots V.4"
            ),
            leurres: dtos
        )

        // 3. Encoder en JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData: Data
        do {
            jsonData = try encoder.encode(database)
        } catch {
            throw StorageError.encodageEchoue(detail: error.localizedDescription)
        }

        // 4. Préparer les URLs temporaires
        let timestamp = horodatage()
        let tempDir   = FileManager.default.temporaryDirectory
            .appendingPathComponent("glp_export_\(timestamp)")
        let jsonURL   = tempDir.appendingPathComponent("leurres.json")
        let zipURL    = FileManager.default.temporaryDirectory
            .appendingPathComponent("go_les_picots_\(timestamp).zip")

        // Nettoyer d'éventuels restes
        try? FileManager.default.removeItem(at: tempDir)
        try? FileManager.default.removeItem(at: zipURL)

        // 5. Écrire le JSON dans le dossier temporaire
        try FileManager.default.createDirectory(
            at: tempDir, withIntermediateDirectories: true
        )
        try jsonData.write(to: jsonURL)

        // 6. Comprimer en ZIP
        do {
            try FileManager.default.zipItem(
                at: tempDir,
                to: zipURL,
                shouldKeepParent: false
            )
        } catch {
            throw StorageError.exportEchoue(detail: "Compression ZIP échouée : \(error.localizedDescription)")
        }

        // 7. Nettoyer le dossier temporaire intermédiaire
        try? FileManager.default.removeItem(at: tempDir)

        print("✅ Export ZIP : \(dtos.count) leurres — \(zipURL.lastPathComponent)")
        return zipURL
    }

    // MARK: - Import

    /// Importe les leurres depuis un fichier ZIP sélectionné par l'utilisateur.
    /// Les leurres dont l'id existe déjà dans SwiftData sont ignorés.
    /// Retourne le nombre de leurres effectivement créés.
    @discardableResult
    static func importerZIP(
        depuis zipURL: URL,
        dans context: ModelContext
    ) throws -> Int {

        // 1. Décompresser dans un dossier temporaire
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("glp_import_\(horodatage())")

        try? FileManager.default.removeItem(at: tempDir)

        do {
            try FileManager.default.unzipItem(at: zipURL, to: tempDir)
        } catch {
            throw StorageError.decodageEchoue(
                detail: "Décompression ZIP échouée : \(error.localizedDescription)"
            )
        }

        defer { try? FileManager.default.removeItem(at: tempDir) }

        // 2. Localiser leurres.json dans le ZIP décompressé
        let jsonURL = try localiserJSON(dans: tempDir)

        // 3. Décoder
        let data = try Data(contentsOf: jsonURL)
        let dtos  = try decoderJSON(data: data)

        // 4. Insérer les nouveaux leurres (vrais doublons ignorés)
        //    Les ZIP antérieurs à la V4 rangent les photos dans photos/ et
        //    référencent le fichier par photoPath : on les récupère aussi.
        let dossierPhotos = jsonURL.deletingLastPathComponent().appendingPathComponent("photos")
        let compteur = try insererDTOs(
            dtos,
            dans: context,
            cheminsPhotos: extraireCheminsPhotos(depuis: data),
            dossierPhotos: dossierPhotos
        )

        print("✅ Import ZIP : \(compteur) leurres créés, \(dtos.count - compteur) ignorés (doublons)")
        return compteur
    }
    /// Importe les leurres depuis un fichier JSON nu (non compressé).
    /// Accepte le format V4 (LeurreDatabase) comme le format legacy (array direct).
    /// Les leurres dont l'id existe déjà dans SwiftData sont ignorés.
    /// Retourne le nombre de leurres effectivement créés.
    @discardableResult
    static func importerJSON(
        depuis jsonURL: URL,
        dans context: ModelContext
    ) throws -> Int {

        let data = try Data(contentsOf: jsonURL)
        let dtos = try decoderJSON(data: data)

        let compteur = try insererDTOs(dtos, dans: context)

        print("✅ Import JSON : \(compteur) leurres créés, \(dtos.count - compteur) ignorés (doublons)")
        return compteur
    }

    // MARK: - Remplacement de la boîte

    /// Contenu d'un fichier d'import entièrement lu et vérifié, photos
    /// comprises. Rien n'est encore écrit dans la base.
    struct LotImport {
        let dtos: [LeurreDTO]
        /// Photo de chaque leurre, par numéro (Base64 V4 ou dossier photos/ des anciens ZIP).
        let photos: [Int: Data]
        var nombreAvecPhoto: Int { photos.count }
    }

    enum ErreurRemplacement: LocalizedError {
        case fichierVide
        case formatInconnu
        case numerosEnDouble([Int])
        case photoIllisible(id: Int, nom: String)

        var errorDescription: String? {
            switch self {
            case .fichierVide:
                return "Le fichier ne contient aucun leurre."
            case .formatInconnu:
                return "Format de fichier non reconnu (.zip ou .json attendu)."
            case .numerosEnDouble(let ids):
                return "Numéros en double dans le fichier : \(ids.map(String.init).joined(separator: ", "))."
            case .photoIllisible(let id, let nom):
                return "Photo illisible pour le leurre \(id) (\(nom))."
            }
        }
    }

    /// Lit et vérifie tout le fichier (ZIP ou JSON) sans toucher à la base.
    /// Une seule fiche illisible, un numéro en double ou une photo corrompue
    /// font échouer la lecture : la boîte reste alors intacte.
    static func lireLot(depuis url: URL) throws -> LotImport {
        let data: Data
        var dossierPhotos: URL? = nil
        var dossierTemporaire: URL? = nil
        defer { if let dossierTemporaire { try? FileManager.default.removeItem(at: dossierTemporaire) } }

        switch url.pathExtension.lowercased() {
        case "zip":
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("glp_remplacement_\(horodatage())")
            try? FileManager.default.removeItem(at: dir)
            do {
                try FileManager.default.unzipItem(at: url, to: dir)
            } catch {
                throw StorageError.decodageEchoue(
                    detail: "Décompression ZIP échouée : \(error.localizedDescription)"
                )
            }
            dossierTemporaire = dir
            let jsonURL = try localiserJSON(dans: dir)
            data = try Data(contentsOf: jsonURL)
            dossierPhotos = jsonURL.deletingLastPathComponent().appendingPathComponent("photos")
        case "json":
            data = try Data(contentsOf: url)
        default:
            throw ErreurRemplacement.formatInconnu
        }

        let dtos = try decoderJSON(data: data)
        guard !dtos.isEmpty else { throw ErreurRemplacement.fichierVide }

        // Les numéros sont conservés tels quels : ils doivent être uniques.
        var vus = Set<Int>()
        var doubles = Set<Int>()
        for dto in dtos where !vus.insert(dto.id).inserted { doubles.insert(dto.id) }
        guard doubles.isEmpty else { throw ErreurRemplacement.numerosEnDouble(doubles.sorted()) }

        let chemins = extraireCheminsPhotos(depuis: data)
        var photos: [Int: Data] = [:]
        for dto in dtos {
            if let b64 = dto.photoBase64, !b64.isEmpty {
                guard let photo = Data(base64Encoded: b64) else {
                    throw ErreurRemplacement.photoIllisible(id: dto.id, nom: dto.nom)
                }
                photos[dto.id] = photo
            } else if let dossier = dossierPhotos,
                      let chemin = chemins[dto.id],
                      let photo = try? Data(contentsOf: dossier.appendingPathComponent(chemin)) {
                photos[dto.id] = photo
            }
        }
        return LotImport(dtos: dtos, photos: photos)
    }

    /// Sauvegarde ZIP de la boîte actuelle dans Documents/Sauvegardes boîte,
    /// visible dans l'app Fichiers (Sur mon iPad › Go Les Picots).
    static func sauvegarderBoite(leurres: [Leurre]) throws -> URL {
        let zip = try exporterZIP(leurres: leurres)
        let documents = try FileManager.default.url(
            for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )
        let dossier = documents.appendingPathComponent("Sauvegardes boîte", isDirectory: true)
        try FileManager.default.createDirectory(at: dossier, withIntermediateDirectories: true)
        let destination = dossier.appendingPathComponent("boite_avant_remplacement_\(horodatage()).zip")
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: zip, to: destination)
        return destination
    }

    /// Remplace toute la boîte par le lot. Les numéros du fichier sont
    /// conservés (le journal désigne les leurres par leur numéro) et chaque
    /// photo revient sur sa fiche. Si l'enregistrement échoue, la boîte
    /// d'origine est remise en place, photos comprises.
    @discardableResult
    static func remplacerBoite(par lot: LotImport, dans context: ModelContext) throws -> Int {
        // Nouvelles fiches préparées avant toute suppression.
        let nouveaux: [Leurre] = lot.dtos.map { dto in
            let leurre = dto.toLeurre()
            leurre.photoData = lot.photos[dto.id]
            return leurre
        }

        // Copie de secours en mémoire de la boîte actuelle (photos comprises).
        let anciens = try context.fetch(FetchDescriptor<Leurre>())
        let secours = anciens.map { leurreVersDTO($0) }

        // 1. Suppression (enregistrée seule : les numéros sont uniques en base).
        do {
            for leurre in anciens { context.delete(leurre) }
            try context.save()
        } catch {
            context.rollback()
            throw error
        }

        // 2. Insertion de la nouvelle boîte.
        do {
            for leurre in nouveaux { context.insert(leurre) }
            try context.save()
        } catch {
            context.rollback()
            for dto in secours {
                let leurre = dto.toLeurre()
                if let b64 = dto.photoBase64 { leurre.photoData = Data(base64Encoded: b64) }
                context.insert(leurre)
            }
            try? context.save()
            throw error
        }

        print("✅ Boîte remplacée : \(anciens.count) → \(nouveaux.count) leurres, \(lot.nombreAvecPhoto) photos")
        return nouveaux.count
    }

    // MARK: - Insertion SwiftData

    /// Insère les DTO absents de la base et retourne le nombre de créations.
    /// Partagé par importerZIP et importerJSON — déduplication par id.
    private static func insererDTOs(
        _ dtos: [LeurreDTO],
        dans context: ModelContext,
        cheminsPhotos: [Int: String] = [:],
        dossierPhotos: URL? = nil
    ) throws -> Int {

        // Leurres déjà présents, indexés par id
        let descriptor = FetchDescriptor<Leurre>()
        let existants  = try context.fetch(descriptor)
        var parID: [Int: Leurre] = [:]
        for leurre in existants { parID[leurre.id] = leurre }
        var prochainID = (existants.map { $0.id }.max() ?? 0) + 1

        var compteur = 0
        for dto in dtos {
            let leurre = dto.toLeurre()

            if let present = parID[dto.id] {
                // Même id, même leurre : vrai doublon, ignoré.
                let memeLeurre = present.nom.caseInsensitiveCompare(dto.nom) == .orderedSame
                    && present.marque.caseInsensitiveCompare(dto.marque) == .orderedSame
                if memeLeurre { continue }
                // Même id, leurre différent (boîte d'un autre appareil) :
                // renuméroté plutôt que perdu.
                leurre.id = prochainID
                prochainID += 1
            }

            // Photo : Base64 (format V4), sinon fichier photos/ (ancien ZIP)
            if let b64 = dto.photoBase64,
               let photoData = Data(base64Encoded: b64) {
                leurre.photoData = photoData
            } else if let dossier = dossierPhotos,
                      let chemin = cheminsPhotos[dto.id],
                      let photoData = try? Data(contentsOf: dossier.appendingPathComponent(chemin)) {
                leurre.photoData = photoData
            }

            context.insert(leurre)
            parID[leurre.id] = leurre
            compteur += 1
        }

        try context.save()
        return compteur
    }

    /// Table id → photoPath lue dans le JSON brut (champ ignoré par LeurreDTO).
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

    // MARK: - Conversion Leurre → LeurreDTO

    /// Conversion complète d'un objet SwiftData vers son DTO sérialisable.
    /// La photo est encodée en Base64 si elle existe.
    static func leurreVersDTO(_ leurre: Leurre) -> LeurreDTO {

        // Encoder la photo en Base64
        let photoBase64: String?
        if let data = leurre.photoData {
            photoBase64 = data.base64EncodedString()
        } else {
            photoBase64 = nil
        }

        // Reconstruire le DTO manuellement — pas de Codable sur Leurre (@Model)
        let dto = LeurreDTO(
            id:                      leurre.id,
            nom:                     leurre.nom,
            marque:                  leurre.marque,
            modele:                  leurre.modele,
            typeLeurre:              leurre.typeLeurre,
            typePeche:               leurre.typePeche,
            typesPecheCompatibles:   leurre.typesPecheCompatibles,
            longueur:                leurre.longueur,
            poids:                   leurre.poids,
            couleurPrincipale:       leurre.couleurPrincipale,
            couleurPrincipaleCustom: leurre.couleurPrincipaleCustom,
            couleurSecondaire:       leurre.couleurSecondaire,
            couleurSecondaireCustom: leurre.couleurSecondaireCustom,
            finition:                leurre.finition,
            typesDeNage:             leurre.typesDeNage,
            profondeurNageMin:       leurre.profondeurNageMin,
            profondeurNageMax:       leurre.profondeurNageMax,
            vitesseTraineMin:        leurre.vitesseTraineMin,
            vitesseTraineMax:        leurre.vitesseTraineMax,
            notes:                   leurre.notes,
            photoBase64:             photoBase64,
            contraste:               leurre.profilVisuel,
            zonesAdaptees:           leurre.zonesAdaptees,
            especesCibles:           leurre.especesCibles,
            positionsSpread:         leurre.positionsSpread,
            conditionsOptimales:     leurre.conditionsOptimales,
            isComputed:              leurre.isComputed,
            notesMotsCles:           leurre.notesMotsCles.isEmpty ? nil : leurre.notesMotsCles,
            qualiteDataScore:        leurre.qualiteDataScore,
            quantite:                leurre.quantite,
            dateAjout:               leurre.dateAjout
        )
        return dto
    }

    // MARK: - Helpers privés

    /// Localise leurres.json dans le dossier décompressé (racine ou sous-dossier).
    private static func localiserJSON(dans dir: URL) throws -> URL {
        // Cherche en racine d'abord
        let racine = dir.appendingPathComponent("leurres.json")
        if FileManager.default.fileExists(atPath: racine.path) { return racine }

        // Cherche en profondeur 1 (ancien format avec sous-dossier)
        let contenu = (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []

        for item in contenu {
            var isDir: ObjCBool = false
            FileManager.default.fileExists(atPath: item.path, isDirectory: &isDir)
            if isDir.boolValue {
                let candidate = item.appendingPathComponent("leurres.json")
                if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            }
        }

        throw StorageError.fichierIntrouvable
    }

    /// Décode le JSON — essaie le format V4 (LeurreDatabase) puis legacy (array direct).
    static func decoderJSON(data: Data) throws -> [LeurreDTO] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        if let database = try? decoder.decode(LeurreDatabase.self, from: data) {
            return database.leurres
        }

        if let dtos = try? decoder.decode([LeurreDTO].self, from: data) {
            return dtos
        }

        throw StorageError.decodageEchoue(detail: "Format JSON non reconnu")
    }

    /// Produit un horodatage compact pour les noms de fichiers.
    private static func horodatage() -> String {
        ISO8601DateFormatter()
            .string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
            .replacingOccurrences(of: ".", with: "-")
    }
}
