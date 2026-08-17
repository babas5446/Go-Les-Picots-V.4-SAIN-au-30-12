//
//  Leurre.swift
//  Go les Picots V.4 — Module 1
//
//  @Model SwiftData pur — aucune trace de Codable
//  La sérialisation JSON est gérée par LeurreDTO.swift
//
//  V4 — Architecture propre SwiftData + Swift 6 :
//  - @Model final class Leurre : propriétés + computed properties uniquement
//  - Codable entièrement déplacé vers LeurreDTO
//  - Enums conservés à l'identique
//  - Façades couleurs custom via computed properties
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Modèle Principal

@Model final class Leurre {

    // MARK: - Identification
    @Attribute(.unique) var id: Int

    // ═══════════════════════════════════════════════════════════════
    // CHAMPS SAISIS PAR L'UTILISATEUR
    // ═══════════════════════════════════════════════════════════════

    var nom: String
    var marque: String
    var modele: String?

    var typeLeurre: TypeLeurre
    var typePeche: TypePeche
    var typesPecheCompatibles: [TypePeche]?

    var longueur: Double
    var poids: Double?

    var couleurPrincipale: Couleur
    var couleurPrincipaleCustomData: Data?
    var couleurSecondaire: Couleur?
    var couleurSecondaireCustomData: Data?
    var finition: Finition?

    var typesDeNage: [TypeDeNage]?

    var profondeurNageMin: Double?
    var profondeurNageMax: Double?
    var vitesseTraineMin: Double?
    var vitesseTraineMax: Double?

    var notes: String?

    @Attribute(.externalStorage) var photoData: Data?

    // ═══════════════════════════════════════════════════════════════
    // CHAMPS DÉDUITS PAR LE MOTEUR (Module 2)
    // ═══════════════════════════════════════════════════════════════

    var contraste: Contraste?
    var zonesAdaptees: [Zone]?
    var especesCibles: [String]?
    var positionsSpread: [PositionSpread]?
    var conditionsOptimales: ConditionsOptimales?
    var isComputed: Bool

    // ═══════════════════════════════════════════════════════════════
    // CHAMPS V4
    // ═══════════════════════════════════════════════════════════════

    var notesMotsCles: [String]
    var qualiteDataScore: Int

    // ═══════════════════════════════════════════════════════════════
    // GESTION
    // ═══════════════════════════════════════════════════════════════

    var quantite: Int
    var dateAjout: Date?

