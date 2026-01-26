//
//  APIConfig.swift
//  Go Les Picots V.4
//
//  ⚠️ IMPORTANT : Ce fichier contient des clés API sensibles
//  ⚠️ NE JAMAIS commiter ce fichier dans Git
//  ⚠️ Ajoutez "APIConfig.swift" dans votre .gitignore
//

import Foundation

struct APIConfig {
    /// Clé API OpenWeatherMap (météo)
    static let openWeatherMapKey = "7cc82c01cf82b7f7dcced03eca56bc20"
    
    /// Clé API Stormglass.io (marées + soleil/lune + météo marine)
    static let stormglassKey = "c25b2d8c-f586-11f0-b27a-0242ac120004-c25b2dfa-f586-11f0-b27a-0242ac120004" // ⚠️ À REMPLACER
}
