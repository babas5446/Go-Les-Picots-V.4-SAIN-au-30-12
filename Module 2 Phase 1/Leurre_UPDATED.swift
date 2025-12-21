//
//  Leurre.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  MISE À JOUR : Ajout enum Luminosite pour Module 2
//
//  Created: 2024-12-04
//  Updated: 2024-12-05 (ajout Luminosite)
//

// ⚠️ INSTRUCTIONS D'INTÉGRATION
// Ajouter UNIQUEMENT la section "enum Luminosite" ci-dessous 
// dans ton fichier Leurre.swift existant, juste après l'enum "PhaseLunaire"

// MARK: - NOUVELLE ENUM POUR MODULE 2

enum Luminosite: String, Codable, CaseIterable {
    case forte = "forte"           // Soleil haut, ciel dégagé
    case diffuse = "diffuse"       // Nuageux, lumière plate
    case faible = "faible"         // Aube/crépuscule/temps noir
    
    var displayName: String {
        switch self {
        case .forte: return "Forte (soleil)"
        case .diffuse: return "Diffuse (nuageux)"
        case .faible: return "Faible (aube/crépuscule)"
        }
    }
    
    var icon: String {
        switch self {
        case .forte: return "sun.max.fill"
        case .diffuse: return "cloud.sun.fill"
        case .faible: return "moon.stars.fill"
        }
    }
    
    var description: String {
        switch self {
        case .forte: return "Soleil haut, ciel dégagé - Forte visibilité"
        case .diffuse: return "Nuageux, lumière plate - Visibilité moyenne"
        case .faible: return "Aube/crépuscule/temps noir - Faible visibilité"
        }
    }
}

// ⚠️ FIN DE L'AJOUT - Copier uniquement cette section dans Leurre.swift