    // MARK: - Initialisation

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
        couleurPrincipaleCustom: CouleurCustom? = nil,
        couleurSecondaire: Couleur? = nil,
        couleurSecondaireCustom: CouleurCustom? = nil,
        finition: Finition? = nil,
        typesDeNage: [TypeDeNage]? = nil,
        profondeurNageMin: Double? = nil,
        profondeurNageMax: Double? = nil,
        vitesseTraineMin: Double? = nil,
        vitesseTraineMax: Double? = nil,
        notes: String? = nil,
        photoData: Data? = nil,
        quantite: Int = 1,
        notesMotsCles: [String] = [],
        qualiteDataScore: Int = 0
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
        self.couleurPrincipaleCustomData = couleurPrincipaleCustom?.toData()
        self.couleurSecondaire = couleurSecondaire
        self.couleurSecondaireCustomData = couleurSecondaireCustom?.toData()
        self.finition = finition
        self.typesDeNage = typesDeNage
        self.profondeurNageMin = profondeurNageMin
        self.profondeurNageMax = profondeurNageMax
        self.vitesseTraineMin = vitesseTraineMin
        self.vitesseTraineMax = vitesseTraineMax
        self.notes = notes
        self.photoData = photoData
        self.quantite = quantite
        self.dateAjout = Date()
        self.notesMotsCles = notesMotsCles
        self.qualiteDataScore = qualiteDataScore
        self.contraste = nil
        self.zonesAdaptees = nil
        self.especesCibles = nil
        self.positionsSpread = nil
        self.conditionsOptimales = nil
        self.isComputed = false
    }

    // MARK: - Computed Properties utilitaires

    var profondeurFormatee: String? {
        guard let min = profondeurNageMin, let max = profondeurNageMax else { return nil }
        if min == max { return "\(Int(min))m" }
        return "\(Int(min))-\(Int(max))m"
    }

    var vitesseFormatee: String? {
        guard let min = vitesseTraineMin, let max = vitesseTraineMax else { return nil }
        return "\(Int(min))-\(Int(max)) noeuds"
    }

    var estLeurreDeTraine: Bool {
        typePeche == .traine || (typesPecheCompatibles?.contains(.traine) ?? false)
    }

    func estCompatibleAvec(technique: TypePeche) -> Bool {
        if typePeche == technique { return true }
        return typesPecheCompatibles?.contains(technique) ?? false
    }

    var toutesLesTechniques: [TypePeche] {
        var techniques = [typePeche]
        if let compatibles = typesPecheCompatibles {
            for technique in compatibles where !techniques.contains(technique) {
                techniques.append(technique)
            }
        }
        return techniques
    }

    var descriptionCouleurs: String {
        let principale = couleurPrincipaleCustom?.nom ?? couleurPrincipale.displayName
        if let custom = couleurSecondaireCustom {
            return "\(principale) / \(custom.nom)"
        } else if let secondaire = couleurSecondaire {
            return "\(principale) / \(secondaire.displayName)"
        }
        return principale
    }

    var estCouleurPrincipaleRainbow: Bool { couleurPrincipaleCustom?.isRainbow ?? false }
    var estCouleurSecondaireRainbow: Bool { couleurSecondaireCustom?.isRainbow ?? false }

    var luminositePercueCouleur: Double {
        if let custom = couleurPrincipaleCustom { return custom.luminositePercue }
        switch couleurPrincipale.contrasteNaturel {
        case .flashy:    return 0.7
        case .naturel:   return 0.5
        case .sombre:    return 0.2
        case .contraste: return 0.5
        }
    }

    var estCouleurClaire: Bool { luminositePercueCouleur > 0.5 }
    var estCouleurFoncee: Bool { luminositePercueCouleur < 0.3 }

    // MARK: - Deductions moteur

    var zonesAdapteesFinales: [Zone] {
        if let zones = zonesAdaptees, !zones.isEmpty { return zones }
        if let notes = notes, !notes.isEmpty {
            let z = NoteAnalysisService.detecterZones(dans: notes)
            if !z.isEmpty { return z }
        }
        return LeurreIntelligenceService.deduireZones(leurre: self)
    }

    var profilVisuel: Contraste {
        let base = contrastePrincipaleReel
        guard let finition = finition else { return base }
        switch finition {
        case .holographique, .chrome, .miroir, .paillete:
            switch base {
            case .naturel:   return .naturel
            case .flashy:    return .flashy
            case .sombre:    return .contraste
            case .contraste: return .contraste
            }
        case .mate:
            switch base {
            case .sombre:    return .sombre
            case .naturel:   return .naturel
            case .flashy:    return .flashy
            case .contraste: return .contraste
            }
        case .phosphorescent: return .sombre
        case .UV:
            switch base {
            case .sombre:    return .sombre
            case .naturel:   return .contraste
            case .flashy:    return .flashy
            case .contraste: return .contraste
            }
        case .metallique, .brillante:
            switch base {
            case .naturel:   return .naturel
            case .sombre:    return .contraste
            case .flashy:    return .flashy
            case .contraste: return .contraste
            }
        case .perlee: return base
        }
    }

    var especesCiblesFinales: [String] {
        var especes: [String] = []
        if let notes = notes, !notes.isEmpty {
            especes.append(contentsOf: NoteAnalysisService.detecterEspeces(dans: notes))
        }
        if let especesJSON = especesCibles {
            for e in especesJSON where !especes.contains(e) { especes.append(e) }
        }
        if especes.isEmpty {
            especes = LeurreIntelligenceService.deduireEspeces(leurre: self)
        }
        return especes
    }

    var vitessesTraineFinales: (min: Double, max: Double) {
        if let min = vitesseTraineMin, let max = vitesseTraineMax { return (min, max) }
        return LeurreIntelligenceService.deduireVitesses(leurre: self)
    }

    var conditionsOptimalesFinales: ConditionsOptimales {
        conditionsOptimales ?? LeurreIntelligenceService.deduireConditions(leurre: self)
    }

    var positionsSpreadFinales: [PositionSpread] {
        if let p = positionsSpread, !p.isEmpty { return p }
        if let notes = notes, !notes.isEmpty {
            let p = NoteAnalysisService.detecterPositionsSpread(dans: notes)
            if !p.isEmpty { return p }
        }
        return [.libre]
    }
}

// MARK: - Facades couleurs custom

extension Leurre {

    var couleurPrincipaleCustom: CouleurCustom? {
        get { couleurPrincipaleCustomData.flatMap { CouleurCustom.fromData($0) } }
        set { couleurPrincipaleCustomData = newValue?.toData() }
    }

    var couleurSecondaireCustom: CouleurCustom? {
        get { couleurSecondaireCustomData.flatMap { CouleurCustom.fromData($0) } }
        set { couleurSecondaireCustomData = newValue?.toData() }
    }
}

// MARK: - Extensions affichage et moteur

extension Leurre {

    var couleurPrincipaleAffichage: (isRainbow: Bool, color: Color, nom: String) {
        if let c = couleurPrincipaleCustom { return (c.isRainbow, c.swiftUIColor, c.nom) }
        return (false, couleurPrincipale.swiftUIColor, couleurPrincipale.displayName)
    }

    var couleurSecondaireAffichage: (isRainbow: Bool, color: Color, nom: String)? {
        if let c = couleurSecondaireCustom { return (c.isRainbow, c.swiftUIColor, c.nom) }
        if let s = couleurSecondaire { return (false, s.swiftUIColor, s.displayName) }
        return nil
    }

    var contrastePrincipaleReel: Contraste {
        couleurPrincipaleCustom?.contraste ?? couleurPrincipale.contrasteNaturel
    }

