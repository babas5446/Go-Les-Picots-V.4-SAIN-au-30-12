//
//  TypesCommuns.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 18/01/2026.
//
//  Types partagés entre modules (Météo, Marée, Leurres)
//

import Foundation

// MARK: - État Mer
enum EtatMer: String, Codable, CaseIterable, Hashable {
    case calme = "calme"
    case peuAgitee = "peuAgitee"
    case agitee = "agitee"
    case formee = "formee"
    
    var displayName: String {
        switch self {
        case .calme: return "Calme"
        case .peuAgitee: return "Peu agitée"
        case .agitee: return "Agitée"
        case .formee: return "Formée"
        }
    }
}

// MARK: - Phase Marée
enum PhaseMaree: String, Codable, CaseIterable, Hashable {
    case montante = "montante"
    case etaleHaut = "etaleHaut"
    case descendante = "descendante"
    case etaleBas = "etaleBas"
    
    var displayName: String {
        switch self {
        case .montante: return "Montante"
        case .etaleHaut: return "Étale haut"
        case .descendante: return "Descendante"
        case .etaleBas: return "Étale bas"
        }
    }
    
    var emoji: String {
        switch self {
        case .montante: return "⬆️"
        case .etaleHaut: return "🔝"
        case .descendante: return "⬇️"
        case .etaleBas: return "🔽"
        }
    }
}
