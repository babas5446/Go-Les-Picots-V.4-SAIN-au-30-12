//
//  LeureDatabase.swift.swift
//  Go Les Picots V.4
////
//  Structure de la base de données avec metadata
//
//  Created by LANES Sebastien on 01/01/2026.
//

import Foundation

/// Structure complète de la base de données exportée
struct LeureDatabase: Codable {
    let metadata: Metadata
    let leurres: [Leurre]
    
    /// Métadonnées de la base de données
    struct Metadata: Codable {
        let version: String
        let dateCreation: String
        let nombreTotal: Int
        let description: String
        let proprietaire: String
        let source: String
    }
}
