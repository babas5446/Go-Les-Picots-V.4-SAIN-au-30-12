//
//  Leurre.swift
//  Go les Picots - Module 1 Phase 2
//
//  Modèle de données complet avec distinction :
//  - Champs SAISIS par l'utilisateur (infos sur la boîte du leurre)
//  - Champs DÉDUITS par le moteur de suggestion (Module 2)
//
//  Created: 2024-12-10
//

import Foundation
import SwiftUI

// MARK: - Modèle Principal

struct Leurre: Identifiable, Codable, Hashable {
    
    // MARK: - Identification
    let id: Int
    
    // ═══════════════════════════════════════════════════════════════
    // CHAMPS SAISIS PAR L'UTILISATEUR (infos sur la boîte du leurre)
    // ═══════════════════════════════════════════════════════════════
    
    var nom: String                          // Obligatoire
    var marque: String                       // Obligatoire
    var modele: String?                      // Facultatif
    
    var typeLeurre: TypeLeurre               // Obligatoire (forme physique)
    var typePeche: TypePeche                 // Obligatoire (méthode de pêche)
    
    var longueur: Double                     // Obligatoire (cm)
    var poids: Double?                       // Facultatif (g)
    
    var couleurPrincipale: Couleur           // Obligatoire
    var couleurSecondaire: Couleur?          // Facultatif
    
    // Conditionnel : SI typePeche == .traine
    var profondeurNageMin: Double?           // mètres
    var profondeurNageMax: Double?           // mètres
    var vitesseTraineMin: Double?            // nœuds
    var vitesseTraineMax: Double?            // nœuds
    
    var notes: String?                       // Facultatif
    var photoPath: String?                   // Chemin fichier photo (facultatif)
    
    // ═══════════════════════════════════════════════════════════════
    // CHAMPS DÉDUITS PAR LE MOTEUR (Module 2)
    // ═══════════════════════════════════════════════════════════════
    
    var contraste: Contraste?                // Déduit des couleurs
    var zonesAdaptees: [Zone]?               // Déduit du type + profondeur
    var especesCibles: [String]?             // Déduit des zones
    var positionsSpread: [PositionSpread]?   // Déduit du type + contraste
    var conditionsOptimales: ConditionsOptimales? // Déduit de l'ensemble
    
    // Flag indiquant si les champs déduits ont été calculés
    var isComputed: Bool
    
    // ═══════════════════════════════════════════════════════════════
    // GESTION
    // ═══════════════════════════════════════════════════════════════
    
    var quantite: Int
    var dateAjout: Date?
    
    // MARK: - Initialisation pour nouveau leurre (saisie utilisateur)
    
    init(
        id: Int,
        nom: String,
        marque: String,
        modele: String? = nil,
        typeLeurre: TypeLeurre,
        typePeche: TypePeche,
        longueur: Double,
        poids: Double? = nil,
        couleurPrincipale: Couleur,
        couleurSecondaire: Couleur? = nil,
        profondeurNageMin: Double? = nil,
        profondeurNageMax: Double? = nil,
        vitesseTraineMin: Double? = nil,
        vitesseTraineMax: Double? = nil,
        notes: String? = nil,
        photoPath: String? = nil,
        quantite: Int = 1
    ) {
        self.id = id
        self.nom = nom
        self.marque = marque
        self.modele = modele
        self.typeLeurre = typeLeurre
        self.typePeche = typePeche
        self.longueur = longueur
        self.poids = poids
        self.couleurPrincipale = couleurPrincipale
        self.couleurSecondaire = couleurSecondaire
        self.profondeurNageMin = profondeurNageMin
        self.profondeurNageMax = profondeurNageMax
        self.vitesseTraineMin = vitesseTraineMin
        self.vitesseTraineMax = vitesseTraineMax
        self.notes = notes
        self.photoPath = photoPath
        self.quantite = quantite
        self.dateAjout = Date()
        
        // Champs déduits initialisés à nil
        self.contraste = nil
        self.zonesAdaptees = nil
        self.especesCibles = nil
        self.positionsSpread = nil
        self.conditionsOptimales = nil
        self.isComputed = false
    }
    
