//
//  StatistiquesCalcul.swift
//  Go Les Picots V.4
//
//  MODULE 5 — Statistiques : calculs (sans SwiftUI ni SwiftData, testables).
//
//  Principe : une prise ne dit rien seule ; il faut la rapporter au temps
//  passé à l'eau. L'effort de pêche se lit dans les spreads enregistrés
//  pendant la sortie : chaque spread est à l'eau de son heure de mise à
//  l'eau jusqu'au spread suivant ou au retour. Les pauses (durée connue,
//  heures inconnues) sont retirées au prorata.
//
//  Les conditions sont reconstituées quart d'heure par quart d'heure :
//  moment (lever et coucher du soleil, transitions de 45 minutes), lune
//  (calcul astronomique) et marée (horaires en cache, sinon marée saisie)
//  changent pendant une sortie ; zone, eau, état de la mer et courant
//  viennent de la saisie. Prises et effort sont classés par la même règle.
//
//  Aucun malus : les leurres sans prise ne figurent dans aucun classement.
//

import Foundation

// MARK: - Données d'entrée

struct StatPrise {
    let heure: Date
    /// Clé stable de l'espèce : rawValue de Espece (anciens noms convertis) ou saisie libre.
    let especeCle: String
    let especeNom: String
    let leurreID: Int?
    let relache: Bool
    let tailleCm: Double?
    let poidsKg: Double?
    let conditions: ConditionsPeche?
}

struct StatSortie {
    let debut: Date?
    let fin: Date?
    let pauses: TimeInterval
    let conditions: ConditionsPeche?
    let spreads: [SpreadSnapshot]
    let prises: [StatPrise]
}

struct StatLeurre {
    let id: Int
    let nom: String
    let marque: String
    let famille: Contraste?
}

// MARK: - Résultats

/// Une ligne de rendement : prises rapportées aux heures de pêche.
struct LigneRendement: Identifiable {
    let id: String
    let libelle: String
    var detail: String = ""
    var heures: Double = 0
    /// Prises faites pendant un spread enregistré (base du rendement).
    var prises: Int = 0
    /// Prises du leurre sans spread enregistré à ce moment-là (hors rendement).
    var horsEffort: Int = 0

    /// Seuil sous lequel le rendement n'est pas affiché.
    static let heuresMinimum = 0.5
    /// Seuil sous lequel l'échantillon est signalé comme faible.
    static let heuresSolides = 3.0

    var rendement: Double? { heures >= Self.heuresMinimum ? Double(prises) / heures : nil }
    var echantillonFaible: Bool { heures < Self.heuresSolides }
}

struct FacteurRendement: Identifiable {
    var id: String { titre }
    let titre: String
    let lignes: [LigneRendement]
}

struct BilanEspece: Identifiable {
    var id: String { cle }
    let cle: String
    let nom: String
    var prises = 0
    var relachees = 0
    var tailleMoyenne: Double?
    var tailleMax: Double?
    var poidsMoyen: Double?
    var poidsMax: Double?
    /// Leurres preneurs, du plus productif au moins productif (prises ≥ 1 seulement).
    var leurres: [LigneRendement] = []
    var meilleurMoment: LigneRendement?
    var meilleureMaree: LigneRendement?
    var secteurs: [String] = []
    /// Poissons gardés sous la taille minimale de la fiche (si elle en donne une).
    var gardesSousTaille = 0
    var tailleMinLegale: Double?
    /// Identifiant de la fiche de la Bibliothèque.
    var ficheIdentifiant: String?
}

struct AnalyseJournal {
    var heuresPeche: Double = 0
    var sortiesAvecSpread = 0
    var sortiesSansSpread = 0
    var prisesAvecEffort = 0
    var prisesSansEffort = 0

    var leurres: [LigneRendement] = []
    var facteurs: [FacteurRendement] = []
    var postes: [LigneRendement] = []
    var couleurs: [FacteurRendement] = []
    var especes: [BilanEspece] = []

