//
//  LeurreIntelligenceService.swift
//  Go les Picots
//
//  Déductions automatiques à partir de la fiche d'un leurre.
//
//  V4.2 (octobre 2026) — règles de déduction, version 2
//  (onglet « Règles de déduction » de l'audit, décisions des 3 et 4 octobre) :
//  - Zones : un seul seuil de profondeur, la taille décide du large.
//  - Espèces : un profil de traîne par espèce (taille, tranche d'eau, zones,
//    nage) ; six espèces calculées au plus ; la couleur ne choisit plus
//    l'espèce.
//  - Postes : la profondeur fixe les postes possibles, la famille visuelle
//    désigne le poste conseillé (premier de la liste).
//  - Lignes repères des notes (Espèces, Zones, Postes) prioritaires.
//  - Couleur : profil du leurre en trois attributs (famille, teinte, éclat),
//    famille corrigée par la profondeur, besoin de contraste du jour en cinq
//    niveaux (ReglesCouleur).
//
//  Hiérarchie des sources : manuels CPS 93 et CPS 2025 (zone, longueur de
//  ligne, surface ou profondeur, espèces) ; données fabricant (vitesse,
//  profondeur) ; pêche sportive (couleur). La couleur départage, elle
//  n'élimine jamais.
//
//  Created: 2024-12-23
//

import Foundation

// MARK: - Fiche utile aux déductions

/// Champs saisis d'un leurre, indépendants de SwiftData : les règles
/// se testent ainsi hors de l'app.
struct FicheDeduction {
    struct CouleurPerso {
        let contraste: Contraste
        let r: Double
        let g: Double
        let b: Double
        var luminosite: Double { 0.2126 * r + 0.7152 * g + 0.0722 * b }
    }

    var typeLeurre: TypeLeurre
    var typePeche: TypePeche
    var typesPecheCompatibles: [TypePeche] = []
    var longueur: Double
    var profondeurMin: Double?
    var profondeurMax: Double?
    var typesDeNage: [TypeDeNage] = []
    var couleurPrincipale: Couleur
    var couleurSecondaire: Couleur?
    var persoPrincipale: CouleurPerso?
    var persoSecondaire: CouleurPerso?
    var finition: Finition?
    var notes: String?

    var estTraine: Bool { typePeche == .traine || typesPecheCompatibles.contains(.traine) }
}

// MARK: - Règles de déduction (zones, espèces, postes)

enum AmplitudeNage: String {
    case serree  = "serrée"
    case moyenne = "moyenne"
    case large   = "large"
}

enum ReglesDeduction {

    /// Version des règles. Un changement de version déclenche, au lancement
    /// suivant, un recalcul unique de toute la boîte (BoiteLeurresViewModel).
    /// 3 : zone tombant et thon à dents de chien (octobre 2026).
    static let versionDeductions = 3
    static let cleVersion = "versionDeductions"

    /// Espèces calculées gardées au plus (celles du texte libre s'ajoutent).
    static let maxEspecesCalculees = 6

    // MARK: Caractéristiques de la fiche

    static let typesDeSurface: Set<TypeLeurre> = [
        .leurreAJupe, .leurreDeTrainePoissonVolant, .squid, .popper, .stickbaitFlottant
    ]

    /// Profondeur maximale de nage, ou valeur par défaut selon le type.
    static func profondeurMax(_ f: FicheDeduction) -> Double {
        if let p = f.profondeurMax ?? f.profondeurMin { return p }
        switch f.typeLeurre {
        case .leurreAJupe, .leurreDeTrainePoissonVolant, .squid, .popper, .stickbaitFlottant: return 0.5
        case .poissonNageurPlongeant:                         return 4
        case .poissonNageurCoulant, .poissonNageurVibrant:    return 2
        case .cuiller:                                        return 1
        case .jigMetallique, .jigVibrant, .madai, .inchiku,
             .jigStickbait, .jigStickbaitCoulant:             return 30
        default:                                              return 1.5
        }
    }

    static func profondeurMin(_ f: FicheDeduction) -> Double {
        if let p = f.profondeurMin { return min(p, profondeurMax(f)) }
        return estDeSurface(f) ? 0 : profondeurMax(f) * 0.5
    }