    // MARK: - Computed Properties
    
    /// Description formatée de la profondeur de nage
    var profondeurFormatee: String? {
        guard let min = profondeurNageMin, let max = profondeurNageMax else {
            return nil
        }
        if min == max {
            return "\(Int(min))m"
        }
        return "\(Int(min))-\(Int(max))m"
    }
    
    /// Description formatée de la vitesse de traîne
    var vitesseFormatee: String? {
        guard let min = vitesseTraineMin, let max = vitesseTraineMax else {
            return nil
        }
        return "\(Int(min))-\(Int(max)) nœuds"
    }
    
    /// Vérifie si c'est un leurre de traîne (utilisable par le moteur)
    var estLeurreDeTraîne: Bool {
        return typePeche == .traine
    }
    
    /// Description des couleurs
    var descriptionCouleurs: String {
        if let secondaire = couleurSecondaire {
            return "\(couleurPrincipale.displayName) / \(secondaire.displayName)"
        }
        return couleurPrincipale.displayName
    }
}

// MARK: - TypePeche (Méthode de pêche)

enum TypePeche: String, Codable, CaseIterable, Hashable {
    case traine = "traine"
    case lancer = "lancer"
    case jig = "jig"
    case montage = "montage"
    case palangrotte = "palangrotte"
    case jigging = "jigging"
    
    var displayName: String {
        switch self {
        case .traine: return "Traîne"
        case .lancer: return "Lancer"
        case .jig: return "Jig"
        case .montage: return "Montage"
        case .palangrotte: return "Palangrotte"
        case .jigging: return "Jigging vertical"
        }
    }
    
    var icon: String {
        switch self {
        case .traine: return "arrow.right.circle"
        case .lancer: return "figure.fishing"
        case .jig: return "arrow.down.circle"
        case .montage: return "link"
        case .palangrotte: return "arrow.up.and.down"
        case .jigging: return "arrow.up.arrow.down"
        }
    }
    
    /// Indique si ce type nécessite les infos de profondeur/vitesse
    var necessiteInfosTraine: Bool {
        return self == .traine
    }
}

// MARK: - TypeLeurre (Forme physique du leurre)

enum TypeLeurre: String, Codable, CaseIterable, Hashable {
    case poissonNageur = "poissonNageur"
    case poissonNageurPlongeant = "poissonNageurPlongeant"
    case poissonNageurCoulant = "poissonNageurCoulant"
    case leurreAJupe = "leurreAJupe"
    case popper = "popper"
    case stickbait = "stickbait"
    case jigMetallique = "jigMetallique"
    case vibeLipless = "vibeLipless"
    case leurreDeTrainePoissonVolant = "leurreDeTrainePoissonVolant"
    case cuiller = "cuiller"
    case leurreSouple = "leurreSouple"
    case madai = "madai"
    case inchiku = "inchiku"
    
    var displayName: String {
        switch self {
        case .poissonNageur: return "Poisson nageur"
        case .poissonNageurPlongeant: return "Poisson nageur plongeant"
        case .poissonNageurCoulant: return "Poisson nageur coulant"
        case .leurreAJupe: return "Leurre à jupe (octopus)"
        case .popper: return "Popper"
        case .stickbait: return "Stickbait"
        case .jigMetallique: return "Jig métallique"
        case .vibeLipless: return "Vibe / Lipless"
        case .leurreDeTrainePoissonVolant: return "Leurre traîne (poisson volant)"
        case .cuiller: return "Cuiller"
        case .leurreSouple: return "Leurre souple"
        case .madai: return "Madaï"
        case .inchiku: return "Inchiku"
        }
    }
    
    var icon: String {
        switch self {
        case .poissonNageur, .poissonNageurPlongeant, .poissonNageurCoulant:
            return "🐟"
        case .leurreAJupe:
            return "🦑"
        case .popper, .stickbait:
            return "💨"
        case .jigMetallique, .vibeLipless:
            return "⚡"
        case .leurreDeTrainePoissonVolant:
            return "🐦"
        case .cuiller:
            return "🥄"
        case .leurreSouple:
            return "🪱"
        case .madai, .inchiku:
            return "🎣"
        }
    }
}

