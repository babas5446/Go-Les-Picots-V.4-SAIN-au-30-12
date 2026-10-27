//
//  GLPSchema.swift
//  Go les Picots V.4 — Persistance
//
//  Versionnement du schéma SwiftData.
//
//  Pourquoi : sans version déclarée, toute modification future d'un modèle
//  (ajout d'un champ obligatoire, renommage, changement de type) laisserait
//  SwiftData deviner seul la migration ; en cas d'échec, la base ne s'ouvre
//  plus. Avec un plan de migration, chaque évolution du schéma devient une
//  étape écrite, testable, et la base de l'utilisateur la franchit sans perte.
//
//  Mode d'emploi pour une évolution future (V4) :
//  1. Figer les modèles actuels : copier leurs propriétés enregistrées dans
//     GLPSchemaV3 (classes imbriquées, comme GLPSchemaV1 et V2), sans rien changer.
//  2. Créer GLPSchemaV4 (version 4.0.0) qui liste les modèles vivants modifiés.
//  3. Ajouter GLPSchemaV4 à la fin de `schemas` et une étape
//     .lightweight(fromVersion: GLPSchemaV3.self, toVersion: GLPSchemaV4.self)
//     ou .custom(...) si des données doivent être transformées.
//  4. Tester la migration sur le simulateur avec une vraie boîte (ancienne
//     version + import ZIP, puis nouvelle version par-dessus) avant l'iPhone.
//

import Foundation
import SwiftData