    var vide: Bool { heuresPeche == 0 && especes.isEmpty }
}

// MARK: - Conditions reconstituées

struct ClassementInstant {
    let moment: MomentJournee
    let lune: PhaseLunaire
    let maree: TypeMaree?
    let zone: Zone?
    let turbidite: Turbidite?
    let courant: ForceCourant?
    let niveau: NiveauContraste?
}

enum StatistiquesCalcul {

    static let pas: TimeInterval = 15 * 60

    // MARK: Libellés (ordre d'affichage)

    static let ordreMoments: [MomentJournee] = [.aube, .matinee, .midi, .apresMidi, .crepuscule, .nuit]
    static let ordreMarees: [TypeMaree] = [.montante, .etale, .descendante]
    static let ordreLunes: [PhaseLunaire] = [.nouvelleLune, .premierQuartier, .pleineLune, .dernierQuartier]
    static let ordreZones: [Zone] = [.lagon, .recif, .passe, .tombant, .large, .dcp, .profond]
    static let ordreEaux: [Turbidite] = [.claire, .legerementTrouble, .trouble, .tresTrouble]
    static let ordreCourants: [ForceCourant] = [.faible, .modere, .fort]
    static let ordreNiveaux: [NiveauContraste] = [.faible, .moyen, .fort, .silhouette, .nuitClaire]
    static let ordreFamilles: [Contraste] = [.naturel, .flashy, .sombre, .contraste]

    static func libelle(_ m: MomentJournee) -> String { m.libelleCourt.prefix(1).uppercased() + m.libelleCourt.dropFirst() }
    static func libelle(_ m: TypeMaree) -> String {
        switch m { case .montante: return "Montante"; case .descendante: return "Descendante"; case .etale: return "Étale" }
    }
    static func libelle(_ z: Zone) -> String {
        switch z {
        case .lagon: return "Lagon"; case .recif: return "Récif"; case .passe: return "Passe"
        case .tombant: return "Tombant"; case .large: return "Large"; case .dcp: return "DCP"; case .profond: return "Profond"
        }
    }
    static func libelle(_ t: Turbidite) -> String {
        switch t {
        case .claire: return "Claire"; case .legerementTrouble: return "Légèrement trouble"
        case .trouble: return "Trouble"; case .tresTrouble: return "Très trouble"
        }
    }
    static func libelle(_ n: NiveauContraste) -> String {
        switch n {
        case .faible: return "Faible (soleil, eau claire)"; case .moyen: return "Moyen"; case .fort: return "Fort (eau trouble, mer formée)"
        case .silhouette: return "Silhouette (aube, crépuscule)"; case .nuitClaire: return "Nuit claire"
        }
    }
    static func libelle(_ f: Contraste) -> String {
        switch f { case .naturel: return "Naturel"; case .flashy: return "Flashy"; case .sombre: return "Sombre"; case .contraste: return "Contrasté" }
    }
    static func libelle(_ p: PositionSpread?) -> String {
        switch p {
        case .shortCorner?: return "Short corner"
        case .longCorner?: return "Long corner"
        case .shotgun?: return "Centre (shotgun)"
        case .shortRigger?, .longRigger?: return "Tangon"
        case .libre?, nil: return "Position libre"
        }
    }
    static func cle(_ p: PositionSpread?) -> String {
        switch p {
        case .shortRigger?, .longRigger?: return "tangon"
        case .libre?, nil: return "libre"
        case let x?: return x.rawValue
        }
    }
    static let ordrePostes = ["shortCorner", "longCorner", "shotgun", "tangon", "libre"]

    // MARK: Classement d'un instant

