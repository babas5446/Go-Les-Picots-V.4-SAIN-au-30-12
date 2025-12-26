//
//  LeurreIntelligenceService.swift
//  Go les Picots
//
//  Service de déduction automatique pour les champs manquants des leurres :
//  - Zones adaptées (basé sur type + profondeur + taille)
//  - Espèces cibles (basé sur type + taille + profondeur + couleur)
//  - Vitesses de traîne (basé sur type + taille)
//  - Conditions optimales (basé sur contraste + couleur)
//
//  Created: 2024-12-23
//

import Foundation

class LeurreIntelligenceService {
    
    // MARK: - 📍 Déduction Zones Adaptées
    
    /// Déduit les zones adaptées à partir des caractéristiques du leurre
    static func deduireZones(leurre: Leurre) -> [Zone] {
        var zones: [Zone] = []
        
        let profMax = leurre.profondeurNageMax ?? 5
        let taille = leurre.longueur
        
        // Règle 1 : Surface/sub-surface (0-3m)
        if profMax <= 3 {
            zones.append(.lagon)
            zones.append(.recif)
            if taille >= 12 {
                zones.append(.passe)
            }
        }
        
        // Règle 2 : Moyenne profondeur (3-8m)
        if profMax > 3 && profMax <= 8 {
            zones.append(.passe)
            if taille >= 12 {
                zones.append(.large)
            }
            if taille >= 15 {
                zones.append(.recif)
            }
        }
        
        // Règle 3 : Profond (> 8m)
        if profMax > 8 {
            zones.append(.large)
            zones.append(.profond)
            if taille >= 15 {
                zones.append(.dcp)
            }
        }
        
        // Règle 4 : Ajustements selon type de leurre
        switch leurre.typeLeurre {
        case .popper, .stickbaitFlottant:
            // Surface uniquement
            zones = [.lagon, .recif, .passe]
            
        case .leurreAJupe:
            // Polyvalent mais excellent au large
            if !zones.contains(.dcp) {
                zones.append(.dcp)
            }
            if !zones.contains(.large) {
                zones.append(.large)
            }
            
        case .jigMetallique, .jigVibrant:
            // Profondeur uniquement
            zones = [.profond, .recif, .dcp, .tombant]
            
        case .leurreDeTrainePoissonVolant:
            // Haute mer principalement
            zones = [.large, .dcp, .passe]
            
        case .cuiller:
            // Polyvalent côtier
            if taille < 10 {
                zones = [.lagon, .recif, .passe]
            }
            
        default:
            break
        }
        
        return Array(Set(zones))  // Éliminer doublons
    }
    
    // MARK: - 🎯 Déduction Espèces Cibles
    
    /// Déduit les espèces cibles en combinant taille, profondeur, couleur et type
    static func deduireEspeces(leurre: Leurre) -> [String] {
        var especes: [String] = []
        
        // 1. Déduction depuis TAILLE + PROFONDEUR
        let especesTailleProfondeur = deduireEspecesDepuisTailleProfondeur(leurre: leurre)
        especes.append(contentsOf: especesTailleProfondeur)
        
        // 2. Déduction depuis COULEUR
        let especesCouleur = deduireEspecesDepuisCouleur(leurre: leurre)
        for espece in especesCouleur {
            if !especes.contains(espece) {
                especes.append(espece)
            }
        }
        
        // 3. Déduction depuis TYPE
        let especesType = deduireEspecesDepuisType(leurre: leurre)
        for espece in especesType {
            if !especes.contains(espece) {
                especes.append(espece)
            }
        }
        
        return especes
    }
    
    // MARK: - 🎯 Déduction Espèces depuis Taille/Profondeur
    
    private static func deduireEspecesDepuisTailleProfondeur(leurre: Leurre) -> [String] {
        var especes: [String] = []
        
        let taille = leurre.longueur
        let profMax = leurre.profondeurNageMax ?? 5
        
        // Petits leurres surface (< 12cm, 0-3m)
        if taille < 12 && profMax <= 3 {
            especes.append(contentsOf: ["Thazard", "Bonite", "Barracuda", "Carangue"])
        }
        
        // Moyens polyvalents (12-18cm)
        if taille >= 12 && taille <= 18 {
            especes.append(contentsOf: ["Carangue GT", "Thazard", "Bonite"])
            if profMax >= 5 {
                especes.append(contentsOf: ["Mahi-mahi", "Thon jaune"])
            }
        }
        
        // Gros profonds (> 15cm, > 8m)
        if taille > 15 && profMax > 8 {
            especes.append(contentsOf: ["Wahoo", "Thon jaune", "Mahi-mahi"])
            if taille > 20 {
                especes.append(contentsOf: ["Marlin", "Voilier"])
            }
        }
        
        // Spécificités Nouvelle-Calédonie : Loches et Picots
        if taille < 10 && profMax <= 5 {
            especes.append(contentsOf: ["Loche", "Picot"])
        }
        
        return especes
    }
    