    var contrasteSecondaireReel: Contraste? {
        couleurSecondaireCustom?.contraste ?? couleurSecondaire?.contrasteNaturel
    }

    var luminositePrincipaleReelle: Double {
        if let c = couleurPrincipaleCustom { return c.luminositePercue }
        return extraireLuminosite(de: couleurPrincipale.swiftUIColor)
    }

    var luminositeSecondaireReelle: Double? {
        if let c = couleurSecondaireCustom { return c.luminositePercue }
        if let s = couleurSecondaire { return extraireLuminosite(de: s.swiftUIColor) }
        return nil
    }

    private func extraireLuminosite(de color: Color) -> Double {
        guard let components = UIColor(color).cgColor.components,
              components.count >= 3 else { return 0.5 }
        return 0.2126 * Double(components[0])
             + 0.7152 * Double(components[1])
             + 0.0722 * Double(components[2])
    }

    var estCouleurPrincipaleClaire: Bool {
        couleurPrincipaleCustom?.estClaire ?? (luminositePrincipaleReelle > 0.5)
    }

    var estCouleurPrincipaleFoncee: Bool {
        couleurPrincipaleCustom?.estFoncee ?? (luminositePrincipaleReelle < 0.3)
    }

    var composantesRGBPrincipale: (r: Double, g: Double, b: Double) {
        if let c = couleurPrincipaleCustom { return (c.red, c.green, c.blue) }
        guard let comp = UIColor(couleurPrincipale.swiftUIColor).cgColor.components,
              comp.count >= 3 else { return (0.5, 0.5, 0.5) }
        return (Double(comp[0]), Double(comp[1]), Double(comp[2]))
    }

    var composantesRGBSecondaire: (r: Double, g: Double, b: Double)? {
        if let c = couleurSecondaireCustom { return (c.red, c.green, c.blue) }
        guard let s = couleurSecondaire,
              let comp = UIColor(s.swiftUIColor).cgColor.components,
              comp.count >= 3 else { return nil }
        return (Double(comp[0]), Double(comp[1]), Double(comp[2]))
    }
}

// MARK: - Alias compatibilite

typealias CategoriePeche = Zone

extension Zone {
    static var lagonCotier: Zone { .lagon }
    static var passes: Zone     { .passe }
    static var hauturier: Zone  { .large }
}

// MARK: - TypePeche

enum TypePeche: String, Codable, CaseIterable, Hashable {
    case traine      = "traine"
    case lancer      = "lancer"
    case jig         = "jig"
    case montage     = "montage"
    case palangrotte = "palangrotte"
    case jigging     = "jigging"

    var displayName: String {
        switch self {
        case .traine:      return "Traine"
        case .lancer:      return "Lancer"
        case .jig:         return "Jig"
        case .montage:     return "Montage"
        case .palangrotte: return "Palangrotte"
        case .jigging:     return "Jigging vertical"
        }
    }

    var icon: String {
        switch self {
        case .traine:      return "arrow.right.circle"
        case .lancer:      return "figure.fishing"
        case .jig:         return "arrow.down.circle"
        case .montage:     return "link"
        case .palangrotte: return "arrow.up.and.down"
        case .jigging:     return "arrow.up.arrow.down"
        }
    }

    var necessiteInfosTraine: Bool { self == .traine }
}

// MARK: - TypeLeurre

enum TypeLeurre: String, Codable, CaseIterable, Hashable {
    case poissonNageur               = "poissonNageur"
    case poissonNageurPlongeant      = "poissonNageurPlongeant"
    case poissonNageurCoulant        = "poissonNageurCoulant"
    case poissonNageurVibrant        = "poissonNageurVibrant"
    case leurreAJupe                 = "leurreAJupe"
    case popper                      = "popper"
    case stickbait                   = "stickbait"
    case stickbaitFlottant           = "stickbaitFlottant"
    case stickbaitCoulant            = "stickbaitCoulant"
    case jigMetallique               = "jigMetallique"
    case jigStickbait                = "jigStickbait"
    case jigStickbaitCoulant         = "jigStickbaitCoulant"
    case jigVibrant                  = "jigVibrant"
    case vibeLipless                 = "vibeLipless"
    case leurreDeTrainePoissonVolant = "leurreDeTrainePoissonVolant"
    case cuiller                     = "cuiller"
    case leurreSouple                = "leurreSouple"
    case squid                       = "Squid"
    case madai                       = "madai"
    case inchiku                     = "inchiku"