    /// Jupe, poisson volant, Squid, popper, stickbait flottant,
    /// ou tout leurre qui ne nage pas sous 1 m.
    static func estDeSurface(_ f: FicheDeduction) -> Bool {
        typesDeSurface.contains(f.typeLeurre) || profondeurMax(f) <= 1
    }

    static func amplitude(_ f: FicheDeduction) -> AmplitudeNage? {
        let n = f.typesDeNage
        if n.contains(where: { [.wobblingLarge, .balayageLarge, .thumping].contains($0) }) { return .large }
        if n.contains(where: { [.wobblingSerré, .rectiligneStable, .vibration].contains($0) }) { return .serree }
        if n.contains(where: { [.wobbling, .wobblingRolling, .rolling].contains($0) }) { return .moyenne }
        switch f.typeLeurre {
        case .leurreAJupe, .squid, .cuiller: return .moyenne
        default: return nil
        }
    }

    // MARK: Zones

    static let ordreZones: [Zone] = [.lagon, .recif, .passe, .tombant, .large, .dcp, .profond]

    /// Traîne : la profondeur d'abord (un seul seuil), la taille décide du large.
    static func zonesTraine(_ f: FicheDeduction) -> [Zone] {
        let p = profondeurMax(f)
        let l = f.longueur
        var z = Set<Zone>()
        if p <= 8 && l <= 18 { z.insert(.lagon) }
        if p <= 8 && l <= 20 { z.insert(.recif) }
        if l >= 10 { z.insert(.passe) }
        if l >= 14 || (estDeSurface(f) && l >= 13) { z.formUnion([.large, .dcp]) }
        // Tombant (CPS 93 : à l'aplomb du tombant, lignes allongées et lestées
        // ou leurres plongeants) : plongeants de 3 m et plus, ou leurres de
        // surface de 13 cm et plus ; jamais sous 10 cm.
        if l >= 10 && ((!estDeSurface(f) && p >= 3) || (estDeSurface(f) && l >= 13)) { z.insert(.tombant) }
        if z.isEmpty { z = [.lagon, .passe] }
        return ordreZones.filter { z.contains($0) }
    }

    /// Autres techniques (lancer, jig…) : règle par type, inchangée sur le fond.
    static func zonesHorsTraine(_ f: FicheDeduction) -> [Zone] {
        let p = profondeurMax(f)
        let l = f.longueur
        var z = Set<Zone>()
        if p <= 3 { z.formUnion([.lagon, .recif]); if l >= 12 { z.insert(.passe) } }
        if p > 3 && p <= 8 { z.insert(.passe); if l >= 12 { z.insert(.large) }; if l >= 15 { z.insert(.recif) } }
        if p > 8 { z.formUnion([.large, .profond]); if l >= 15 { z.insert(.dcp) } }
        switch f.typeLeurre {
        case .popper, .stickbaitFlottant:       z = [.lagon, .recif, .passe]
        case .jigMetallique, .jigVibrant:       z = [.profond, .recif, .dcp, .tombant]
        case .cuiller where l < 10:             z = [.lagon, .recif, .passe]
        default: break
        }
        if z.isEmpty { z = [.lagon, .passe] }
        return ordreZones.filter { z.contains($0) }
    }

    // MARK: Espèces : profil de traîne

    struct ProfilTraine {
        let espece: Espece
        let longueurMin: Double
        let longueurMax: Double?
        /// Le leurre doit pouvoir nager à cette profondeur ou moins (profondeur min ≤ valeur).
        let nageJusqua: Double?
        let zones: [Zone]
        let nagePreferee: AmplitudeNage?
        /// Le leurre doit atteindre au moins cette profondeur, jamais de surface
        /// (loche 3 m, thon à dents de chien 4 m).
        let atteintAuMoins: Double?
        /// Voilier et marlin : leurre de surface obligatoire.
        let surfaceObligatoire: Bool
    }

