//
//  ConditionsPeche.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Modèle de saisie des conditions de pêche par l'utilisateur
//
//  Created: 2024-12-05
//  Updated: 2024-12-11 (correction .apresMidi)
//

import Foundation

// MARK: - Conditions de Pêche (INPUT utilisateur)

struct ConditionsPeche: Codable, Hashable {
    
    // MARK: - Zone et Technique
    var zone: CategoriePeche
    var profondeurZone: Double              // Profondeur du fond (sondeur) en mètres
    var vitesseBateau: Double               // en nœuds
    
    // MARK: - Environnement Visuel
    var momentJournee: MomentJournee
    var luminosite: Luminosite  // Toujours renseignée (calculée auto si besoin)
    var turbiditeEau: Turbidite
    
    // MARK: - Conditions Marines
    var etatMer: EtatMer
    var typeMaree: TypeMaree  // ✅ Utilise TypeMaree de Leurre.swift (montante/descendante/etale)
    var phaseLunaire: PhaseLunaire
    
    // MARK: - Optionnel
    var especePrioritaire: Espece?
    var nombreLignes: Int = 3                // 1-5 lignes
    var profilBateau: ProfilBateau = .classique  // Profil bateau (classique ou Clark 4,29 m)

    /// true : le moteur choisit la vitesse ; false : vitesse fixée à la main.
    /// Optionnel pour rester lisible par les conditions déjà enregistrées.
    var vitesseLibre: Bool? = nil
    
    // MARK: - Initialisation par défaut (Scénario 1 - Lagon aube)
    static var scenario1LagunAube: ConditionsPeche {
        return ConditionsPeche(
            zone: .lagon,
            profondeurZone: 15.0,  // Lagon profond
            vitesseBateau: 5.0,
            momentJournee: .aube,
            luminosite: .faible,
            turbiditeEau: .claire,
            etatMer: .calme,
            typeMaree: .montante,
            phaseLunaire: .premierQuartier,
            especePrioritaire: .thazard,
            nombreLignes: 3
        )
    }
    
    // MARK: - Validation
    func estValide() -> (Bool, String?) {
        // Profondeur
        if profondeurZone < 0 || profondeurZone > 300 {
            return (false, "Profondeur doit être entre 0-300m")
        }
        
        // Vitesse
        if vitesseBateau < 3 || vitesseBateau > 20 {
            return (false, "Vitesse doit être entre 3-20 nœuds")
        }
        
        // Nombre de lignes
        if nombreLignes < 1 || nombreLignes > 5 {
            return (false, "Nombre de lignes : 1-5")
        }
        
        // Cohérence zone/profondeur
        if zone == .lagon && profondeurZone > 30 {
            return (false, "Profondeur trop importante pour le lagon (max 30m)")
        }
        
        if zone == .profond && profondeurZone < 50 {
            return (false, "Profondeur insuffisante pour zone profonde (min 50m)")
        }
        
        // Cohérence vitesse/zone
        if zone == .lagon && vitesseBateau > 8 {
            return (false, "Vitesse trop élevée pour le lagon (max 8 nœuds)")
        }
        
        return (true, nil)
    }
    
    // MARK: - Description formatée
    var descriptionCourte: String {
        return "\(zone.displayName) • \(momentJournee.displayName) • \(Int(vitesseBateau)) nœuds"
    }
    
    var descriptionComplete: String {
        var desc = """
        Zone : \(zone.displayName)
        Profondeur : \(Int(profondeurZone))m
        Vitesse : \(Int(vitesseBateau)) nœuds
        Moment : \(momentJournee.displayName)
        Luminosité : \(luminosite.displayName)
        Eau : \(turbiditeEau.displayName)
        Mer : \(etatMer.displayName)
        Marée : \(typeMaree.displayName)
        Lune : \(phaseLunaire.displayName)
        """
        
        if let espece = especePrioritaire {
            desc += "\nEspèce : \(espece.displayName)"
        }
        
        desc += "\nLignes : \(nombreLignes)"
        
        return desc
    }
    
    // MARK: - 🎯 Déduction de profondeur de nage
    
    /// Déduit la profondeur de nage optimale selon la profondeur du fond et la zone
    var profondeurNageDeduite: (min: Double, max: Double) {
        switch zone {
        case .lagon:
            if profondeurZone <= 10 {
                // Lagon peu profond : pêche près du fond
                return (max(1.0, profondeurZone - 5), max(2.0, profondeurZone - 1))
            } else {
                // Lagon profond : mi-eau à surface
                return (2.0, min(8.0, profondeurZone / 2))
            }
            
        case .recif:
            // Récif : généralement 3-10m
            return (3.0, min(10.0, max(8.0, profondeurZone - 2)))
            
        case .passe:
            // Passe : couche 5-15m généralement
            return (5.0, min(15.0, profondeurZone - 5))
            
        case .large, .tombant:
            // Large : surface à mi-eau (0-15m)
            return (0.0, 15.0)
            
        case .profond, .dcp:
            // Profond : large plage 5-30m
            return (5.0, min(30.0, profondeurZone / 3))
        }
    }
    