    var displayName: String {
        switch self {
        case .poissonNageur:               return "Poisson nageur"
        case .poissonNageurPlongeant:      return "Poisson nageur plongeant"
        case .poissonNageurCoulant:        return "Poisson nageur coulant"
        case .poissonNageurVibrant:        return "Poisson nageur vibrant"
        case .leurreAJupe:                 return "Leurre a jupe (octopus)"
        case .popper:                      return "Popper"
        case .stickbait:                   return "Stickbait"
        case .stickbaitFlottant:           return "Stickbait flottant"
        case .stickbaitCoulant:            return "Stickbait coulant"
        case .jigMetallique:               return "Jig metallique"
        case .jigStickbait:                return "Jig stickbait"
        case .jigStickbaitCoulant:         return "Jig stickbait coulant"
        case .jigVibrant:                  return "Jig vibrant"
        case .vibeLipless:                 return "Vibe / Lipless"
        case .leurreDeTrainePoissonVolant: return "Leurre traine (poisson volant)"
        case .cuiller:                     return "Cuiller"
        case .leurreSouple:                return "Leurre souple"
        case .squid:                       return "Squid"
        case .madai:                       return "Madai"
        case .inchiku:                     return "Inchiku"
        }
    }

    var icon: String {
        switch self {
        case .poissonNageur, .poissonNageurPlongeant,
             .poissonNageurCoulant, .poissonNageurVibrant: return "fish"
        case .leurreAJupe:                                return "squid"
        case .popper, .stickbait,
             .stickbaitFlottant, .stickbaitCoulant:       return "wind"
        case .jigMetallique, .jigStickbait,
             .jigStickbaitCoulant, .jigVibrant,
             .vibeLipless:                                return "bolt"
        case .leurreDeTrainePoissonVolant:                return "bird"
        case .cuiller:                                    return "spoon"
        case .leurreSouple, .squid:                       return "worm"
        case .madai, .inchiku:                            return "fish.fill"
        }
    }
}

// MARK: - Couleur

enum Couleur: String, Codable, CaseIterable, Hashable {
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
    case roseFuchsia = "roseFuchsia"
    case rose = "rose"
    case roseFluo = "roseFluo"
    case chartreuse = "chartreuse"
    case orange = "orange"
    case jaune = "jaune"
    case jauneFluo = "jauneFluo"
    case roseHolographique = "roseHolographique"
    case jauneHolographique = "jauneHolographique"
    case noir = "noir"
    case noirViolet = "noirViolet"
    case noirBleu = "noirBleu"
    case bleuNoir = "bleuNoir"
    case vertNoir = "vertNoir"
    case violetFonce = "violetFonce"
    case bleuFonce = "bleuFonce"
    case noirRouge = "noirRouge"
    case violet = "violet"
    case bleuNoirGris = "bleuNoirGris"
    case violetNoir = "violetNoir"
    case roseBlanc = "roseBlanc"
    case rougeJaune = "rougeJaune"
    case orangeJaune = "orangeJaune"
    case blancRouge = "blancRouge"
    case blancOrange = "blancOrange"
    case vertBlanc = "vertBlanc"
    case roseBleu = "roseBleu"
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
        case .bleuArgente: return "Bleu/Argente"
        case .bleuBlanc: return "Bleu/Blanc"
        case .vertArgente: return "Vert/Argente"
        case .vertDore: return "Vert/Dore"
        case .sardine: return "Sardine"
        case .maquereau: return "Maquereau"
        case .argente: return "Argente"
        case .argenteBleu: return "Argente/Bleu"
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
        case .violetFonce: return "Violet Fonce"
        case .bleuFonce: return "Bleu Fonce"
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

    var swiftUIColor: Color {
        switch self {
        case .bleuArgente: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .bleuBlanc:   return Color(red: 0.5, green: 0.7, blue: 1.0)
        case .vertArgente: return Color(red: 0.2, green: 0.7, blue: 0.5)
        case .vertDore:    return Color(red: 0.4, green: 0.7, blue: 0.2)
        case .sardine:     return Color(red: 0.7, green: 0.8, blue: 0.9)
        case .maquereau:   return Color(red: 0.2, green: 0.6, blue: 0.5)
        case .argente:     return Color.gray.opacity(0.6)
        case .argenteBleu: return Color(red: 0.6, green: 0.7, blue: 0.9)
        case .blanc:       return Color.white
        case .transparent: return Color.gray.opacity(0.3)
        case .roseFuchsia: return Color(red: 1.0, green: 0.0, blue: 0.5)
        case .rose:        return .pink
        case .roseFluo:    return Color(red: 1.0, green: 0.2, blue: 0.7)
        case .chartreuse:  return Color(red: 0.5, green: 1.0, blue: 0.0)
        case .orange:      return .orange
        case .jaune:       return .yellow
        case .jauneFluo:   return Color(red: 1.0, green: 1.0, blue: 0.0)
        case .roseHolographique:  return Color(red: 1.0, green: 0.5, blue: 0.8)
        case .jauneHolographique: return Color(red: 1.0, green: 0.9, blue: 0.3)
        case .noir:        return .black
        case .noirViolet:  return Color(red: 0.2, green: 0.0, blue: 0.3)
        case .noirBleu:    return Color(red: 0.0, green: 0.1, blue: 0.3)
        case .bleuNoir:    return Color(red: 0.1, green: 0.1, blue: 0.3)
        case .vertNoir:    return Color(red: 0.0, green: 0.2, blue: 0.1)
        case .violetFonce: return Color(red: 0.3, green: 0.0, blue: 0.5)
        case .bleuFonce:   return Color(red: 0.0, green: 0.2, blue: 0.6)
        case .noirRouge:   return Color(red: 0.3, green: 0.0, blue: 0.1)
        case .violet:      return .purple
        case .bleuNoirGris: return Color(red: 0.2, green: 0.3, blue: 0.4)
        case .violetNoir:  return Color(red: 0.3, green: 0.0, blue: 0.4)
        case .roseBlanc:   return Color(red: 1.0, green: 0.7, blue: 0.8)
        case .rougeJaune:  return Color(red: 1.0, green: 0.5, blue: 0.0)
        case .orangeJaune: return Color(red: 1.0, green: 0.7, blue: 0.0)
        case .blancRouge:  return Color(red: 1.0, green: 0.3, blue: 0.3)
        case .blancOrange: return Color(red: 1.0, green: 0.6, blue: 0.4)
        case .vertBlanc:   return Color(red: 0.5, green: 0.9, blue: 0.6)
        case .roseBleu:    return Color(red: 0.7, green: 0.4, blue: 0.9)
        case .brun:        return Color(red: 0.6, green: 0.4, blue: 0.2)
        case .beige:       return Color(red: 0.9, green: 0.9, blue: 0.7)
        case .marron:      return Color(red: 0.4, green: 0.2, blue: 0.1)
        case .vert:        return .green
        case .vertOlive:   return Color(red: 0.5, green: 0.5, blue: 0.2)
        case .bleu:        return .blue
        case .blow:        return Color(red: 0.5, green: 0.8, blue: 1.0)
        case .rouge:       return .red
        case .or:          return Color(red: 1.0, green: 0.84, blue: 0.0)
        }
    }
}