    /// Fourchettes d'expertise (onglet « Règles de déduction »), à régler
    /// avec la pratique. L'ordre départage les égalités.
    static let profilsTraine: [ProfilTraine] = [
        ProfilTraine(espece: .thazard,          longueurMin: 10, longueurMax: 20, nageJusqua: 6, zones: [.passe, .lagon, .large, .tombant],     nagePreferee: .serree, atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .thazardBatard,    longueurMin: 12, longueurMax: 20, nageJusqua: 6, zones: [.large, .passe, .tombant],             nagePreferee: .serree, atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .bonite,           longueurMin: 6,  longueurMax: 14, nageJusqua: 4, zones: [.passe, .large, .dcp, .tombant],       nagePreferee: .serree, atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .wahoo,            longueurMin: 14, longueurMax: 25, nageJusqua: 9, zones: [.passe, .large, .dcp, .tombant],       nagePreferee: .serree, atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .thonJaune,        longueurMin: 12, longueurMax: 25, nageJusqua: 9, zones: [.large, .dcp, .tombant],               nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .mahiMahi,         longueurMin: 12, longueurMax: 25, nageJusqua: 3, zones: [.large, .dcp, .passe],                 nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .carangueGT,       longueurMin: 12, longueurMax: 22, nageJusqua: 4, zones: [.passe, .recif, .tombant],             nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .thonDentsDeChien, longueurMin: 14, longueurMax: 25, nageJusqua: nil, zones: [.tombant, .passe],                   nagePreferee: nil,     atteintAuMoins: 4,   surfaceObligatoire: false),
        ProfilTraine(espece: .carangueBleue,    longueurMin: 7,  longueurMax: 14, nageJusqua: 5, zones: [.lagon, .recif, .passe, .tombant],     nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .barracuda,        longueurMin: 12, longueurMax: 20, nageJusqua: 6, zones: [.lagon, .recif, .passe, .tombant],     nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .becune,           longueurMin: 8,  longueurMax: 14, nageJusqua: 4, zones: [.lagon, .recif],                       nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .loche,            longueurMin: 10, longueurMax: 18, nageJusqua: nil, zones: [.lagon, .recif],                     nagePreferee: .large,  atteintAuMoins: 3,   surfaceObligatoire: false),
        ProfilTraine(espece: .coureurArcEnCiel, longueurMin: 12, longueurMax: 20, nageJusqua: 6, zones: [.large, .passe, .tombant],             nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .thonObese,        longueurMin: 18, longueurMax: nil, nageJusqua: nil, zones: [.large, .dcp],                      nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: false),
        ProfilTraine(espece: .voilier,          longueurMin: 18, longueurMax: nil, nageJusqua: 3, zones: [.large, .dcp],                        nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: true),
        ProfilTraine(espece: .marlin,           longueurMin: 20, longueurMax: nil, nageJusqua: 3, zones: [.large, .dcp],                        nagePreferee: nil,     atteintAuMoins: nil, surfaceObligatoire: true)
    ]

    /// Note de pertinence d'une espèce pour un leurre, ou nil si une
    /// condition éliminatoire n'est pas remplie.
    static func pertinence(_ pr: ProfilTraine, fiche f: FicheDeduction, zones: [Zone], tailleStricte: Bool = true) -> Double? {
        let communes = pr.zones.filter { zones.contains($0) }.count
        guard communes > 0 else { return nil }

        let l = f.longueur
        if tailleStricte {
            guard l >= pr.longueurMin else { return nil }
            if let m = pr.longueurMax { guard l <= m else { return nil } }
        }

        let surface = estDeSurface(f)
        if let jusqua = pr.nageJusqua { guard profondeurMin(f) <= jusqua else { return nil } }
        if let mini = pr.atteintAuMoins { guard !surface, profondeurMax(f) >= mini else { return nil } }
        if pr.surfaceObligatoire { guard surface else { return nil } }

        var note = 2.0 * Double(communes)
        if let n = pr.nagePreferee, amplitude(f) == n { note += 1.5 }
        let haut = pr.longueurMax ?? (pr.longueurMin + 10)
        let centre = (pr.longueurMin + haut) / 2
        let demi = max(1, (haut - pr.longueurMin) / 2)
        note += max(0, 1 - abs(l - centre) / demi)
        return note
    }

