//
//  MoteurLagon.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Moteur de traîne du Clark (trois postes, sans tangons) pour toutes les
//  zones depuis octobre 2026 : lagon, platier et pâtés, passes, tombant
//  externe, large et DCP (lignes allongées de 4 m hors lagon et passe),
//  pensé pour le Clark 4,29 m sans tangons et une boîte de poissons nageurs.
//  Il remplace, pour ces zones, la logique héritée de la pêche au large.
//  Référence : audit « Moteur de suggestion — lagon » (octobre 2026).
//
//  Principes :
//  1. La vitesse ne sert qu'à valider la nage (plage constructeur ± 0,5 nd).
//  2. La profondeur réelle d'une bavette dépend de la longueur de ligne du
//     poste : profondeur catalogue × (1 − e^(−L/12)). Hypothèse à étalonner
//     au sondeur ; elle est signalée comme estimation.
//  3. Couleur (modèle validé le 4 octobre 2026) : profil du leurre (famille
//     corrigée par la profondeur effective, teinte jugée au ventre près de
//     la surface, éclat) face au besoin de contraste du jour (faible, moyen,
//     fort, silhouette, nuit claire). La marée descendante relève le niveau
//     d'un cran ; la lune ne compte que de nuit. La couleur départage, elle
//     n'élimine jamais : 25 points = famille 15, teinte 7, éclat 3.
//  4. Postes du Clark : short corner 16 m, long corner 23 m, centre 30 m,
//     latéraux 20 et 22 m. Short corner = signal (ventre chaud dans le
//     bouillon) ; lignes longues discrètes en eau claire, contrastées en
//     eau trouble.
//  5. Étages distincts (1,5 m d'écart), le plus profond sur la ligne la plus
//     longue, au moins deux amplitudes de nage dès trois lignes.
//  6. Le moteur propose la vitesse commune qui fait le mieux pêcher le spread.
//
//  Score sur 100 : profondeur 25, couleur 25, taille 20, nage 15, espèce 15.
//

import Foundation

// MARK: - Espace de noms

enum Lagon {

    // MARK: Postes du Clark en lagon

    enum Poste: Int, CaseIterable {
        case shortCorner = 1
        case longCorner
        case centre
        case lateralTribord
        case lateralBabord

        var nom: String {
            switch self {
            case .shortCorner:    return "Short corner"
            case .longCorner:     return "Long corner"
            case .centre:         return "Centre"
            case .lateralTribord: return "Latéral tribord"
            case .lateralBabord:  return "Latéral bâbord"
            }
        }

        var support: String {
            switch self {
            case .shortCorner:    return "porte-canne de tableau tribord"
            case .longCorner:     return "porte-canne de tableau bâbord"
            case .centre:         return "porte-canne de console, canne haute"
            case .lateralTribord: return "porte-canne de bordé tribord, incliné vers l'extérieur"
            case .lateralBabord:  return "porte-canne de bordé bâbord, incliné vers l'extérieur"
            }
        }

        /// Longueur de ligne de base, en mètres.
        var longueurLigne: Double {
            switch self {
            case .shortCorner:    return 16
            case .longCorner:     return 23
            case .centre:         return 30
            case .lateralTribord: return 20
            case .lateralBabord:  return 22
            }
        }

        var role: String {
            switch self {
            case .shortCorner:    return "le plus haut et le plus contrasté : attaque réflexe au bord du bouillon"
            case .longCorner:     return "leurre crédible dans le couloir d'eau claire"
            case .centre:         return "le plus profond, naturel discret, pour les poissons méfiants"
            case .lateralTribord: return "signal visuel ou vibratoire différent des corners"
            case .lateralBabord:  return "signal différent des autres lignes"
            }
        }

        /// Correspondance avec les postes connus de l'interface.
        var positionSpread: PositionSpread {
            switch self {
            case .shortCorner:    return .shortCorner
            case .longCorner:     return .longCorner
            case .centre:         return .shotgun
            case .lateralTribord: return .shortRigger
            case .lateralBabord:  return .longRigger
            }
        }

        static func postes(pour nombreLignes: Int) -> [Poste] {
            Array(allCases.prefix(max(1, min(Lagon.postesInstalles, nombreLignes))))
        }
    }

    /// Postes réellement équipés sur le Clark : deux corners et le centre.
    /// Les latéraux restent décrits ci-dessus pour un équipement futur.
    static let postesInstalles = 3

    // MARK: Variables dérivées

    enum Amplitude: String {
        case serree  = "serrée"
        case moyenne = "moyenne"
        case large   = "large"
    }

    enum Lumiere: String { case forte = "forte", diffuse = "diffuse", faible = "faible" }
    enum Eau: String { case claire = "claire", teintee = "teintée", trouble = "trouble" }

    static func lumiere(_ l: Luminosite) -> Lumiere {
        switch l {
        case .forte:                  return .forte
        case .diffuse:                return .diffuse
        case .faible, .sombre, .nuit: return .faible
        }
    }

    static func eau(_ t: Turbidite) -> Eau {
        switch t {
        case .claire:             return .claire
        case .legerementTrouble:  return .teintee
        case .trouble, .tresTrouble: return .trouble
        }
    }

    // MARK: Couleur par poste (modèle validé le 4 octobre 2026)

    /// Ce que vise un poste du Clark pour le niveau de contraste du jour.
    struct CibleCouleur {
        /// Familles acceptées, la première est la famille visée.
        let familles: [Contraste]
        /// Short corner : ventre chaud (rouge, orange, rose) dans le bouillon.
        let ventreChaud: Bool
        /// nil : teintes conseillées du jour.
        let teintes: [Teinte]?
        let eclats: [Eclat]
        let eclatsProscrits: [Eclat]
        let consigne: String
    }

    /// Répartition sur le Clark (3 postes). Le short corner nage dans le
    /// bouillon : c'est le poste du signal. Les lignes longues restent
    /// discrètes en eau claire et prennent du contraste en eau trouble.
    static func cible(poste: Poste?, niveau: NiveauContraste, nombreLignes: Int) -> CibleCouleur {
        func c(_ f: [Contraste], ventre: Bool = false, teintes: [Teinte]? = nil,
               _ e: [Eclat], proscrits: [Eclat] = [], _ texte: String) -> CibleCouleur {
            CibleCouleur(familles: f, ventreChaud: ventre, teintes: teintes,
                         eclats: e, eclatsProscrits: proscrits, consigne: texte)
        }
        guard let poste else {
            return c(niveau.familles, niveau.eclats, proscrits: niveau.eclatsProscrits,
                     "famille \(niveau.familles.map(nomCouleur).joined(separator: " ou "))")
        }
        // Une seule ligne : la famille visée par le niveau.
        if nombreLignes == 1 && poste == .shortCorner && niveau == .moyen {
            return c([.contraste], ventre: true, [.opaque, .fluoUV, .paillete], "contrasté, ventre chaud, opaque ou UV")
        }
        switch (niveau, poste) {
        case (.faible, .shortCorner):
            return c([.naturel], ventre: true, [.argente, .translucide], "flancs naturels, ventre chaud (rouge, orange ou rose)")
        case (.faible, .longCorner):
            return c([.naturel], [.argente], "naturel, éclat argenté")
        case (.faible, .centre):
            return c([.naturel], [.translucide, .argente], "naturel ; translucide si les touches sont rares en pleine lumière")

        case (.moyen, .shortCorner):
            return c([.flashy], ventre: true, [.opaque, .fluoUV, .paillete], "vif, ventre chaud")
        case (.moyen, .longCorner):
            return c([.contraste, .sombre], [.opaque], "contrasté ou sombre, opaque")
        case (.moyen, .centre):
            return c([.naturel], [.opaque, .paillete], "naturel, opaque ou pailleté")

        case (.fort, .shortCorner):
            return c([.flashy], [.fluoUV], proscrits: [.argente], "vif fluo, nage ample")
        case (.fort, .longCorner):
            return c([.sombre], [.opaque], proscrits: [.argente], "sombre, nage ample")
        case (.fort, .centre):
            return c([.contraste], [.paillete], proscrits: [.argente], "contrasté, pailleté")

        case (.silhouette, .shortCorner):
            return c([.flashy], teintes: [.rose], [.paillete], proscrits: [.argente], "rose à ventre pailleté argent")
        case (.silhouette, .longCorner):
            return c([.sombre], [.opaque], proscrits: [.argente], "sombre (silhouette)")
        case (.silhouette, .centre):
            return c([.naturel, .sombre], [.opaque], proscrits: [.argente], "naturel ou sombre")

        case (.nuitClaire, .shortCorner):
            return c([.sombre], [.lumineux, .argente], "sombre, phosphorescent ou réfléchissant")
        case (.nuitClaire, .longCorner):
            return c([.sombre], [.lumineux], "sombre, phosphorescent")
        case (.nuitClaire, .centre):
            return c([.contraste, .sombre], [.lumineux, .argente], "contrasté ou sombre, réfléchissant")

        case (_, .lateralTribord), (_, .lateralBabord):
            return niveau == .faible
                ? c([.contraste], [.argente, .opaque], "contrasté, signal différent des corners")
                : c([.flashy], niveau.eclats, proscrits: niveau.eclatsProscrits, "vif, signal différent des corners")
        }
    }