// MARK: - Finition

enum Finition: String, Codable, CaseIterable, Hashable {
    case holographique  = "holographique"
    case metallique     = "metallique"
    case mate           = "mate"
    case brillante      = "brillante"
    case perlee         = "perlee"
    case paillete       = "paillete"
    case UV             = "UV"
    case phosphorescent = "phosphorescent"
    case chrome         = "chrome"
    case miroir         = "miroir"

    var displayName: String {
        switch self {
        case .holographique:  return "Holographique"
        case .metallique:     return "Metallique"
        case .mate:           return "Mat"
        case .brillante:      return "Brillante"
        case .perlee:         return "Perlee"
        case .paillete:       return "Paillette"
        case .UV:             return "UV"
        case .phosphorescent: return "Phosphorescent"
        case .chrome:         return "Chrome"
        case .miroir:         return "Miroir"
        }
    }

    var conditionsIdeales: String {
        switch self {
        case .holographique, .chrome, .miroir, .paillete: return "Eau claire, forte luminosite"
        case .metallique, .brillante:                     return "Polyvalent, toutes conditions"
        case .mate:                                       return "Faible luminosite, eau trouble"
        case .UV:                                         return "Profondeur, faible luminosite"
        case .phosphorescent:                             return "Crepuscule, nuit"
        case .perlee:                                     return "Eau legerement trouble"
        }
    }

    func bonusScoring(luminosite: Luminosite, profondeurMax: Double?) -> Double {
        switch (luminosite, self) {
        case (.forte, .holographique), (.forte, .chrome),
             (.forte, .miroir), (.forte, .paillete):  return 3.0
        case (.faible, .mate), (.sombre, .mate),
             (.nuit, .mate):                          return 3.0
        case (_, .UV):
            return (profondeurMax ?? 0) > 10 ? 2.0 : 0.5
        case (.nuit, .phosphorescent):                return 4.0
        case (.diffuse, .perlee):                     return 2.0
        case (_, .metallique), (_, .brillante):       return 1.0
        default:                                      return 0.5
        }
    }
}

// MARK: - Contraste

enum Contraste: String, Codable, CaseIterable, Hashable {
    case naturel   = "naturel"
    case flashy    = "flashy"
    case sombre    = "sombre"
    case contraste = "contraste"

    var displayName: String {
        switch self {
        case .naturel:   return "Naturel/Realiste"
        case .flashy:    return "Flashy/Attirant"
        case .sombre:    return "Sombre/Silhouette"
        case .contraste: return "Fort contraste"
        }
    }

    func efficaciteDansContexte(turbidite: Turbidite, luminosite: Luminosite) -> Double {
        var score: Double = 5.0
        if turbidite == .claire {
            switch self {
            case .naturel:   score = 10.0
            case .contraste: score = 7.0
            case .flashy:    score = 5.0
            case .sombre:    score = 3.0
            }
        } else if turbidite == .trouble || turbidite == .tresTrouble {
            if luminosite == .faible || luminosite == .sombre || luminosite == .nuit {
                switch self {
                case .flashy:    score = 10.0
                case .contraste: score = 8.0
                case .naturel:   score = 6.0
                case .sombre:    score = 2.0
                }
            } else {
                switch self {
                case .sombre:    score = 10.0
                case .contraste: score = 8.0
                case .flashy:    score = 6.0
                case .naturel:   score = 3.0
                }
            }
        } else if turbidite == .legerementTrouble {
            switch self {
            case .contraste: score = 10.0
            case .flashy:    score = 8.0
            case .naturel:   score = 6.0
            case .sombre:    score = luminosite == .forte ? 7.0 : 4.0
            }
        }
        return score
    }
}

