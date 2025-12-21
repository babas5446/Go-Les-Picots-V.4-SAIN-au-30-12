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
    var typePeche: TypePeche                 // Obligatoire (méthode de pêche PRINCIPALE)
    var typesPecheCompatibles: [TypePeche]?  // Facultatif (TOUTES les techniques possibles)
    
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
    var especesCibles: [String]?             // JSON + complété par moteur (forme, taille, couleur, profondeur, vitesse, zone)
    var positionsSpread: [PositionSpread]?   // Déduit du type + contraste
    var conditionsOptimales: ConditionsOptimales? // Déduit de l'ensemble
    
    // Flag indiquant si les champs déduits ont été calculés
    var isComputed: Bool
    
    // ═══════════════════════════════════════════════════════════════
    // GESTION
    // ═══════════════════════════════════════════════════════════════
    
    var quantite: Int
    var dateAjout: Date?
    
    // MARK: - 🔧 CodingKeys pour compatibilité JSON
    
    enum CodingKeys: String, CodingKey {
        case id
        case nom
        case marque
        case modele
        case reference  // Champ JSON uniquement (ignoré)
        case typeLeurre = "type"           // ✅ JSON utilise "type"
        case typePeche = "categoriePeche"  // ✅ JSON utilise "categoriePeche" (technique principale)
        case typesPecheCompatibles = "techniquesPossibles"  // ✅ JSON utilise "techniquesPossibles"
        case longueur                      // ✅ JSON utilise "longueur"
        case poids
        case couleurPrincipale             // ✅ JSON utilise "couleurPrincipale"
        case couleurSecondaire = "couleursSecondaires"  // ✅ JSON utilise "couleursSecondaires" (array)
        case profondeurNageMin = "profondeurMin"
        case profondeurNageMax = "profondeurMax"
        case vitesseTraineMin = "vitesseMinimale"     // ✅ JSON utilise "vitesseMinimale"
        case vitesseTraineMax = "vitesseMaximale"     // ✅ JSON utilise "vitesseMaximale"
        case notes
        case photoPath
        case contraste
        case zonesAdaptees = "zones"
        case especesCibles                 // ✅ JSON utilise "especesCibles"
        case positionsSpread               // ✅ JSON utilise "positionsSpread"
        case conditionsOptimales           // ✅ JSON utilise "conditionsOptimales"
        case isComputed
        case quantite
        case dateAjout
        
        // Champs supplémentaires du JSON (ignorés pour l'instant)
        case typeTete
        case actionNage
        case finition
        case vitesseOptimale
    }
    
    // MARK: - Custom Decodable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Décodage des champs obligatoires
        id = try container.decode(Int.self, forKey: .id)
        nom = try container.decode(String.self, forKey: .nom)
        marque = try container.decode(String.self, forKey: .marque)
        modele = try container.decodeIfPresent(String.self, forKey: .modele)
        
        typeLeurre = try container.decode(TypeLeurre.self, forKey: .typeLeurre)
        
        // 🔧 GESTION FLEXIBLE: categoriePeche peut être String OU Array
        // Cela permet la compatibilité avec les anciens JSON
        if let typePecheArray = try? container.decode([TypePeche].self, forKey: .typePeche),
           let firstType = typePecheArray.first {
            // Si c'est un array: le premier = technique principale
            typePeche = firstType
            // Tout l'array = techniques compatibles
            typesPecheCompatibles = typePecheArray
        } else {
            // Sinon: décodage standard comme String
            typePeche = try container.decode(TypePeche.self, forKey: .typePeche)
            // Et on essaie de charger le champ "techniquesPossibles"
            typesPecheCompatibles = try container.decodeIfPresent([TypePeche].self, forKey: .typesPecheCompatibles)
        }
        
        longueur = try container.decode(Double.self, forKey: .longueur)
        poids = try container.decodeIfPresent(Double.self, forKey: .poids)
        
        couleurPrincipale = try container.decode(Couleur.self, forKey: .couleurPrincipale)
        
        // 🔧 GESTION: couleursSecondaires est un array dans le JSON, on prend la première
        if let couleursSecondairesArray = try? container.decode([Couleur].self, forKey: .couleurSecondaire),
           let firstColor = couleursSecondairesArray.first {
            couleurSecondaire = firstColor
        } else if let couleurSecondaireSimple = try? container.decode(Couleur.self, forKey: .couleurSecondaire) {
            couleurSecondaire = couleurSecondaireSimple
        } else {
            couleurSecondaire = nil
        }
        
        profondeurNageMin = try container.decodeIfPresent(Double.self, forKey: .profondeurNageMin)
        profondeurNageMax = try container.decodeIfPresent(Double.self, forKey: .profondeurNageMax)
        vitesseTraineMin = try container.decodeIfPresent(Double.self, forKey: .vitesseTraineMin)
        vitesseTraineMax = try container.decodeIfPresent(Double.self, forKey: .vitesseTraineMax)
        
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
        
        // Champs déduits
        contraste = try container.decodeIfPresent(Contraste.self, forKey: .contraste)
        zonesAdaptees = try container.decodeIfPresent([Zone].self, forKey: .zonesAdaptees)
        especesCibles = try container.decodeIfPresent([String].self, forKey: .especesCibles)
        positionsSpread = try container.decodeIfPresent([PositionSpread].self, forKey: .positionsSpread)
        conditionsOptimales = try container.decodeIfPresent(ConditionsOptimales.self, forKey: .conditionsOptimales)
        
        isComputed = try container.decodeIfPresent(Bool.self, forKey: .isComputed) ?? false
        quantite = try container.decodeIfPresent(Int.self, forKey: .quantite) ?? 1
        dateAjout = try container.decodeIfPresent(Date.self, forKey: .dateAjout)
    }
    
    // MARK: - Custom Encodable
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encodage de tous les champs
        try container.encode(id, forKey: .id)
        try container.encode(nom, forKey: .nom)
        try container.encode(marque, forKey: .marque)
        try container.encodeIfPresent(modele, forKey: .modele)
        
        try container.encode(typeLeurre, forKey: .typeLeurre)
        try container.encode(typePeche, forKey: .typePeche)
        try container.encodeIfPresent(typesPecheCompatibles, forKey: .typesPecheCompatibles)
        try container.encode(longueur, forKey: .longueur)
        try container.encodeIfPresent(poids, forKey: .poids)
        
        try container.encode(couleurPrincipale, forKey: .couleurPrincipale)
        try container.encodeIfPresent(couleurSecondaire, forKey: .couleurSecondaire)
        
        try container.encodeIfPresent(profondeurNageMin, forKey: .profondeurNageMin)
        try container.encodeIfPresent(profondeurNageMax, forKey: .profondeurNageMax)
        try container.encodeIfPresent(vitesseTraineMin, forKey: .vitesseTraineMin)
        try container.encodeIfPresent(vitesseTraineMax, forKey: .vitesseTraineMax)
        
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(photoPath, forKey: .photoPath)
        
        // Champs déduits
        try container.encodeIfPresent(contraste, forKey: .contraste)
        try container.encodeIfPresent(zonesAdaptees, forKey: .zonesAdaptees)
        try container.encodeIfPresent(especesCibles, forKey: .especesCibles)
        try container.encodeIfPresent(positionsSpread, forKey: .positionsSpread)
        try container.encodeIfPresent(conditionsOptimales, forKey: .conditionsOptimales)
        
        try container.encode(isComputed, forKey: .isComputed)
        try container.encode(quantite, forKey: .quantite)
        try container.encodeIfPresent(dateAjout, forKey: .dateAjout)
    }
    
    // MARK: - Initialisation pour nouveau leurre (saisie utilisateur)
    
    init(
        id: Int,
        nom: String,
        marque: String,
        modele: String? = nil,
        typeLeurre: TypeLeurre,
        typePeche: TypePeche,
        typesPecheCompatibles: [TypePeche]? = nil,
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
        self.typesPecheCompatibles = typesPecheCompatibles
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
        return typePeche == .traine || (typesPecheCompatibles?.contains(.traine) ?? false)
    }
    
    /// Vérifie si le leurre est compatible avec une technique donnée
    func estCompatibleAvec(technique: TypePeche) -> Bool {
        if typePeche == technique {
            return true
        }
        return typesPecheCompatibles?.contains(technique) ?? false
    }
    
    /// Toutes les techniques utilisables avec ce leurre
    var toutesLesTechniques: [TypePeche] {
        var techniques = [typePeche]
        if let compatibles = typesPecheCompatibles {
            for technique in compatibles where !techniques.contains(technique) {
                techniques.append(technique)
            }
        }
        return techniques
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
    case poissonNageurVibrant = "poissonNageurVibrant"
    case leurreAJupe = "leurreAJupe"
    case popper = "popper"
    case stickbait = "stickbait"
    case stickbaitFlottant = "stickbaitFlottant"
    case stickbaitCoulant = "stickbaitCoulant"
    case jigMetallique = "jigMetallique"
    case jigStickbait = "jigStickbait"
    case jigStickbaitCoulant = "jigStickbaitCoulant"
    case jigVibrant = "jigVibrant"
    case vibeLipless = "vibeLipless"
    case leurreDeTrainePoissonVolant = "leurreDeTrainePoissonVolant"
    case cuiller = "cuiller"
    case leurreSouple = "leurreSouple"
    case squid = "Squid"
    case madai = "madai"
    case inchiku = "inchiku"
    
    var displayName: String {
        switch self {
        case .poissonNageur: return "Poisson nageur"
        case .poissonNageurPlongeant: return "Poisson nageur plongeant"
        case .poissonNageurCoulant: return "Poisson nageur coulant"
        case .poissonNageurVibrant: return "Poisson nageur vibrant"
        case .leurreAJupe: return "Leurre à jupe (octopus)"
        case .popper: return "Popper"
        case .stickbait: return "Stickbait"
        case .stickbaitFlottant: return "Stickbait flottant"
        case .stickbaitCoulant: return "Stickbait coulant"
        case .jigMetallique: return "Jig métallique"
        case .jigStickbait: return "Jig stickbait"
        case .jigStickbaitCoulant: return "Jig stickbait coulant"
        case .jigVibrant: return "Jig vibrant"
        case .vibeLipless: return "Vibe / Lipless"
        case .leurreDeTrainePoissonVolant: return "Leurre traîne (poisson volant)"
        case .cuiller: return "Cuiller"
        case .leurreSouple: return "Leurre souple"
        case .squid: return "Squid"
        case .madai: return "Madaï"
        case .inchiku: return "Inchiku"
        }
    }
    
    var icon: String {
        switch self {
        case .poissonNageur, .poissonNageurPlongeant, .poissonNageurCoulant, .poissonNageurVibrant:
            return "🐟"
        case .leurreAJupe:
            return "🦑"
        case .popper, .stickbait, .stickbaitFlottant, .stickbaitCoulant:
            return "💨"
        case .jigMetallique, .jigStickbait, .jigStickbaitCoulant, .jigVibrant, .vibeLipless:
            return "⚡"
        case .leurreDeTrainePoissonVolant:
            return "🐦"
        case .cuiller:
            return "🥄"
        case .leurreSouple, .squid:
            return "🪱"
        case .madai, .inchiku:
            return "🎣"
        }
    }
}