// MARK: - Couleur

enum Couleur: String, Codable, CaseIterable, Hashable {
    // Naturels
    case bleuArgente = "bleuArgente"
    case bleuBlanc = "bleuBlanc"
    case vertDore = "vertDore"
    case sardine = "sardine"
    case maquereau = "maquereau"
    case transparent = "transparent"
    
    // Flashy / Vifs
    case rose = "rose"
    case roseFuchsia = "roseFuchsia"
    case roseFluo = "roseFluo"
    case chartreuse = "chartreuse"
    case chartreuseArgente = "chartreuseArgente"
    case orange = "orange"
    case orangeFluo = "orangeFluo"
    case jaune = "jaune"
    case jauneFluo = "jauneFluo"
    case or = "or"
    
    // Sombres
    case noir = "noir"
    case noirViolet = "noirViolet"
    case noirRouge = "noirRouge"
    case violet = "violet"
    case violetFonce = "violetFonce"
    case bleuFonce = "bleuFonce"
    case rouge = "rouge"
    
    // Contrastés
    case blancRouge = "blancRouge"
    case rougeBlanche = "rougeBlanche"
    case bleuOrange = "bleuOrange"
    case vertRouge = "vertRouge"
    
    // Métalliques / Spéciaux
    case argente = "argente"
    case holographique = "holographique"
    case nacre = "nacre"
    case cuivre = "cuivre"
    
    // Autres
    case blanc = "blanc"
    case bleu = "bleu"
    case vert = "vert"
    case turquoise = "turquoise"
    
    var displayName: String {
        switch self {
        case .bleuArgente: return "Bleu/Argenté"
        case .bleuBlanc: return "Bleu/Blanc"
        case .vertDore: return "Vert/Doré"
        case .sardine: return "Sardine"
        case .maquereau: return "Maquereau"
        case .transparent: return "Transparent"
        case .rose: return "Rose"
        case .roseFuchsia: return "Rose fuchsia"
        case .roseFluo: return "Rose fluo"
        case .chartreuse: return "Chartreuse"
        case .chartreuseArgente: return "Chartreuse/Argenté"
        case .orange: return "Orange"
        case .orangeFluo: return "Orange fluo"
        case .jaune: return "Jaune"
        case .jauneFluo: return "Jaune fluo"
        case .or: return "Or"
        case .noir: return "Noir"
        case .noirViolet: return "Noir/Violet"
        case .noirRouge: return "Noir/Rouge"
        case .violet: return "Violet"
        case .violetFonce: return "Violet foncé"
        case .bleuFonce: return "Bleu foncé"
        case .rouge: return "Rouge"
        case .blancRouge: return "Blanc/Rouge"
        case .rougeBlanche: return "Rouge/Blanche"
        case .bleuOrange: return "Bleu/Orange"
        case .vertRouge: return "Vert/Rouge"
        case .argente: return "Argenté"
        case .holographique: return "Holographique"
        case .nacre: return "Nacré"
        case .cuivre: return "Cuivré"
        case .blanc: return "Blanc"
        case .bleu: return "Bleu"
        case .vert: return "Vert"
        case .turquoise: return "Turquoise"
        }
    }
    
    /// Couleur SwiftUI associée pour affichage
    var swiftUIColor: Color {
        switch self {
        case .bleuArgente, .bleuBlanc, .bleu: return .blue
        case .vertDore, .vert: return .green
        case .sardine, .maquereau: return Color(red: 0.5, green: 0.6, blue: 0.7)
        case .transparent: return .gray.opacity(0.3)
        case .rose, .roseFuchsia, .roseFluo: return .pink
        case .chartreuse, .chartreuseArgente: return Color(red: 0.5, green: 1.0, blue: 0.0)
        case .orange, .orangeFluo: return .orange
        case .jaune, .jauneFluo, .or: return .yellow
        case .noir: return .black
        case .noirViolet, .violet, .violetFonce: return .purple
        case .noirRouge, .rouge, .rougeBlanche, .blancRouge: return .red
        case .bleuFonce: return Color(red: 0.0, green: 0.0, blue: 0.5)
        case .bleuOrange: return .orange
        case .vertRouge: return .red
        case .argente, .holographique: return Color(red: 0.75, green: 0.75, blue: 0.8)
        case .nacre: return Color(red: 0.95, green: 0.9, blue: 0.85)
        case .cuivre: return Color(red: 0.7, green: 0.4, blue: 0.2)
        case .blanc: return .white
        case .turquoise: return .cyan
        }
    }
    