// MARK: - Zone

enum Zone: String, Codable, CaseIterable, Hashable {
    case lagon   = "lagon"
    case recif   = "recif"
    case passe   = "passe"
    case tombant = "tombant"
    case large   = "large"
    case profond = "profond"
    case dcp     = "dcp"

    var displayName: String {
        switch self {
        case .lagon:   return "Lagon"
        case .recif:   return "Recif"
        case .passe:   return "Passe"
        case .tombant: return "Tombant"
        case .large:   return "Large/Hauturier"
        case .profond: return "Profond (>100m)"
        case .dcp:     return "DCP"
        }
    }

    var icon: String {
        switch self {
        case .lagon:   return "beach.umbrella"
        case .recif:   return "wave.3.right"
        case .passe:   return "water.waves"
        case .tombant: return "mountain.2"
        case .large:   return "ferry"
        case .profond: return "moon.fill"
        case .dcp:     return "anchor"
        }
    }

    var especesTypiques: [String] {
        switch self {
        case .lagon:
            return ["Carangue ignobilis (GT)", "Carangue bleue", "Becune", "Barracuda",
                    "Thazard raye", "Vivaneau queue noire", "Loche croissant", "Bec de cane"]
        case .recif:
            return ["Carangue GT", "Loche pintade", "Loche areolée", "Bec de cane",
                    "Vivaneau chien rouge", "Empereur", "Merou", "Barracuda"]
        case .passe:
            return ["Thazard commun", "Thon jaune", "Wahoo", "Carangue GT",
                    "Bonite", "Barracuda", "Mahi-mahi", "Voilier"]
        case .tombant:
            return ["Loche pintade (100-280m)", "Bec de cane", "Vivaneau rubis (200-300m)",
                    "Vivaneau la flamme (200-300m)", "Vivaneau blanc (150-250m)",
                    "Merou", "Thon jaune", "Wahoo"]
        case .large:
            return ["Thon jaune", "Thon obese", "Marlin", "Espadon voilier",
                    "Wahoo", "Mahi-mahi (Coryphene)", "Thazard batard", "Bonite"]
        case .profond:
            return ["Vivaneau rubis (200-300m)", "Vivaneau la flamme (200-300m)",
                    "Vivaneau blanc (150-250m)", "Loche pintade profonde",
                    "Merou profond", "Thon obese", "Beryx"]
        case .dcp:
            return ["Thon jaune", "Bonite", "Mahi-mahi", "Wahoo",
                    "Loche", "Thazard", "Voilier", "Marlin"]
        }
    }
}

// MARK: - PositionSpread

enum PositionSpread: String, Codable, CaseIterable, Hashable {
    case libre       = "libre"
    case shortCorner = "shortCorner"
    case longCorner  = "longCorner"
    case shortRigger = "shortRigger"
    case longRigger  = "longRigger"
    case shotgun     = "shotgun"

    var displayName: String {
        switch self {
        case .libre:       return "Libre"
        case .shortCorner: return "Short Corner (10-20m)"
        case .longCorner:  return "Long Corner (30-50m)"
        case .shortRigger: return "Short Rigger (40-60m)"
        case .longRigger:  return "Long Rigger (50-70m)"
        case .shotgun:     return "Shotgun (70-100m)"
        }
    }

    var emoji: String {
        switch self {
        case .libre:       return "pin"
        case .shortCorner: return "circle.fill"
        case .longCorner:  return "circle.fill"
        case .shortRigger: return "circle.fill"
        case .longRigger:  return "circle.fill"
        case .shotgun:     return "circle.fill"
        }
    }

    var distance: String {
        switch self {
        case .libre:       return "Variable"
        case .shortCorner: return "10-20m"
        case .longCorner:  return "30-50m"
        case .shortRigger: return "40-60m"
        case .longRigger:  return "50-70m"
        case .shotgun:     return "70-100m"
        }
    }

    var caracteristiques: String {
        switch self {
        case .libre:       return "Position libre"
        case .shortCorner: return "Agressif, naturel, dans les bulles"
        case .longCorner:  return "Sombre, silhouette"
        case .shortRigger: return "Flashy, attracteur lateral"
        case .longRigger:  return "Flashy, couleur differente"
        case .shotgun:     return "Discret, fort contraste, tres loin"
        }
    }
}

// MARK: - ProfilBateau

enum ProfilBateau: String, Codable, CaseIterable, Hashable {
    case classique = "classique"
    case clark429  = "clark429"

    var displayName: String {
        switch self {
        case .classique: return "Classique"
        case .clark429:  return "Clark 4,29 m"
        }
    }