// MARK: - Couleur

enum Couleur: String, Codable, CaseIterable, Hashable {
    // Naturelles
    case bleuArgente = "bleuArgente"
    case bleuBlanc = "bleuBlanc"
    case vertArgente = "vertArgente"
    case vertDore = "vertDore"
    case sardine = "sardine"
    case maquereau = "maquereau"
    case argente = "argente"
    case argenteBleu = "argenteBleu"
    case blanc = "blanc"
    case transparent = "transparent"
    
    // Flashy
    case roseFuchsia = "roseFuchsia"
    case rose = "rose"
    case roseFluo = "roseFluo"
    case chartreuse = "chartreuse"
    case orange = "orange"
    case jaune = "jaune"
    case jauneFluo = "jauneFluo"
    case roseHolographique = "roseHolographique"
    case jauneHolographique = "jauneHolographique"
    
    // Sombres
    case noir = "noir"
    case noirViolet = "noirViolet"
    case noirBleu = "noirBleu"
    case bleuNoir = "bleuNoir"
    case vertNoir = "vertNoir"
    case violetFonce = "violetFonce"
    case bleuFonce = "bleuFonce"
    case noirRouge = "noirRouge"
    case violet = "violet"
    
    // Contrastées
    case bleuNoirGris = "bleuNoirGris"
    case violetNoir = "violetNoir"
    case roseBlanc = "roseBlanc"
    case rougeJaune = "rougeJaune"
    case orangeJaune = "orangeJaune"
    case blancRouge = "blancRouge"
    case blancOrange = "blancOrange"
    case vertBlanc = "vertBlanc"
    case roseBleu = "roseBleu"
    