    /// Catégorie de contraste naturel de cette couleur
    var contrasteNaturel: Contraste {
        switch self {
        case .bleuArgente, .bleuBlanc, .vertDore, .sardine, .maquereau,
             .transparent, .argente, .nacre, .blanc, .bleu, .vert, .turquoise:
            return .naturel
        case .rose, .roseFuchsia, .roseFluo, .chartreuse, .chartreuseArgente,
             .orange, .orangeFluo, .jaune, .jauneFluo, .or, .holographique, .cuivre:
            return .flashy
        case .noir, .noirViolet, .noirRouge, .violet, .violetFonce, .bleuFonce, .rouge:
            return .sombre
        case .blancRouge, .rougeBlanche, .bleuOrange, .vertRouge:
            return .contraste
        }
    }
}

// MARK: - Contraste

enum Contraste: String, Codable, CaseIterable, Hashable {
    case naturel = "naturel"
    case flashy = "flashy"
    case sombre = "sombre"
    case contraste = "contraste"
    
    var displayName: String {
        switch self {
        case .naturel: return "Naturel/Réaliste"
        case .flashy: return "Flashy/Attirant"
        case .sombre: return "Sombre/Silhouette"
        case .contraste: return "Fort contraste"
        }
    }
    
    var description: String {
        switch self {
        case .naturel:
            return "Imitation réaliste, eau claire, forte luminosité"
        case .flashy:
            return "Couleurs vives, attire l'attention de loin"
        case .sombre:
            return "Silhouette visible par en-dessous, faible luminosité"
        case .contraste:
            return "Bicolore marqué, efficace en eau trouble"
        }
    }
}

// MARK: - Zone de pêche

enum Zone: String, Codable, CaseIterable, Hashable {
    case lagon = "lagon"
    case recif = "recif"
    case passe = "passe"
    case tombant = "tombant"
    case large = "large"
    case dcp = "dcp"
    
    var displayName: String {
        switch self {
        case .lagon: return "Lagon"
        case .recif: return "Récif"
        case .passe: return "Passe"
        case .tombant: return "Tombant"
        case .large: return "Large/Hauturier"
        case .dcp: return "DCP"
        }
    }
    
    var icon: String {
        switch self {
        case .lagon: return "🏝️"
        case .recif: return "🪸"
        case .passe: return "🌊"
        case .tombant: return "⛰️"
        case .large: return "🚢"
        case .dcp: return "⚓"
        }
    }
    
    /// Espèces typiques de cette zone
    var especesTypiques: [String] {
        switch self {
        case .lagon:
            return [
                "Carangue ignobilis (GT)",
                "Carangue bleue",
                "Bécune",
                "Barracuda",
                "Thazard rayé",
                "Vivaneau queue noire",
                "Loche croissant",
                "Bec-de-cane"
            ]
        case .recif:
            return [
                "Carangue GT",
                "Loche pintade",
                "Loche aréolée",
                "Bec de canne",
                "Vivaneau chien rouge",
                "Empereur",
                "Mérou",
                "Barracuda"
            ]
        case .passe:
            return [
                "Thazard commun",
                "Thon jaune",
                "Wahoo",
                "Carangue GT",
                "Bonite",
                "Barracuda",
                "Mahi-mahi",
                "Voilier"
            ]
        case .tombant:
            return [
                "Loche pintade (100-280m)",
                "Bec de canne",
                "Vivaneau rubis (200-300m)",
                "Vivaneau la flamme (200-300m)",
                "Vivaneau blanc (150-250m)",
                "Mérou",
                "Thon jaune",
                "Wahoo"
            ]
        case .large:
            return [
                "Thon jaune",
                "Thon obèse",
                "Marlin",
                "Espadon voilier",
                "Wahoo",
                "Mahi-mahi (Coryphène)",
                "Thazard bâtard",
                "Bonite"
            ]
        case .dcp:
            return [
                "Thon jaune",
                "Bonite",
                "Mahi-mahi",
                "Wahoo",
                "Loche",
                "Thazard",
                "Voilier",
                "Marlin"
            ]
        }
    }
}