    /// Espèces de traîne calculées, classées par pertinence (six au plus).
    static func especesTraine(_ f: FicheDeduction, zones: [Zone]) -> [String] {
        func classer(stricte: Bool) -> [String] {
            profilsTraine.enumerated()
                .compactMap { (i, pr) -> (Double, Int, String)? in
                    guard let n = pertinence(pr, fiche: f, zones: zones, tailleStricte: stricte) else { return nil }
                    return (n, i, pr.espece.displayName)
                }
                .sorted { $0.0 != $1.0 ? $0.0 > $1.0 : $0.1 < $1.1 }
                .map { $0.2 }
        }
        let liste = classer(stricte: true)
        if !liste.isEmpty { return Array(liste.prefix(maxEspecesCalculees)) }
        // Aucun profil ne convient à cette taille : les trois plus proches.
        return Array(classer(stricte: false).prefix(3))
    }

    /// Autres techniques : taille, profondeur et type (sans la couleur).
    static func especesHorsTraine(_ f: FicheDeduction) -> [Espece] {
        let l = f.longueur
        let p = profondeurMax(f)
        var e: [Espece] = []
        func ajouter(_ liste: [Espece]) { for x in liste where !e.contains(x) { e.append(x) } }
        switch f.typeLeurre {
        case .popper, .stickbait, .stickbaitFlottant, .stickbaitCoulant:
            ajouter([.carangueGT, .thazard, .barracuda, .bonite])
        case .jigMetallique, .jigVibrant, .madai, .inchiku, .jigStickbait, .jigStickbaitCoulant:
            ajouter([.loche, .lochePintade, .seriole, .carangue, .merou, .vivaneauRouge, .thonJaune])
        case .cuiller:
            ajouter([.thazard, .bonite, .carangue, .barracuda])
        default:
            if l < 12 && p <= 3 { ajouter([.thazard, .bonite, .barracuda, .carangue]) }
            if l >= 12 && l <= 18 { ajouter([.carangueGT, .thazard, .bonite]) }
            if l > 15 && p > 8 { ajouter([.wahoo, .thonJaune, .mahiMahi]) }
        }
        return Array(e.prefix(maxEspecesCalculees))
    }

    // MARK: Postes de traîne

    static let ordrePostes: [PositionSpread] = [.shortCorner, .longCorner, .shortRigger, .longRigger, .shotgun]

    /// Postes physiquement possibles, le poste conseillé par la famille en tête.
    /// - surface ou ≤ 2 m : tous les postes ;
    /// - plongeant de 2 à 5 m : short corner, long corner, centre (pas de tangon) ;
    /// - au-delà de 5 m : long corner ou centre.
    static func postesTraine(_ f: FicheDeduction, famille: Contraste) -> [PositionSpread] {
        let p = profondeurMax(f)
        let surface = estDeSurface(f) || p <= 2

        let possibles: [PositionSpread]
        let conseilles: [PositionSpread]
        if surface {
            possibles = ordrePostes
            switch famille {
            case .naturel:   conseilles = [.shortCorner]
            case .sombre:    conseilles = [.longCorner]
            case .contraste: conseilles = [.shotgun]
            case .flashy:    conseilles = [.shortRigger, .longRigger]
            }
        } else if p <= 5 {
            possibles = [.shortCorner, .longCorner, .shotgun]
            switch famille {
            case .naturel, .flashy: conseilles = [.shortCorner]
            case .sombre:           conseilles = [.longCorner]
            case .contraste:        conseilles = [.shotgun]
            }
        } else {
            possibles = [.longCorner, .shotgun]
            switch famille {
            case .naturel, .sombre:   conseilles = [.longCorner]
            case .contraste, .flashy: conseilles = [.shotgun]
            }
        }
        var postes = conseilles
        // Un grand leurre de surface (≥ 18 cm) se défend aussi au short corner.
        if surface && f.longueur >= 18 && !postes.contains(.shortCorner) { postes.append(.shortCorner) }
        for x in possibles where !postes.contains(x) { postes.append(x) }
        return postes
    }

    // MARK: Synthèse

    struct Resultat {
        var zones: [Zone]
        var especes: [String]
        /// nil hors traîne.
        var postes: [PositionSpread]?
        var reperes: LignesReperes
    }

