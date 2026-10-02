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
//  Mode d'emploi pour une évolution future :
//  1. Copier GLPSchemaV1 en GLPSchemaV2 (version 2.0.0) avec les modèles modifiés.
//  2. Ajouter GLPSchemaV2 à la fin de `schemas`.
//  3. Ajouter une étape : .lightweight(fromVersion: GLPSchemaV1.self, toVersion: GLPSchemaV2.self)
//     ou .custom(...) si des données doivent être transformées.
//

import SwiftData

/// Version 1 : état du modèle au 2 octobre 2026 (V4.2 corrigée).
nonisolated enum GLPSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Leurre.self, Sortie.self, Prise.self, PointGPS.self]
    }
}

/// Plan de migration de la base. Une seule version pour l'instant : aucune étape.
nonisolated enum GLPMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [GLPSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
