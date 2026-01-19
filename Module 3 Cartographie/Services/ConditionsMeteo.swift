//
//  ConditionsMeteo.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Modèle représentant les conditions météorologiques
//

import Foundation

/// Conditions météorologiques complètes pour une sortie de pêche
struct ConditionsMeteo: Codable {
    // MARK: - Vent
    let forceVent: Int?  // nœuds
    let directionVent: DirectionVent?
    
    // MARK: - Mer
    let etatMer: EtatMer?  // ✅ Utilise l'enum de Leurre.swift
    let hauteurHoule: Double?  // mètres
    
    // MARK: - Visibilité
    let visibilite: Visibilite?
    
    // MARK: - Marée
    let coefficientMaree: Int?  // 20-120
    let phaseMaree: PhaseMaree?  // ✅ Utilise l'enum de Leurre.swift
    let heureMareeHaute: Date?
    let heureMareeBasse: Date?
    
    // MARK: - Température
    let temperatureAir: Double?  // °C
    let temperatureEau: Double?  // °C
    
    // MARK: - Pression
    let pressionAtmospherique: Double?  // hPa
    
    // MARK: - Computed Properties
    
    /// Force du vent formatée
    var forceVentFormatee: String? {
        guard let force = forceVent else { return nil }
        return "\(force) kts"
    }
    
    /// Vent complet formaté (ex: "15 kts NE")
    var ventComplet: String? {
        guard let force = forceVent else { return nil }
        let direction = directionVent?.displayName ?? ""
        return "\(force) kts \(direction)"
    }
    
    /// Température air formatée
    var temperatureAirFormatee: String? {
        guard let temp = temperatureAir else { return nil }
        return String(format: "%.1f°C", temp)
    }
    
    /// Température eau formatée
    var temperatureEauFormatee: String? {
        guard let temp = temperatureEau else { return nil }
        return String(format: "%.1f°C", temp)
    }
    
    /// Coefficient marée formaté
    var coefficientFormate: String? {
        guard let coef = coefficientMaree else { return nil }
        return "\(coef)"
    }
    
    /// Hauteur houle formatée
    var hauteurHouleFormatee: String? {
        guard let hauteur = hauteurHoule else { return nil }
        return String(format: "%.1f m", hauteur)
    }
    
    /// Indique si conditions favorables à la pêche
    var conditionsFavorables: Bool {
        // Conditions idéales : vent <15kts, mer calme, bonne visibilité
        guard let vent = forceVent,
              let mer = etatMer,
              let vis = visibilite else { return false }
        
        return vent < 15 &&
               (mer == .calme || mer == .peuAgitee) &&
               (vis == .excellente || vis == .bonne)
    }
    
    // MARK: - Initializer
    init(
        forceVent: Int? = nil,
        directionVent: DirectionVent? = nil,
        etatMer: EtatMer? = nil,
        hauteurHoule: Double? = nil,
        visibilite: Visibilite? = nil,
        coefficientMaree: Int? = nil,
        phaseMaree: PhaseMaree? = nil,
        heureMareeHaute: Date? = nil,
        heureMareeBasse: Date? = nil,
        temperatureAir: Double? = nil,
        temperatureEau: Double? = nil,
        pressionAtmospherique: Double? = nil
    ) {
        self.forceVent = forceVent
        self.directionVent = directionVent
        self.etatMer = etatMer
        self.hauteurHoule = hauteurHoule
        self.visibilite = visibilite
        self.coefficientMaree = coefficientMaree
        self.phaseMaree = phaseMaree
        self.heureMareeHaute = heureMareeHaute
        self.heureMareeBasse = heureMareeBasse
        self.temperatureAir = temperatureAir
        self.temperatureEau = temperatureEau
        self.pressionAtmospherique = pressionAtmospherique
    }
}

// MARK: - Direction Vent
enum DirectionVent: String, Codable, CaseIterable {
    case nord = "N"
    case nordEst = "NE"
    case est = "E"
    case sudEst = "SE"
    case sud = "S"
    case sudOuest = "SO"
    case ouest = "O"
    case nordOuest = "NO"
    
    var displayName: String { rawValue }
    
    var degrees: Double {
        switch self {
        case .nord: return 0
        case .nordEst: return 45
        case .est: return 90
        case .sudEst: return 135
        case .sud: return 180
        case .sudOuest: return 225
        case .ouest: return 270
        case .nordOuest: return 315
        }
    }
}

// MARK: - Visibilité
enum Visibilite: String, Codable, CaseIterable {
    case excellente = "Excellente"
    case bonne = "Bonne"
    case moyenne = "Moyenne"
    case médiocre = "Médiocre"
    
    var displayName: String { rawValue }
    
    var description: String {
        switch self {
        case .excellente: return "> 10 km"
        case .bonne: return "5-10 km"
        case .moyenne: return "2-5 km"
        case .médiocre: return "< 2 km"
        }
    }
}

// MARK: - Sample Data
extension ConditionsMeteo {
    static let bonnesConditions = ConditionsMeteo(
        forceVent: 10,
        directionVent: .sudEst,
        etatMer: .peuAgitee,
        hauteurHoule: 0.3,
        visibilite: .bonne,
        coefficientMaree: 65,
        phaseMaree: .montante,
        temperatureAir: 28.0,
        temperatureEau: 25.5,
        pressionAtmospherique: 1015.0
    )
    
    static let conditionsMoyennes = ConditionsMeteo(
        forceVent: 18,
        directionVent: .est,
        etatMer: .agitee,
        hauteurHoule: 0.8,
        visibilite: .moyenne,
        coefficientMaree: 45,
        phaseMaree: .descendante,
        temperatureAir: 26.0,
        temperatureEau: 24.0,
        pressionAtmospherique: 1012.0
    )
}