    /// Champs déduits d'une fiche, lignes repères comprises :
    /// - « Espèces : » remplace la liste calculée ;
    /// - « Zones : » remplace les zones, et les espèces sont alors déduites
    ///   de ces zones (sauf ligne « Espèces : ») ;
    /// - « Postes : » remplace les postes ;
    /// - le texte libre complète toujours la liste des espèces.
    static func deduire(_ f: FicheDeduction, famille: Contraste) -> Resultat {
        let reperes = NoteAnalysisService.lireLignesReperes(dans: f.notes)

        let zones = reperes.zones ?? (f.estTraine ? zonesTraine(f) : zonesHorsTraine(f))

        var especes: [String]
        if let e = reperes.especes {
            especes = e
        } else if f.estTraine {
            especes = especesTraine(f, zones: zones)
        } else {
            especes = especesHorsTraine(f).map { $0.displayName }
        }
        if let notes = f.notes, !notes.isEmpty {
            for e in NoteAnalysisService.detecterEspeces(dans: notes) where !especes.contains(e) {
                especes.append(e)
            }
        }

        var postes: [PositionSpread]? = nil
        if f.typePeche == .traine {
            postes = reperes.postes ?? postesTraine(f, famille: famille)
        }
        return Resultat(zones: zones, especes: especes, postes: postes, reperes: reperes)
    }
}

// MARK: - Couleur : profil du leurre et besoin de contraste du jour

/// Teinte dominante (ce qui se voit de près).
enum Teinte: String, CaseIterable {
    case bleuArgent      = "bleu-argent"
    case vert            = "vert"
    case chartreuseJaune = "chartreuse-jaune"
    case rose            = "rose"
    case orangeRouge     = "orange-rouge"
    case violetNoir      = "violet-noir"
    case blanc           = "blanc"
    case imitation       = "imitation"
}

/// Éclat (le flash), sur une seule échelle.
enum Eclat: String, CaseIterable {
    case translucide = "translucide"
    case argente     = "argenté ou holographique"
    case opaque      = "opaque ou mat"
    case paillete    = "pailleté"
    case fluoUV      = "fluo ou UV"
    case lumineux    = "phosphorescent"
}

/// Couleur du ventre, donnée par la ligne « Ventre : » des notes.
struct Ventre: Equatable {
    enum Ton: String { case chaud, clair, vif }
    var ton: Ton?
    var paillete: Bool
}

/// Besoin de contraste du jour (calculé à chaque sortie).
enum NiveauContraste: String, CaseIterable {
    case faible     = "faible"
    case moyen      = "moyen"
    case fort       = "fort"
    case silhouette = "silhouette"
    case nuitClaire = "nuit claire"

    /// - Faible : soleil haut, eau claire, mer calme.
    /// - Moyen : ciel voilé, eau légèrement trouble, clapot.
    /// - Fort : eau trouble, mer formée.
    /// - Silhouette : aube, crépuscule, temps très sombre, nuit noire.
    /// - Nuit claire : nuit de pleine lune.
    /// La marée descendante relève le niveau d'un cran (indice, pas certitude).
    static func depuis(luminosite: Luminosite, turbidite: Turbidite, etatMer: EtatMer,
                       moment: MomentJournee, lune: PhaseLunaire, maree: TypeMaree) -> NiveauContraste {
        if moment == .nuit || luminosite == .nuit {
            return lune == .pleineLune ? .nuitClaire : .silhouette
        }
        if moment == .aube || moment == .crepuscule || luminosite == .faible || luminosite == .sombre {
            return .silhouette
        }
        var cran: Int
        if turbidite == .trouble || turbidite == .tresTrouble || etatMer == .formee {
            cran = 2
        } else if luminosite == .diffuse || turbidite == .legerementTrouble || etatMer == .agitee {
            cran = 1
        } else {
            cran = 0
        }
        if maree == .descendante { cran = min(2, cran + 1) }
        return [.faible, .moyen, .fort][cran]
    }