    /// Conditions à l'instant t : moment, lune et marée calculés, le reste saisi.
    static func classer(_ t: Date, conditions c: ConditionsPeche?, marees: [CabaigneDay],
                        cacheSoleil: inout [String: (Date, Date)], cacheLune: inout [String: PhaseLunaire]) -> ClassementInstant {
        let jour = cleJour(t)
        let soleil: (Date, Date)?
        if let s = cacheSoleil[jour] { soleil = s }
        else if let s = PropositionConditions.soleil(jour: t) { cacheSoleil[jour] = (s.lever, s.coucher); soleil = (s.lever, s.coucher) }
        else { soleil = nil }
        let moment = soleil.map { PropositionConditions.moment(a: t, lever: $0.0, coucher: $0.1) } ?? c?.momentJournee ?? .matinee

        let lune: PhaseLunaire
        if let l = cacheLune[jour] { lune = l }
        else {
            let age = SolunarCalculator.moonPhaseData(jde: SolunarCalculator.julianEphemerisDay(from: t)).age
            lune = PropositionConditions.lune(age: age); cacheLune[jour] = lune
        }

        let evenements = marees
            .filter { abs($0.date.timeIntervalSince(t)) < 2 * 86_400 }
            .flatMap { $0.events }
            .map { (heure: $0.time, haute: $0.isHigh) }
        let maree = PropositionConditions.maree(a: t, evenements: evenements) ?? c?.typeMaree

        guard let c else {
            return ClassementInstant(moment: moment, lune: lune, maree: maree, zone: nil, turbidite: nil, courant: nil, niveau: nil)
        }
        let luminosite = moment == c.momentJournee ? c.luminosite : ConditionsPeche.luminositeAutoDepuisMoment(moment)
        let niveau = NiveauContraste.depuis(
            luminosite: luminosite, turbidite: c.turbiditeEau, etatMer: c.etatMer,
            moment: moment, lune: lune, maree: maree ?? c.typeMaree,
            courantFort: c.zone == .passe && c.courant == .fort
        )
        return ClassementInstant(moment: moment, lune: lune, maree: maree, zone: c.zone,
                                 turbidite: c.turbiditeEau, courant: c.zone == .passe ? c.courant : nil, niveau: niveau)
    }

