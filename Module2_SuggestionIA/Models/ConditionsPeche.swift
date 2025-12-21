//
//  ConditionsPeche.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Modèle de saisie des conditions de pêche par l'utilisateur
//
//  Created: 2024-12-05
//  Updated: 2024-12-11 (correction .apresMidi)
//

import Foundation

// MARK: - Conditions de Pêche (INPUT utilisateur)

struct ConditionsPeche: Codable, Hashable {
    
    // MARK: - Zone et Technique
    var zone: CategoriePeche
    var profondeurCible: Double              // en mètres
    var vitesseBateau: Double                // en nœuds
    
    // MARK: - Environnement Visuel
    var momentJournee: MomentJournee
    var luminosite: Luminosite
    var turbiditeEau: Turbidite
    
    // MARK: - Conditions Marines
    var etatMer: EtatMer
    var typeMaree: TypeMaree
    var phaseLunaire: PhaseLunaire
    
    // MARK: - Optionnel
    var especePrioritaire: Espece?
    var nombreLignes: Int = 3                // 1-5 lignes
    var profilBateau: ProfilBateau = .classique  // Profil bateau (classique ou Clark 4,29 m)
    
    // MARK: - Initialisation par défaut (Scénario 1 - Lagon aube)
    static var scenario1LagunAube: ConditionsPeche {
        return ConditionsPeche(
            zone: .lagon,
            profondeurCible: 3.0,
            vitesseBateau: 5.0,
            momentJournee: .aube,
            luminosite: .faible,
            turbiditeEau: .claire,
            etatMer: .calme,
            typeMaree: .montante,
            phaseLunaire: .premierQuartier,
            especePrioritaire: .thazard,
            nombreLignes: 3
        )
    }
    
    // MARK: - Validation
    func estValide() -> (Bool, String?) {
        // Profondeur
        if profondeurCible < 0 || profondeurCible > 300 {
            return (false, "Profondeur doit être entre 0-300m")
        }
        
        // Vitesse
        if vitesseBateau < 3 || vitesseBateau > 20 {
            return (false, "Vitesse doit être entre 3-20 nœuds")
        }
        
        // Nombre de lignes
        if nombreLignes < 1 || nombreLignes > 5 {
            return (false, "Nombre de lignes : 1-5")
        }
        
        // Cohérence zone/profondeur
        if zone == .lagon && profondeurCible > 30 {
            return (false, "Profondeur trop importante pour le lagon (max 30m)")
        }
        
        if zone == .profond && profondeurCible < 50 {
            return (false, "Profondeur insuffisante pour zone profonde (min 50m)")
        }
        
        // Cohérence vitesse/zone
        if zone == .lagon && vitesseBateau > 8 {
            return (false, "Vitesse trop élevée pour le lagon (max 8 nœuds)")
        }
        
        return (true, nil)
    }
    
    // MARK: - Description formatée
    var descriptionCourte: String {
        return "\(zone.displayName) • \(momentJournee.displayName) • \(Int(vitesseBateau)) nœuds"
    }
    
    var descriptionComplete: String {
        var desc = """
        Zone : \(zone.displayName)
        Profondeur : \(Int(profondeurCible))m
        Vitesse : \(Int(vitesseBateau)) nœuds
        Moment : \(momentJournee.displayName)
        Luminosité : \(luminosite.displayName)
        Eau : \(turbiditeEau.displayName)
        Mer : \(etatMer.displayName)
        Marée : \(typeMaree.displayName)
        Lune : \(phaseLunaire.displayName)
        """
        
        if let espece = especePrioritaire {
            desc += "\nEspèce : \(espece.displayName)"
        }
        
        desc += "\nLignes : \(nombreLignes)"
        
        return desc
    }
}

// MARK: - Extensions pour cohérence automatique

extension ConditionsPeche {
    
    /// Suggère une luminosité automatique selon le moment
    static func luminositeAutoDepuisMoment(_ moment: MomentJournee) -> Luminosite {
        switch moment {
        case .aube, .crepuscule:
            return .faible
        case .matinee, .apresMidi:
            return .diffuse
        case .midi:
            return .forte
        case .nuit:
            return .nuit
        }
    }
    
    /// Vérifie si les conditions sont cohérentes entre elles
    func avertissementsCoherence() -> [String] {
        var avertissements: [String] = []
        
        // Luminosité vs Moment
        if (momentJournee == .aube || momentJournee == .crepuscule) && luminosite == .forte {
            avertissements.append("⚠️ Luminosité forte inhabituelle à l'aube/crépuscule")
        }
        
        if momentJournee == .midi && luminosite == .faible {
            avertissements.append("⚠️ Luminosité faible inhabituelle à midi")
        }
        
        // Turbidité vs Marée
        if typeMaree == .descendante && turbiditeEau == .claire {
            avertissements.append("ℹ️ Eau souvent plus trouble à marée descendante")
        }
        
        // État mer vs Zone
        if zone == .lagon && etatMer == .formee {
            avertissements.append("⚠️ Mer formée inhabituelle en lagon")
        }
        
        // Vitesse vs Espèce
        if let espece = especePrioritaire {
            if espece == .wahoo && vitesseBateau < 10 {
                avertissements.append("⚠️ Wahoo nécessite vitesse > 12 nœuds")
            }
        }
        
        return avertissements
    }
}
