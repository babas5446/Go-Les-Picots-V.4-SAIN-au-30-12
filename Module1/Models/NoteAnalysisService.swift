//
//  NoteAnalysisService.swift
//  Go les Picots
//
//  Lecture des notes personnelles d'un leurre.
//
//  V4.2 (octobre 2026) — règles de déduction, version 2 :
//  1. Lignes repères. Seules les lignes qui commencent par un mot repère
//     suivi de « : » priment sur le calcul automatique :
//        Espèces : thazard, bonite, carangue
//        Zones : lagon, passe
//        Postes : long corner, centre
//        Ventre : orange
//     Majuscules et accents indifférents ; séparateurs « , », « ; », « et ».
//  2. Texte libre (tout le reste des notes) : lu pour les espèces seulement,
//     par mots entiers (« GT » seul, « passe » jamais dans « dépasse »).
//     Il ne fournit plus ni zones ni postes.
//  3. Les noms saisis sont traduits vers les libellés de l'énumération Espece ;
//     un nom d'espèce inconnu est gardé tel quel.
//
//  Created: 2024-12-23
//

import Foundation

// MARK: - Lignes repères

struct LignesReperes: Equatable {
    /// nil : pas de ligne « Espèces : » (ou ligne vide).
    var especes: [String]?
    var zones: [Zone]?
    var postes: [PositionSpread]?
    /// Texte brut de la ligne « Ventre : ».
    var ventre: String?
    /// Mots de zones ou de postes non reconnus (ignorés, signalés).
    var motsInconnus: [String] = []

    var estVide: Bool { especes == nil && zones == nil && postes == nil && ventre == nil }
}

class NoteAnalysisService {

    // MARK: - Normalisation

