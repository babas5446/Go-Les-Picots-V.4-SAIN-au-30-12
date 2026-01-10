//
//  NoteAnalysisService.swift
//  Go les Picots
//
//  Service d'analyse des notes textuelles pour extraire automatiquement :
//  - Zones de pêche (lagon, large, passe, etc.)
//  - Espèces cibles (wahoo, thon, carangue, etc.)
//  - Positions spread (short corner, rigger, shotgun, etc.)
//  - Indications techniques diverses
//
//  Created: 2024-12-23
//

import Foundation

class NoteAnalysisService {
    
    // MARK: - 📍 Détection Zones de Pêche
    
    /// Analyse une note pour détecter les zones de pêche mentionnées
    static func detecterZones(dans texte: String) -> [Zone] {
        let texte = texte.lowercased()
        var zones: [Zone] = []
        
        // Lagon
        if texte.contains("lagon") {
            zones.append(.lagon)
        }
        
        // Récif
        if texte.contains("récif") || texte.contains("recif") {
            zones.append(.recif)
        }
        
        // Large / Hauturier
        if texte.contains("large") || 
           texte.contains("haute mer") || 
           texte.contains("hauturier") ||
           texte.contains("trolling") ||
           texte.contains("traine") {
            zones.append(.large)
        }
        
        // Profond / Tombant
        if texte.contains("profond") || 
           texte.contains("tombant") || 
           texte.contains("deep") {
            zones.append(.profond)
        }
        
        // Passe
        if texte.contains("passe") {
            zones.append(.passe)
        }
        
        // DCP
        if texte.contains("dcp") {
            zones.append(.dcp)
        }
        
        return Array(Set(zones))  // Éliminer les doublons
    }
    
    // MARK: - 🎯 Détection Espèces Cibles
    
    /// Analyse une note pour détecter les espèces mentionnées
    static func detecterEspeces(dans texte: String) -> [String] {
        let texte = texte.lowercased()
        var especes: [String] = []
        
        // Wahoo
        if texte.contains("wahoo") || texte.contains("wahou") {
            especes.append("Wahoo")
        }
        
        // Thon (attention aux mots composés)
        if texte.contains("thon") && !texte.contains("bonite") {
            if texte.contains("thon jaune") {
                especes.append("Thon jaune")
            } else if texte.contains("thon obèse") || 
                      texte.contains("thon obese") {
                especes.append("Thon obèse")
            } else {
                especes.append("Thon jaune")  // Par défaut
            }
        }
        
        // Thazard
        if texte.contains("thazard") {
            especes.append("Thazard")
        }
        
        // Bonite
        if texte.contains("bonite") {
            especes.append("Bonite")
        }
        
        // Carangue
        if texte.contains("carangue") {
            if texte.contains("gt") || 
               texte.contains("ignobilis") ||
               texte.contains("g.t") {
                especes.append("Carangue GT")
            } else if texte.contains("bleue") {
                especes.append("Carangue bleue")
            } else {
                especes.append("Carangue")
            }
        }
        
        // Mahi-mahi
        if texte.contains("mahi") || 
           texte.contains("dorade coryphène") || 
           texte.contains("coryphene") ||
           texte.contains("dorade coryphene") {
            especes.append("Mahi-mahi")
        }
        
        // Marlin
        if texte.contains("marlin") {
            especes.append("Marlin")
        }
        
        // Voilier / Espadon voilier
        if texte.contains("voilier") || 
           texte.contains("espadon voilier") {
            especes.append("Voilier")
        }
        
        // Loche
        if texte.contains("loche") {
            if texte.contains("pintade") {
                especes.append("Loche pintade")
            } else {
                especes.append("Loche")
            }
        }
        
        // Picot (spécifique Nouvelle-Calédonie)
        if texte.contains("picot") {
            especes.append("Picot")
        }
        
        // Barracuda / Bécune
        if texte.contains("barracuda") || 
           texte.contains("bécune") || 
           texte.contains("becune") {
            especes.append("Barracuda")
        }
        
        // Mérou
        if texte.contains("mérou") || 
           texte.contains("merou") {
            especes.append("Mérou")
        }
        
        // Vivaneau
        if texte.contains("vivaneau") {
            if texte.contains("rouge") {
                especes.append("Vivaneau rouge")
            } else if texte.contains("chien rouge") {
                especes.append("Vivaneau chien rouge")
            } else {
                especes.append("Vivaneau")
            }
        }
        
        // Coureur arc-en-ciel
        if texte.contains("coureur") {
            especes.append("Coureur arc-en-ciel")
        }
        
        return Array(Set(especes))  // Éliminer les doublons
    }
    
    // MARK: - 🎣 Détection Positions Spread
    
    /// Analyse une note pour détecter les positions spread mentionnées
    static func detecterPositionsSpread(dans texte: String) -> [PositionSpread] {
        let texte = texte.lowercased()
        var positions: [PositionSpread] = []
        
        // Short Corner
        if texte.contains("short corner") || 
           texte.contains("shortcorner") ||
           texte.contains("short-corner") {
            positions.append(.shortCorner)
        }
        
        // Long Corner
        if texte.contains("long corner") || 
           texte.contains("longcorner") ||
           texte.contains("long-corner") {
            positions.append(.longCorner)
        }
        
        // Riggers
        if texte.contains("rigger") {
            if texte.contains("short") {
                positions.append(.shortRigger)
            }
            if texte.contains("long") {
                positions.append(.longRigger)
            }
            // Si "rigger" sans précision, ajouter les deux
            if !texte.contains("short") && !texte.contains("long") {
                positions.append(.shortRigger)
                positions.append(.longRigger)
            }
        }
        
        // Shotgun
        if texte.contains("shotgun") {
            positions.append(.shotgun)
        }
        
        // Corner (sans précision)
        if texte.contains("corner") && 
           !texte.contains("short") && 
           !texte.contains("long") {
            positions.append(.shortCorner)
            positions.append(.longCorner)
        }
        
        return Array(Set(positions))  // Éliminer les doublons
    }
    
    // MARK: - 🎨 Détection Finition (pour enrichissement futur)
    
    /// Analyse une note pour détecter la finition mentionnée
    static func detecterFinition(dans texte: String) -> Finition? {
        let texte = texte.lowercased()
        
        if texte.contains("holographique") || texte.contains("holo") {
            return .holographique
        }
        
        if texte.contains("métallique") || texte.contains("metallique") {
            return .metallique
        }
        
        if texte.contains("mat") || texte.contains("mate") {
            return .mate
        }
        
        if texte.contains("brillant") {
            return .brillante
        }
        
        if texte.contains("perlé") || texte.contains("perle") || texte.contains("nacré") {
            return .perlee
        }
        
        if texte.contains("pailleté") || texte.contains("paillette") || texte.contains("glitter") {
            return .paillete
        }
        
        if texte.contains("uv") {
            return .UV
        }
        
        if texte.contains("phosphorescent") || texte.contains("glow") {
            return .phosphorescent
        }
        
        if texte.contains("chrome") {
            return .chrome
        }
        
        if texte.contains("miroir") {
            return .miroir
        }
        
        return nil
    }
}