    /// Famille(s) visée(s) pour une ligne seule.
    var familles: [Contraste] {
        switch self {
        case .faible:     return [.naturel]
        case .moyen:      return [.contraste]
        case .fort:       return [.flashy]
        case .silhouette: return [.flashy, .sombre]
        case .nuitClaire: return [.sombre]
        }
    }

    var eclats: [Eclat] {
        switch self {
        case .faible:     return [.translucide, .argente]
        case .moyen:      return [.opaque, .fluoUV, .paillete]
        case .fort:       return [.fluoUV, .paillete]
        case .silhouette: return [.opaque, .paillete]
        case .nuitClaire: return [.lumineux, .argente]
        }
    }

    /// Chrome et argenté ne valent qu'en soleil direct.
    var eclatsProscrits: [Eclat] {
        switch self {
        case .fort, .silhouette: return [.argente]
        default:                 return []
        }
    }

    /// Nages amples (wobbling large, thumping) favorisées.
    var nageAmple: Bool { self == .fort || self == .silhouette }

    var description: String {
        switch self {
        case .faible:     return "faible (soleil, eau claire, mer calme)"
        case .moyen:      return "moyen (ciel voilé, eau légèrement trouble ou clapot)"
        case .fort:       return "fort (eau trouble ou mer formée)"
        case .silhouette: return "silhouette (lumière basse)"
        case .nuitClaire: return "nuit claire (pleine lune)"
        }
    }
}

enum ReglesCouleur {

    // MARK: Famille (ce que le poisson voit à distance)

    /// Famille d'une couleur du catalogue. La finition n'intervient plus.
    static func famille(_ c: Couleur) -> Contraste {
        switch c {
        case .bleuArgente, .bleuBlanc, .vertArgente, .vertDore, .sardine, .maquereau,
             .argente, .argenteBleu, .blanc, .transparent, .bleu, .vert, .vertOlive,
             .blow, .beige, .bleuNoirGris, .vertBlanc:
            return .naturel
        case .roseFuchsia, .rose, .roseFluo, .chartreuse, .orange, .jaune, .jauneFluo,
             .roseHolographique, .jauneHolographique, .or, .rouge, .rougeJaune, .orangeJaune,
             .roseBlanc, .blancRouge, .blancOrange, .roseBleu:
            return .flashy
        case .noir, .noirViolet, .violetNoir, .noirBleu, .bleuNoir, .vertNoir, .violetFonce,
             .bleuFonce, .noirRouge, .violet, .brun, .marron:
            return .sombre
        }
    }

    /// Couleurs claires franches (blanc, beige) : face à un sombre, elles font contraste.
    static let clairesFranches: Set<Couleur> = [.blanc, .beige, .bleuBlanc, .vertBlanc, .roseBlanc, .blancRouge, .blancOrange]

    /// Famille depuis les couleurs du catalogue seules (aperçu du formulaire).
    static func famille(principale: Couleur, secondaire: Couleur?) -> Contraste {
        combiner(fp: famille(principale), clairP: clairesFranches.contains(principale),
                 fs: secondaire.map { famille($0) }, clairS: secondaire.map { clairesFranches.contains($0) } ?? false)
    }

    /// Contrasté seulement si les deux couleurs s'opposent franchement :
    /// sombre et vif, ou foncé et clair. L'argenté, l'or ou le bleu d'un
    /// flanc ne font pas d'un sombre un contrasté (c'est de l'éclat).
    private static func combiner(fp: Contraste, clairP: Bool, fs: Contraste?, clairS: Bool) -> Contraste {
        guard let fs else { return fp }
        if fp == .sombre && (fs == .flashy || clairS) { return .contraste }
        if fp == .flashy && fs == .sombre { return .contraste }
        if clairP && fs == .sombre { return .contraste }
        return fp
    }

    /// Famille d'un leurre (couleurs personnalisées comprises).
    static func famille(_ f: FicheDeduction) -> Contraste {
        let fp = f.persoPrincipale?.contraste ?? famille(f.couleurPrincipale)
        let clairP = f.persoPrincipale.map { $0.luminosite > 0.8 } ?? clairesFranches.contains(f.couleurPrincipale)
        let fs: Contraste? = f.persoSecondaire?.contraste ?? f.couleurSecondaire.map { famille($0) }
        let clairS = f.persoSecondaire.map { $0.luminosite > 0.8 }
            ?? f.couleurSecondaire.map { clairesFranches.contains($0) } ?? false
        return combiner(fp: fp, clairP: clairP, fs: fs, clairS: clairS)
    }