    /// Minuscules, sans accents, apostrophes typographiques remplacées.
    static func normaliser(_ texte: String) -> String {
        texte
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
            .lowercased()
            .replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "œ", with: "oe")
    }

    /// Mots entiers (lettres et chiffres) d'un texte normalisé.
    static func mots(_ texte: String) -> [String] {
        normaliser(texte)
            .split(whereSeparator: { !($0.isLetter || $0.isNumber) })
            .map(String.init)
    }

    /// Un mot du texte correspond au mot du vocabulaire, au pluriel près.
    private static func correspond(_ mot: String, _ motif: String) -> Bool {
        mot == motif || mot == motif + "s" || mot == motif + "x"
    }

    // MARK: - Vocabulaire

    /// Espèces : du plus précis au plus général (l'ordre compte).
    static let vocabulaireEspeces: [(motifs: [String], espece: Espece)] = [
        (["thazard batard", "thazard du large"],                        .thazardBatard),
        (["thazard", "thazard raye", "thazard commun"],                   .thazard),
        (["thon obese", "patudo", "big eye", "bigeye"],                   .thonObese),
        (["thon a dents de chien", "thon dents de chien", "dents de chien", "dogtooth", "gymnosarda"], .thonDentsDeChien),
        (["thon jaune", "albacore", "yellowfin", "thon"],                 .thonJaune),
        (["wahoo", "wahou"],                                              .wahoo),
        (["bonite", "listao"],                                            .bonite),
        (["mahi mahi", "dorade coryphene", "coryphene", "mahi", "dorado"], .mahiMahi),
        (["marlin"],                                                      .marlin),
        (["espadon voilier", "voilier"],                                  .voilier),
        (["carangue gt", "carangue ignobilis", "ignobilis", "gt", "g t"], .carangueGT),
        (["carangue bleue"],                                              .carangueBleue),
        (["carangue"],                                                    .carangue),
        (["barracuda"],                                                   .barracuda),
        (["becune"],                                                      .becune),
        (["loche pintade"],                                               .lochePintade),
        (["loche saumonee", "loche"],                                     .loche),
        (["merou"],                                                       .merou),
        (["seriole", "amberjack", "kingfish"],                            .seriole),
        (["vivaneau chien rouge", "chien rouge"],                         .vivaneauChienRouge),
        (["vivaneau queue noire", "queue noire"],                         .vivaneauQueueNoire),
        (["vivaneau rouge"],                                              .vivaneauRouge),
        (["empereur"],                                                    .empereur),
        (["bec de cane"],                                                 .becDeCane),
        (["coureur arc en ciel", "arc en ciel", "coureur"],               .coureurArcEnCiel)
    ]

    static let vocabulaireZones: [(motifs: [String], zones: [Zone])] = [
        (["lagon"],                                [.lagon]),
        (["recif", "platier", "pate", "pates"],    [.recif]),
        (["passe"],                                [.passe]),
        (["large", "hauturier", "haute mer"],      [.large]),
        (["dcp"],                                  [.dcp]),
        (["tombant"],                              [.tombant]),
        (["profond"],                              [.profond])
    ]

    static let vocabulairePostes: [(motifs: [String], postes: [PositionSpread])] = [
        (["short corner", "shortcorner", "corner court"],              [.shortCorner]),
        (["long corner", "longcorner", "corner long"],                 [.longCorner]),
        (["centre", "shotgun", "shot gun"],                            [.shotgun]),
        (["tangon court", "short rigger", "shortrigger"],              [.shortRigger]),
        (["tangon long", "long rigger", "longrigger"],                 [.longRigger]),
        (["tangon", "rigger"],                                         [.shortRigger, .longRigger]),
        (["corner"],                                                   [.shortCorner, .longCorner]),
        (["libre"],                                                    [.libre])
    ]

    /// Trouve l'entrée du vocabulaire dont un motif couvre exactement l'élément saisi.
    private static func traduire<T>(_ element: String, dans vocabulaire: [(motifs: [String], valeur: T)]) -> T? {
        let m = mots(element)
        guard !m.isEmpty else { return nil }
        for entree in vocabulaire {
            for motif in entree.motifs {
                let mm = motif.split(separator: " ").map(String.init)
                if mm.count == m.count && zip(m, mm).allSatisfy({ correspond($0, $1) }) {
                    return entree.valeur
                }
            }
        }
        return nil
    }

    /// Nom d'espèce de l'app pour un mot saisi, ou nil s'il est inconnu.
    static func traduireEspece(_ element: String) -> String? {
        traduire(element, dans: vocabulaireEspeces.map { ($0.motifs, $0.espece) })?.displayName
    }

    // MARK: - Lecture des lignes repères

    private enum Repere { case especes, zones, postes, ventre }

    /// Mot repère en début de ligne, suivi de « : ». Renvoie le repère et la valeur.
    private static func repere(de ligne: String) -> (Repere, String)? {
        guard let deuxPoints = ligne.firstIndex(of: ":") else { return nil }
        let cle = normaliser(String(ligne[..<deuxPoints])).trimmingCharacters(in: .whitespaces)
        let valeur = String(ligne[ligne.index(after: deuxPoints)...]).trimmingCharacters(in: .whitespaces)
        switch cle {
        case "espece", "especes", "espece cible", "especes cibles":
                                                     return (.especes, valeur)
        case "zone", "zones":                        return (.zones, valeur)
        case "poste", "postes":                      return (.postes, valeur)
        case "ventre":                               return (.ventre, valeur)
        default:                                     return nil
        }
    }

    /// Découpe une valeur sur « , », « ; » et le mot « et ».
    static func elements(_ valeur: String) -> [String] {
        valeur
            .components(separatedBy: CharacterSet(charactersIn: ",;"))
            .flatMap { $0.components(separatedBy: " et ") }
            .flatMap { $0.components(separatedBy: " ET ") }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines.union(CharacterSet(charactersIn: ".!"))) }
            .filter { !$0.isEmpty }
    }

    static func lireLignesReperes(dans notes: String?) -> LignesReperes {
        var r = LignesReperes()
        guard let notes, !notes.isEmpty else { return r }

        for ligne in notes.components(separatedBy: .newlines) {
            guard let (cle, valeur) = repere(de: ligne.trimmingCharacters(in: .whitespaces)) else { continue }
            let items = elements(valeur)
            switch cle {
            case .especes:
                guard !items.isEmpty else { continue }
                var liste = r.especes ?? []
                for item in items {
                    // Un nom inconnu est gardé tel quel (première lettre en capitale).
                    let nom = traduireEspece(item) ?? (item.prefix(1).uppercased() + item.dropFirst())
                    if !liste.contains(nom) { liste.append(nom) }
                }
                r.especes = liste
            case .zones:
                guard !items.isEmpty else { continue }
                var liste = r.zones ?? []
                for item in items {
                    if let zs = traduire(item, dans: vocabulaireZones.map { ($0.motifs, $0.zones) }) {
                        for z in zs where !liste.contains(z) { liste.append(z) }
                    } else {
                        r.motsInconnus.append(item)
                    }
                }
                if !liste.isEmpty { r.zones = liste }
            case .postes:
                guard !items.isEmpty else { continue }
                var liste = r.postes ?? []
                for item in items {
                    if let ps = traduire(item, dans: vocabulairePostes.map { ($0.motifs, $0.postes) }) {
                        for p in ps where !liste.contains(p) { liste.append(p) }
                    } else {
                        r.motsInconnus.append(item)
                    }
                }
                if !liste.isEmpty { r.postes = liste }
            case .ventre:
                if !valeur.isEmpty { r.ventre = valeur }
            }
        }
        return r
    }

    /// Notes sans les lignes repères.
    static func texteLibre(_ notes: String?) -> String {
        guard let notes else { return "" }
        return notes
            .components(separatedBy: .newlines)
            .filter { repere(de: $0.trimmingCharacters(in: .whitespaces)) == nil }
            .joined(separator: "\n")
    }

    // MARK: - Espèces du texte libre (mots entiers)

    /// Espèces citées dans le texte libre des notes (hors lignes repères),
    /// par mots entiers, avec les libellés de l'énumération Espece.
    static func detecterEspeces(dans texte: String) -> [String] {
        let m = mots(texteLibre(texte))
        guard !m.isEmpty else { return [] }
        var pris = [Bool](repeating: false, count: m.count)
        var especes: [String] = []

        // Du plus précis au plus général : un mot déjà rattaché à
        // « thazard bâtard » ne compte plus pour « thazard ».
        for entree in vocabulaireEspeces {
            let motifs = entree.motifs
                .map { $0.split(separator: " ").map(String.init) }
                .sorted { $0.count > $1.count }
            for motif in motifs where motif.count <= m.count {
                var i = 0
                while i + motif.count <= m.count {
                    let fenetre = i..<(i + motif.count)
                    if fenetre.allSatisfy({ !pris[$0] }) &&
                       zip(m[fenetre], motif).allSatisfy({ correspond($0, $1) }) {
                        for k in fenetre { pris[k] = true }
                        let nom = entree.espece.displayName
                        if !especes.contains(nom) { especes.append(nom) }
                        i += motif.count
                    } else {
                        i += 1
                    }
                }
            }
        }
        return especes
    }

    // MARK: - 🎨 Détection Finition (pour enrichissement futur)
    
    /// Analyse une note pour détecter la finition mentionnée
    static func detecterFinition(dans texte: String) -> Finition? {
        let texte = texte.lowercased()
        
        if texte.contains("holographique") || texte.contains("holo") {
            return .holographique
        }
        
        if texte.contains("métallique") || texte.contains("metallique") {
            return .metallique
        }
        
        if texte.contains("mat") || texte.contains("mate") {
            return .mate
        }
        
        if texte.contains("brillant") {
            return .brillante
        }
        
        if texte.contains("perlé") || texte.contains("perle") || texte.contains("nacré") {
            return .perlee
        }
        
        if texte.contains("pailleté") || texte.contains("paillette") || texte.contains("glitter") {
            return .paillete
        }
        
        if texte.contains("uv") {
            return .UV
        }
        
        if texte.contains("phosphorescent") || texte.contains("glow") {
            return .phosphorescent
        }
        
        if texte.contains("chrome") {
            return .chrome
        }
        
        if texte.contains("miroir") {
            return .miroir
        }
        
        return nil
    }
}
