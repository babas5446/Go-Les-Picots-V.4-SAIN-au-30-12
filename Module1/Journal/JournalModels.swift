//
//  JournalModels.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Modèles SwiftData du Journal de sorties.
//  Container partagé avec Module 1 via LeurreStorageService.
//
//  Modèles :
//  - Sortie      : entité principale (session de pêche)
//  - Prise       : rattachée à une Sortie (un poisson capturé)
//  - PointGPS    : point de trace, rattaché à une Sortie
//
//  Convention d'encodage :
//  - ConditionsPeche (struct Codable) → stocké en Data via propriété backing privée
//  - [Int] leurresSessionIDs         → stocké en Data via propriété backing privée
//  - Photos                          → @Attribute(.externalStorage)
//

import Foundation
import SwiftData

// MARK: - Sortie

@Model
final class Sortie {

    // MARK: Identification
    var id: UUID

    // MARK: Temporel
    var date: Date
    var heureDepart: Date?
    var heureRetour: Date?

    // MARK: Localisation
    var nomSpot: String
    var latitude: Double?
    var longitude: Double?

    // MARK: Conditions — backing privé
    /// ConditionsPeche encodé en JSON. Accès via la propriété calculée `conditions`.
    private var conditionsData: Data?

    // MARK: Spread de la session — backing privé
    /// [Int] des IDs de leurres de la boîte. Accès via `leurresSessionIDs`.
    private var leurresSessionIDsData: Data?

    // MARK: Relations SwiftData
    @Relationship(deleteRule: .cascade, inverse: \Prise.sortie)
    var prises: [Prise]

    @Relationship(deleteRule: .cascade, inverse: \PointGPS.sortie)
    var pointsGPS: [PointGPS]

    // MARK: Notes et photo
    var notes: String

    @Attribute(.externalStorage)
    var photoSpotData: Data?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        heureDepart: Date? = nil,
        heureRetour: Date? = nil,
        nomSpot: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        conditions: ConditionsPeche? = nil,
        leurresSessionIDs: [Int] = [],
        notes: String = "",
        photoSpotData: Data? = nil
    ) {
        self.id               = id
        self.date             = date
        self.heureDepart      = heureDepart
        self.heureRetour      = heureRetour
        self.nomSpot          = nomSpot
        self.latitude         = latitude
        self.longitude        = longitude
        self.conditionsData   = Self.encoder(conditions)
        self.leurresSessionIDsData = Self.encoderIDs(leurresSessionIDs)
        self.prises           = []
        self.pointsGPS        = []
        self.notes            = notes
        self.photoSpotData    = photoSpotData
    }

    // MARK: - Propriétés calculées publiques

    /// Conditions de pêche de la session, décodées depuis conditionsData.
    var conditions: ConditionsPeche? {
        get { Self.decoder(conditionsData) }
        set { conditionsData = Self.encoder(newValue) }
    }

    /// IDs des leurres du spread de la session, décodés depuis leurresSessionIDsData.
    var leurresSessionIDs: [Int] {
        get { Self.decoderIDs(leurresSessionIDsData) }
        set { leurresSessionIDsData = Self.encoderIDs(newValue) }
    }

    // MARK: - Propriétés calculées utilitaires

    /// Durée de la sortie en secondes, si heureDepart et heureRetour sont renseignées.
    var duree: TimeInterval? {
        guard let depart = heureDepart, let retour = heureRetour else { return nil }
        return retour.timeIntervalSince(depart)
    }

    /// Durée formatée "Xh Ymin".
    var dureeFormatee: String? {
        guard let d = duree, d > 0 else { return nil }
        let heures  = Int(d) / 3600
        let minutes = (Int(d) % 3600) / 60
        if heures > 0 { return "\(heures)h \(minutes)min" }
        return "\(minutes)min"
    }

    /// Nombre de prises gardées.
    var nombrePrisesGardees: Int {
        prises.filter { !$0.relache }.count
    }

    // MARK: - Helpers d'encodage (privés, statiques)

    private static func encoder(_ conditions: ConditionsPeche?) -> Data? {
        guard let c = conditions else { return nil }
        return try? JSONEncoder().encode(c)
    }

    private static func decoder(_ data: Data?) -> ConditionsPeche? {
        guard let d = data else { return nil }
        return try? JSONDecoder().decode(ConditionsPeche.self, from: d)
    }

    private static func encoderIDs(_ ids: [Int]) -> Data? {
        return try? JSONEncoder().encode(ids)
    }

    private static func decoderIDs(_ data: Data?) -> [Int] {
        guard let d = data else { return [] }
        return (try? JSONDecoder().decode([Int].self, from: d)) ?? []
    }
}

