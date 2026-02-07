//
//  SpotCategory.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//
//
//  Catégorisation des spots de pêche (V2)
//

import Foundation
import SwiftUI

enum SpotCategory: String, CaseIterable, Codable {
    case shallowLagoon = "shallow_lagoon"
    case deepLagoon = "deep_lagoon"
    case pass = "pass"
    case offshore = "offshore"
    case dropOff = "drop_off"
    case reef = "reef"
    
    // MARK: - Affichage
    
    var displayName: String {
        switch self {
        case .shallowLagoon: return "Lagon peu profond"
        case .deepLagoon: return "Lagon profond"
        case .pass: return "Passe"
        case .offshore: return "Hors lagon"
        case .dropOff: return "Tombant"
        case .reef: return "Récif"
        }
    }
    
    var icon: String {
        switch self {
        case .shallowLagoon: return "🏖️"
        case .deepLagoon: return "🌊"
        case .pass: return "〰️"
        case .offshore: return "🌐"
        case .dropOff: return "⬇️"
        case .reef: return "🪸"
        }
    }
    
    var description: String {
        switch self {
        case .shallowLagoon: return "Profondeur < 5m"
        case .deepLagoon: return "Profondeur 5-20m"
        case .pass: return "Zone de passage"
        case .offshore: return "Profondeur > 20m"
        case .dropOff: return "Tombant récifal"
        case .reef: return "Patate de corail"
        }
    }
    
    var color: Color {
        switch self {
        case .shallowLagoon: return .cyan.opacity(0.3)
        case .deepLagoon: return .blue.opacity(0.5)
        case .pass: return .indigo
        case .offshore: return .blue.opacity(0.8)
        case .dropOff: return .purple
        case .reef: return .orange
        }
    }
    
    // MARK: - Profondeur suggérée
    
    var suggestedDepthRange: ClosedRange<Double>? {
        switch self {
        case .shallowLagoon: return 0...5
        case .deepLagoon: return 5...20
        case .pass: return 5...30
        case .offshore: return 20...100
        case .dropOff: return 10...50
        case .reef: return 3...15
        }
    }
}