    static func cleJour(_ t: Date) -> String {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = PropositionConditions.fuseau
        let c = cal.dateComponents([.year, .month, .day], from: t)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    // MARK: Tranches d'effort d'une sortie

    struct Tranche {
        let debut: Date
        let fin: Date
        let spread: SpreadSnapshot
    }

    /// Spreads à l'eau, bornés par le départ et le retour.
    static func tranches(_ s: StatSortie) -> [Tranche] {
        let spreads = s.spreads.sorted { $0.date < $1.date }
        guard !spreads.isEmpty else { return [] }
        let derniere = s.prises.map(\.heure).max()
        var r: [Tranche] = []
        for (i, sp) in spreads.enumerated() {
            var debut = sp.date
            if let d = s.debut, debut < d { debut = d }
            var fin: Date
            if i + 1 < spreads.count { fin = spreads[i + 1].date }
            else if let f = s.fin { fin = f }
            else if let p = derniere, p > debut { fin = p }
            else { continue }
            if let f = s.fin, fin > f { fin = f }
            if fin > debut { r.append(Tranche(debut: debut, fin: fin, spread: sp)) }
        }
        return r
    }

    /// Part du temps réellement passée à pêcher (pauses retirées au prorata).
    static func facteurPeche(_ s: StatSortie, tranches: [Tranche]) -> Double {
        let total = tranches.reduce(0) { $0 + $1.fin.timeIntervalSince($1.debut) }
        guard total > 0, s.pauses > 0 else { return 1 }
        return max(0, 1 - s.pauses / total)
    }

    // MARK: Analyse complète

    static func analyser(sorties: [StatSortie], leurres: [StatLeurre], marees: [CabaigneDay],
                         fiches: [String: (fiche: String?, tailleMin: Double?)] = [:]) -> AnalyseJournal {
        var a = AnalyseJournal()
        var cacheSoleil: [String: (Date, Date)] = [:]
        var cacheLune: [String: PhaseLunaire] = [:]
        let parID = Dictionary(leurres.map { ($0.id, $0) }, uniquingKeysWith: { x, _ in x })

        // Accumulateurs : clé → (heures, prises)
        var hLeurre: [Int: Double] = [:], pLeurre: [Int: Int] = [:]
        var hPoste: [String: Double] = [:], pPoste: [String: Int] = [:]
        var hFacteur: [String: [String: Double]] = [:], pFacteur: [String: [String: Int]] = [:]
        var hCouleur: [String: [String: Double]] = [:], pCouleur: [String: [String: Int]] = [:]
        var pEspeceFacteur: [String: [String: [String: Int]]] = [:]   // espèce → facteur → valeur → prises
        var pEspeceLeurre: [String: [Int: Int]] = [:]
        var pLeurreHors: [Int: Int] = [:]
        var pEspeceLeurreHors: [String: [Int: Int]] = [:]

        func cles(_ k: ClassementInstant) -> [(String, String)] {
            var r: [(String, String)] = [("Moment", libelle(k.moment)), ("Lune", k.lune.displayName)]
            if let m = k.maree { r.append(("Marée", libelle(m))) }
            r.append(("Zone", k.zone.map(libelle) ?? "Non renseignée"))
            if let t = k.turbidite { r.append(("Eau", libelle(t))) }
            if let c = k.courant { r.append(("Courant en passe", c.displayName)) }
            if let n = k.niveau { r.append(("Besoin de contraste", libelle(n))) }
            return r
        }

        for s in sorties {
            let tr = tranches(s)
            if tr.isEmpty { a.sortiesSansSpread += 1 } else { a.sortiesAvecSpread += 1 }
            let facteur = facteurPeche(s, tranches: tr)

            // Effort, quart d'heure par quart d'heure
            for t in tr {
                var debut = t.debut
                while debut < t.fin {
                    let fin = min(t.fin, debut.addingTimeInterval(pas))
                    let h = fin.timeIntervalSince(debut) / 3600 * facteur
                    let k = classer(debut.addingTimeInterval(fin.timeIntervalSince(debut) / 2), conditions: s.conditions,
                                    marees: marees, cacheSoleil: &cacheSoleil, cacheLune: &cacheLune)
                    a.heuresPeche += h
                    for (f, v) in cles(k) { hFacteur[f, default: [:]][v, default: 0] += h }
                    for ligne in t.spread.lignes {
                        hLeurre[ligne.leurreID, default: 0] += h
                        hPoste[cle(ligne.position), default: 0] += h
                        if let n = k.niveau, let fam = parID[ligne.leurreID]?.famille {
                            hCouleur[libelle(n), default: [:]][libelle(fam), default: 0] += h
                        }
                    }
                    debut = fin
                }
            }

            // Prises
            for p in s.prises {
                let c = p.conditions ?? s.conditions
                let k = classer(p.heure, conditions: c, marees: marees, cacheSoleil: &cacheSoleil, cacheLune: &cacheLune)
                let tranche = tr.first { p.heure >= $0.debut && p.heure <= $0.fin }
                if tranche != nil { a.prisesAvecEffort += 1 } else { a.prisesSansEffort += 1 }
                // Les tables de conditions ne comptent que les prises faites pendant un spread enregistré :
                // sinon le rendement serait gonflé par des prises sans effort connu.
                if tranche != nil {
                    for (f, v) in cles(k) {
                        pFacteur[f, default: [:]][v, default: 0] += 1
                        pEspeceFacteur[p.especeCle, default: [:]][f, default: [:]][v, default: 0] += 1
                    }
                }
                if let id = p.leurreID {
                    if let t = tranche, let ligne = t.spread.lignes.first(where: { $0.leurreID == id }) {
                        pLeurre[id, default: 0] += 1
                        pEspeceLeurre[p.especeCle, default: [:]][id, default: 0] += 1
                        pPoste[cle(ligne.position), default: 0] += 1
                        if let n = k.niveau, let fam = parID[id]?.famille {
                            pCouleur[libelle(n), default: [:]][libelle(fam), default: 0] += 1
                        }
                    } else {
                        pLeurreHors[id, default: 0] += 1
                        pEspeceLeurreHors[p.especeCle, default: [:]][id, default: 0] += 1
                    }
                }
            }
        }

        // Leurres : seulement ceux qui ont pris (pas de malus)
        a.leurres = Set(pLeurre.keys).union(pLeurreHors.keys).map { id in
            let l = parID[id]
            return LigneRendement(id: String(id), libelle: l?.nom ?? "Leurre n° \(id)",
                                  detail: l.map { $0.marque } ?? "plus dans la boîte",
                                  heures: hLeurre[id] ?? 0, prises: pLeurre[id] ?? 0, horsEffort: pLeurreHors[id] ?? 0)
        }
        .sorted { trier($0, $1) }

        // Conditions
        let ordres: [(String, [String])] = [
            ("Moment", ordreMoments.map(libelle)),
            ("Marée", ordreMarees.map(libelle)),
            ("Lune", ordreLunes.map { $0.displayName }),
            ("Zone", ordreZones.map(libelle) + ["Non renseignée"]),
            ("Eau", ordreEaux.map(libelle)),
            ("Courant en passe", ordreCourants.map { $0.displayName }),
            ("Besoin de contraste", ordreNiveaux.map(libelle))
        ]
        a.facteurs = ordres.compactMap { titre, valeurs in
            let lignes = valeurs.compactMap { v -> LigneRendement? in
                let h = hFacteur[titre]?[v] ?? 0
                let n = pFacteur[titre]?[v] ?? 0
                guard h > 0 || n > 0 else { return nil }
                return LigneRendement(id: titre + v, libelle: v, heures: h, prises: n)
            }
            return lignes.isEmpty ? nil : FacteurRendement(titre: titre, lignes: lignes)
        }

        // Postes
        a.postes = ordrePostes.compactMap { k in
            let h = hPoste[k] ?? 0, n = pPoste[k] ?? 0
            guard h > 0 || n > 0 else { return nil }
            let libellePoste: String
            switch k {
            case "shortCorner": libellePoste = libelle(PositionSpread.shortCorner)
            case "longCorner": libellePoste = libelle(PositionSpread.longCorner)
            case "shotgun": libellePoste = libelle(PositionSpread.shotgun)
            case "tangon": libellePoste = "Tangon"
            default: libellePoste = "Position libre"
            }
            return LigneRendement(id: k, libelle: libellePoste, heures: h, prises: n)
        }

        // Couleur selon le besoin de contraste
        a.couleurs = ordreNiveaux.map(libelle).compactMap { niveau in
            let lignes = ordreFamilles.map(libelle).compactMap { fam -> LigneRendement? in
                let h = hCouleur[niveau]?[fam] ?? 0, n = pCouleur[niveau]?[fam] ?? 0
                guard h > 0 || n > 0 else { return nil }
                return LigneRendement(id: niveau + fam, libelle: fam, heures: h, prises: n)
            }
            return lignes.isEmpty ? nil : FacteurRendement(titre: niveau, lignes: lignes)
        }

        // Bilan par espèce
        var bilans: [String: BilanEspece] = [:]
        var tailles: [String: [Double]] = [:], poids: [String: [Double]] = [:]
        for s in sorties {
            for p in s.prises {
                var b = bilans[p.especeCle] ?? BilanEspece(cle: p.especeCle, nom: p.especeNom)
                b.prises += 1
                if p.relache { b.relachees += 1 }
                if let t = p.tailleCm, t > 0 { tailles[p.especeCle, default: []].append(t) }
                if let w = p.poidsKg, w > 0 { poids[p.especeCle, default: []].append(w) }
                if let f = fiches[p.especeCle] {
                    b.ficheIdentifiant = f.fiche
                    b.tailleMinLegale = f.tailleMin
                    if !p.relache, let min = f.tailleMin, let t = p.tailleCm, t > 0, t < min { b.gardesSousTaille += 1 }
                }
                let c = p.conditions ?? s.conditions
                if let z = c?.zone, !b.secteurs.contains(libelle(z)) { b.secteurs.append(libelle(z)) }
                bilans[p.especeCle] = b
            }
        }
        for (k, var b) in bilans {
            if let t = tailles[k], !t.isEmpty { b.tailleMoyenne = t.reduce(0, +) / Double(t.count); b.tailleMax = t.max() }
            if let w = poids[k], !w.isEmpty { b.poidsMoyen = w.reduce(0, +) / Double(w.count); b.poidsMax = w.max() }
            let avec = pEspeceLeurre[k] ?? [:], hors = pEspeceLeurreHors[k] ?? [:]
            b.leurres = Set(avec.keys).union(hors.keys).map { id in
                LigneRendement(id: String(id), libelle: parID[id]?.nom ?? "Leurre n° \(id)",
                               detail: parID[id]?.marque ?? "", heures: hLeurre[id] ?? 0,
                               prises: avec[id] ?? 0, horsEffort: hors[id] ?? 0)
            }.sorted { trier($0, $1) }
            b.meilleurMoment = meilleur(espece: pEspeceFacteur[k]?["Moment"], effort: hFacteur["Moment"])
            b.meilleureMaree = meilleur(espece: pEspeceFacteur[k]?["Marée"], effort: hFacteur["Marée"])
            bilans[k] = b
        }
        a.especes = bilans.values.sorted { $0.prises == $1.prises ? $0.nom < $1.nom : $0.prises > $1.prises }
        return a
    }

    /// Plus de prises par heure d'abord ; à défaut d'effort connu, plus de prises.
    static func trier(_ x: LigneRendement, _ y: LigneRendement) -> Bool {
        switch (x.rendement, y.rendement) {
        case let (rx?, ry?) where rx != ry: return rx > ry
        case (_?, nil): return true
        case (nil, _?): return false
        default:
            let nx = x.prises + x.horsEffort, ny = y.prises + y.horsEffort
            return nx == ny ? x.libelle < y.libelle : nx > ny
        }
    }

    /// Valeur où l'espèce se prend le mieux par heure de pêche (une heure d'effort au moins).
    static func meilleur(espece: [String: Int]?, effort: [String: Double]?) -> LigneRendement? {
        guard let espece else { return nil }
        let lignes = espece.compactMap { v, n -> LigneRendement? in
            let h = effort?[v] ?? 0
            guard n > 0, h >= 1 else { return nil }
            return LigneRendement(id: v, libelle: v, heures: h, prises: n)
        }
        return lignes.sorted { trier($0, $1) }.first
    }

    // MARK: Format

    static func rendement(_ r: Double) -> String {
        String(format: r < 1 ? "%.2f" : "%.1f", r).replacingOccurrences(of: ".", with: ",")
    }
    static func heures(_ h: Double) -> String {
        if h < 1 { return "\(Int((h * 60).rounded())) min" }
        return String(format: "%.1f h", h).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Bilan d'un leurre (fiche leurre)

/// Ce que le journal dit d'un leurre. N'existe que si le leurre a pris (pas de malus).
struct BilanLeurre {
    /// Prises faites pendant un spread où le leurre était monté (base du rendement).
    var prises = 0
    /// Prises du leurre sans spread enregistré à ce moment-là.
    var horsEffort = 0
    var heures: Double = 0
    var especes: [(nom: String, nombre: Int)] = []
    var meilleurMoment: LigneRendement?
    var meilleureMaree: LigneRendement?
    var meilleureZone: LigneRendement?
    var meilleurPoste: LigneRendement?
    var dernierePrise: Date?
    /// Plus gros poisson pris : « Wahoo, 12,4 kg ».
    var plusGros: String?

    var total: Int { prises + horsEffort }
    var rendement: Double? { heures >= LigneRendement.heuresMinimum ? Double(prises) / heures : nil }
    var echantillonFaible: Bool { heures < LigneRendement.heuresSolides }
}

extension StatistiquesCalcul {

    static func bilanLeurre(id: Int, sorties: [StatSortie], marees: [CabaigneDay]) -> BilanLeurre? {
        guard sorties.contains(where: { $0.prises.contains { $0.leurreID == id } }) else { return nil }
        var b = BilanLeurre()
        var cacheSoleil: [String: (Date, Date)] = [:]
        var cacheLune: [String: PhaseLunaire] = [:]
        var h: [String: [String: Double]] = [:], p: [String: [String: Int]] = [:]
        var especes: [String: Int] = [:]
        var record: (poids: Double, texte: String)?, recordTaille: (taille: Double, texte: String)?

        func cles(_ k: ClassementInstant, poste: PositionSpread?) -> [(String, String)] {
            var r: [(String, String)] = [("Moment", libelle(k.moment)), ("Poste", libelle(poste))]
            if let m = k.maree { r.append(("Marée", libelle(m))) }
            if let z = k.zone { r.append(("Zone", libelle(z))) }
            return r
        }

        for s in sorties {
            let tr = tranches(s)
            let facteur = facteurPeche(s, tranches: tr)
            for t in tr {
                guard let ligne = t.spread.lignes.first(where: { $0.leurreID == id }) else { continue }
                var debut = t.debut
                while debut < t.fin {
                    let fin = min(t.fin, debut.addingTimeInterval(pas))
                    let duree = fin.timeIntervalSince(debut) / 3600 * facteur
                    let k = classer(debut.addingTimeInterval(fin.timeIntervalSince(debut) / 2), conditions: s.conditions,
                                    marees: marees, cacheSoleil: &cacheSoleil, cacheLune: &cacheLune)
                    b.heures += duree
                    for (f, v) in cles(k, poste: ligne.position) { h[f, default: [:]][v, default: 0] += duree }
                    debut = fin
                }
            }
            for pr in s.prises where pr.leurreID == id {
                especes[pr.especeNom, default: 0] += 1
                if b.dernierePrise.map({ pr.heure > $0 }) ?? true { b.dernierePrise = pr.heure }
                if let w = pr.poidsKg, w > 0, w > (record?.poids ?? 0) {
                    record = (w, "\(pr.especeNom), " + String(format: "%.1f kg", w).replacingOccurrences(of: ".", with: ","))
                }
                if let t = pr.tailleCm, t > 0, t > (recordTaille?.taille ?? 0) {
                    recordTaille = (t, "\(pr.especeNom), \(Int(t)) cm")
                }
                if let t = tr.first(where: { pr.heure >= $0.debut && pr.heure <= $0.fin }),
                   let ligne = t.spread.lignes.first(where: { $0.leurreID == id }) {
                    b.prises += 1
                    let k = classer(pr.heure, conditions: pr.conditions ?? s.conditions, marees: marees,
                                    cacheSoleil: &cacheSoleil, cacheLune: &cacheLune)
                    for (f, v) in cles(k, poste: ligne.position) { p[f, default: [:]][v, default: 0] += 1 }
                } else {
                    b.horsEffort += 1
                }
            }
        }
        b.especes = especes.map { (nom: $0.key, nombre: $0.value) }
            .sorted { $0.nombre == $1.nombre ? $0.nom < $1.nom : $0.nombre > $1.nombre }
        b.meilleurMoment = meilleur(espece: p["Moment"], effort: h["Moment"])
        b.meilleureMaree = meilleur(espece: p["Marée"], effort: h["Marée"])
        b.meilleureZone = meilleur(espece: p["Zone"], effort: h["Zone"])
        b.meilleurPoste = meilleur(espece: p["Poste"], effort: h["Poste"])
        b.plusGros = record?.texte ?? recordTaille?.texte
        return b
    }
}