// MARK: - Prise

@Model
final class Prise {

    // MARK: Identification
    var id: UUID

    // MARK: Temporel
    var heure: Date

    // MARK: Espèce
    /// rawValue de l'enum Espece — saisie via picker, pas de saisie libre.
    var especeNom: String
    /// Espèce hors liste enum, saisie libre.
    var especeLibre: String?

    // MARK: Mensurations
    var tailleCm: Double?
    var poidsKg: Double?
    var relache: Bool

    // MARK: Leurre
    /// ID du leurre dans la boîte (Int, résolu à l'affichage via BoiteLeurresViewModel).
    var leurreID: Int?
    /// Nom libre si leurre hors boîte.
    var leurreLibre: String?
    /// Copie de la photo du leurre au moment de la prise — indépendante de la boîte.
    @Attribute(.externalStorage)
    var leurrePhotoData: Data?

    // MARK: Localisation
    var latitude: Double?
    var longitude: Double?

    // MARK: Conditions — backing privé
    /// ConditionsPeche encodé. Accès via la propriété calculée `conditions`.
    private var conditionsData: Data?

    // MARK: Photo du poisson
    @Attribute(.externalStorage)
    var photoData: Data?

    // MARK: Relation inverse
    var sortie: Sortie?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        heure: Date = Date(),
        especeNom: String = "",
        especeLibre: String? = nil,
        tailleCm: Double? = nil,
        poidsKg: Double? = nil,
        relache: Bool = false,
        leurreID: Int? = nil,
        leurreLibre: String? = nil,
        leurrePhotoData: Data? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        conditions: ConditionsPeche? = nil,
        photoData: Data? = nil
    ) {
        self.id               = id
        self.heure            = heure
        self.especeNom        = especeNom
        self.especeLibre      = especeLibre
        self.tailleCm         = tailleCm
        self.poidsKg          = poidsKg
        self.relache          = relache
        self.leurreID         = leurreID
        self.leurreLibre      = leurreLibre
        self.leurrePhotoData  = leurrePhotoData
        self.latitude         = latitude
        self.longitude        = longitude
        self.conditionsData   = Self.encoder(conditions)
        self.photoData        = photoData
    }

    // MARK: - Propriété calculée publique

    /// Conditions au moment de la prise, décodées depuis conditionsData.
    var conditions: ConditionsPeche? {
        get { Self.decoder(conditionsData) }
        set { conditionsData = Self.encoder(newValue) }
    }

    // MARK: - Propriété utilitaire

    /// Nom affiché : especeNom si dans la liste, sinon especeLibre, sinon "Espèce inconnue".
    var especeAffichee: String {
        if !especeNom.isEmpty { return especeNom }
        return especeLibre ?? "Espèce inconnue"
    }

    /// Description courte pour les listes.
    var descriptionCourte: String {
        var parts: [String] = [especeAffichee]
        if let t = tailleCm { parts.append("\(Int(t)) cm") }
        if let p = poidsKg  { parts.append(String(format: "%.1f kg", p)) }
        return parts.joined(separator: " • ")
    }

    // MARK: - Helper d'encodage (privé, statique)

    private static func encoder(_ conditions: ConditionsPeche?) -> Data? {
        guard let c = conditions else { return nil }
        return try? JSONEncoder().encode(c)
    }

    private static func decoder(_ data: Data?) -> ConditionsPeche? {
        guard let d = data else { return nil }
        return try? JSONDecoder().decode(ConditionsPeche.self, from: d)
    }
}

// MARK: - PointGPS

@Model
final class PointGPS {

    // MARK: Identification
    var id: UUID

    // MARK: Données
    var timestamp: Date
    var latitude: Double
    var longitude: Double

    // MARK: Relation inverse
    var sortie: Sortie?

    // MARK: - Initialisation

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        latitude: Double,
        longitude: Double
    ) {
        self.id        = id
        self.timestamp = timestamp
        self.latitude  = latitude
        self.longitude = longitude
    }
}