    var vitesseReference: Double    { self == .clark429 ? 5.5 : 7.0 }
    var vitesseOptimaleMin: Double  { self == .clark429 ? 5.2 : 6.0 }
    var vitesseOptimaleMax: Double  { self == .clark429 ? 6.2 : 12.0 }
    var nombreLignesRecommande: Int { self == .clark429 ? 4   : 5 }

    var description: String {
        switch self {
        case .classique:
            return "Bateau classique - Spread complet 5 lignes - Vitesse: \(Int(vitesseOptimaleMin))-\(Int(vitesseOptimaleMax)) noeuds"
        case .clark429:
            return "Clark 4,29 m - Max 4 lignes - Vitesse: \(String(format: "%.1f", vitesseOptimaleMin))-\(String(format: "%.1f", vitesseOptimaleMax)) noeuds"
        }
    }
}

// MARK: - ConditionsOptimales

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
        self.moments        = moments
        self.etatMer        = etatMer
        self.turbidite      = turbidite
        self.maree          = maree
        self.phasesLunaires = phasesLunaires
    }
}

// MARK: - MomentJournee

enum MomentJournee: String, Codable, CaseIterable, Hashable {
    case aube       = "aube"
    case matinee    = "matinee"
    case midi       = "midi"
    case apresMidi  = "apres_midi"
    case crepuscule = "crepuscule"
    case nuit       = "nuit"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        let normalized = raw.replacingOccurrences(of: "_", with: "").lowercased()
        switch normalized {
        case "aube":                                  self = .aube
        case "matinee", "matinee":                    self = .matinee
        case "midi":                                  self = .midi
        case "apresmidi", "apres-midi", "apres_midi": self = .apresMidi
        case "crepuscule":                            self = .crepuscule
        case "nuit":                                  self = .nuit
        default:
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "MomentJournee invalide: '\(raw)'")
        }
    }

    var displayName: String {
        switch self {
        case .aube:       return "Aube (05:00-07:00)"
        case .matinee:    return "Matinee (07:00-11:00)"
        case .midi:       return "Midi (11:00-14:00)"
        case .apresMidi:  return "Apres-midi (14:00-17:00)"
        case .crepuscule: return "Crepuscule (17:00-19:00)"
        case .nuit:       return "Nuit (19:00-05:00)"
        }
    }
}

// MARK: - Turbidite

enum Turbidite: String, Codable, CaseIterable, Hashable {
    case claire            = "claire"
    case legerementTrouble = "legerementTrouble"
    case trouble           = "trouble"
    case tresTrouble       = "tresTrouble"

    var displayName: String {
        switch self {
        case .claire:            return "Claire"
        case .legerementTrouble: return "Legerement trouble"
        case .trouble:           return "Trouble"
        case .tresTrouble:       return "Tres trouble"
        }
    }
}

// MARK: - TypeMaree

enum TypeMaree: String, Codable, CaseIterable, Hashable {
    case montante    = "montante"
    case descendante = "descendante"
    case etale       = "etale"

    var displayName: String {
        switch self {
        case .montante:    return "Montante"
        case .descendante: return "Descendante"
        case .etale:       return "Etale"
        }
    }
}

// MARK: - PhaseMaree

enum PhaseMaree: String, Codable, CaseIterable, Hashable {
    case montante    = "montante"
    case etaleHaut   = "etaleHaut"
    case descendante = "descendante"
    case etaleBas    = "etaleBas"

    var displayName: String {
        switch self {
        case .montante:    return "Montante"
        case .etaleHaut:   return "Etale haut"
        case .descendante: return "Descendante"
        case .etaleBas:    return "Etale bas"
        }
    }

    var toTypeMaree: TypeMaree {
        switch self {
        case .montante:    return .montante
        case .etaleHaut:   return .etale
        case .descendante: return .descendante
        case .etaleBas:    return .etale
        }
    }
}

// MARK: - EtatMer

enum EtatMer: String, Codable, CaseIterable, Hashable {
    case calme     = "calme"
    case peuAgitee = "peuAgitee"
    case agitee    = "agitee"
    case formee    = "formee"

    var displayName: String {
        switch self {
        case .calme:     return "Calme"
        case .peuAgitee: return "Peu agitee"
        case .agitee:    return "Agitee"
        case .formee:    return "Formee"
        }
    }
}

// MARK: - PhaseLunaire

enum PhaseLunaire: String, Codable, CaseIterable, Hashable {
    case nouvelleLune    = "nouvelleLune"
    case premierQuartier = "premierQuartier"
    case pleineLune      = "pleineLune"
    case dernierQuartier = "dernierQuartier"

    var displayName: String {
        switch self {
        case .nouvelleLune:    return "Nouvelle lune"
        case .premierQuartier: return "Premier quartier"
        case .pleineLune:      return "Pleine lune"
        case .dernierQuartier: return "Dernier quartier"
        }
    }
}

// MARK: - Luminosite

enum Luminosite: String, Codable, CaseIterable, Hashable {
    case forte   = "forte"
    case diffuse = "diffuse"
    case faible  = "faible"
    case sombre  = "sombre"
    case nuit    = "nuit"

