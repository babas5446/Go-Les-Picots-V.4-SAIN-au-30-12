//
//  MoteurLagon.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Moteur de traîne propre au lagon (lagon, platier et pâtés, passes),
//  pensé pour le Clark 4,29 m sans tangons et une boîte de poissons nageurs.
//  Il remplace, pour ces zones, la logique héritée de la pêche au large.
//  Référence : audit « Moteur de suggestion — lagon » (octobre 2026).
//
//  Principes :
//  1. La vitesse ne sert qu'à valider la nage (plage constructeur ± 0,5 nd).
//  2. La profondeur réelle d'une bavette dépend de la longueur de ligne du
//     poste : profondeur catalogue × (1 − e^(−L/12)). Hypothèse à étalonner
//     au sondeur ; elle est signalée comme estimation.
//  3. Couleur = f(luminosité, turbidité), une seule table. La marée et la
//     lune n'agissent pas sur la couleur ; la lune est hors score.
//  4. Postes du Clark : short corner 16 m, long corner 23 m, centre 30 m,
//     latéraux 20 et 22 m. Short corner contrasté, lignes arrière naturelles.
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
            case .centre:         return "Centre (shotgun lagon)"
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
            Array(allCases.prefix(max(1, min(5, nombreLignes))))
        }
    }

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

    // MARK: Table couleur unique (luminosité × turbidité)

    static func couleurDeBase(_ lum: Lumiere, _ eau: Eau) -> Contraste {
        switch (lum, eau) {
        case (.forte, .claire):    return .naturel
        case (.forte, .teintee):   return .contraste
        case (.forte, .trouble):   return .flashy
        case (.diffuse, .claire):  return .contraste
        case (.diffuse, .teintee): return .flashy
        case (.diffuse, .trouble): return .sombre
        case (.faible, _):         return .sombre
        }
    }

    /// Le rôle du poste décale la couleur de base (règle propre au lagon).
    static func couleurCible(poste: Poste?, base: Contraste, eau: Eau) -> Contraste {
        guard let poste else { return base }
        switch poste {
        case .shortCorner:
            return base == .naturel ? .contraste : base
        case .longCorner, .centre:
            switch base {
            case .sombre:    return eau == .claire ? .naturel : .contraste
            case .flashy:    return .contraste
            case .contraste: return eau == .claire ? .naturel : .contraste
            case .naturel:   return .naturel
            }
        case .lateralTribord, .lateralBabord:
            return eau == .claire ? .contraste : .flashy
        }
    }

    /// Proximité entre la couleur visée et le profil du leurre (0…1).
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
        let tailleMixte: (Double, Double)
        if c.zone == .passe {
            tailleMixte = (12, 18)
        } else if c.etatMer == .calme && c.turbiditeEau == .claire && c.luminosite == .forte {
            tailleMixte = (8, 12)
        } else {
            tailleMixte = (10, 15)
        }

        let mixte = Preset(
            nom: "mixte lagon", vitesseMin: 4.5, vitesseMax: 6.5, vitesseCible: 5.5,
            bandeProfondeur: nil, taille: tailleMixte, nage: nil,
            basDeLigne: "fluorocarbone 60 à 80 lb ; acier si les thazards sont là",
            alerteCiguatera: nil, modeConseille: 2, margeFond: nil, horsLagon: nil
        )

        guard let espece = c.especePrioritaire else { return mixte }

        switch espece {
        case .thazard, .thazardBatard:
            return Preset(
                nom: "thazard", vitesseMin: 6.0, vitesseMax: 6.5, vitesseCible: 6.25,
                bandeProfondeur: (1, 5), taille: (12, 18), nage: .serree,
                basDeLigne: "acier 30 à 60 lb sur toutes les lignes",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .carangue, .carangueBleue, .carangueGT:
            return Preset(
                nom: espece == .carangueGT ? "carangue GT" : "carangue",
                vitesseMin: 4.5, vitesseMax: 5.5, vitesseCible: 5.0,
                bandeProfondeur: (0, 3), taille: (10, 15), nage: nil,
                basDeLigne: "fluorocarbone épais (80 à 130 lb)",
                alerteCiguatera: espece == .carangueGT
                    ? "Carangue GT : risque de ciguatera très élevé ; pêche no-kill conseillée."
                    : nil,
                modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        case .loche, .lochePintade:
            return Preset(
                nom: "loche", vitesseMin: 4.25, vitesseMax: 5.25, vitesseCible: 4.75,
                bandeProfondeur: nil, taille: (10, 15), nage: nil,
                basDeLigne: "fluorocarbone 60 à 80 lb",
                alerteCiguatera: nil, modeConseille: 1, margeFond: 1.5, horsLagon: nil
            )
        case .bonite, .coureurArcEnCiel:
            return Preset(
                nom: "bonite", vitesseMin: 5.5, vitesseMax: 6.5, vitesseCible: 6.0,
                bandeProfondeur: (0, 2), taille: (8, 12), nage: .serree,
                basDeLigne: "nylon 40 à 60 lb",
                alerteCiguatera: nil, modeConseille: 3, margeFond: nil, horsLagon: nil
            )
        case .barracuda, .becune:
            return Preset(
                nom: espece == .becune ? "bécune" : "barracuda",
                vitesseMin: 4.5, vitesseMax: 6.5, vitesseCible: 5.5,
                bandeProfondeur: (1, 3), taille: (12, 18), nage: nil,
                basDeLigne: "acier 30 à 60 lb",
                alerteCiguatera: "Barracuda et grosses bécunes : ciguatera fréquente au-delà de 3 à 5 kg.",
                modeConseille: 2, margeFond: nil, horsLagon: nil
            )
        default:
            return Preset(
                nom: mixte.nom, vitesseMin: mixte.vitesseMin, vitesseMax: mixte.vitesseMax,
                vitesseCible: mixte.vitesseCible, bandeProfondeur: nil, taille: mixte.taille,
                nage: nil, basDeLigne: mixte.basDeLigne, alerteCiguatera: nil,
                modeConseille: 2, margeFond: nil, horsLagon: espece
            )
        }
    }

    // MARK: Contexte de calcul

    struct Contexte {
        let conditions: ConditionsPeche
        let preset: Preset
        let lumiere: Lumiere
        let eau: Eau
        let couleurBase: Contraste
        let nageCible: Amplitude
        let marge: Double
        let plafond: Double
        let ajustementDistance: Double
        let allongementArriere: Double

        init(_ c: ConditionsPeche) {
            conditions = c
            preset = Lagon.preset(pour: c)
            lumiere = Lagon.lumiere(c.luminosite)
            eau = Lagon.eau(c.turbiditeEau)
            couleurBase = Lagon.couleurDeBase(lumiere, eau)

            if eau == .trouble || lumiere == .faible {
                nageCible = .large
            } else if eau == .claire && lumiere == .forte && (c.etatMer == .calme || c.etatMer == .peuAgitee) {
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
            return max(12, l)
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
        let amplitude: Amplitude?
        let sProfondeur: Double
        let sCouleur: Double
        let sTaille: Double
        let sNage: Double
        let sEspece: Double
        let donneesIncompletes: Bool

        var total: Double { sProfondeur + sCouleur + sTaille + sNage + sEspece }
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

        // Couleur (25)
        let cible = couleurCible(poste: poste, base: ctx.couleurBase, eau: ctx.eau)
        let sCoul = 25 * similarite(cible: cible, leurre: l.profilVisuel)

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

        return Evaluation(
            leurre: l, poste: poste, longueurLigne: longueur,
            profondeur: prof.valeur, profondeurEstimee: prof.estimee,
            couleurVisee: cible, amplitude: amp,
            sProfondeur: sProf, sCouleur: sCoul, sTaille: sTaille, sNage: sNage, sEspece: sEsp,
            donneesIncompletes: !plage.complete || l.profondeurNageMax == nil
        )
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

    /// Le moteur lagon traite le lagon, le platier et les pâtés, et les passes.
    static func moteurLagonApplicable(_ c: ConditionsPeche) -> Bool {
        c.zone == .lagon || c.zone == .recif || c.zone == .passe
    }

    func executerMoteurLagon(conditions c: ConditionsPeche) {
        let ctx = Lagon.Contexte(c)
        let candidats = self.BoiteLeurresViewModel.tousLesLeurres.filter { Lagon.estLeurreDeTraine($0) }

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
            }
            resultatsSpread.append(r)
        }
        let idsSpread = Set(spread.lignes.map { $0.leurre.id })
        let autres = candidats
            .filter { !idsSpread.contains($0.id) }
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
            ajustementsVitesse: ajustementsVitesse(ctx)
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
        let conditions = e.sNage + e.sEspece
        let total = ((technique + couleur + conditions) * 10).rounded() / 10

        let plage = Lagon.plageVitesse(l)
        var jTech = "Nage vers \(Lagon.nb(e.profondeur.arrondi(1))) m à \(Lagon.nb(e.longueurLigne)) m de ligne"
        jTech += e.profondeurEstimee ? " (estimation catalogue, à vérifier au sondeur)" : ""
        jTech += ". Plage de vitesse \(Lagon.nb(plage.min))–\(Lagon.nb(plage.max)) nd"
        jTech += plage.complete ? "." : " (valeur par défaut : fiche à compléter)."
        jTech += " Taille \(Lagon.nb(l.longueur)) cm pour une cible de \(Lagon.nb(ctx.preset.taille.min))–\(Lagon.nb(ctx.preset.taille.max)) cm."
        let b = ctx.bande
        jTech += " Étage visé : \(Lagon.nb(b.min))–\(Lagon.nb(b.max)) m (fond \(Lagon.nb(ctx.conditions.profondeurZone)) m, marge \(Lagon.nb(ctx.marge)) m)."

        let jCoul = "Lumière \(ctx.lumiere.rawValue), eau \(ctx.eau.rawValue) : couleur visée \(Lagon.nomCouleur(e.couleurVisee)). Profil du leurre : \(Lagon.nomCouleur(l.profilVisuel)) (\(l.descriptionCouleurs))."

        var jCond = "Nage visée \(ctx.nageVisee.rawValue) ; ce leurre : \(e.amplitude?.rawValue ?? "non renseignée")."
        jCond += " Cible : \(ctx.preset.nom). La lune n'entre pas dans le choix."

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
        lignes.append("Lumière \(ctx.lumiere.rawValue), eau \(ctx.eau.rawValue) : base couleur \(Lagon.nomCouleur(ctx.couleurBase)). Short corner contrasté, lignes arrière naturelles. Nage visée : \(ctx.nageVisee.rawValue).")

        // Alertes
        var alertes: [String] = []
        if let hors = ctx.preset.horsLagon {
            alertes.append("« \(hors.displayName) » ne se pêche pas à la traîne en lagon : suggestion faite en mode mixte lagon.")
        }
        if spread.lignes.count < postes.count {
            alertes.append("Seulement \(spread.lignes.count) leurre(s) nagent correctement ici : spread réduit à \(spread.lignes.count) ligne(s).")
        }
        if Lagon.penalites(spread.lignes) >= 25 {
            alertes.append("Deux lignes nagent au même étage : spread dégradé, la boîte manque de leurres à d'autres profondeurs.")
        }
        if c.nombreLignes >= 3 {
            alertes.append("Trois lignes et plus : seul à bord, à la touche, remontez les autres lignes avant de combattre.")
        }
        if c.nombreLignes >= 4 {
            alertes.append("Quatre lignes et plus : deux personnes à bord indispensables, virages larges.")
        }
        if c.nombreLignes == 5 {
            alertes.append("Cinq lignes : exceptionnel sur 4,29 m ; risque d'emmêlement en cas de prise multiple.")
        }
        if c.zone == .recif && c.nombreLignes >= 4 {
            alertes.append("Platier et pâtés : passez à 2 ou 3 lignes.")
        }
        if ctx.preset.horsLagon == nil && ctx.preset.nom != "mixte lagon" && c.nombreLignes != ctx.preset.modeConseille {
            alertes.append("Pour la cible \(ctx.preset.nom), le mode conseillé est \(ctx.preset.modeConseille) ligne\(ctx.preset.modeConseille > 1 ? "s" : "").")
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
            "• Le pâté se travaille côté au vent, d'assez près.",
            "• Rien après 30 minutes : changer la profondeur, puis la nage, la couleur en dernier."
        ])

        // À acheter : postes servis à moins de 70 points
        var achats: [String] = []
        for e in spread.lignes where e.total < 70 {
            guard let poste = e.poste else { continue }
            achats.append("• \(poste.nom) : leurre \(Lagon.nomCouleur(e.couleurVisee)), \(Lagon.nb(ctx.preset.taille.min))–\(Lagon.nb(ctx.preset.taille.max)) cm, nage \(ctx.nageVisee.rawValue), nageant vers \(etageVise(poste, ctx: ctx)) (meilleur leurre actuel : \(e.leurre.nom), \(Int(e.total))/100).")
        }
        for poste in postes.dropFirst(spread.lignes.count) {
            achats.append("• \(poste.nom) : aucun leurre ne nage ici ; profil \(Lagon.nomCouleur(Lagon.couleurCible(poste: poste, base: ctx.couleurBase, eau: ctx.eau))), \(etageVise(poste, ctx: ctx)).")
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
