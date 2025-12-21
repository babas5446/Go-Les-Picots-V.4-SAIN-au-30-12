//
//  Leurre.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Modèle de données complet basé sur l'extraction des critères
//  du document "Consignes pour moteur stratégique de suggestion de leurres"
//
//  Created: 2024-12-04
//

import Foundation
import SwiftUI

// MARK: - Modèle Principal : Leurre

struct Leurre: Identifiable, Codable, Hashable {
    
    // MARK: - Identification
    let id: Int
    var nom: String
    var marque: String
    var modele: String?
    var reference: String?
    
    // MARK: - Classification
    var type: TypeLeurre
    var categoriePeche: [CategoriePeche]
    
    // MARK: - Caractéristiques Physiques
    var longueur: Double // en cm
    var poids: Double?   // en grammes
    
    // MARK: - Caractéristiques Visuelles
    var couleurPrincipale: Couleur
    var couleursSecondaires: [Couleur]
    var contraste: Contraste
    var finition: Finition?
    
    // MARK: - Performance Technique
    var typeTete: TypeTete?
    var actionNage: ActionNage
    var profondeurMin: Double  // en mètres
    var profondeurMax: Double  // en mètres
    var vitesseMinimale: Double   // en nœuds
    var vitesseOptimale: Double   // en nœuds
    var vitesseMaximale: Double   // en nœuds
    
    // MARK: - Critères de Suggestion (Module 2)
    var especesCibles: [Espece]
    var positionsSpread: [PositionSpread]
    var notes: String?
    
    // MARK: - Conditions Optimales
    var conditionsOptimales: ConditionsOptimales
    
    // MARK: - Gestion Inventaire
    var photo: Data?
    var quantite: Int
    var emplacement: String?
    var dateAjout: Date
    
    // MARK: - Initialisation
    init(
        id: Int,
        nom: String,
        marque: String,
        modele: String? = nil,
        reference: String? = nil,
        type: TypeLeurre,
        categoriePeche: [CategoriePeche],
        longueur: Double,
        poids: Double? = nil,
        couleurPrincipale: Couleur,
        couleursSecondaires: [Couleur] = [],
        contraste: Contraste,
        finition: Finition? = nil,
        typeTete: TypeTete? = nil,
        actionNage: ActionNage,
        profondeurMin: Double,
        profondeurMax: Double,
        vitesseMinimale: Double,
        vitesseOptimale: Double,
        vitesseMaximale: Double,
        especesCibles: [Espece],
        positionsSpread: [PositionSpread],
        notes: String? = nil,
        conditionsOptimales: ConditionsOptimales,
        photo: Data? = nil,
        quantite: Int = 1,
        emplacement: String? = nil,
        dateAjout: Date = Date()
    ) {
        self.id = id
        self.nom = nom
        self.marque = marque
        self.modele = modele
        self.reference = reference
        self.type = type
        self.categoriePeche = categoriePeche
        self.longueur = longueur
        self.poids = poids
        self.couleurPrincipale = couleurPrincipale
        self.couleursSecondaires = couleursSecondaires
        self.contraste = contraste
        self.finition = finition
        self.typeTete = typeTete
        self.actionNage = actionNage
        self.profondeurMin = profondeurMin
        self.profondeurMax = profondeurMax
        self.vitesseMinimale = vitesseMinimale
        self.vitesseOptimale = vitesseOptimale
        self.vitesseMaximale = vitesseMaximale
        self.especesCibles = especesCibles
        self.positionsSpread = positionsSpread
        self.notes = notes
        self.conditionsOptimales = conditionsOptimales
        self.photo = photo
        self.quantite = quantite
        self.emplacement = emplacement
        self.dateAjout = dateAjout
    }
}

// MARK: - Énumérations

enum TypeLeurre: String, Codable, CaseIterable {
    case poissonNageur = "poissonNageur"
    case poissonNageurPlongeant = "poissonNageurPlongeant"
    case leurreAJupe = "leurreAJupe"
    case popper = "popper"
    case stickbait = "stickbait"
    case jigMetallique = "jigMetallique"
    case vibeLipless = "vibeLipless"
    case leurreDeTrainePoissonVolant = "leurreDeTrainePoissonVolant"
    
    var displayName: String {
        switch self {
        case .poissonNageur: return "Poisson nageur"
        case .poissonNageurPlongeant: return "Poisson nageur plongeant"
        case .leurreAJupe: return "Leurre à jupe (octopus)"
        case .popper: return "Popper de surface"
        case .stickbait: return "Stickbait"
        case .jigMetallique: return "Jig métallique"
        case .vibeLipless: return "Vibe/Lipless"
        case .leurreDeTrainePoissonVolant: return "Leurre traîne (Flying Fish)"
        }
    }
    
    var icon: String {
        switch self {
        case .poissonNageur, .poissonNageurPlongeant: return "🐟"
        case .leurreAJupe: return "🦑"
        case .popper: return "💦"
        case .stickbait: return "📏"
        case .jigMetallique: return "⚓️"
        case .vibeLipless: return "〰️"
        case .leurreDeTrainePoissonVolant: return "🐠"
        }
    }
}