    /// Description textuelle de la profondeur de nage déduite
    var profondeurNageDeduiteDescription: String {
        let (min, max) = profondeurNageDeduite
        let minStr = min == 0 ? "Surface" : "\(Int(min))m"
        let maxStr = "\(Int(max))m"
        
        let contexte: String
        switch zone {
        case .lagon:
            if profondeurZone <= 10 {
                contexte = "lagon peu profond, près du fond"
            } else {
                contexte = "lagon profond, mi-eau"
            }
        case .recif:
            contexte = "récif, au-dessus des structures"
        case .passe:
            contexte = "passe, mi-eau"
        case .large, .tombant:
            contexte = "large, surface à mi-eau"
        case .profond, .dcp:
            contexte = "profond, large couche d'eau"
        }
        
        return "\(minStr)-\(maxStr) (\(contexte))"
    }
}

// MARK: - Extensions pour cohérence automatique

extension ConditionsPeche {
    
    /// Suggère une luminosité automatique selon le moment
    static func luminositeAutoDepuisMoment(_ moment: MomentJournee) -> Luminosite {
        switch moment {
        case .aube, .crepuscule:
            return .faible
        case .matinee, .apresMidi:
            return .diffuse
        case .midi:
            return .forte
        case .nuit:
            return .nuit
        }
    }
    
    /// Vérifie si les conditions sont cohérentes entre elles
    func avertissementsCoherence() -> [String] {
        var avertissements: [String] = []
        
        // Luminosité vs Moment
        if (momentJournee == .aube || momentJournee == .crepuscule) && luminosite == .forte {
            avertissements.append("⚠️ Luminosité forte inhabituelle à l'aube/crépuscule")
        }
        
        if momentJournee == .midi && luminosite == .faible {
            avertissements.append("⚠️ Luminosité faible inhabituelle à midi")
        }
        
        // Turbidité vs Marée
        if typeMaree == .descendante && turbiditeEau == .claire {
            avertissements.append("ℹ️ Eau souvent plus trouble à marée descendante")
        }
        
        // État mer vs Zone
        if zone == .lagon && etatMer == .formee {
            avertissements.append("⚠️ Mer formée inhabituelle en lagon")
        }
        
        // Vitesse vs Espèce
        if let espece = especePrioritaire {
            if espece == .wahoo && vitesseBateau < 10 {
                avertissements.append("⚠️ Wahoo nécessite vitesse > 12 nœuds")
            }
        }
        
        return avertissements
    }
}

// MARK: - Proposition automatique à l'ouverture (moment, luminosité, marée, lune)

/// Conditions proposées à l'ouverture du formulaire, toujours modifiables à la main.
/// - Moment : lever et coucher du soleil (cache des marées, sinon calcul
///   astronomique). Aube et crépuscule couvrent 45 minutes de part et d'autre
///   du lever et du coucher : le passage au jour se fait 45 minutes après le
///   lever, le passage à la nuit 45 minutes après le coucher.
/// - Marée : horaires des pleines et basses mers en cache ; étale à
///   30 minutes ou moins d'une pleine ou basse mer.
/// - Lune : calcul astronomique local, phase la plus proche.
struct PropositionConditions {
    var moment: MomentJournee
    var luminosite: Luminosite
    var maree: TypeMaree?
    var lune: PhaseLunaire
    var explication: String

    static let transitionLumiere: TimeInterval = 45 * 60
    static let etaleMaree: TimeInterval = 30 * 60
    static let latitudeNoumea = -22.2758
    static let longitudeNoumea = 166.4580
    static let fuseau = TimeZone(identifier: "Pacific/Noumea") ?? .current

    /// Moment de la journée d'après le lever et le coucher du soleil.
    static func moment(a date: Date, lever: Date, coucher: Date, fuseau: TimeZone = fuseau) -> MomentJournee {
        let t = transitionLumiere
        if date < lever.addingTimeInterval(-t) || date > coucher.addingTimeInterval(t) { return .nuit }
        if date <= lever.addingTimeInterval(t) { return .aube }
        if date >= coucher.addingTimeInterval(-t) { return .crepuscule }
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = fuseau
        let h = cal.component(.hour, from: date)
        if h < 11 { return .matinee }
        if h < 14 { return .midi }
        return .apresMidi
    }

    /// Sens de la marée à l'instant donné d'après les pleines et basses mers.
    static func maree(a date: Date, evenements: [(heure: Date, haute: Bool)]) -> TypeMaree? {
        let tries = evenements.sorted { $0.heure < $1.heure }
        guard !tries.isEmpty else { return nil }
        if tries.contains(where: { abs($0.heure.timeIntervalSince(date)) <= etaleMaree }) { return .etale }
        if let precedent = tries.last(where: { $0.heure <= date }) {
            return precedent.haute ? .descendante : .montante
        }
        return tries[0].haute ? .montante : .descendante
    }