    /// Sous l'eau, le rouge disparaît vers 4 à 5 m, l'orange vers 6 m, le
    /// jaune vers 14 m : au-delà de 5 m de nage effective, une dominante
    /// rouge ou orange passe en sombre ; jaune et chartreuse au-delà de 12 m.
    static func familleCorrigee(_ f: FicheDeduction, profondeur p: Double) -> Contraste {
        let base = famille(f)
        guard base != .sombre else { return base }
        switch teinte(f) {
        case .orangeRouge where p > 5:      return .sombre
        case .chartreuseJaune where p > 12: return .sombre
        default:                            return base
        }
    }

    // MARK: Teinte

    static func teinte(_ c: Couleur) -> Teinte {
        switch c {
        case .bleuArgente, .bleuBlanc, .argente, .argenteBleu, .bleu, .blow, .bleuNoirGris: return .bleuArgent
        case .vertArgente, .vertDore, .vert, .vertOlive, .vertBlanc:                        return .vert
        case .chartreuse, .jaune, .jauneFluo, .jauneHolographique, .or:                      return .chartreuseJaune
        case .rose, .roseFuchsia, .roseFluo, .roseHolographique, .roseBlanc, .roseBleu:      return .rose
        case .orange, .rouge, .orangeJaune, .rougeJaune:                                     return .orangeRouge
        case .noir, .noirViolet, .violetNoir, .noirBleu, .bleuNoir, .vertNoir, .violetFonce,
             .bleuFonce, .noirRouge, .violet, .brun, .marron:                                return .violetNoir
        case .blanc, .beige, .transparent, .blancRouge, .blancOrange:                        return .blanc
        case .sardine, .maquereau:                                                           return .imitation
        }
    }

    /// Teinte d'une couleur personnalisée, d'après sa composition.
    static func teinte(_ c: FicheDeduction.CouleurPerso) -> Teinte {
        let mx = max(c.r, c.g, c.b), mn = min(c.r, c.g, c.b)
        if mx - mn < 0.12 {
            if c.luminosite > 0.75 { return .blanc }
            return c.luminosite < 0.25 ? .violetNoir : .bleuArgent
        }
        if mx < 0.3 { return .violetNoir }
        var h: Double
        if mx == c.r      { h = 60 * ((c.g - c.b) / (mx - mn)) }
        else if mx == c.g { h = 60 * ((c.b - c.r) / (mx - mn) + 2) }
        else              { h = 60 * ((c.r - c.g) / (mx - mn) + 4) }
        if h < 0 { h += 360 }
        switch h {
        case ..<40:   return .orangeRouge
        case ..<75:   return .chartreuseJaune
        case ..<165:  return .vert
        case ..<255:  return .bleuArgent
        case ..<300:  return .violetNoir
        case ..<345:  return .rose
        default:      return .orangeRouge
        }
    }

    static func teinte(_ f: FicheDeduction) -> Teinte {
        f.persoPrincipale.map { teinte($0) } ?? teinte(f.couleurPrincipale)
    }

    static func teinteSecondaire(_ f: FicheDeduction) -> Teinte? {
        if let p = f.persoSecondaire { return teinte(p) }
        return f.couleurSecondaire.map { teinte($0) }
    }

    // MARK: Ventre

    /// Ligne « Ventre : » des notes. Mots reconnus : rouge, orange, rose
    /// (chaud) ; blanc, argenté, nacré (clair) ; jaune, chartreuse (vif) ;
    /// pailleté, doré (éclat).
    static func ventre(_ f: FicheDeduction) -> Ventre? {
        guard let brut = NoteAnalysisService.lireLignesReperes(dans: f.notes).ventre else { return nil }
        let m = NoteAnalysisService.mots(brut)
        func cite(_ liste: [String]) -> Bool {
            m.contains { mot in liste.contains { mot.hasPrefix($0) } }
        }
        var ton: Ventre.Ton? = nil
        if cite(["rouge", "orange", "rose", "saumon", "corail"]) { ton = .chaud }
        else if cite(["jaune", "chartreuse"])                   { ton = .vif }
        else if cite(["blanc", "argent", "nacr", "perl"])       { ton = .clair }
        let paillete = cite(["paillet", "glitter"]) || m.contains { ["or", "dore", "doree", "dores"].contains($0) }
        return Ventre(ton: ton, paillete: paillete)
    }