    var displayName: String {
        switch self {
        case .forte:   return "Forte (soleil)"
        case .diffuse: return "Diffuse (nuageux)"
        case .faible:  return "Faible (aube/crepuscule)"
        case .sombre:  return "Sombre (couvert)"
        case .nuit:    return "Nuit"
        }
    }

    var icon: String {
        switch self {
        case .forte:   return "sun.max.fill"
        case .diffuse: return "cloud.sun.fill"
        case .faible:  return "moonphase.first.quarter"
        case .sombre:  return "cloud.fill"
        case .nuit:    return "moon.stars.fill"
        }
    }

    static func depuis(moment: MomentJournee) -> Luminosite {
        switch moment {
        case .midi:                return .forte
        case .matinee, .apresMidi: return .diffuse
        case .aube, .crepuscule:   return .faible
        case .nuit:                return .nuit
        }
    }
}

// MARK: - Espece

enum Espece: String, Codable, CaseIterable, Hashable {
    case thonJaune          = "thonJaune"
    case thonObese          = "thonObese"
    case bonite             = "bonite"
    case wahoo              = "wahoo"
    case mahiMahi           = "mahiMahi"
    case marlin             = "marlin"
    case voilier            = "voilier"
    case thazard            = "thazard"
    case thazardBatard      = "thazardBatard"
    case carangue           = "carangue"
    case carangueGT         = "carangueGT"
    case carangueBleue      = "carangueBleue"
    case barracuda          = "barracuda"
    case becune             = "becune"
    case loche              = "loche"
    case lochePintade       = "lochePintade"
    case merou              = "merou"
    case empereur           = "empereur"
    case vivaneauRouge      = "vivaneauRouge"
    case vivaneauChienRouge = "vivaneauChienRouge"
    case vivaneauQueueNoire = "vivaneauQueueNoire"
    case becDeCane          = "becDeCane"
    case coureurArcEnCiel   = "coureurArcEnCiel"

    var displayName: String {
        switch self {
        case .thonJaune:          return "Thon jaune"
        case .thonObese:          return "Thon obese"
        case .bonite:             return "Bonite"
        case .wahoo:              return "Wahoo"
        case .mahiMahi:           return "Mahi-mahi"
        case .marlin:             return "Marlin"
        case .voilier:            return "Voilier"
        case .thazard:            return "Thazard"
        case .thazardBatard:      return "Thazard batard"
        case .carangue:           return "Carangue"
        case .carangueGT:         return "Carangue GT"
        case .carangueBleue:      return "Carangue bleue"
        case .barracuda:          return "Barracuda"
        case .becune:             return "Becune"
        case .loche:              return "Loche"
        case .lochePintade:       return "Loche pintade"
        case .merou:              return "Merou"
        case .empereur:           return "Empereur"
        case .vivaneauRouge:      return "Vivaneau rouge"
        case .vivaneauChienRouge: return "Vivaneau chien rouge"
        case .vivaneauQueueNoire: return "Vivaneau queue noire"
        case .becDeCane:          return "Bec de cane"
        case .coureurArcEnCiel:   return "Coureur arc-en-ciel"
        }
    }

    var zonesTypiques: [Zone] {
        switch self {
        case .thonJaune, .thonObese, .marlin, .voilier:      return [.large, .dcp]
        case .wahoo, .mahiMahi, .bonite:                      return [.large, .passe, .dcp]
        case .thazard, .thazardBatard:                        return [.passe, .lagon, .large]
        case .carangue, .carangueBleue, .barracuda, .becune:  return [.lagon, .recif, .passe]
        case .carangueGT:                                     return [.passe, .recif, .large]
        case .loche, .lochePintade, .merou:                   return [.recif, .tombant]
        case .empereur:                                       return [.lagon, .recif]
        case .vivaneauRouge, .vivaneauChienRouge,
             .vivaneauQueueNoire, .becDeCane:                 return [.tombant, .recif]
        case .coureurArcEnCiel:                               return [.large, .passe]
        }
    }

    var typesPecheCompatibles: [TypePeche] {
        switch self {
        case .thonJaune, .thonObese, .wahoo,
             .marlin, .voilier, .thazardBatard:  return [.traine]
        case .mahiMahi, .bonite, .thazard,
             .carangue, .carangueBleue,
             .barracuda, .becune:                return [.traine, .lancer]
        case .carangueGT:                        return [.traine, .lancer, .jig]
        case .loche:                             return [.jig, .montage, .traine]
        case .lochePintade, .merou:              return [.jig, .montage]
        case .empereur:                          return [.montage, .palangrotte]
        case .vivaneauRouge:                     return [.montage, .jig, .palangrotte]
        case .vivaneauChienRouge:                return [.montage, .jig]
        case .vivaneauQueueNoire, .becDeCane:    return [.montage, .palangrotte]
        case .coureurArcEnCiel:                  return [.traine]
        }
    }

    var estPechableEnTraine: Bool { typesPecheCompatibles.contains(.traine) }
}