    /// Phase lunaire la plus proche de l'âge de la lune (cycle de 29,53 jours).
    static func lune(age: Double) -> PhaseLunaire {
        let a = age.truncatingRemainder(dividingBy: 29.530588)
        switch a {
        case ..<3.69:  return .nouvelleLune
        case ..<11.07: return .premierQuartier
        case ..<18.46: return .pleineLune
        case ..<25.84: return .dernierQuartier
        default:       return .nouvelleLune
        }
    }

    /// Lever et coucher du soleil (équations NOAA, précision de quelques minutes).
    static func soleil(jour: Date, latitude: Double = latitudeNoumea, longitude: Double = longitudeNoumea,
                       fuseau: TimeZone = fuseau) -> (lever: Date, coucher: Date)? {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = fuseau
        let c = cal.dateComponents([.year, .month, .day], from: jour)
        guard let n = cal.ordinality(of: .day, in: .year, for: jour) else { return nil }
        let g = 2 * Double.pi / 365 * Double(n - 1)
        let eq = 229.18 * (0.000075 + 0.001868 * cos(g) - 0.032077 * sin(g)
                           - 0.014615 * cos(2 * g) - 0.040849 * sin(2 * g))
        let decl = 0.006918 - 0.399912 * cos(g) + 0.070257 * sin(g) - 0.006758 * cos(2 * g)
                 + 0.000907 * sin(2 * g) - 0.002697 * cos(3 * g) + 0.00148 * sin(3 * g)
        let lat = latitude * .pi / 180
        let cosH = cos(90.833 * .pi / 180) / (cos(lat) * cos(decl)) - tan(lat) * tan(decl)
        guard cosH >= -1 && cosH <= 1 else { return nil }
        let h = acos(cosH) * 180 / .pi
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(identifier: "UTC")!
        guard let minuitUTC = utc.date(from: DateComponents(year: c.year, month: c.month, day: c.day)) else { return nil }
        let lever = minuitUTC.addingTimeInterval((720 - 4 * (longitude + h) - eq) * 60)
        let coucher = minuitUTC.addingTimeInterval((720 - 4 * (longitude - h) - eq) * 60)
        return (lever, coucher)
    }

    /// Proposition complète pour l'instant donné.
    /// - Parameter joursMaree: jours de marée en cache (lever, coucher, pleines et basses mers).
    static func proposer(maintenant: Date = Date(), joursMaree: [CabaigneDay]) -> PropositionConditions {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = fuseau
        let fmt = DateFormatter()
        fmt.timeZone = fuseau
        fmt.dateFormat = "HH:mm"

        // Soleil : horaires du jour en cache, sinon calcul.
        let jour = joursMaree.first { cal.isDate($0.date, inSameDayAs: maintenant) }
        var lever = jour?.sunrise
        var coucher = jour?.sunset
        if lever == nil || coucher == nil, let s = soleil(jour: maintenant) {
            lever = lever ?? s.lever
            coucher = coucher ?? s.coucher
        }
        let m: MomentJournee
        var morceaux: [String] = []
        if let lever, let coucher {
            m = moment(a: maintenant, lever: lever, coucher: coucher)
            morceaux.append("\(m.libelleCourt) (lever \(fmt.string(from: lever)), coucher \(fmt.string(from: coucher)))")
        } else {
            m = .matinee
            morceaux.append("moment à choisir")
        }

        // Marée : événements d'hier, d'aujourd'hui et de demain.
        let evenements = joursMaree
            .filter { abs($0.date.timeIntervalSince(maintenant)) < 2 * 86_400 }
            .flatMap { $0.events }
            .map { (heure: $0.time, haute: $0.isHigh) }
        let mar = maree(a: maintenant, evenements: evenements)
        if let mar {
            var texte = "marée \(mar == .etale ? "étale" : mar.displayName.lowercased())"
            if let suivant = evenements.sorted(by: { $0.heure < $1.heure }).first(where: { $0.heure > maintenant }) {
                texte += " (\(suivant.haute ? "PM" : "BM") \(fmt.string(from: suivant.heure)))"
            }
            morceaux.append(texte)
        } else {
            morceaux.append("marée à choisir (pas d'horaires en cache)")
        }

        // Lune.
        let age = SolunarCalculator.moonPhaseData(jde: SolunarCalculator.julianEphemerisDay(from: maintenant)).age
        let l = lune(age: age)
        morceaux.append(l.displayName.lowercased())

        return PropositionConditions(
            moment: m,
            luminosite: ConditionsPeche.luminositeAutoDepuisMoment(m),
            maree: mar,
            lune: l,
            explication: "Proposé à \(fmt.string(from: maintenant)) : " + morceaux.joined(separator: ", ") + ". Modifiable à la main."
        )
    }
}

extension MomentJournee {
    /// Libellé sans les heures indicatives.
    var libelleCourt: String {
        switch self {
        case .aube:       return "aube"
        case .matinee:    return "matinée"
        case .midi:       return "midi"
        case .apresMidi:  return "après-midi"
        case .crepuscule: return "crépuscule"
        case .nuit:       return "nuit"
        }
    }
}