    // MARK: - 🎨 Déduction Espèces depuis Couleur
    
    private static func deduireEspecesDepuisCouleur(leurre: Leurre) -> [String] {
        var especes: [String] = []
        
        switch leurre.couleurPrincipale {
        
        // 🔴 ROSE/FUCHSIA → Thazard, Wahoo (excellents en mer formée)
        case .roseFuchsia, .roseFluo, .rose, .roseHolographique:
            especes.append(contentsOf: ["Thazard", "Wahoo", "Bonite", "Carangue GT"])
            
        // 🟡 CHARTREUSE/JAUNE FLUO → Eau trouble, tous pélagiques
        case .chartreuse, .jauneFluo, .jauneHolographique:
            especes.append(contentsOf: ["Carangue GT", "Thon jaune", "Wahoo", "Mahi-mahi", "Thazard"])
            
        // ⚪ ARGENTÉ/BLEU → Imitation sardine, tous pélagiques
        case .argente, .bleuArgente, .sardine, .argenteBleu, .bleuBlanc:
            especes.append(contentsOf: ["Thon jaune", "Bonite", "Thazard", "Barracuda", "Carangue"])
            
        // 🟢 VERT → Mahi-mahi, Carangue
        case .vert, .vertArgente, .vertOlive, .vertDore:
            especes.append(contentsOf: ["Mahi-mahi", "Carangue GT", "Barracuda", "Thon jaune"])
            
        // ⚫ SOMBRES → Gros pélagiques (silhouette visible par en-dessous)
        case .noir, .noirViolet, .violetFonce, .bleuNoir, .bleuFonce, .violet, .noirBleu:
            especes.append(contentsOf: ["Wahoo", "Marlin", "Thon obèse", "Thon jaune", "Voilier"])
            
        // 🟠 ORANGE/ROUGE → Loche, Picot, espèces récif
        case .orange, .rouge, .marron, .orangeJaune:
            especes.append(contentsOf: ["Loche", "Picot", "Carangue", "Mérou"])
            
        // 🔵 BLEU/BLANC → Polyvalent
        case .bleu, .blanc:
            especes.append(contentsOf: ["Carangue GT", "Thazard", "Bonite", "Barracuda"])
            
        // 🟡 OR/DORÉ → Attractif pour gros prédateurs
        case .or:
            especes.append(contentsOf: ["Wahoo", "Thon jaune", "Marlin", "Mahi-mahi"])
            
        // Autres couleurs contrastées
        case .blancRouge, .blancOrange, .rougeJaune:
            especes.append(contentsOf: ["Carangue GT", "Thazard", "Bonite", "Thon jaune"])
            
        case .roseBleu, .roseBlanc:
            especes.append(contentsOf: ["Mahi-mahi", "Thazard", "Wahoo"])
            
        default:
            break
        }
        
        return especes
    }
    
    // MARK: - 🎣 Déduction Espèces depuis Type
    
    private static func deduireEspecesDepuisType(leurre: Leurre) -> [String] {
        var especes: [String] = []
        
        switch leurre.typeLeurre {
        case .popper:
            especes = ["Carangue GT", "Thazard", "Barracuda", "Bonite"]
            
        case .leurreAJupe:
            if leurre.longueur >= 15 {
                especes = ["Mahi-mahi", "Wahoo", "Thon jaune", "Marlin", "Voilier"]
            } else {
                especes = ["Mahi-mahi", "Thazard", "Carangue GT"]
            }
            
        case .jigMetallique, .jigVibrant:
            especes = ["Loche", "Loche pintade", "Thon", "Carangue", "Mérou"]
            
        case .leurreDeTrainePoissonVolant:
            especes = ["Wahoo", "Marlin", "Thon jaune", "Mahi-mahi", "Voilier"]
            
        case .cuiller:
            especes = ["Thazard", "Bonite", "Carangue", "Barracuda"]
            
        case .stickbait, .stickbaitFlottant:
            especes = ["Carangue GT", "Thazard", "Barracuda"]
            
        default:
            break
        }
        
        return especes
    }
    
    // MARK: - ⚡ Déduction Vitesses de Traîne
    