    /// Ventre chaud (rouge, orange, rose) : ligne « Ventre : » d'abord,
    /// sinon les couleurs de la fiche.
    static func ventreChaud(_ f: FicheDeduction) -> Bool {
        if let v = ventre(f), let ton = v.ton { return ton == .chaud }
        let chaudes: [Teinte] = [.rose, .orangeRouge]
        if chaudes.contains(teinte(f)) { return true }
        if let s = teinteSecondaire(f), chaudes.contains(s) { return true }
        return false
    }

    // MARK: Éclat

    static func eclat(_ f: FicheDeduction) -> Eclat {
        if f.finition == .phosphorescent { return .lumineux }
        if f.persoPrincipale == nil && f.couleurPrincipale == .transparent { return .translucide }
        switch f.finition {
        case .holographique, .chrome, .miroir, .metallique: return .argente
        case .paillete:                                     return .paillete
        case .UV:                                           return .fluoUV
        case .mate, .brillante, .perlee:                    return .opaque
        case .phosphorescent:                               return .lumineux
        case nil:
            if f.persoPrincipale == nil {
                switch f.couleurPrincipale {
                case .argente, .argenteBleu, .bleuArgente, .sardine, .vertArgente,
                     .roseHolographique, .jauneHolographique, .or:
                    return .argente
                case .roseFluo, .jauneFluo, .chartreuse:
                    return .fluoUV
                default:
                    break
                }
            }
            return .opaque
        }
    }

    // MARK: Besoin du jour

    /// Proximité entre la famille visée et celle du leurre (0…1).
    static func similarite(cible: Contraste, leurre: Contraste) -> Double {
        if cible == leurre { return 1 }
        switch (cible, leurre) {
        case (.naturel, .contraste):   return 0.6
        case (.naturel, .flashy):      return 0.2
        case (.naturel, .sombre):      return 0.1
        case (.contraste, _):          return 0.6
        case (.flashy, .contraste):    return 0.6
        case (.flashy, .sombre):       return 0.3
        case (.flashy, .naturel):      return 0.1
        case (.sombre, .contraste):    return 0.6
        case (.sombre, .flashy):       return 0.3
        case (.sombre, .naturel):      return 0.0
        default:                       return 0.3
        }
    }

    /// Teintes conseillées selon la lumière et l'eau (documents du Projet).
    static func teintesConseillees(niveau: NiveauContraste, luminosite: Luminosite,
                                   turbidite: Turbidite, lagon: Bool) -> [Teinte] {
        var t: [Teinte]
        switch niveau {
        case .silhouette, .nuitClaire:
            t = [.violetNoir, .orangeRouge]             // noir/pourpre, noir/bleu, orange
        default:
            switch turbidite {
            case .trouble, .tresTrouble: t = [.violetNoir, .orangeRouge]          // noir, violet, rouge
            case .legerementTrouble:     t = [.chartreuseJaune, .rose, .violetNoir]
            case .claire:
                t = luminosite == .forte
                    ? [.bleuArgent, .imitation, .blanc]                            // bleu, argent, sardine, transparent
                    : [.bleuArgent, .blanc, .rose, .violetNoir]                    // bleu/blanc, rose/blanc, violet
            }
        }
        if lagon && turbidite != .trouble && turbidite != .tresTrouble {
            // Lagon : bleu/blanc, violet/noir, vert/jaune discret, argent/translucide.
            for x in [Teinte.bleuArgent, .violetNoir, .vert, .blanc] where !t.contains(x) { t.append(x) }
        }
        return t
    }
}

// MARK: - Anciennes déductions (vitesses, conditions)

class LeurreIntelligenceService {

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