    // Autres
    case brun = "brun"
    case beige = "beige"
    case marron = "marron"
    case vert = "vert"
    case vertOlive = "vertOlive"
    case bleu = "bleu"
    case blow = "blow"
    case rouge = "rouge"
    case or = "or"
    
    var displayName: String {
        switch self {
        case .bleuArgente: return "Bleu/Argenté"
        case .bleuBlanc: return "Bleu/Blanc"
        case .vertArgente: return "Vert/Argenté"
        case .vertDore: return "Vert/Doré"
        case .sardine: return "Sardine"
        case .maquereau: return "Maquereau"
        case .argente: return "Argenté"
        case .argenteBleu: return "Argenté/Bleu"
        case .blanc: return "Blanc"
        case .transparent: return "Transparent"
        case .roseFuchsia: return "Rose Fuchsia"
        case .rose: return "Rose"
        case .roseFluo: return "Rose Fluo"
        case .chartreuse: return "Chartreuse"
        case .orange: return "Orange"
        case .jaune: return "Jaune"
        case .jauneFluo: return "Jaune Fluo"
        case .roseHolographique: return "Rose Holographique"
        case .jauneHolographique: return "Jaune Holographique"
        case .noir: return "Noir"
        case .noirViolet: return "Noir/Violet"
        case .noirBleu: return "Noir/Bleu"
        case .bleuNoir: return "Bleu/Noir"
        case .vertNoir: return "Vert/Noir"
        case .violetFonce: return "Violet Foncé"
        case .bleuFonce: return "Bleu Foncé"
        case .noirRouge: return "Noir/Rouge"
        case .violet: return "Violet"
        case .bleuNoirGris: return "Bleu Noir/Gris"
        case .violetNoir: return "Violet/Noir"
        case .roseBlanc: return "Rose/Blanc"
        case .rougeJaune: return "Rouge/Jaune"
        case .orangeJaune: return "Orange/Jaune"
        case .blancRouge: return "Blanc/Rouge"
        case .blancOrange: return "Blanc/Orange"
        case .vertBlanc: return "Vert/Blanc"
        case .roseBleu: return "Rose/Bleu"
        case .brun: return "Brun"
        case .beige: return "Beige"
        case .marron: return "Marron"
        case .vert: return "Vert"
        case .vertOlive: return "Vert Olive"
        case .bleu: return "Bleu"
        case .blow: return "Blow"
        case .rouge: return "Rouge"
        case .or: return "Or"
        }
    }
    
