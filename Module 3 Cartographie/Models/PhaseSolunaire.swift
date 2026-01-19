//
//  PhaseSolunaire.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Modèle représentant les phases lunaires et périodes d'activité des poissons
//

import Foundation

/// Phases lunaires et solunaires pour optimiser les sorties de pêche
struct PhaseSolunaire: Codable {
    // MARK: - Phase lunaire
    let phaseLune: PhaseLune
    let pourcentageIllumination: Double  // 0-100
    
    // MARK: - Horaires solaires
    let leverSoleil: Date
    let coucherSoleil: Date
    let leverLune: Date?
    let coucherLune: Date?
    
    // MARK: - Périodes d'activité (théorie solunaire)
    let periodesMajeures: [PeriodeActivite]  // 2 par jour (passages lune au zénith/nadir)
    let periodesMineurs: [PeriodeActivite]  // 2 par jour (lever/coucher lune)
    
    // MARK: - Computed Properties
    
    /// Indice qualité du jour pour la pêche (0-100)
    var indiceQualite: Int {
        var score = 0
        
        // Phase lunaire (poids : 40%)
        switch phaseLune {
        case .nouvelleLune, .pleineLune:
            score += 40  // meilleures phases
        case .premierQuartier, .dernierQuartier:
            score += 30
        default:
            score += 20
        }
        
        // Pourcentage illumination (poids : 20%)
        if pourcentageIllumination > 80 || pourcentageIllumination < 20 {
            score += 20  // extrêmes favorables
        } else {
            score += 10
        }
        
        // Nombre périodes majeures (poids : 40%)
        score += min(periodesMajeures.count * 20, 40)
        
        return min(score, 100)
    }
    
    /// Qualité sous forme de texte
    var qualiteJour: String {
        switch indiceQualite {
        case 80...100: return "Excellente"
        case 60..<80: return "Très bonne"
        case 40..<60: return "Bonne"
        case 20..<40: return "Moyenne"
        default: return "Faible"
        }
    }
    
    /// Emoji qualité jour
    var emojiQualite: String {
        switch indiceQualite {
        case 80...100: return "🌟"
        case 60..<80: return "⭐️"
        case 40..<60: return "✨"
        default: return "💫"
        }
    }
    
    /// Durée du jour (heures)
    var dureeDuJour: TimeInterval {
        coucherSoleil.timeIntervalSince(leverSoleil)
    }
    
    /// Durée du jour formatée
    var dureeDuJourFormatee: String {
        let heures = Int(dureeDuJour / 3600)
        let minutes = Int((dureeDuJour.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(heures)h \(minutes)min"
    }
    
    /// Période majeure en cours ou à venir
    func prochainePeriodeMajeure(from date: Date = Date()) -> PeriodeActivite? {
        periodesMajeures.first { $0.heureDebut > date }
    }
    
    /// Période mineure en cours ou à venir
    func prochainePeriodeMineure(from date: Date = Date()) -> PeriodeActivite? {
        periodesMineurs.first { $0.heureDebut > date }
    }
    
    /// Vérifie si on est dans une période d'activité
    func estEnPeriodeActivite(date: Date = Date()) -> Bool {
        let toutesLesPeriodes = periodesMajeures + periodesMineurs
        return toutesLesPeriodes.contains { periode in
            date >= periode.heureDebut && date <= periode.heureFin
        }
    }
    
    // MARK: - Initializer
    init(
        phaseLune: PhaseLune,
        pourcentageIllumination: Double,
        leverSoleil: Date,
        coucherSoleil: Date,
        leverLune: Date? = nil,
        coucherLune: Date? = nil,
        periodesMajeures: [PeriodeActivite] = [],
        periodesMineurs: [PeriodeActivite] = []
    ) {
        self.phaseLune = phaseLune
        self.pourcentageIllumination = pourcentageIllumination
        self.leverSoleil = leverSoleil
        self.coucherSoleil = coucherSoleil
        self.leverLune = leverLune
        self.coucherLune = coucherLune
        self.periodesMajeures = periodesMajeures
        self.periodesMineurs = periodesMineurs
    }
}

// MARK: - Phase Lune
enum PhaseLune: String, Codable, CaseIterable {
    case nouvelleLune = "Nouvelle lune"
    case premierCroissant = "Premier croissant"
    case premierQuartier = "Premier quartier"
    case gibbeuseCroissante = "Gibbeuse croissante"
    case pleineLune = "Pleine lune"
    case gibbeuseDecroissante = "Gibbeuse décroissante"
    case dernierQuartier = "Dernier quartier"
    case dernierCroissant = "Dernier croissant"
    
    var displayName: String { rawValue }
    
    var emoji: String {
        switch self {
        case .nouvelleLune: return "🌑"
        case .premierCroissant: return "🌒"
        case .premierQuartier: return "🌓"
        case .gibbeuseCroissante: return "🌔"
        case .pleineLune: return "🌕"
        case .gibbeuseDecroissante: return "🌖"
        case .dernierQuartier: return "🌗"
        case .dernierCroissant: return "🌘"
        }
    }
    
    var description: String {
        switch self {
        case .nouvelleLune: return "Activité maximale - lune invisible"
        case .pleineLune: return "Activité maximale - lune pleine"
        case .premierQuartier, .dernierQuartier: return "Bonne activité"
        default: return "Activité modérée"
        }
    }
}

// MARK: - Période Activité
struct PeriodeActivite: Codable {
    let type: TypePeriode
    let heureDebut: Date
    let heureFin: Date
    
    /// Durée de la période
    var duree: TimeInterval {
        heureFin.timeIntervalSince(heureDebut)
    }
    
    /// Durée formatée
    var dureeFormatee: String {
        let minutes = Int(duree / 60)
        return "\(minutes) min"
    }
    
    /// Heure début formatée
    var heureDebutFormatee: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: heureDebut)
    }
    