enum CategoriePeche: String, Codable, CaseIterable {
    case lagon = "lagon"
    case passes = "passes"
    case cotier = "cotier"
    case hauturier = "hauturier"
    case large = "large"
    case recif = "recif"
    
    var displayName: String {
        switch self {
        case .lagon: return "Lagon"
        case .passes: return "Passes"
        case .cotier: return "Côtier"
        case .hauturier: return "Hauturier"
        case .large: return "Large"
        case .recif: return "Récif"
        }
    }
}

enum Couleur: String, Codable, CaseIterable {
    // Naturelles
    case bleuArgente = "bleuArgente"
    case bleuBlanc = "bleuBlanc"
    case vertArgente = "vertArgente"
    case vertDore = "vertDore"
    case sardine = "sardine"
    case maquereau = "maquereau"
    case argente = "argente"
    case blanc = "blanc"
    case transparent = "transparent"
    
    // Flashy
    case roseFuchsia = "roseFuchsia"
    case rose = "rose"
    case chartreuse = "chartreuse"
    case orange = "orange"
    case jaune = "jaune"
    case roseHolographique = "roseHolographique"
    
    // Sombres
    case noirViolet = "noirViolet"
    case noirBleu = "noirBleu"
    case violetFonce = "violetFonce"
    case bleuFonce = "bleuFonce"
    case noirRouge = "noirRouge"
    case violet = "violet"
    
    // Contrastées
    case bleuNoirGris = "bleuNoirGris"
    case violetNoir = "violetNoir"
    case roseBlanc = "roseBlanc"
    case rougeJaune = "rougeJaune"
    
    // Autres
    case brun = "brun"
    case beige = "beige"
    case vert = "vert"
    case bleu = "bleu"
    case rouge = "rouge"
    
    var displayName: String {
        switch self {
        case .bleuArgente: return "Bleu/Argenté"
        case .bleuBlanc: return "Bleu/Blanc"
        case .vertArgente: return "Vert/Argenté"
        case .vertDore: return "Vert/Doré"
        case .sardine: return "Sardine"
        case .maquereau: return "Maquereau"
        case .argente: return "Argenté"
        case .blanc: return "Blanc"
        case .transparent: return "Transparent"
        case .roseFuchsia: return "Rose Fuchsia"
        case .rose: return "Rose"
        case .chartreuse: return "Chartreuse"
        case .orange: return "Orange"
        case .jaune: return "Jaune"
        case .roseHolographique: return "Rose Holographique"
        case .noirViolet: return "Noir/Violet"
        case .noirBleu: return "Noir/Bleu"
        case .violetFonce: return "Violet Foncé"
        case .bleuFonce: return "Bleu Foncé"
        case .noirRouge: return "Noir/Rouge"
        case .violet: return "Violet"
        case .bleuNoirGris: return "Bleu Noir/Gris"
        case .violetNoir: return "Violet/Noir"
        case .roseBlanc: return "Rose/Blanc"
        case .rougeJaune: return "Rouge/Jaune"
        case .brun: return "Brun"
        case .beige: return "Beige"
        case .vert: return "Vert"
        case .bleu: return "Bleu"
        case .rouge: return "Rouge"
        }
    }
}

enum Contraste: String, Codable, CaseIterable {
    case naturel = "naturel"
    case flashy = "flashy"
    case sombre = "sombre"
    case contraste = "contraste"
    
    var displayName: String {
        switch self {
        case .naturel: return "Naturel"
        case .flashy: return "Flashy"
        case .sombre: return "Sombre"
        case .contraste: return "Contrasté"
        }
    }
    
    var color: Color {
        switch self {
        case .naturel: return .blue
        case .flashy: return .pink
        case .sombre: return .gray
        case .contraste: return .purple
        }
    }
}

enum Finition: String, Codable, CaseIterable {
    case holographique = "holographique"
    case metallique = "metallique"
    case mat = "mat"
    case brillant = "brillant"
    
    var displayName: String {
        switch self {
        case .holographique: return "Holographique"
        case .metallique: return "Métallique"
        case .mat: return "Mat"
        case .brillant: return "Brillant"
        }
    }
}

enum TypeTete: String, Codable, CaseIterable {
    case bullet = "bullet"
    case pusher = "pusher"
    case plunger = "plunger"
    case cupFace = "cupFace"
    case siffleuse = "siffleuse"
    case bavetteCourte = "bavetteCourte"
    case bavetteMoyenne = "bavetteMoyenne"
    case bavetteProfonde = "bavetteProfonde"
    case jigLike = "jigLike"
    
    var displayName: String {
        switch self {
        case .bullet: return "Bullet"
        case .pusher: return "Pusher"
        case .plunger: return "Plunger"
        case .cupFace: return "Cup Face"
        case .siffleuse: return "Siffleuse"
        case .bavetteCourte: return "Bavette courte"
        case .bavetteMoyenne: return "Bavette moyenne"
        case .bavetteProfonde: return "Bavette profonde"
        case .jigLike: return "Jig-like"
        }
    }
}

