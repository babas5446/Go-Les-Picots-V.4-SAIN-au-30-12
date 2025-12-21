//
//  SuggestionResult.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Modèle de résultat de suggestion avec scoring détaillé
//
//  Created: 2024-12-05
//

import Foundation

// MARK: - Résultat de Suggestion (OUTPUT)

struct SuggestionResult: Identifiable {
    let id = UUID()
    
    let leurre: Leurre
    let scoreTechnique: Double      // /40
    let scoreCouleur: Double        // /30
    let scoreConditions: Double     // /30
    let scoreTotal: Double          // /100
    
    var niveauEtoiles: Int {
        switch scoreTotal {
        case 80...100: return 5
        case 70..<80: return 4
        case 60..<70: return 3
        case 50..<60: return 2
        default: return 1
        }
    }
    
    var niveauQualite: String {
        switch scoreTotal {
        case 80...100: return "EXCELLENT"
        case 70..<80: return "TRÈS BON"
        case 60..<70: return "BON"
        case 50..<60: return "CORRECT"
        default: return "À ÉVITER"
        }
    }
    
    // Position attribuée sur le spread
    var positionSpread: PositionSpread?
    var distanceSpread: Int?  // en mètres
    
    // Justifications pédagogiques
    var justificationTechnique: String
    var justificationCouleur: String
    var justificationConditions: String
    var justificationPosition: String
    var astucePro: String
    
    // Détails scoring (pour debug/transparence)
    var detailsScoring: ScoringDetails
}

// MARK: - Détails du scoring

struct ScoringDetails: Codable {
    // Phase 1 : Technique (40 points)
    let compatibiliteZone: Double           // /15
    let compatibiliteProfondeur: Double     // /10
    let compatibiliteVitesse: Double        // /10
    let compatibiliteEspeces: Double        // /5
    
    // Phase 2 : Couleur (30 points)
    let bonusLuminosite: Double             // /10
    let bonusTurbidite: Double              // /10
    let bonusContraste: Double              // /10
    
    // Phase 3 : Conditions (30 points)
    let bonusMoment: Double                 // /10
    let bonusMer: Double                    // /8
    let bonusMaree: Double                  // /6
    let bonusLune: Double                   // /6
    
    let multiplicateurContextuel: Double
    
    // Calculé
    var totalTechnique: Double {
        compatibiliteZone + compatibiliteProfondeur + 
        compatibiliteVitesse + compatibiliteEspeces
    }
    
    var totalCouleur: Double {
        bonusLuminosite + bonusTurbidite + bonusContraste
    }
    
    var totalConditions: Double {
        (bonusMoment + bonusMer + bonusMaree + bonusLune) * multiplicateurContextuel
    }
}

// MARK: - Configuration Spread Complète

struct ConfigurationSpread: Identifiable {
    let id = UUID()
    
    let conditions: ConditionsPeche
    let suggestions: [SuggestionResult]  // Triées par score
    let dateGeneration: Date
    
    var spreadComplet: [PositionSpreadAttribuee] {
        return suggestions.compactMap { suggestion in
            guard let position = suggestion.positionSpread,
                  let distance = suggestion.distanceSpread else {
                return nil
            }
            
            return PositionSpreadAttribuee(
                position: position,
                leurre: suggestion.leurre,
                distance: distance,
                role: determinerRole(suggestion),
                justification: suggestion.justificationPosition
            )
        }
    }
    
    private func determinerRole(_ suggestion: SuggestionResult) -> String {
        switch suggestion.leurre.contraste {
        case .naturel: return "Naturel"
        case .flashy: return "Flashy"
        case .sombre: return "Sombre"
        case .contraste: return "Contrasté"
        }
    }
    
    var strategieSpread: String {
        let nbLignes = conditions.nombreLignes
        
        switch nbLignes {
        case 1:
            return "Configuration 1 ligne : Meilleur leurre polyvalent"
        case 2:
            return "Configuration 2 lignes : Meilleur + Contraste opposé"
        case 3:
            return "Configuration 3 lignes : Meilleur + Contraste + Shotgun discret"
        case 4:
            return "Configuration 4 lignes : 2 Corners + 2 Riggers (spread équilibré)"
        case 5:
            return "Configuration 5 lignes : Spread complet avec couverture maximale"
        default:
            return "Configuration personnalisée"
        }
    }
}

struct PositionSpreadAttribuee: Identifiable {
    let id = UUID()
    let position: PositionSpread
    let leurre: Leurre
    let distance: Int  // en mètres
    let role: String   // "Naturel", "Sombre", "Flashy", "Contrasté"
    let justification: String
    
    var distanceFormatee: String {
        return "\(distance)m"
    }
    
    var iconeRole: String {
        switch role {
        case "Naturel": return "🐟"
        case "Flashy": return "✨"
        case "Sombre": return "🌑"
        case "Contrasté": return "🎨"
        default: return "🎣"
        }
    }
}

// MARK: - Extensions utilitaires

extension SuggestionResult {
    
    /// Retourne une description courte pour affichage rapide
    var resumeCourt: String {
        return """
        \(leurre.nom) (\(leurre.marque))
        Score : \(Int(scoreTotal))/100 (\(niveauQualite))
        \(leurre.longueur)cm • \(leurre.couleurPrincipale.displayName)
        """
    }
    
    /// Génère un texte de justification complète formaté
    var justificationComplete: String {
        return """
        🎯 TECHNIQUE (\(Int(scoreTechnique))/40)
        \(justificationTechnique)
        
        🎨 COULEUR (\(Int(scoreCouleur))/30)
        \(justificationCouleur)
        
        🌊 CONDITIONS (\(Int(scoreConditions))/30)
        \(justificationConditions)
        
        📍 POSITION : \(positionSpread?.displayName ?? "Libre")
        \(justificationPosition)
        
        💡 ASTUCE PRO
        \(astucePro)
        """
    }
    
    /// Vérifie si le leurre est adapté (score >= 50)
    var estAdapte: Bool {
        return scoreTotal >= 50
    }
    
    /// Vérifie si le leurre est recommandé (score >= 70)
    var estRecommande: Bool {
        return scoreTotal >= 70
    }
    
    /// Vérifie si le leurre est excellent (score >= 80)
    var estExcellent: Bool {
        return scoreTotal >= 80
    }
}

extension ConfigurationSpread {
    
    /// Retourne le nombre de leurres suggérés
    var nombreSuggestions: Int {
        return suggestions.count
    }
    
    /// Retourne les leurres excellents (score >= 80)
    var suggestionsExcellentes: [SuggestionResult] {
        return suggestions.filter { $0.scoreTotal >= 80 }
    }
    
    /// Retourne les leurres recommandés (score >= 70)
    var suggestionsRecommandees: [SuggestionResult] {
        return suggestions.filter { $0.scoreTotal >= 70 }
    }
    
    /// Vérifie si le spread est complet
    var spreadEstComplet: Bool {
        return spreadComplet.count == conditions.nombreLignes
    }
    
    /// Retourne un résumé du spread
    var resumeSpread: String {
        let positions = spreadComplet.map { "\($0.position.displayName): \($0.leurre.nom)" }
        return positions.joined(separator: "\n")
    }
}