    /// Déduit les vitesses de traîne optimales selon type et taille
    static func deduireVitesses(leurre: Leurre) -> (min: Double, max: Double) {
        let taille = leurre.longueur
        
        switch leurre.typeLeurre {
        case .popper, .stickbaitFlottant:
            return (4.0, 7.0)
            
        case .cuiller:
            return taille < 8 ? (3.0, 6.0) : (4.0, 7.0)
            
        case .poissonNageur, .poissonNageurVibrant:
            return taille < 12 ? (4.0, 7.0) : (5.0, 8.0)
            
        case .poissonNageurPlongeant:
            if taille < 12 {
                return (4.0, 7.0)
            } else if taille < 18 {
                return (5.0, 9.0)
            } else {
                return (6.0, 11.0)
            }
            
        case .poissonNageurCoulant:
            return (5.0, 9.0)
            
        case .leurreAJupe:
            return (6.0, 10.0)
            
        case .leurreDeTrainePoissonVolant:
            return (5.0, 9.0)
            
        case .squid:
            return (4.0, 7.0)
            
        case .stickbait, .stickbaitCoulant:
            return (3.0, 6.0)
            
        default:
            return (5.0, 8.0)  // Défaut polyvalent
        }
    }
    
    // MARK: - 🌤️ Déduction Conditions Optimales
    
    /// Déduit les conditions optimales selon contraste et couleur
    static func deduireConditions(leurre: Leurre) -> ConditionsOptimales {
        var moments: [MomentJournee] = []
        var turbidites: [Turbidite] = []
        var etatsMer: [EtatMer] = []
        
        // ✅ Utiliser le profil visuel (qui tient compte de couleur + finition)
        let profil = leurre.profilVisuel
        
        // Règles selon profil visuel
        switch profil {
        case .naturel:
            moments = [.matinee, .apresMidi]
            turbidites = [.claire, .legerementTrouble]
            etatsMer = [.calme, .peuAgitee]
            
        case .flashy:
            moments = [.matinee, .apresMidi, .midi]
            turbidites = [.legerementTrouble, .trouble, .tresTrouble]
            etatsMer = [.peuAgitee, .agitee]
            
        case .sombre:
            moments = [.aube, .crepuscule, .nuit]
            turbidites = [.trouble, .tresTrouble]
            etatsMer = [.peuAgitee, .agitee, .formee]
            
        case .contraste:
            moments = [.aube, .crepuscule, .matinee]
            turbidites = [.legerementTrouble, .trouble]
            etatsMer = [.calme, .peuAgitee, .agitee]
        }
        
        // Ajustements selon couleurs spécifiques
        // ✅ AMÉLIORATION : Utiliser les composantes RGB réelles
        let rgb = leurre.composantesRGBPrincipale
        let estRoseFlashy = (rgb.r > 0.8 && rgb.g < 0.5 && rgb.b > 0.4)
        let estJauneVert = (rgb.g > 0.7 && rgb.r > 0.4 && rgb.b < 0.3)
        let estTresSombre = (rgb.r < 0.3 && rgb.g < 0.3 && rgb.b < 0.4)
        
        if estRoseFlashy {
            // Rose excellent en mer formée
            if !etatsMer.contains(.formee) {
                etatsMer.append(.formee)
            }
        }
        
        if estJauneVert {
            // Chartreuse/Jaune fluo pour eau trouble
            turbidites = [.trouble, .tresTrouble]
        }
        
        if estTresSombre {
            // Sombres pour faible luminosité
            moments = [.aube, .crepuscule, .nuit]
        }
        
        // Ajustements selon finition (déjà pris en compte dans profilVisuel,
        // mais on peut affiner les moments/turbidités)
        if let finition = leurre.finition {
            switch finition {
            case .phosphorescent:
                // Phosphorescent excellent la nuit
                if !moments.contains(.nuit) {
                    moments.append(.nuit)
                }
                if !moments.contains(.crepuscule) {
                    moments.append(.crepuscule)
                }
                
            case .UV:
                // UV bon en profondeur (toutes conditions)
                break
                
            case .mate:
                // Mat pour faible luminosité
                moments = [.aube, .crepuscule]
                turbidites = [.trouble, .tresTrouble]
                
            case .holographique, .chrome, .miroir, .paillete:
                // Très flashy : eau claire, forte lumière
                turbidites = [.claire, .legerementTrouble]
                if !moments.contains(.midi) {
                    moments.append(.midi)
                }
                
            default:
                break
            }
        }
        
        // Marées : toujours polyvalent par défaut
        let marees: [TypeMaree] = [.montante, .descendante]
        
        return ConditionsOptimales(
            moments: moments,
            etatMer: etatsMer,
            turbidite: turbidites,
            maree: marees,
            phasesLunaires: nil  // Non déductible automatiquement
        )
    }
}