    /// Proximité entre la famille visée et celle du leurre (0…1).
    static func similarite(cible: Contraste, leurre: Contraste) -> Double {
        ReglesCouleur.similarite(cible: cible, leurre: leurre)
    }

    static func nomCouleur(_ c: Contraste) -> String {
        switch c {
        case .naturel:   return "naturel"
        case .contraste: return "contrasté"
        case .flashy:    return "vif"
        case .sombre:    return "sombre"
        }
    }

    // MARK: Presets par espèce

    struct Preset {
        let nom: String
        let vitesseMin: Double
        let vitesseMax: Double
        let vitesseCible: Double
        /// nil : toute la colonne d'eau sous le plafond.
        let bandeProfondeur: (min: Double, max: Double)?
        let taille: (min: Double, max: Double)
        let nage: Amplitude?
        let basDeLigne: String
        let alerteCiguatera: String?
        let modeConseille: Int
        let margeFond: Double?
        let horsLagon: Espece?
    }

    static func preset(pour c: ConditionsPeche) -> Preset {
        let tombant = c.zone == .tombant
        let large = c.zone == .large || c.zone == .dcp || c.zone == .profond
        let tailleMixte: (Double, Double)
        if large {
            // Proies du large : bonites, maquereaux, poissons volants (« Critères » : 15–22 cm).
            tailleMixte = (14, 22)
        } else if tombant {
            // Proies du tombant plus grosses (CPS 93 ; « Critères de choix » : 14–20 cm hors lagon).
            tailleMixte = (14, 20)
        } else if c.zone == .passe {
            tailleMixte = (12, 18)
        } else if c.etatMer == .calme && c.turbiditeEau == .claire && c.luminosite == .forte {
            tailleMixte = (8, 12)
        } else {
            tailleMixte = (10, 15)
        }

        let mixte: Preset
        if large {
            mixte = Preset(
                nom: "mixte large", vitesseMin: 6.0, vitesseMax: 7.5, vitesseCible: 6.75,
                bandeProfondeur: nil, taille: tailleMixte, nage: nil,
                basDeLigne: "câble ou acier 60 à 90 lb (wahoo) ; fluorocarbone 100 à 130 lb (thons, mahi-mahi)",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        } else if tombant {
            mixte = Preset(
                nom: "mixte tombant", vitesseMin: 5.0, vitesseMax: 7.0, vitesseCible: 6.0,
                bandeProfondeur: nil, taille: tailleMixte, nage: nil,
                basDeLigne: "acier ou câble 60 à 90 lb (wahoo, thazards) ; fluorocarbone 100 lb sinon",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        } else {
            mixte = Preset(
                nom: "mixte lagon", vitesseMin: 4.5, vitesseMax: 6.5, vitesseCible: 5.5,
                bandeProfondeur: nil, taille: tailleMixte, nage: nil,
                basDeLigne: "fluorocarbone 60 à 80 lb ; acier si les thazards sont là",
                alerteCiguatera: nil, modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        }

        func horsZone(_ e: Espece) -> Preset {
            Preset(
                nom: mixte.nom, vitesseMin: mixte.vitesseMin, vitesseMax: mixte.vitesseMax,
                vitesseCible: mixte.vitesseCible, bandeProfondeur: nil, taille: mixte.taille,
                nage: nil, basDeLigne: mixte.basDeLigne, alerteCiguatera: nil,
                modeConseille: mixte.modeConseille, margeFond: nil, horsLagon: e
            )
        }

        guard let espece = c.especePrioritaire else { return mixte }
        let horsLagonExterieur = tombant || large
        let exterieur = horsLagonExterieur || c.zone == .passe

        switch espece {
        case .thazard, .thazardBatard:
            // Sur le tombant et au large, thazards plus gros que dans le lagon (CPS 93).
            return Preset(
                nom: "thazard", vitesseMin: 6.0, vitesseMax: horsLagonExterieur ? 7.0 : 6.5,
                vitesseCible: horsLagonExterieur ? 6.5 : 6.25,
                bandeProfondeur: horsLagonExterieur ? (1, 8) : (1, 5),
                taille: horsLagonExterieur ? (14, 20) : (12, 18),
                nage: .serree,
                basDeLigne: "acier 30 à 60 lb sur toutes les lignes",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .carangue, .carangueBleue, .carangueGT:
            // Au large, seule la GT a sa place (zones typiques).
            if large && espece != .carangueGT { return horsZone(espece) }
            // Tombant : traîne en zigzag ou en huit le long de la paroi, 5 à 7 nœuds (« Consignes »).
            return Preset(
                nom: espece == .carangueGT ? "carangue GT" : "carangue",
                vitesseMin: horsLagonExterieur ? 5.0 : 4.5, vitesseMax: horsLagonExterieur ? 7.0 : 5.5,
                vitesseCible: horsLagonExterieur ? 6.0 : 5.0,
                bandeProfondeur: horsLagonExterieur ? (0, 6) : (0, 3),
                taille: horsLagonExterieur ? (12, 18) : (10, 15),
                nage: nil,
                basDeLigne: "fluorocarbone épais (80 à 130 lb)",
                alerteCiguatera: espece == .carangueGT
                    ? "Carangue GT : risque de ciguatera très élevé ; pêche no-kill conseillée."
                    : nil,
                modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        case .loche, .lochePintade:
            // Sur le tombant et au large, la loche se pêche au jig, pas à la traîne.
            if horsLagonExterieur { return horsZone(espece) }
            return Preset(
                nom: "loche", vitesseMin: 4.25, vitesseMax: 5.25, vitesseCible: 4.75,
                bandeProfondeur: nil, taille: (10, 15), nage: nil,
                basDeLigne: "fluorocarbone 60 à 80 lb",
                alerteCiguatera: nil, modeConseille: 1, margeFond: 1.5, horsLagon: nil
            )
        case .bonite, .coureurArcEnCiel:
            return Preset(
                nom: "bonite", vitesseMin: 5.5, vitesseMax: large ? 7.5 : 6.5, vitesseCible: large ? 6.75 : 6.0,
                bandeProfondeur: (0, 2), taille: large ? (10, 14) : (8, 12), nage: .serree,
                basDeLigne: "nylon 40 à 60 lb",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .barracuda, .becune:
            if horsLagonExterieur && espece == .becune { return horsZone(espece) }
            return Preset(
                nom: espece == .becune ? "bécune" : "barracuda",
                vitesseMin: 4.5, vitesseMax: 6.5, vitesseCible: 5.5,
                bandeProfondeur: horsLagonExterieur ? (1, 6) : (1, 3), taille: (12, 18), nage: nil,
                basDeLigne: "acier 30 à 60 lb",
                alerteCiguatera: "Barracuda et grosses bécunes : ciguatera fréquente au-delà de 3 à 5 kg.",
                modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        case .wahoo where exterieur:
            // Plongeants 6–12 m pour le wahoo (« Critères de choix ») ; le Clark plafonne vers 7,5 nœuds.
            return Preset(
                nom: "wahoo", vitesseMin: 6.0, vitesseMax: 7.5, vitesseCible: 7.0,
                bandeProfondeur: (3, 12), taille: (14, 20), nage: nil,
                basDeLigne: "câble ou acier 60 à 90 lb obligatoire (dents)",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .thonJaune where exterieur, .thonObese where exterieur:
            // Thons en subsurface ou en profondeur près du tombant, avant l'aube et après le coucher (CPS 93).
            return Preset(
                nom: "thon", vitesseMin: 5.5, vitesseMax: large ? 7.5 : 7.0, vitesseCible: large ? 6.75 : 6.25,
                bandeProfondeur: (3, 12), taille: large ? (15, 22) : (14, 20), nage: nil,
                basDeLigne: "fluorocarbone 80 à 130 lb",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .thonDentsDeChien:
            // Ne s'aventure pas en pleine mer (CPS 93) : passes et tombant seulement.
            if large { return horsZone(espece) }
            return Preset(
                nom: "thon dents de chien", vitesseMin: 5.0, vitesseMax: 6.5, vitesseCible: 5.75,
                bandeProfondeur: (4, 12), taille: (14, 22), nage: nil,
                basDeLigne: "fluorocarbone 100 à 150 lb (dents et rochers)",
                alerteCiguatera: nil, modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        case .mahiMahi where large || c.zone == .passe:
            // Large et DCP, souvent les premiers à mordre sous les DCP ; attaque de côté (CPS 93).
            return Preset(
                nom: "mahi-mahi", vitesseMin: 6.5, vitesseMax: 7.5, vitesseCible: 7.0,
                bandeProfondeur: (0, 3), taille: (15, 25), nage: nil,
                basDeLigne: "fluorocarbone 80 à 100 lb",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .marlin where large, .voilier where large:
            // Grands leurres de surface (25 cm et plus, « Consignes ») ; le Clark plafonne vers 7,5 nœuds.
            return Preset(
                nom: "rostres", vitesseMin: 6.5, vitesseMax: 7.5, vitesseCible: 7.25,
                bandeProfondeur: (0, 1), taille: (20, 30), nage: nil,
                basDeLigne: "fluorocarbone 200 à 300 lb",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        default:
            return horsZone(espece)
        }
    }

    /// Espèces de fond : sur le tombant et au large, jig ou ligne profonde, jamais la traîne.
    static let especesDeFond: Set<Espece> = [
        .loche, .lochePintade, .merou, .seriole, .empereur,
        .vivaneauRouge, .vivaneauChienRouge, .vivaneauQueueNoire, .becDeCane
    ]

    // MARK: Journal : bonus appris

    /// Prise du journal, réduite à ce qui sert au bonus.
    struct PriseResumee {
        let zone: Zone?
        let niveau: NiveauContraste?
        /// rawValue de l'énumération Espece.
        let espece: String
    }

    /// Secteurs comparables pour le journal : lagon et récif ensemble,
    /// large, DCP et profond ensemble.
    static func memeSecteur(_ a: Zone, _ b: Zone) -> Bool {
        func secteur(_ z: Zone) -> Int {
            switch z {
            case .lagon, .recif:          return 0
            case .passe:                  return 1
            case .tombant:                return 2
            case .large, .dcp, .profond:  return 3
            }
        }
        return secteur(a) == secteur(b)
    }

    /// Bonus appris du journal, de 0 à 15 points, jamais négatif : un leurre
    /// sans prise garde 0. Chaque prise compte de 0,4 à 1 selon la ressemblance
    /// avec la sortie (même secteur +0,3, même contraste du jour +0,3), moitié
    /// moins si l'espèce prise n'est pas l'espèce visée ; 5 points par prise
    /// équivalente, plafonnés à 15.
    static func bonusJournal(_ l: Leurre, ctx: Contexte) -> (points: Double, prises: Int) {
        guard let prises = ctx.historique[l.id], !prises.isEmpty else { return (0, 0) }
        var somme = 0.0
        for p in prises {
            var s = 0.4
            if let z = p.zone, memeSecteur(z, ctx.conditions.zone) { s += 0.3 }
            if let n = p.niveau, n == ctx.niveau { s += 0.3 }
            if let e = ctx.conditions.especePrioritaire, p.espece != e.rawValue { s *= 0.5 }
            somme += s
        }
        return (min(15, 5 * somme), prises.count)
    }

    // MARK: Contexte de calcul

    struct Contexte {
        let conditions: ConditionsPeche
        let preset: Preset
        let lumiere: Lumiere
        let eau: Eau
        let niveau: NiveauContraste
        let teintesDuJour: [Teinte]
        let nageCible: Amplitude
        let marge: Double
        let plafond: Double
        let ajustementDistance: Double
        let allongementArriere: Double
        /// Tombant externe : lignes allongées (CPS 93).
        let tombant: Bool
        /// Large, DCP et profond : lignes allongées (CPS 2025 : 30 à 50 m en eaux côtières).
        let large: Bool
        /// Zones que doit porter un leurre (nil : pas de filtre, lagon et passe).
        let zonesCibles: Set<Zone>?
        /// Prises du journal par numéro de leurre (bonus appris).
        let historique: [Int: [PriseResumee]]

        init(_ c: ConditionsPeche, historique: [Int: [PriseResumee]] = [:]) {
            conditions = c
            tombant = c.zone == .tombant
            large = c.zone == .large || c.zone == .dcp || c.zone == .profond
            zonesCibles = tombant ? [.tombant] : (large ? [.large, .dcp] : nil)
            self.historique = historique
            preset = Lagon.preset(pour: c)
            lumiere = Lagon.lumiere(c.luminosite)
            eau = Lagon.eau(c.turbiditeEau)
            niveau = NiveauContraste.depuis(
                luminosite: c.luminosite, turbidite: c.turbiditeEau, etatMer: c.etatMer,
                moment: c.momentJournee, lune: c.phaseLunaire, maree: c.typeMaree
            )
            teintesDuJour = ReglesCouleur.teintesConseillees(
                niveau: niveau, luminosite: c.luminosite, turbidite: c.turbiditeEau, lagon: true
            )

            // Niveaux fort et silhouette : nages amples (le leurre doit déplacer de l'eau).
            if niveau.nageAmple {
                nageCible = .large
            } else if niveau == .faible && (c.etatMer == .calme || c.etatMer == .peuAgitee) {
                nageCible = .serree
            } else {
                nageCible = .moyenne
            }

            marge = preset.margeFond ?? (c.zone == .passe ? 3 : 5)
            plafond = max(1.0, c.profondeurZone - marge)
            ajustementDistance = (c.etatMer == .agitee || c.etatMer == .formee) ? -3 : 0
            allongementArriere = (eau == .claire && lumiere == .forte) ? 3 : 0
        }

        /// Nage visée : celle de l'espèce l'emporte, sauf en eau trouble.
        var nageVisee: Amplitude {
            if let n = preset.nage, eau != .trouble { return n }
            return nageCible
        }

        /// Tranche de profondeur visée pour l'espèce.
        var bande: (min: Double, max: Double) {
            if let b = preset.bandeProfondeur { return (b.min, min(b.max, plafond)) }
            if preset.margeFond != nil { return (max(0, plafond - 3), plafond) }   // loche
            return (0, plafond)
        }

        func longueurLigne(_ poste: Poste) -> Double {
            var l = poste.longueurLigne + ajustementDistance
            if poste == .longCorner || poste == .centre { l += allongementArriere }
            if tombant || large { l += 4 }
            // 35 m au plus : limite du schéma du Clark.
            return min(35, max(12, l))
        }
    }

    // MARK: Caractéristiques des leurres

    static let typesTraine: Set<TypeLeurre> = [
        .poissonNageur, .poissonNageurPlongeant, .poissonNageurCoulant, .poissonNageurVibrant,
        .leurreAJupe, .cuiller, .leurreDeTrainePoissonVolant, .squid
    ]

    static func estLeurreDeTraine(_ l: Leurre) -> Bool {
        typesTraine.contains(l.typeLeurre) && l.estCompatibleAvec(technique: .traine)
    }

    static func estJupe(_ l: Leurre) -> Bool {
        l.typeLeurre == .leurreAJupe || l.typeLeurre == .squid
    }

    static func amplitude(_ l: Leurre) -> Amplitude? {
        let nages = l.typesDeNage ?? []
        if nages.contains(where: { [.wobblingLarge, .balayageLarge, .thumping].contains($0) }) { return .large }
        if nages.contains(where: { [.wobblingSerré, .rectiligneStable, .vibration].contains($0) }) { return .serree }
        if nages.contains(where: { [.wobbling, .wobblingRolling, .rolling].contains($0) }) { return .moyenne }
        switch l.typeLeurre {
        case .leurreAJupe, .squid, .cuiller: return .moyenne
        default: return nil
        }
    }

    /// Plage de vitesse et indicateur de donnée manquante.
    static func plageVitesse(_ l: Leurre) -> (min: Double, max: Double, complete: Bool) {
        let defaut: (Double, Double)
        switch l.typeLeurre {
        case .leurreAJupe, .squid, .leurreDeTrainePoissonVolant: defaut = (6, 10)
        case .cuiller: defaut = (3, 6)
        default: defaut = (3.5, 7)
        }
        let vMin = l.vitesseTraineMin ?? defaut.0
        let vMax = l.vitesseTraineMax ?? defaut.1
        return (vMin, max(vMin, vMax), l.vitesseTraineMin != nil && l.vitesseTraineMax != nil)
    }

    /// Profondeur atteinte à une longueur de ligne donnée.
    static func profondeur(_ l: Leurre, longueurLigne: Double) -> (valeur: Double, estimee: Bool) {
        if estJupe(l) { return (0.3, false) }
        if l.typeLeurre == .cuiller { return (l.profondeurNageMax ?? 1.0, l.profondeurNageMax == nil) }

        let defaut: Double
        switch l.typeLeurre {
        case .poissonNageurPlongeant: defaut = 4
        case .poissonNageurCoulant, .poissonNageurVibrant: defaut = 2
        default: defaut = 1.5
        }
        let pMax = l.profondeurNageMax ?? l.profondeurNageMin ?? defaut
        let pMin = min(l.profondeurNageMin ?? pMax * 0.5, pMax)
        let coefficient = 1 - exp(-longueurLigne / 12)
        return (max(pMin, pMax * coefficient), true)
    }

    // MARK: Évaluation d'un leurre

    struct Evaluation {
        let leurre: Leurre
        let poste: Poste?
        let longueurLigne: Double
        let profondeur: Double
        let profondeurEstimee: Bool
        let couleurVisee: Contraste
        let famille: Contraste
        let teinte: Teinte
        let amplitude: Amplitude?
        let sProfondeur: Double
        let sCouleur: Double
        let sTaille: Double
        let sNage: Double
        let sEspece: Double
        /// Tombant et large : leurre d'une autre zone pris en repli (−8).
        let sZone: Double
        /// Bonus appris du journal (0 à 15, jamais négatif).
        let sJournal: Double
        let prisesJournal: Int
        let donneesIncompletes: Bool

        var total: Double { sProfondeur + sCouleur + sTaille + sNage + sEspece + sZone + sJournal }
    }

    static func evaluer(_ l: Leurre, poste: Poste?, vitesse v: Double, ctx: Contexte) -> Evaluation? {
        let plage = plageVitesse(l)
        guard v >= plage.min - 0.5, v <= plage.max + 0.5 else { return nil }

        let longueur = ctx.longueurLigne(poste ?? .shortCorner)
        let prof = profondeur(l, longueurLigne: longueur)
        guard prof.valeur <= ctx.plafond + 0.01 else { return nil }

        // Profondeur (25)
        let bande = ctx.bande
        let ecartBande = prof.valeur < bande.min ? bande.min - prof.valeur
                       : (prof.valeur > bande.max ? prof.valeur - bande.max : 0)
        var sProf = max(0, 25 - 6 * ecartBande)
        if poste == .shortCorner, prof.valeur > 3 { sProf = max(0, sProf - 5 * (prof.valeur - 3)) }

        // Couleur (25) : famille 15, teinte 7, éclat 3
        let cib = cible(poste: poste, niveau: ctx.niveau, nombreLignes: ctx.conditions.nombreLignes)
        let coul = scoreCouleur(l, profondeur: prof.valeur, poste: poste, cible: cib, ctx: ctx)
        let sCoul = coul.total

        // Taille (20)
        let t = ctx.preset.taille
        let ecartTaille = l.longueur < t.min ? t.min - l.longueur : (l.longueur > t.max ? l.longueur - t.max : 0)
        let sTaille = max(0, 20 - 4 * ecartTaille)

        // Nage (15)
        let amp = amplitude(l)
        let sNage: Double
        if let amp {
            if amp == ctx.nageVisee { sNage = 15 }
            else if amp == .moyenne || ctx.nageVisee == .moyenne { sNage = 9 }
            else { sNage = 3 }
        } else {
            sNage = 8
        }

        // Espèce (15)
        let sEsp = scoreEspece(l, profondeur: prof.valeur, amplitude: amp, ctx: ctx)

        // Journal : bonus appris (0 à 15)
        let journal = bonusJournal(l, ctx: ctx)

        return Evaluation(
            leurre: l, poste: poste, longueurLigne: longueur,
            profondeur: prof.valeur, profondeurEstimee: prof.estimee,
            couleurVisee: cib.familles.first ?? .naturel, famille: coul.famille, teinte: coul.teinte,
            amplitude: amp,
            sProfondeur: sProf, sCouleur: sCoul, sTaille: sTaille, sNage: sNage, sEspece: sEsp,
            sZone: ctx.zonesCibles.map { zc in zc.isDisjoint(with: l.zonesAdapteesFinales) ? -8 : 0 } ?? 0,
            sJournal: journal.points, prisesJournal: journal.prises,
            donneesIncompletes: !plage.complete || l.profondeurNageMax == nil
        )
    }

    /// Score couleur sur 25 : famille 15 (corrigée par la profondeur
    /// effective), teinte 7 (ventre d'abord près de la surface), éclat 3.
    static func scoreCouleur(_ l: Leurre, profondeur p: Double, poste: Poste?,
                             cible: CibleCouleur, ctx: Contexte) -> (total: Double, famille: Contraste, teinte: Teinte) {
        let f = l.ficheDeduction
        let famille = ReglesCouleur.familleCorrigee(f, profondeur: p)
        let sFamille = 15 * (cible.familles.map { similarite(cible: $0, leurre: famille) }.max() ?? 0)

        let t = ReglesCouleur.teinte(f)
        let t2 = ReglesCouleur.teinteSecondaire(f)
        let preferees = cible.teintes ?? ctx.teintesDuJour
        var sTeinte: Double
        if cible.ventreChaud && p <= 3 {
            // Le prédateur, sous le leurre, voit surtout le ventre.
            sTeinte = ReglesCouleur.ventreChaud(f) ? 7 : (preferees.contains(t) ? 3 : 1)
        } else if preferees.contains(t) {
            sTeinte = 7
        } else if let t2, preferees.contains(t2) {
            sTeinte = 4
        } else {
            sTeinte = 1
        }
        // Lagon : pas de contraste agressif rouge/noir hors short corner en eau claire.
        if poste != .shortCorner && ctx.eau == .claire && famille == .contraste &&
           (t == .orangeRouge || t2 == .orangeRouge) {
            sTeinte = 0
        }

        var e = ReglesCouleur.eclat(f)
        if ReglesCouleur.ventre(f)?.paillete == true && cible.eclats.contains(.paillete) { e = .paillete }
        let sEclat: Double = cible.eclats.contains(e) ? 3 : (cible.eclatsProscrits.contains(e) ? 0 : 1)

        return (sFamille + sTeinte + sEclat, famille, t)
    }

    static func scoreEspece(_ l: Leurre, profondeur: Double, amplitude: Amplitude?, ctx: Contexte) -> Double {
        switch ctx.preset.nom {
        case "thazard":
            let nageOK = amplitude == .serree
            let tailleOK = l.longueur >= 12
            return nageOK && tailleOK ? 15 : (nageOK || tailleOK ? 10 : 5)
        case "carangue", "carangue GT":
            return profondeur <= 3 ? 15 : 7
        case "loche":
            return (l.typeLeurre == .poissonNageurPlongeant || profondeur >= ctx.plafond - 3) ? 15 : 5
        case "bonite":
            let petit = l.longueur <= 12
            let droit = amplitude == .serree
            return petit && droit ? 15 : (petit || droit ? 10 : 5)
        case "barracuda", "bécune":
            return l.longueur >= 12 ? 15 : 8
        case "wahoo", "thon":
            let plonge = profondeur >= 3
            let taille = l.longueur >= 14
            return plonge && taille ? 15 : (plonge || taille ? 10 : 5)
        case "mahi-mahi":
            let surface = profondeur <= 3
            let taille = l.longueur >= 15
            return surface && taille ? 15 : (surface || taille ? 9 : 4)
        case "rostres":
            return (estJupe(l) || l.typeLeurre == .leurreDeTrainePoissonVolant) && l.longueur >= 20 ? 15 : 4
        case "thon dents de chien":
            let plonge = profondeur >= 4 && !estJupe(l)
            let taille = l.longueur >= 14
            return plonge && taille ? 15 : (plonge || taille ? 9 : 4)
        default:
            return estJupe(l) ? 10 : 12
        }
    }

    // MARK: Assemblage du spread

    struct Spread {
        let vitesse: Double
        let lignes: [Evaluation]
        let score: Double
    }

    /// Pénalités d'étagement et de diversité sur un ensemble de lignes.
    static func penalites(_ lignes: [Evaluation]) -> Double {
        var p: Double = 0
        for i in 0..<lignes.count {
            for j in (i + 1)..<lignes.count {
                let a = lignes[i], b = lignes[j]
                if abs(a.profondeur - b.profondeur) < 1.5 { p += 25 }
                // Le plus profond sur la ligne la plus longue.
                let (court, long) = a.longueurLigne <= b.longueurLigne ? (a, b) : (b, a)
                if long.profondeur < court.profondeur - 0.5 { p += 15 }
                // Diversité : ni même famille ni même teinte quand la boîte le permet.
                if a.famille == b.famille && a.teinte == b.teinte { p += 6 }
            }
        }
        if lignes.count >= 3 {
            let amps = Set(lignes.compactMap { $0.amplitude })
            if amps.count == 1 && lignes.allSatisfy({ $0.amplitude != nil }) { p += 10 }
        }
        return p
    }

    static func assembler(candidats: [Leurre], postes: [Poste], vitesse v: Double, ctx: Contexte) -> Spread {
        func noteEnsemble(_ e: [Evaluation]) -> Double {
            e.reduce(0) { $0 + $1.total } - penalites(e)
        }

        // 1. Recherche en faisceau, poste par poste : on garde les 40 meilleurs
        //    spreads partiels, ce qui évite les choix gloutons qui bloquent
        //    l'étagement des postes suivants.
        var faisceau: [[Evaluation]] = [[]]
        for poste in postes {
            var suivants: [[Evaluation]] = []
            for partiel in faisceau {
                let pris = Set(partiel.map { $0.leurre.id })
                var etendu = false
                for l in candidats where !pris.contains(l.id) {
                    if let e = evaluer(l, poste: poste, vitesse: v, ctx: ctx) {
                        suivants.append(partiel + [e])
                        etendu = true
                    }
                }
                if !etendu { suivants.append(partiel) }
            }
            faisceau = suivants
                .map { (note: noteEnsemble($0), spread: $0) }
                .sorted { $0.note > $1.note }
                .prefix(40)
                .map { $0.spread }
        }
        var choisis = faisceau.first ?? []

        // 2. Amélioration locale : on remplace un leurre par un autre tant que
        //    l'ensemble y gagne (étages, ordre des profondeurs, nages).
        func ameliorer(_ depart: [Evaluation]) -> [Evaluation] {
            var courant = depart
            var progres = true
            var passes = 0
            while progres && passes < 4 {
                progres = false
                passes += 1
                for k in courant.indices {
                    guard let poste = courant[k].poste else { continue }
                    let pris = Set(courant.map { $0.leurre.id })
                    for l in candidats where !pris.contains(l.id) {
                        guard let e = evaluer(l, poste: poste, vitesse: v, ctx: ctx) else { continue }
                        var essai = courant
                        essai[k] = e
                        if noteEnsemble(essai) > noteEnsemble(courant) + 0.01 {
                            courant = essai
                            progres = true
                        }
                    }
                }
            }
            return courant
        }
        choisis = ameliorer(choisis)

        // 3. Meilleure répartition des leurres retenus entre les postes.
        let postesUtilises = choisis.compactMap { $0.poste }
        let leurres = choisis.map { $0.leurre }
        var meilleure = choisis
        var meilleurScore = noteEnsemble(choisis)
        for perm in permutations(Array(0..<leurres.count)) {
            var essai: [Evaluation] = []
            var valide = true
            for (k, idx) in perm.enumerated() {
                guard let e = evaluer(leurres[idx], poste: postesUtilises[k], vitesse: v, ctx: ctx) else {
                    valide = false; break
                }
                essai.append(e)
            }
            guard valide else { continue }
            let s = noteEnsemble(essai)
            if s > meilleurScore { meilleurScore = s; meilleure = essai }
        }
        meilleure = ameliorer(meilleure)
        meilleurScore = noteEnsemble(meilleure)

        // Un spread incomplet vaut moins qu'un spread complet.
        let manque = Double(postes.count - meilleure.count) * 60
        return Spread(vitesse: v, lignes: meilleure, score: meilleurScore - manque)
    }

    static func permutations(_ a: [Int]) -> [[Int]] {
        guard a.count > 1 else { return [a] }
        var res: [[Int]] = []
        for (i, x) in a.enumerated() {
            var reste = a
            reste.remove(at: i)
            for p in permutations(reste) { res.append([x] + p) }
        }
        return res
    }

    /// Distance de mise à l'eau : mètres pour les bavettes, vague de sillage
    /// la plus proche pour les jupes (λ = 0,17 × v²).
    static func distance(_ e: Evaluation, vitesse v: Double) -> Int {
        if estJupe(e.leurre) {
            let vague = 0.17 * v * v
            let n = max(2, (e.longueurLigne / vague).rounded())
            return Int((n * vague).rounded())
        }
        return Int(e.longueurLigne.rounded())
    }

    // MARK: Mise en forme

    static func nb(_ x: Double) -> String {
        let s = x.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", x) : String(format: "%.1f", x)
        return s.replacingOccurrences(of: ".", with: ",")
    }

    static func nbVitesse(_ x: Double) -> String {
        String(format: x.truncatingRemainder(dividingBy: 0.5) == 0 ? "%.1f" : "%.2f", x)
            .replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Branchement sur le moteur

extension SuggestionEngine {

    /// Le moteur du Clark traite toutes les zones depuis octobre 2026 : le
    /// bateau n'a pas de tangons, le spread compétiteurs à cinq lignes ne
    /// s'applique pas.
    static func moteurLagonApplicable(_ c: ConditionsPeche) -> Bool {
        true
    }

    func executerMoteurLagon(conditions c: ConditionsPeche) {
        let ctx = Lagon.Contexte(c, historique: self.BoiteLeurresViewModel.historiquePrises())
        var candidats = self.BoiteLeurresViewModel.tousLesLeurres.filter { Lagon.estLeurreDeTraine($0) }

        // Tombant, large et DCP : leurres marqués pour la zone ; ceux des zones
        // voisines seulement en repli, quand la boîte n'en compte pas assez.
        if let zc = ctx.zonesCibles {
            let deLaZone = candidats.filter { !zc.isDisjoint(with: $0.zonesAdapteesFinales) }
            if deLaZone.count >= min(c.nombreLignes, Lagon.postesInstalles) {
                candidats = deLaZone
            } else {
                let voisines: Set<Zone> = ctx.tombant ? [.tombant, .passe, .large] : [.large, .dcp, .tombant, .passe]
                candidats = candidats.filter { !voisines.isDisjoint(with: $0.zonesAdapteesFinales) }
            }
        }

        guard !candidats.isEmpty else {
            terminerAvecErreur("❌ Aucun leurre de traîne dans la boîte.")
            return
        }

        let postes = Lagon.Poste.postes(pour: c.nombreLignes)

        // Vitesse : proposée par le moteur, sauf si l'utilisateur l'a fixée.
        let vitesseImposee = c.vitesseLibre == false
        var vitesses: [Double] = []
        if vitesseImposee {
            vitesses = [c.vitesseBateau]
        } else {
            var v = ctx.preset.vitesseMin
            while v <= ctx.preset.vitesseMax + 0.001 { vitesses.append(v); v += 0.25 }
        }

        var meilleur: Lagon.Spread?
        for v in vitesses {
            let s = Lagon.assembler(candidats: candidats, postes: postes, vitesse: v, ctx: ctx)
            let note = s.score - 2 * abs(v - ctx.preset.vitesseCible)
            let noteMeilleur = meilleur.map { $0.score - 2 * abs($0.vitesse - ctx.preset.vitesseCible) } ?? -Double.infinity
            if note > noteMeilleur { meilleur = s }
        }

        guard let spread = meilleur, !spread.lignes.isEmpty else {
            terminerAvecErreur("❌ Aucun leurre ne nage correctement dans ces conditions.\n\nVérifiez la profondeur du fond (marge de \(Lagon.nb(ctx.marge)) m) et la vitesse.")
            return
        }

        let v = spread.vitesse

        // Liste complète : les leurres du spread d'abord, puis les autres valides.
        var resultatsSpread: [SuggestionResult] = []
        for e in spread.lignes {
            var r = construireResultat(e, ctx: ctx)
            if let poste = e.poste {
                r.positionSpread = poste.positionSpread
                r.distanceSpread = Lagon.distance(e, vitesse: v)
                r.justificationPosition = justificationPoste(e, poste: poste, vitesse: v, ctx: ctx)
                r.libellePoste = poste.nom
                r.rolePoste = poste.role.prefix(1).uppercased() + poste.role.dropFirst()
                r.etagePoste = "≈ \(Lagon.nb(e.profondeur.arrondi(1))) m"

            }
            resultatsSpread.append(r)
        }
        let idsSpread = Set(spread.lignes.map { $0.leurre.id })
        // « Tous » : seulement les leurres compatibles avec la zone et, si elle
        // est renseignée, l'espèce visée.
        func zoneCompatible(_ l: Leurre) -> Bool {
            let z = Set(l.zonesAdapteesFinales)
            switch c.zone {
            case .lagon, .recif:          return z.contains(.lagon) || z.contains(.recif)
            case .large, .dcp, .profond:  return z.contains(.large) || z.contains(.dcp)
            default:                      return z.contains(c.zone)
            }
        }
        func especeCompatible(_ l: Leurre) -> Bool {
            guard let e = c.especePrioritaire else { return true }
            return l.especesCiblesFinales.contains(e.displayName)
        }
        let autres = candidats
            .filter { !idsSpread.contains($0.id) && zoneCompatible($0) && especeCompatible($0) }
            .compactMap { Lagon.evaluer($0, poste: nil, vitesse: v, ctx: ctx) }
            .sorted { $0.total > $1.total }
            .map { construireResultat($0, ctx: ctx) }

        let analyse = analyseSpread(spread, postes: postes, candidats: candidats, ctx: ctx, vitesseImposee: vitesseImposee)
        let distances = resultatsSpread.compactMap { $0.distanceSpread }

        let config = ConfigurationSpread(
            suggestions: resultatsSpread,
            nombreLignes: resultatsSpread.count,
            distanceMoyenne: distances.isEmpty ? 0 : Double(distances.reduce(0, +)) / Double(distances.count),
            analyseSpread: analyse,
            vitesseRecommandee: v,
            vitessePlageMin: ctx.preset.vitesseMin,
            vitessePlageMax: ctx.preset.vitesseMax,
            justificationVitesse: vitesseImposee
                ? "Vitesse fixée à la main : \(Lagon.nbVitesse(v)) nœuds."
                : "Vitesse qui fait le mieux nager l'ensemble du spread (plage \(ctx.preset.nom) : \(Lagon.nbVitesse(ctx.preset.vitesseMin)) à \(Lagon.nbVitesse(ctx.preset.vitesseMax)) nœuds).",
            ajustementsVitesse: ajustementsVitesse(ctx),
            modeLagon: true
        )

        self.suggestions = resultatsSpread + autres
        self.configurationSpread = config
        self.analyseGlobale = analyse
        self.isProcessing = false
        self.progressMessage = ""
        self.shouldShowResults = true
        print("✅ Moteur lagon : \(resultatsSpread.count) lignes à \(Lagon.nbVitesse(v)) nd, \(autres.count) autres leurres valides")
    }

    // MARK: - Construction des résultats

    private func terminerAvecErreur(_ message: String) {
        self.errorMessage = message
        self.isProcessing = false
        self.progressMessage = ""
    }

    private func construireResultat(_ e: Lagon.Evaluation, ctx: Lagon.Contexte) -> SuggestionResult {
        let l = e.leurre
        let technique = (e.sProfondeur + e.sTaille) / 45 * 40
        let couleur = e.sCouleur / 25 * 30
        let conditions = e.sNage + e.sEspece + e.sJournal
        let total = min(100, ((technique + couleur + conditions) * 10).rounded() / 10)

        let plage = Lagon.plageVitesse(l)
        var jTech = "Nage vers \(Lagon.nb(e.profondeur.arrondi(1))) m à \(Lagon.nb(e.longueurLigne)) m de ligne"
        jTech += e.profondeurEstimee ? " (estimation catalogue, à vérifier au sondeur)" : ""
        jTech += ". Plage de vitesse \(Lagon.nb(plage.min))–\(Lagon.nb(plage.max)) nd"
        jTech += plage.complete ? "." : " (valeur par défaut : fiche à compléter)."
        jTech += " Taille \(Lagon.nb(l.longueur)) cm pour une cible de \(Lagon.nb(ctx.preset.taille.min))–\(Lagon.nb(ctx.preset.taille.max)) cm."
        let b = ctx.bande
        jTech += " Étage visé : \(Lagon.nb(b.min))–\(Lagon.nb(b.max)) m (fond \(Lagon.nb(ctx.conditions.profondeurZone)) m, marge \(Lagon.nb(ctx.marge)) m)."

        let cib = Lagon.cible(poste: e.poste, niveau: ctx.niveau, nombreLignes: ctx.conditions.nombreLignes)
        var jCoul = "Contraste du jour \(ctx.niveau.rawValue) : \(cib.consigne)."
        jCoul += " Ce leurre : \(Lagon.nomCouleur(e.famille))"
        if e.famille != l.profilVisuel { jCoul += " (\(Lagon.nomCouleur(l.profilVisuel)) en surface, corrigé à \(Lagon.nb(e.profondeur.arrondi(1))) m)" }
        jCoul += ", teinte \(l.teinte.rawValue), éclat \(l.eclat.rawValue)"
        if let v = l.ventre, let ton = v.ton { jCoul += ", ventre \(ton.rawValue)" }
        jCoul += " (\(l.descriptionCouleurs)). La couleur départage, elle n'élimine pas."

        var jCond = "Nage visée \(ctx.nageVisee.rawValue) ; ce leurre : \(e.amplitude?.rawValue ?? "non renseignée")."
        jCond += " Cible : \(ctx.preset.nom). La lune n'entre pas dans le choix."
        if e.prisesJournal > 0 {
            jCond += " Journal : \(e.prisesJournal) prise\(e.prisesJournal > 1 ? "s" : "") avec ce leurre, bonus +\(Int(e.sJournal.rounded())) points."
        } else {
            jCond += " Journal : aucune prise avec ce leurre (bonus 0)."
        }

        let details = ScoringDetails(
            compatibiliteZone: 1,
            compatibiliteProfondeur: e.sProfondeur / 25,
            compatibiliteVitesse: 1,
            compatibiliteEspeces: e.sEspece / 15,
            bonusLuminosite: 0, bonusTurbidite: 0,
            bonusContraste: e.sCouleur / 25,
            bonusMoment: 0, bonusMer: 0, bonusMaree: 0, bonusLune: 0,
            multiplicateurContextuel: 1
        )

        return SuggestionResult(
            leurre: l,
            scoreTechnique: technique,
            scoreCouleur: couleur,
            scoreConditions: conditions,
            scoreTotal: total,
            probabilitePrise: min(95, 30 + total * 0.65),
            positionSpread: nil,
            distanceSpread: nil,
            justificationTechnique: jTech,
            justificationCouleur: jCoul,
            justificationConditions: jCond,
            justificationPosition: "",
            astucePro: "Rien ne mord après 30 minutes : changez d'abord la profondeur, puis la nage, la couleur en dernier.",
            detailsScoring: details
        )
    }

    private func justificationPoste(_ e: Lagon.Evaluation, poste: Lagon.Poste, vitesse v: Double, ctx: Lagon.Contexte) -> String {
        let d = Lagon.distance(e, vitesse: v)
        var t = "\(poste.nom) — \(poste.support), \(d) m de ligne. Rôle : \(poste.role)."
        t += " Nage vers \(Lagon.nb(e.profondeur.arrondi(1))) m"
        t += e.profondeurEstimee ? " (estimée)." : "."
        if Lagon.estJupe(e.leurre) { t += " Jupe : distance calée sur la vague de sillage." }
        return t
    }

    private func ajustementsVitesse(_ ctx: Lagon.Contexte) -> [String] {
        var a: [String] = []
        if ctx.ajustementDistance < 0 { a.append("Mer agitée : toutes les lignes raccourcies de 3 m.") }
        if ctx.allongementArriere > 0 { a.append("Eau très claire et plein soleil : lignes arrière allongées de 3 m.") }
        if ctx.large {
            a.append("Large : lignes allongées de 4 m (CPS 2025 : 30 à 50 m en eaux côtières ; 35 m au plus sur le schéma du Clark).")
        }
        if ctx.tombant {
            a.append("Tombant : lignes allongées de 4 m (CPS 93 : à l'aplomb du tombant, on peut allonger et lester les lignes).")
        }
        if ctx.conditions.zone == .passe {
            a.append("En passe, la vitesse dans l'eau diffère de la vitesse GPS : à contre-courant, lisez moins au GPS ; avec le courant, plus.")
        }
        return a
    }

    // MARK: - Analyse, alertes, consignes, à acheter

    private func analyseSpread(
        _ spread: Lagon.Spread,
        postes: [Lagon.Poste],
        candidats: [Leurre],
        ctx: Lagon.Contexte,
        vitesseImposee: Bool
    ) -> String {
        let c = ctx.conditions
        var lignes: [String] = []

        lignes.append("TRAÎNER À \(Lagon.nbVitesse(spread.vitesse)) NŒUDS")
        lignes.append("Contraste du jour : \(ctx.niveau.description). Lumière \(ctx.lumiere.rawValue), eau \(ctx.eau.rawValue). Nage visée : \(ctx.nageVisee.rawValue).")
        for poste in postes {
            let cb = Lagon.cible(poste: poste, niveau: ctx.niveau, nombreLignes: c.nombreLignes)
            lignes.append("• \(poste.nom) : \(cb.consigne)")
        }

        // Alertes
        var alertes: [String] = []
        if let hors = ctx.preset.horsLagon {
            if ctx.large {
                alertes.append(Lagon.especesDeFond.contains(hors)
                    ? "« \(hors.displayName) » se pêche au jig ou à la ligne profonde, pas à la traîne au large : suggestion faite en mode mixte large."
                    : "« \(hors.displayName) » se cherche plutôt dans le lagon, en passe ou sur le tombant qu'au large : suggestion faite en mode mixte large.")
            } else if c.zone == .tombant {
                alertes.append(Lagon.especesDeFond.contains(hors)
                    ? "« \(hors.displayName) » se pêche au jig ou à la ligne profonde sur le tombant, pas à la traîne : suggestion faite en mode mixte tombant."
                    : "« \(hors.displayName) » se cherche plutôt au large ou sous DCP qu'au tombant : suggestion faite en mode mixte tombant.")
            } else {
                alertes.append("« \(hors.displayName) » ne se pêche pas à la traîne en lagon : suggestion faite en mode mixte lagon.")
            }
        }
        if spread.lignes.contains(where: { $0.sZone < 0 }) {
            alertes.append("Boîte courte en leurres pour cette zone : un leurre d'une zone voisine complète le spread.")
        }
        if ctx.preset.nom == "rostres" {
            alertes.append("Marlin et voilier sur un 4,29 m : combat long et risqué ; ligne et frein réglés à l'avance, tout le monde en gilet.")
        }
        if spread.lignes.contains(where: { $0.prisesJournal > 0 }) {
            alertes.append("Journal : les leurres déjà gagnants dans des conditions proches reçoivent un bonus (jusqu'à +15).")
        }
        if c.especePrioritaire == .thonDentsDeChien {
            alertes.append("Thon à dents de chien : aube et crépuscule, passes et tombant ; après une prise, tournez au même endroit, d'autres suivent souvent (CPS 93).")
        }
        if spread.lignes.count < postes.count {
            alertes.append("Seulement \(spread.lignes.count) leurre(s) nagent correctement ici : spread réduit à \(spread.lignes.count) ligne(s).")
        }
        if Lagon.penalites(spread.lignes) >= 25 {
            alertes.append("Deux lignes nagent au même étage : spread dégradé, la boîte manque de leurres à d'autres profondeurs.")
        }
        if c.nombreLignes > Lagon.postesInstalles {
            alertes.append("Le Clark ne compte que \(Lagon.postesInstalles) postes (deux corners et le centre) : spread limité à \(Lagon.postesInstalles) lignes.")
        }
        if c.nombreLignes >= 3 {
            alertes.append("Trois lignes et plus : seul à bord, à la touche, remontez les autres lignes avant de combattre.")
        }
        if min(c.nombreLignes, Lagon.postesInstalles) >= 4 {
            alertes.append("Quatre lignes et plus : deux personnes à bord indispensables, virages larges.")
        }
        if min(c.nombreLignes, Lagon.postesInstalles) == 5 {
            alertes.append("Cinq lignes : exceptionnel sur 4,29 m ; risque d'emmêlement en cas de prise multiple.")
        }
        if c.zone == .recif && min(c.nombreLignes, Lagon.postesInstalles) >= 4 {
            alertes.append("Platier et pâtés : passez à 2 ou 3 lignes.")
        }
        if ctx.preset.horsLagon == nil && !ctx.preset.nom.hasPrefix("mixte") && c.nombreLignes != ctx.preset.modeConseille {
            alertes.append("Pour la cible \(ctx.preset.nom), le mode conseillé est \(ctx.preset.modeConseille) ligne\(ctx.preset.modeConseille > 1 ? "s" : "").")
        }
        let horsFamille = spread.lignes.filter { e in
            guard let p = e.poste else { return false }
            return !Lagon.cible(poste: p, niveau: ctx.niveau, nombreLignes: c.nombreLignes).familles.contains(e.famille)
        }
        if !horsFamille.isEmpty {
            let noms = horsFamille.compactMap { $0.poste?.nom.lowercased() }.joined(separator: ", ")
            alertes.append("Couleur : la famille visée manque dans la boîte à la bonne profondeur (\(noms)) ; voir « À acheter ».")
        }
        alertes.append("Bas de ligne : \(ctx.preset.basDeLigne).")
        if let cig = ctx.preset.alerteCiguatera { alertes.append(cig) }
        alertes.append("Fond \(Lagon.nb(c.profondeurZone)) m : aucun leurre sous \(Lagon.nb(ctx.plafond)) m (marge \(Lagon.nb(ctx.marge)) m).")
        if ctx.preset.margeFond != nil {
            alertes.append("Marge de fond réduite pour la loche : risque d'accroche assumé.")
        }
        if spread.lignes.contains(where: { $0.profondeurEstimee }) {
            alertes.append("Profondeurs estimées d'après le catalogue et la longueur de ligne : à confirmer au sondeur.")
        }
        let incompletes = spread.lignes.filter { $0.donneesIncompletes }.map { $0.leurre.nom }
        if !incompletes.isEmpty {
            alertes.append("Fiches à compléter (vitesse ou profondeur) : \(incompletes.joined(separator: ", ")).")
        }
        if vitesseImposee {
            alertes.append("Vitesse fixée à la main : le moteur ne l'a pas optimisée.")
        }

        lignes.append("")
        lignes.append("ALERTES")
        lignes.append(contentsOf: alertes.map { "• " + $0 })

        // Consignes
        lignes.append("")
        lignes.append("CONSIGNES")
        lignes.append(contentsOf: [
            "• Mettre à l'eau les lignes longues d'abord, remonter les courtes d'abord.",
            "• Vitesse constante, virages larges : un virage serré écrase la nage des lignes intérieures.",
            "• Après une touche : cercle pour repasser sur le lieu ; ramener les autres lignes excite les suiveurs.",
            ctx.large
                ? "• DCP : tourner autour à bonne distance, sans accrocher la bouée ni son câble ; les mahi-mahi y mordent souvent les premiers (CPS 93)."
                : (c.zone == .tombant
                    ? "• Suivre le tombant à la limite eau verte (au-dessus du récif) et eau bleue (au large), une couleur de chaque bord ; zigzags ou huits le long de la paroi."
                    : "• Le pâté se travaille côté au vent, d'assez près."),
            "• Rien après 30 minutes : changer la profondeur, puis la nage, la couleur en dernier."
        ])

        // À acheter : postes servis à moins de 70 points
        var achats: [String] = []
        for e in spread.lignes where e.total < 70 || horsFamille.contains(where: { $0.leurre.id == e.leurre.id }) {
            guard let poste = e.poste else { continue }
            achats.append("• \(poste.nom) : leurre \(Lagon.cible(poste: poste, niveau: ctx.niveau, nombreLignes: c.nombreLignes).consigne), \(Lagon.nb(ctx.preset.taille.min))–\(Lagon.nb(ctx.preset.taille.max)) cm, nage \(ctx.nageVisee.rawValue), nageant vers \(etageVise(poste, ctx: ctx)) (meilleur leurre actuel : \(e.leurre.nom), \(Int(e.total))/100).")
        }
        for poste in postes.dropFirst(spread.lignes.count) {
            achats.append("• \(poste.nom) : aucun leurre ne nage ici ; profil \(Lagon.cible(poste: poste, niveau: ctx.niveau, nombreLignes: c.nombreLignes).consigne), \(etageVise(poste, ctx: ctx)).")
        }
        if !achats.isEmpty {
            lignes.append("")
            lignes.append("À ACHETER")
            lignes.append(contentsOf: achats)
        }

        return lignes.joined(separator: "\n")
    }

    private func etageVise(_ poste: Lagon.Poste, ctx: Lagon.Contexte) -> String {
        let b = ctx.bande
        switch poste {
        case .shortCorner:
            return "0 à \(Lagon.nb(min(3, b.max))) m"
        case .centre:
            return "\(Lagon.nb(max(b.min, b.max - 2))) à \(Lagon.nb(b.max)) m"
        default:
            return "\(Lagon.nb(b.min)) à \(Lagon.nb(b.max)) m"
        }
    }
}

private extension Double {
    func arrondi(_ p: Int) -> Double {
        let f = pow(10, Double(p))
        return (self * f).rounded() / f
    }
}