// MARK: - Position Spread

enum PositionSpread: String, Codable, CaseIterable, Hashable {
    case shortCorner = "shortCorner"
    case longCorner = "longCorner"
    case shortRigger = "shortRigger"
    case longRigger = "longRigger"
    case shotgun = "shotgun"
    
    var displayName: String {
        switch self {
        case .shortCorner: return "Short Corner (10-15m)"
        case .longCorner: return "Long Corner (20-30m)"
        case .shortRigger: return "Short Rigger (50m)"
        case .longRigger: return "Long Rigger (50m)"
        case .shotgun: return "Shotgun (70-100m)"
        }
    }
    
    var distance: String {
        switch self {
        case .shortCorner: return "10-15m"
        case .longCorner: return "20-30m"
        case .shortRigger: return "~50m"
        case .longRigger: return "~50m"
        case .shotgun: return "70-100m"
        }
    }
    
    var caracteristiques: String {
        switch self {
        case .shortCorner: return "Agressif, grande taille"
        case .longCorner: return "Discret, naturel"
        case .shortRigger: return "Flashy, 0-2m profondeur"
        case .longRigger: return "Flashy, 0-2m profondeur"
        case .shotgun: return "Discret, fort contraste"
        }
    }
}

// MARK: - Conditions Optimales

struct ConditionsOptimales: Codable, Hashable {
    var moments: [MomentJournee]?
    var etatMer: [EtatMer]?
    var turbidite: [Turbidite]?
    var maree: [TypeMaree]?
    var phasesLunaires: [PhaseLunaire]?
    
    init(
        moments: [MomentJournee]? = nil,
        etatMer: [EtatMer]? = nil,
        turbidite: [Turbidite]? = nil,
        maree: [TypeMaree]? = nil,
        phasesLunaires: [PhaseLunaire]? = nil
    ) {
        self.moments = moments
        self.etatMer = etatMer
        self.turbidite = turbidite
        self.maree = maree
        self.phasesLunaires = phasesLunaires
    }
}

// MARK: - Enums pour Conditions

enum MomentJournee: String, Codable, CaseIterable, Hashable {
    case aube = "aube"
    case matinee = "matinee"
    case midi = "midi"
    case apresMidi = "apresMidi"
    case crepuscule = "crepuscule"
    case nuit = "nuit"
    
    var displayName: String {
        switch self {
        case .aube: return "Aube (05:00-07:00)"
        case .matinee: return "Matinée (07:00-11:00)"
        case .midi: return "Midi (11:00-14:00)"
        case .apresMidi: return "Après-midi (14:00-17:00)"
        case .crepuscule: return "Crépuscule (17:00-19:00)"
        case .nuit: return "Nuit (19:00-05:00)"
        }
    }
}

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

enum Turbidite: String, Codable, CaseIterable, Hashable {
    case claire = "claire"
    case legerementTrouble = "legerementTrouble"
    case trouble = "trouble"
    case tresTrouble = "tresTrouble"
    
    var displayName: String {
        switch self {
        case .claire: return "Claire"
        case .legerementTrouble: return "Légèrement trouble"
        case .trouble: return "Trouble"
        case .tresTrouble: return "Très trouble"
        }
    }
}

enum TypeMaree: String, Codable, CaseIterable, Hashable {
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

enum PhaseLunaire: String, Codable, CaseIterable, Hashable {
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

// MARK: - Structure pour la base de données JSON

struct LeurreDatabase: Codable {
    var metadata: DatabaseMetadata
    var leurres: [Leurre]
}

struct DatabaseMetadata: Codable {
    var version: String
    var dateCreation: String
    var derniereMiseAJour: String
    var nombreTotal: Int
    var proprietaire: String
}