    /// Heure fin formatée
    var heureFinFormatee: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: heureFin)
    }
    
    /// Période complète formatée (ex: "08:30 - 10:30")
    var periodeFormatee: String {
        "\(heureDebutFormatee) - \(heureFinFormatee)"
    }
}

// MARK: - Type Période
enum TypePeriode: String, Codable {
    case majeure = "Majeure"
    case mineure = "Mineure"
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .majeure: return "Durée ~2h - Activité maximale"
        case .mineure: return "Durée ~1h - Bonne activité"
        }
    }
    
    var emoji: String {
        switch self {
        case .majeure: return "🔥"
        case .mineure: return "⚡️"
        }
    }
}

// MARK: - Sample Data
extension PhaseSolunaire {
    static let samplePleineLune: PhaseSolunaire = {
        let maintenant = Date()
        let calendar = Calendar.current
        
        let leverSoleil = calendar.date(bySettingHour: 6, minute: 0, second: 0, of: maintenant)!
        let coucherSoleil = calendar.date(bySettingHour: 18, minute: 30, second: 0, of: maintenant)!
        
        let periode1 = PeriodeActivite(
            type: .majeure,
            heureDebut: calendar.date(bySettingHour: 8, minute: 30, second: 0, of: maintenant)!,
            heureFin: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: maintenant)!
        )
        
        let periode2 = PeriodeActivite(
            type: .majeure,
            heureDebut: calendar.date(bySettingHour: 20, minute: 45, second: 0, of: maintenant)!,
            heureFin: calendar.date(bySettingHour: 22, minute: 45, second: 0, of: maintenant)!
        )
        
        let periode3 = PeriodeActivite(
            type: .mineure,
            heureDebut: calendar.date(bySettingHour: 14, minute: 15, second: 0, of: maintenant)!,
            heureFin: calendar.date(bySettingHour: 15, minute: 15, second: 0, of: maintenant)!
        )
        
        return PhaseSolunaire(
            phaseLune: .pleineLune,
            pourcentageIllumination: 100.0,
            leverSoleil: leverSoleil,
            coucherSoleil: coucherSoleil,
            leverLune: calendar.date(bySettingHour: 18, minute: 0, second: 0, of: maintenant),
            coucherLune: calendar.date(bySettingHour: 6, minute: 30, second: 0, of: maintenant),
            periodesMajeures: [periode1, periode2],
            periodesMineurs: [periode3]
        )
    }()
}
