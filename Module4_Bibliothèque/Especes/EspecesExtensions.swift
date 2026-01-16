//
//  EspecesExtensions.swift
//  Go les Picots V.4
//
//  Extensions pour les enums du Module 4 - Bibliothèque
//  Évite les doublons et centralise les symboles/noms
//
//  Created: 2026-01-02
//

import Foundation

// MARK: - Extension Zone

extension Zone {
    /// Nom lisible de la zone
    var nom: String {
        switch self {
        case .lagon: return "Lagon"
        case .recif: return "Récif"
        case .passe: return "Passes"
        case .tombant: return "Tombant"
        case .large: return "Large"
        case .dcp: return "DCP"
        case .profond: return "Pêche profonde"
        }
    }
}

// MARK: - Extension TypePeche

extension TypePeche {
    /// Nom lisible de la technique
    var nom: String {
        switch self {
        case .traine: return "Traîne"
        case .jigging: return "Jigging"
        case .palangrotte: return "Palangrotte"
        case .lancer: return "Lancer"
        case .jig: return "Jig"
        case .montage: return "Montage"
        }
    }
}