    /// Catégorie de contraste naturel de cette couleur
    var contrasteNaturel: Contraste {
        switch self {
        case .bleuArgente, .bleuBlanc, .vertArgente, .vertDore, .sardine, .maquereau,
             .argente, .argenteBleu, .blanc, .transparent, .bleu, .vert, .vertOlive, .blow:
            return .naturel
        case .roseFuchsia, .rose, .roseFluo, .chartreuse, .orange, .jaune, .jauneFluo,
             .roseHolographique, .jauneHolographique, .or:
            return .flashy
        case .noir, .noirViolet, .noirBleu, .bleuNoir, .vertNoir, .violetFonce,
             .bleuFonce, .noirRouge, .violet, .brun, .marron:
            return .sombre
        case .bleuNoirGris, .violetNoir, .roseBlanc, .rougeJaune, .orangeJaune,
             .blancRouge, .blancOrange, .vertBlanc, .roseBleu, .beige, .rouge:
            return .contraste
        }
    }
    
    /// Couleur SwiftUI pour affichage dans l'interface
    var swiftUIColor: Color {
        switch self {
        // Naturelles
        case .bleuArgente: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .bleuBlanc: return Color(red: 0.5, green: 0.7, blue: 1.0)
        case .vertArgente: return Color(red: 0.2, green: 0.7, blue: 0.5)
        case .vertDore: return Color(red: 0.4, green: 0.7, blue: 0.2)
        case .sardine: return Color(red: 0.7, green: 0.8, blue: 0.9)
        case .maquereau: return Color(red: 0.2, green: 0.6, blue: 0.5)
        case .argente: return Color.gray.opacity(0.6)
        case .argenteBleu: return Color(red: 0.6, green: 0.7, blue: 0.9)
        case .blanc: return Color.white
        case .transparent: return Color.gray.opacity(0.3)
        
        // Flashy
        case .roseFuchsia: return Color(red: 1.0, green: 0.0, blue: 0.5)
        case .rose: return .pink
        case .roseFluo: return Color(red: 1.0, green: 0.2, blue: 0.7)
        case .chartreuse: return Color(red: 0.5, green: 1.0, blue: 0.0)
        case .orange: return .orange
        case .jaune: return .yellow
        case .jauneFluo: return Color(red: 1.0, green: 1.0, blue: 0.0)
        case .roseHolographique: return Color(red: 1.0, green: 0.5, blue: 0.8)
        case .jauneHolographique: return Color(red: 1.0, green: 0.9, blue: 0.3)
        
        // Sombres
        case .noir: return .black
        case .noirViolet: return Color(red: 0.2, green: 0.0, blue: 0.3)
        case .noirBleu: return Color(red: 0.0, green: 0.1, blue: 0.3)
        case .bleuNoir: return Color(red: 0.1, green: 0.1, blue: 0.3)
        case .vertNoir: return Color(red: 0.0, green: 0.2, blue: 0.1)
        case .violetFonce: return Color(red: 0.3, green: 0.0, blue: 0.5)
        case .bleuFonce: return Color(red: 0.0, green: 0.2, blue: 0.6)
        case .noirRouge: return Color(red: 0.3, green: 0.0, blue: 0.1)
        case .violet: return .purple
        
        // Contrastées
        case .bleuNoirGris: return Color(red: 0.2, green: 0.3, blue: 0.4)
        case .violetNoir: return Color(red: 0.3, green: 0.0, blue: 0.4)
        case .roseBlanc: return Color(red: 1.0, green: 0.7, blue: 0.8)
        case .rougeJaune: return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .orangeJaune: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .blancRouge: return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .blancOrange: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .vertBlanc: return Color(red: 0.5, green: 0.9, blue: 0.6)
        case .roseBleu: return Color(red: 0.7, green: 0.4, blue: 0.9)
        
        // Autres
        case .brun: return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .beige: return Color(red: 0.9, green: 0.9, blue: 0.7)
        case .marron: return Color(red: 0.4, green: 0.2, blue: 0.1)
        case .vert: return .green
        case .vertOlive: return Color(red: 0.5, green: 0.5, blue: 0.2)
        case .bleu: return .blue
        case .blow: return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .rouge: return .red
        case .or: return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }
}

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
    case profond = "profond"      // Zone profonde > 100m
    case dcp = "dcp"
    