/// Version 1 : état du modèle du 2 au 27 octobre 2026 (V4.2 corrigée).
///
/// Copie FIGÉE des quatre modèles tels qu'ils étaient enregistrés sur
/// l'appareil avant le schéma V2. SwiftData compare cette description à la
/// base pour la reconnaître, puis la fait passer en V2 : ne jamais modifier
/// ces classes (seulement les propriétés enregistrées comptent ; les
/// propriétés calculées et les méthodes des modèles vivants n'y figurent pas).
nonisolated enum GLPSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [GLPSchemaV1.Leurre.self, GLPSchemaV1.Sortie.self,
         GLPSchemaV1.Prise.self, GLPSchemaV1.PointGPS.self]
    }

    @Model final class Leurre {
        @Attribute(.unique) var id: Int
        var nom: String
        var marque: String
        var modele: String?
        var typeLeurre: TypeLeurre
        var typePeche: TypePeche
        var typesPecheCompatibles: [TypePeche]?
        var longueur: Double
        var poids: Double?
        var couleurPrincipale: Couleur
        var couleurPrincipaleCustomData: Data?
        var couleurSecondaire: Couleur?
        var couleurSecondaireCustomData: Data?
        var finition: Finition?
        var typesDeNage: [TypeDeNage]?
        var profondeurNageMin: Double?
        var profondeurNageMax: Double?
        var vitesseTraineMin: Double?
        var vitesseTraineMax: Double?
        var notes: String?
        @Attribute(.externalStorage) var photoData: Data?
        var contraste: Contraste?
        var zonesAdaptees: [Zone]?
        var especesCibles: [String]?
        var positionsSpread: [PositionSpread]?
        var conditionsOptimales: ConditionsOptimales?
        var isComputed: Bool = false
        var notesMotsCles: [String] = []
        var qualiteDataScore: Int = 0
        var quantite: Int = 1
        var dateAjout: Date?

        init(id: Int, nom: String, marque: String, typeLeurre: TypeLeurre,
             typePeche: TypePeche, longueur: Double, couleurPrincipale: Couleur) {
            self.id = id
            self.nom = nom
            self.marque = marque
            self.typeLeurre = typeLeurre
            self.typePeche = typePeche
            self.longueur = longueur
            self.couleurPrincipale = couleurPrincipale
        }
    }

    @Model final class Sortie {
        var id: UUID
        var nomSortie: String = ""
        var date: Date
        var heureDepart: Date?
        var heureRetour: Date?
        var etatRaw: String = "nonDemarree"   // EtatSortie.nonDemarree
        var cumulPausesSecondes: Double = 0
        var debutPauseCourante: Date?
        var carburantLitres: Double?
        var nomSpot: String
        var latitude: Double?
        var longitude: Double?
        var conditionsData: Data?
        var leurresSessionIDsData: Data?
        var spreadsData: Data?
        @Relationship(deleteRule: .cascade, inverse: \GLPSchemaV1.Prise.sortie)
        var prises: [GLPSchemaV1.Prise]
        @Relationship(deleteRule: .cascade, inverse: \GLPSchemaV1.PointGPS.sortie)
        var pointsGPS: [GLPSchemaV1.PointGPS]
        var notes: String
        @Attribute(.externalStorage)
        var photoSpotData: Data?

        init(id: UUID, date: Date, nomSpot: String, notes: String) {
            self.id = id
            self.date = date
            self.nomSpot = nomSpot
            self.notes = notes
            self.prises = []
            self.pointsGPS = []
        }
    }

    @Model final class Prise {
        var id: UUID
        var heure: Date
        var especeNom: String
        var especeLibre: String?
        var tailleCm: Double?
        var poidsKg: Double?
        var relache: Bool
        var leurreID: Int?
        var leurreLibre: String?
        @Attribute(.externalStorage)
        var leurrePhotoData: Data?
        var latitude: Double?
        var longitude: Double?
        var conditionsData: Data?
        @Attribute(.externalStorage)
        var photoData: Data?
        var sortie: GLPSchemaV1.Sortie?

        init(id: UUID, heure: Date, especeNom: String, relache: Bool) {
            self.id = id
            self.heure = heure
            self.especeNom = especeNom
            self.relache = relache
        }
    }

    @Model final class PointGPS {
        var id: UUID
        var timestamp: Date
        var latitude: Double
        var longitude: Double
        var segment: Int = 0
        var vitesseMS: Double = -1
        var sortie: GLPSchemaV1.Sortie?

        init(id: UUID, timestamp: Date, latitude: Double, longitude: Double) {
            self.id = id
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}

/// Version 2 : état du modèle du 27 au 28 octobre 2026 (installée sur
/// l'iPhone le 27 octobre). Copie FIGÉE : V1 + couleurVentre, eclatVentre,
/// transparence sur Leurre. Ne jamais modifier ces classes.
nonisolated enum GLPSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [GLPSchemaV2.Leurre.self, GLPSchemaV2.Sortie.self,
         GLPSchemaV2.Prise.self, GLPSchemaV2.PointGPS.self]
    }

    @Model final class Leurre {
        @Attribute(.unique) var id: Int
        var nom: String
        var marque: String
        var modele: String?
        var typeLeurre: TypeLeurre
        var typePeche: TypePeche
        var typesPecheCompatibles: [TypePeche]?
        var longueur: Double
        var poids: Double?
        var couleurPrincipale: Couleur
        var couleurPrincipaleCustomData: Data?
        var couleurSecondaire: Couleur?
        var couleurSecondaireCustomData: Data?
        var finition: Finition?
        var couleurVentre: Couleur?
        var eclatVentre: EclatVentre?
        var transparence: Transparence?
        var typesDeNage: [TypeDeNage]?
        var profondeurNageMin: Double?
        var profondeurNageMax: Double?
        var vitesseTraineMin: Double?
        var vitesseTraineMax: Double?
        var notes: String?
        @Attribute(.externalStorage) var photoData: Data?
        var contraste: Contraste?
        var zonesAdaptees: [Zone]?
        var especesCibles: [String]?
        var positionsSpread: [PositionSpread]?
        var conditionsOptimales: ConditionsOptimales?
        var isComputed: Bool = false
        var notesMotsCles: [String] = []
        var qualiteDataScore: Int = 0
        var quantite: Int = 1
        var dateAjout: Date?

        init(id: Int, nom: String, marque: String, typeLeurre: TypeLeurre,
             typePeche: TypePeche, longueur: Double, couleurPrincipale: Couleur) {
            self.id = id
            self.nom = nom
            self.marque = marque
            self.typeLeurre = typeLeurre
            self.typePeche = typePeche
            self.longueur = longueur
            self.couleurPrincipale = couleurPrincipale
        }
    }

    @Model final class Sortie {
        var id: UUID
        var nomSortie: String = ""
        var date: Date
        var heureDepart: Date?
        var heureRetour: Date?
        var etatRaw: String = "nonDemarree"   // EtatSortie.nonDemarree
        var cumulPausesSecondes: Double = 0
        var debutPauseCourante: Date?
        var carburantLitres: Double?
        var nomSpot: String
        var latitude: Double?
        var longitude: Double?
        var conditionsData: Data?
        var leurresSessionIDsData: Data?
        var spreadsData: Data?
        @Relationship(deleteRule: .cascade, inverse: \GLPSchemaV2.Prise.sortie)
        var prises: [GLPSchemaV2.Prise]
        @Relationship(deleteRule: .cascade, inverse: \GLPSchemaV2.PointGPS.sortie)
        var pointsGPS: [GLPSchemaV2.PointGPS]
        var notes: String
        @Attribute(.externalStorage)
        var photoSpotData: Data?

        init(id: UUID, date: Date, nomSpot: String, notes: String) {
            self.id = id
            self.date = date
            self.nomSpot = nomSpot
            self.notes = notes
            self.prises = []
            self.pointsGPS = []
        }
    }

    @Model final class Prise {
        var id: UUID
        var heure: Date
        var especeNom: String
        var especeLibre: String?
        var tailleCm: Double?
        var poidsKg: Double?
        var relache: Bool
        var leurreID: Int?
        var leurreLibre: String?
        @Attribute(.externalStorage)
        var leurrePhotoData: Data?
        var latitude: Double?
        var longitude: Double?
        var conditionsData: Data?
        @Attribute(.externalStorage)
        var photoData: Data?
        var sortie: GLPSchemaV2.Sortie?

        init(id: UUID, heure: Date, especeNom: String, relache: Bool) {
            self.id = id
            self.heure = heure
            self.especeNom = especeNom
            self.relache = relache
        }
    }

    @Model final class PointGPS {
        var id: UUID
        var timestamp: Date
        var latitude: Double
        var longitude: Double
        var segment: Int = 0
        var vitesseMS: Double = -1
        var sortie: GLPSchemaV2.Sortie?

        init(id: UUID, timestamp: Date, latitude: Double, longitude: Double) {
            self.id = id
            self.timestamp = timestamp
            self.latitude = latitude
            self.longitude = longitude
        }
    }
}

/// Version 3 (28 octobre 2026) : motif (tigré, pois) et couleurMotif,
/// facultatifs, sur Leurre. Modèles vivants de l'app.
nonisolated enum GLPSchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Leurre.self, Sortie.self, Prise.self, PointGPS.self]
    }
}

/// Plan de migration de la base.
nonisolated enum GLPMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GLPSchemaV1.self, GLPSchemaV2.self, GLPSchemaV3.self]
    }

    /// V1 → V2 : ventre et transparence ; V2 → V3 : motif et sa couleur.
    /// Ajouts de champs facultatifs, migrations légères (aucune donnée
    /// transformée ; les lignes « Ventre : » des notes sont converties
    /// ensuite par l'app, au recalcul unique de la boîte).
    static var stages: [MigrationStage] {
        [
            .lightweight(fromVersion: GLPSchemaV1.self, toVersion: GLPSchemaV2.self),
            .lightweight(fromVersion: GLPSchemaV2.self, toVersion: GLPSchemaV3.self)
        ]
    }
}