enum ActionNage: String, Codable, CaseIterable {
    case lente = "lente"
    case moderate = "moderate"
    case rapide = "rapide"
    case variable = "variable"
    case saccadee = "saccadee"
    
    var displayName: String {
        switch self {
        case .lente: return "Lente"
        case .moderate: return "Moyenne"
        case .rapide: return "Rapide"
        case .variable: return "Variable"
        case .saccadee: return "Saccadée"
        }
    }
}

enum Espece: String, Codable, CaseIterable {
    case carangue = "carangue"
    case carangueGT = "carangueGT"
    case thon = "thon"
    case thonJaune = "thonJaune"
    case thonProfond = "thonProfond"
    case barracuda = "barracuda"
    case wahoo = "wahoo"
    case mahiMahi = "mahiMahi"
    case marlin = "marlin"
    case thazard = "thazard"
    case bonite = "bonite"
    case loche = "loche"
    case picot = "picot"
    case becDeCane = "becDeCane"
    case vivaneau = "vivaneau"
    
    var displayName: String {
        switch self {
        case .carangue: return "Carangue"
        case .carangueGT: return "Carangue GT"
        case .thon: return "Thon"
        case .thonJaune: return "Thon jaune"
        case .thonProfond: return "Thon profond"
        case .barracuda: return "Barracuda"
        case .wahoo: return "Wahoo"
        case .mahiMahi: return "Mahi-mahi"
        case .marlin: return "Marlin"
        case .thazard: return "Thazard"
        case .bonite: return "Bonite"
        case .loche: return "Loche"
        case .picot: return "Picot"
        case .becDeCane: return "Bec-de-cane"
        case .vivaneau: return "Vivaneau"
        }
    }
}

enum PositionSpread: String, Codable, CaseIterable {
    case shortCorner = "shortCorner"
    case longCorner = "longCorner"
    case rigger = "rigger"
    case shotgun = "shotgun"
    case libre = "libre"
    
    var displayName: String {
        switch self {
        case .shortCorner: return "Short Corner (10-20m)"
        case .longCorner: return "Long Corner (30-50m)"
        case .rigger: return "Rigger (50-70m)"
        case .shotgun: return "Shotgun (70-100m)"
        case .libre: return "Libre"
        }
    }
}

// MARK: - Conditions Optimales

struct ConditionsOptimales: Codable, Hashable {
    var moments: [MomentJournee]
    var etatMer: [EtatMer]
    var turbidite: [Turbidite]
    var maree: [TypeMaree]
    var phasesLunaires: [PhaseLunaire]
}

enum MomentJournee: String, Codable, CaseIterable {
    case aube = "aube"
    case matinee = "matinee"
    case midi = "midi"
    case apres_midi = "apres_midi"
    case crepuscule = "crepuscule"
    case nuit = "nuit"
    
    var displayName: String {
        switch self {
        case .aube: return "Aube"
        case .matinee: return "Matinée"
        case .midi: return "Midi"
        case .apres_midi: return "Après-midi"
        case .crepuscule: return "Crépuscule"
        case .nuit: return "Nuit"
        }
    }
}

enum EtatMer: String, Codable, CaseIterable {
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

enum Turbidite: String, Codable, CaseIterable {
    case claire = "claire"
    case legerementTrouble = "legerementTrouble"
    case trouble = "trouble"
    
    var displayName: String {
        switch self {
        case .claire: return "Claire"
        case .legerementTrouble: return "Légèrement trouble"
        case .trouble: return "Trouble"
        }
    }
}

enum TypeMaree: String, Codable, CaseIterable {
    case montante = "montante"
    case descendante = "descendante"
    case etale = "etale"
    
    var displayName: String {
        switch self {
        case .montante: return "Montante"
        case .descendante: return "Descendante"
        case .etale: return "Étale"
        }
    }
}

enum PhaseLunaire: String, Codable, CaseIterable {
    case nouvelleLune = "nouvelleLune"
    case premierQuartier = "premierQuartier"
    case pleineLune = "pleineLune"
    case dernierQuartier = "dernierQuartier"
    
    var displayName: String {
        switch self {
        case .nouvelleLune: return "Nouvelle lune"
        case .premierQuartier: return "Premier quartier"
        case .pleineLune: return "Pleine lune"
        case .dernierQuartier: return "Dernier quartier"
        }
    }
}

// MARK: - Extensions Utilitaires

extension Leurre {
    
    /// Retourne une description formatée de la profondeur
    var profondeurFormatee: String {
        if profondeurMin == profondeurMax {
            return "\(Int(profondeurMin))m"
        } else {
            return "\(Int(profondeurMin))-\(Int(profondeurMax))m"
        }
    }
    
    /// Retourne une description formatée de la vitesse
    var vitesseFormatee: String {
        return "\(Int(vitesseMinimale))-\(Int(vitesseMaximale)) nœuds"
    }
    
    /// Retourne la catégorie principale
    var categorieprincipale: CategoriePeche {
        return categoriePeche.first ?? .lagon
    }
    
    /// Vérifie si le leurre est adapté à une zone donnée
    func estAdapteA(zone: CategoriePeche) -> Bool {
        return categoriePeche.contains(zone)
    }
}