    var displayName: String {
        switch self {
        case .lagon: return "Lagon"
        case .recif: return "Récif"
        case .passe: return "Passe"
        case .tombant: return "Tombant"
        case .large: return "Large/Hauturier"
        case .profond: return "Profond (>100m)"
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
        case .profond: return "🌑"
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
        case .profond:
            return [
                "Vivaneau rubis (200-300m)",
                "Vivaneau la flamme (200-300m)",
                "Vivaneau blanc (150-250m)",
                "Loche pintade profonde",
                "Mérou profond",
                "Thon obèse",
                "Beryx"
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
    case libre = "libre"
    case shortCorner = "shortCorner"
    case longCorner = "longCorner"
    case shortRigger = "shortRigger"
    case longRigger = "longRigger"
    case shotgun = "shotgun"
    
    var displayName: String {
        switch self {
        case .libre: return "Libre"
        case .shortCorner: return "Short Corner (10-20m)"
        case .longCorner: return "Long Corner (30-50m)"
        case .shortRigger: return "Short Rigger (40-60m)"
        case .longRigger: return "Long Rigger (50-70m)"
        case .shotgun: return "Shotgun (70-100m)"
        }
    }
    
    var distance: String {
        switch self {
        case .libre: return "Variable"
        case .shortCorner: return "10-20m"
        case .longCorner: return "30-50m"
        case .shortRigger: return "40-60m"
        case .longRigger: return "50-70m"
        case .shotgun: return "70-100m"
        }
    }
    
    var caracteristiques: String {
        switch self {
        case .libre: return "Position libre"
        case .shortCorner: return "Agressif, naturel, dans les bulles"
        case .longCorner: return "Sombre, silhouette"
        case .shortRigger: return "Flashy, attracteur latéral"
        case .longRigger: return "Flashy, couleur différente"
        case .shotgun: return "Discret, fort contraste, très loin"
        }
    }
}

// MARK: - Profil Bateau

enum ProfilBateau: String, Codable, CaseIterable, Hashable {
    case classique = "classique"
    case clark429 = "clark429"
    
    var displayName: String {
        switch self {
        case .classique: return "Classique"
        case .clark429: return "Clark 4,29 m"
        }
    }
    
    var vitesseReference: Double {
        switch self {
        case .classique: return 7.0
        case .clark429: return 5.5
        }
    }
    
    var vitesseOptimaleMin: Double {
        switch self {
        case .classique: return 6.0
        case .clark429: return 5.2
        }
    }
    
    var vitesseOptimaleMax: Double {
        switch self {
        case .classique: return 12.0
        case .clark429: return 6.2
        }
    }
    
    var nombreLignesRecommande: Int {
        switch self {
        case .classique: return 5
        case .clark429: return 4
        }
    }
    
    var description: String {
        switch self {
        case .classique:
            return "Bateau classique - Spread complet jusqu'à 5 lignes - Vitesse optimale: \(Int(vitesseOptimaleMin))-\(Int(vitesseOptimaleMax)) nœuds"
        case .clark429:
            return "Clark 4,29 m - Spread court - Max 4 lignes recommandé - Vitesse optimale: \(String(format: "%.1f", vitesseOptimaleMin))-\(String(format: "%.1f", vitesseOptimaleMax)) nœuds"
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
    case apresMidi = "apres_midi"       // ✅ JSON utilise "apres_midi"
    case crepuscule = "crepuscule"
    case nuit = "nuit"
    
    // Décodeur personnalisé pour accepter plusieurs formats
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        // Normaliser : remplacer underscore par camelCase
        let normalized = rawValue.replacingOccurrences(of: "_", with: "")
        
        switch normalized.lowercased() {
        case "aube":
            self = .aube
        case "matinee", "matinée":
            self = .matinee
        case "midi":
            self = .midi
        case "apresmidi", "après-midi", "apres_midi":
            self = .apresMidi
        case "crepuscule", "crépuscule":
            self = .crepuscule
        case "nuit":
            self = .nuit
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Valeur MomentJournee invalide: '\(rawValue)'"
            )
        }
    }
    
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
    var derniereMiseAJour: String?  // ✅ RENDU OPTIONNEL
    var nombreTotal: Int
    var proprietaire: String
    
    // Champs additionnels du JSON qui peuvent être présents
    var description: String?
    var source: String?
}

// ═══════════════════════════════════════════════════════════════════════════
// MARK: - TYPES DE COMPATIBILITÉ POUR MODULE 2 (SuggestionEngine)
// Ces types sont conservés pour assurer la compatibilité avec le moteur
// de suggestion existant. Ils seront progressivement migrés.
// ═══════════════════════════════════════════════════════════════════════════

// MARK: - Luminosite (utilisé par Module 2)

enum Luminosite: String, Codable, CaseIterable, Hashable {
    case forte = "forte"           // Soleil franc
    case diffuse = "diffuse"       // Nuageux
    case faible = "faible"         // Aube/Crépuscule
    case sombre = "sombre"         // Nuages épais
    case nuit = "nuit"             // Pêche de nuit
    
    var displayName: String {
        switch self {
        case .forte: return "Forte (soleil)"
        case .diffuse: return "Diffuse (nuageux)"
        case .faible: return "Faible (aube/crépuscule)"
        case .sombre: return "Sombre (couvert)"
        case .nuit: return "Nuit"
        }
    }
    
    var icon: String {
        switch self {
        case .forte: return "sun.max.fill"
        case .diffuse: return "cloud.sun.fill"
        case .faible: return "moonphase.first.quarter"
        case .sombre: return "cloud.fill"
        case .nuit: return "moon.stars.fill"
        }
    }
    
    var description: String {
        switch self {
        case .forte: return "Soleil franc, ciel dégagé"
        case .diffuse: return "Ciel nuageux, lumière filtrée"
        case .faible: return "Aube ou crépuscule"
        case .sombre: return "Ciel très couvert"
        case .nuit: return "Pêche de nuit"
        }
    }
    
    /// Déduit la luminosité depuis le moment de la journée
    static func depuis(moment: MomentJournee) -> Luminosite {
        switch moment {
        case .midi: return .forte
        case .matinee, .apresMidi: return .diffuse
        case .aube, .crepuscule: return .faible
        case .nuit: return .nuit
        }
    }
}

// MARK: - CategoriePeche (alias vers Zone pour compatibilité)

typealias CategoriePeche = Zone

// Extension pour ajouter les anciennes valeurs si nécessaire
extension Zone {
    static var lagonCotier: Zone { .lagon }
    static var passes: Zone { .passe }
    static var hauturier: Zone { .large }
}

// MARK: - Espece (enum pour compatibilité Module 2)

enum Espece: String, Codable, CaseIterable, Hashable {
    // Pélagiques
    case thonJaune = "thonJaune"
    case thonObese = "thonObese"
    case bonite = "bonite"
    case wahoo = "wahoo"
    case mahiMahi = "mahiMahi"
    case marlin = "marlin"
    case voilier = "voilier"
    case thazard = "thazard"
    case thazardBatard = "thazardBatard"
    
    // Récif / Lagon
    case carangue = "carangue"
    case carangueGT = "carangueGT"
    case carangueBleue = "carangueBleue"
    case barracuda = "barracuda"
    case becune = "becune"
    case loche = "loche"
    case lochePintade = "lochePintade"
    case merou = "merou"
    case empereur = "empereur"
    
    // Vivaneaux
    case vivaneauRouge = "vivaneauRouge"
    case vivaneauChienRouge = "vivaneauChienRouge"
    case vivaneauQueueNoire = "vivaneauQueueNoire"
    case becDeCane = "becDeCane"
    
    // Autres
    case coureurArcEnCiel = "coureurArcEnCiel"
    
    var displayName: String {
        switch self {
        case .thonJaune: return "Thon jaune"
        case .thonObese: return "Thon obèse"
        case .bonite: return "Bonite"
        case .wahoo: return "Wahoo"
        case .mahiMahi: return "Mahi-mahi"
        case .marlin: return "Marlin"
        case .voilier: return "Voilier"
        case .thazard: return "Thazard"
        case .thazardBatard: return "Thazard bâtard"
        case .carangue: return "Carangue"
        case .carangueGT: return "Carangue GT"
        case .carangueBleue: return "Carangue bleue"
        case .barracuda: return "Barracuda"
        case .becune: return "Bécune"
        case .loche: return "Loche"
        case .lochePintade: return "Loche pintade"
        case .merou: return "Mérou"
        case .empereur: return "Empereur"
        case .vivaneauRouge: return "Vivaneau rouge"
        case .vivaneauChienRouge: return "Vivaneau chien rouge"
        case .vivaneauQueueNoire: return "Vivaneau queue noire"
        case .becDeCane: return "Bec de cane"
        case .coureurArcEnCiel: return "Coureur arc-en-ciel"
        }
    }
    
    /// Zones typiques pour cette espèce
    var zonesTypiques: [Zone] {
        switch self {
        case .thonJaune, .thonObese, .marlin, .voilier:
            return [.large, .dcp]
        case .wahoo, .mahiMahi, .bonite:
            return [.large, .passe, .dcp]
        case .thazard, .thazardBatard:
            return [.passe, .lagon, .large]
        case .carangue, .carangueBleue, .barracuda, .becune:
            return [.lagon, .recif, .passe]
        case .carangueGT:
            return [.passe, .recif, .large]
        case .loche, .lochePintade, .merou:
            return [.recif, .tombant]
        case .empereur:
            return [.lagon, .recif]
        case .vivaneauRouge, .vivaneauChienRouge, .vivaneauQueueNoire, .becDeCane:
            return [.tombant, .recif]
        case .coureurArcEnCiel:
            return [.large, .passe]
        }
    }
    
    /// Types de pêche compatibles pour cette espèce
    /// IMPORTANT : Une espèce peut être pêchée de plusieurs façons selon la zone
    var typesPecheCompatibles: [TypePeche] {
        switch self {
        // Pélagiques hauturiers - Traîne principalement
        case .thonJaune:
            return [.traine]
        case .thonObese:
            return [.traine]
        case .wahoo:
            return [.traine]
        case .mahiMahi:
            return [.traine, .lancer]
        case .marlin:
            return [.traine]
        case .voilier:
            return [.traine]
        case .bonite:
            return [.traine, .lancer]
            
        // Thazards - Traîne et lancer
        case .thazard:
            return [.traine, .lancer]
        case .thazardBatard:
            return [.traine]
            
        // Carangues - Multiples techniques
        case .carangue:
            return [.traine, .lancer]
        case .carangueGT:
            return [.traine, .lancer, .jig]
        case .carangueBleue:
            return [.traine, .lancer]
            
        // Barracudas/Bécunes - Traîne et lancer
        case .barracuda:
            return [.traine, .lancer]
        case .becune:
            return [.traine, .lancer]
            
        // Loches - Jig et montage principalement, parfois traîne
        case .loche:
            return [.jig, .montage, .traine]
        case .lochePintade:
            return [.jig, .montage]
            
        // Mérous - Jig et montage
        case .merou:
            return [.jig, .montage]
            
        // Empereurs - Montage principalement
        case .empereur:
            return [.montage, .palangrotte]
            
        // Vivaneaux - Montage et jig profond
        case .vivaneauRouge:
            return [.montage, .jig, .palangrotte]
        case .vivaneauChienRouge:
            return [.montage, .jig]
        case .vivaneauQueueNoire:
            return [.montage]
            
        // Bec de cane - Montage uniquement (pas traîne!)
        case .becDeCane:
            return [.montage, .palangrotte]
            
        // Coureur arc-en-ciel - Traîne
        case .coureurArcEnCiel:
            return [.traine]
        }
    }
    
    /// Indique si cette espèce est pêchable à la traîne
    var estPechableEnTraine: Bool {
        typesPecheCompatibles.contains(.traine)
    }
}
