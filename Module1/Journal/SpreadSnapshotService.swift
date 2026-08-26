//
//  SpreadSnapshotService.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Capture d'un spread suggéré par Module 2, pour report dans le Journal.
//
//  Principe :
//  - Module 2 produit une ConfigurationSpread éphémère, vivant en mémoire
//  - Le Journal ouvre la sortie plus tard : il faut un pont persistant
//  - Ce service étend le mécanisme déjà en place pour ConditionsPeche
//    (écriture UserDefaults dans SuggestionInputView, lecture par JournalViewModel)
//
//  Indépendance des données :
//  Le nom et la marque du leurre sont recopiés dans l'instantané, comme la photo
//  l'est déjà dans Prise. Un leurre supprimé de la boîte ne doit pas vider
//  l'historique des sorties.
//
//  Une sortie peut contenir plusieurs spreads : le pêcheur remonte, change de
//  configuration, relance une suggestion. Chaque ajout crée un instantané daté.
//

import Foundation

// MARK: - Ligne de spread

/// Un leurre monté à une position donnée du spread.
struct LigneSpread: Codable, Hashable, Identifiable {

    var id: UUID = UUID()

    /// Identifiant du leurre dans la boîte — peut ne plus exister.
    var leurreID: Int

    /// Copies figées au moment de la capture.
    var nom: String
    var marque: String

    var position: PositionSpread?
    var distance: Int?

    init(
        id: UUID = UUID(),
        leurreID: Int,
        nom: String,
        marque: String,
        position: PositionSpread? = nil,
        distance: Int? = nil
    ) {
        self.id       = id
        self.leurreID = leurreID
        self.nom      = nom
        self.marque   = marque
        self.position = position
        self.distance = distance
    }

    /// « Short Corner — 15 m » ou « Position libre ».
    var descriptionPosition: String {
        guard let position = position else { return "Position libre" }
        if let distance = distance {
            return "\(position.displayName) — \(distance) m"
        }
        return position.displayName
    }
}

// MARK: - Instantané de spread

struct SpreadSnapshot: Codable, Hashable, Identifiable {

    var id: UUID = UUID()

    /// Heure de mise à l'eau de cette configuration.
    var date: Date

    var vitesseRecommandee: Double
    var lignes: [LigneSpread]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        vitesseRecommandee: Double,
        lignes: [LigneSpread]
    ) {
        self.id                 = id
        self.date               = date
        self.vitesseRecommandee = vitesseRecommandee
        self.lignes             = lignes
    }

    /// Identifiants des leurres montés, pour les statistiques.
    var leurreIDs: [Int] { lignes.map(\.leurreID) }

    var heureFormatee: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale    = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }

    var descriptionCourte: String {
        let nb = lignes.count
        let lignesTexte = nb > 1 ? "\(nb) lignes" : "\(nb) ligne"
        return "\(lignesTexte) — \(String(format: "%.1f", vitesseRecommandee)) nœuds"
    }
}

// MARK: - Construction depuis Module 2

extension SpreadSnapshot {

    /// Convertit une configuration produite par le moteur en instantané persistable.
    /// Le moteur n'est pas modifié : on ne fait que lire son résultat.
    init(configuration: SuggestionEngine.ConfigurationSpread, date: Date = Date()) {
        self.init(
            date: date,
            vitesseRecommandee: Double(configuration.vitesseRecommandee),
            lignes: configuration.suggestions.map { suggestion in
                LigneSpread(
                    leurreID: suggestion.leurre.id,
                    nom:      suggestion.leurre.nom,
                    marque:   suggestion.leurre.marque,
                    position: suggestion.positionSpread,
                    distance: suggestion.distanceSpread
                )
            }
        )
    }
}

// MARK: - Service

enum SpreadSnapshotService {

    /// Clé du dernier spread suggéré, écrite par Module 2, lue par le Journal.
    static let cleDernierSpread = "dernierSpreadSuggere"

    // MARK: Pont Module 2 → Journal

    /// Enregistre le spread produit par la dernière suggestion.
    static func enregistrerDernier(_ snapshot: SpreadSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: cleDernierSpread)
    }

    /// Relit le dernier spread suggéré. nil si aucune suggestion n'a été lancée.
    static func dernierSpread() -> SpreadSnapshot? {
        guard let data = UserDefaults.standard.data(forKey: cleDernierSpread) else { return nil }
        return try? JSONDecoder().decode(SpreadSnapshot.self, from: data)
    }

    static func effacerDernier() {
        UserDefaults.standard.removeObject(forKey: cleDernierSpread)
    }

    // MARK: Encodage pour SwiftData

    /// SwiftData ne stocke pas les structures : on passe par un backing Data,
    /// même motif que ConditionsPeche dans Sortie.
    static func encoder(_ spreads: [SpreadSnapshot]) -> Data? {
        try? JSONEncoder().encode(spreads)
    }

    static func decoder(_ data: Data?) -> [SpreadSnapshot] {
        guard let data = data,
              let spreads = try? JSONDecoder().decode([SpreadSnapshot].self, from: data)
        else { return [] }
        return spreads
    }
}
