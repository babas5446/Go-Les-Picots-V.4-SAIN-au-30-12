//
//  MarineModels.swift
//  Go Les Picots V.4
//
//  Modèles de données marines partagés entre services
//  TOUTES les structures sont Codable pour le cache
//

import Foundation

// MARK: - Marine Data

struct MarineData: Identifiable, Codable {
    let id: UUID
    
    let windSpeed: Double
    let windDirection: Double
    let gust: Double?
    
    let airTemperature: Double
    let waterTemperature: Double?
    
    let waveHeight: Double?
    let wavePeriod: Double?
    let waveDirection: Double?
    let swellHeight: Double?
    let swellPeriod: Double?
    let swellDirection: Double?
    
    let currentSpeed: Double?
    let currentDirection: Double?
    
    let pressure: Double?
    let visibility: Double?
    let humidity: Double?
    
    let precipitation: Double?
    let cloudCover: Double?
    
    let timestamp: Date
    
    // Ignore 'id' dans Codable
    enum CodingKeys: String, CodingKey {
        case windSpeed, windDirection, gust
        case airTemperature, waterTemperature
        case waveHeight, wavePeriod, waveDirection
        case swellHeight, swellPeriod, swellDirection
        case currentSpeed, currentDirection
        case pressure, visibility, humidity
        case precipitation, cloudCover
        case timestamp
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.windSpeed = try container.decode(Double.self, forKey: .windSpeed)
        self.windDirection = try container.decode(Double.self, forKey: .windDirection)
        self.gust = try container.decodeIfPresent(Double.self, forKey: .gust)
        self.airTemperature = try container.decode(Double.self, forKey: .airTemperature)
        self.waterTemperature = try container.decodeIfPresent(Double.self, forKey: .waterTemperature)
        self.waveHeight = try container.decodeIfPresent(Double.self, forKey: .waveHeight)
        self.wavePeriod = try container.decodeIfPresent(Double.self, forKey: .wavePeriod)
        self.waveDirection = try container.decodeIfPresent(Double.self, forKey: .waveDirection)
        self.swellHeight = try container.decodeIfPresent(Double.self, forKey: .swellHeight)
        self.swellPeriod = try container.decodeIfPresent(Double.self, forKey: .swellPeriod)
        self.swellDirection = try container.decodeIfPresent(Double.self, forKey: .swellDirection)
        self.currentSpeed = try container.decodeIfPresent(Double.self, forKey: .currentSpeed)
        self.currentDirection = try container.decodeIfPresent(Double.self, forKey: .currentDirection)
        self.pressure = try container.decodeIfPresent(Double.self, forKey: .pressure)
        self.visibility = try container.decodeIfPresent(Double.self, forKey: .visibility)
        self.humidity = try container.decodeIfPresent(Double.self, forKey: .humidity)
        self.precipitation = try container.decodeIfPresent(Double.self, forKey: .precipitation)
        self.cloudCover = try container.decodeIfPresent(Double.self, forKey: .cloudCover)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
    }
    
    init(windSpeed: Double, windDirection: Double, gust: Double?, airTemperature: Double, waterTemperature: Double?, waveHeight: Double?, wavePeriod: Double?, waveDirection: Double?, swellHeight: Double?, swellPeriod: Double?, swellDirection: Double?, currentSpeed: Double?, currentDirection: Double?, pressure: Double?, visibility: Double?, humidity: Double?, precipitation: Double?, cloudCover: Double?, timestamp: Date) {
        self.id = UUID()
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.gust = gust
        self.airTemperature = airTemperature
        self.waterTemperature = waterTemperature
        self.waveHeight = waveHeight
        self.wavePeriod = wavePeriod
        self.waveDirection = waveDirection
        self.swellHeight = swellHeight
        self.swellPeriod = swellPeriod
        self.swellDirection = swellDirection
        self.currentSpeed = currentSpeed
        self.currentDirection = currentDirection
        self.pressure = pressure
        self.visibility = visibility
        self.humidity = humidity
        self.precipitation = precipitation
        self.cloudCover = cloudCover
        self.timestamp = timestamp
    }
}

// MARK: - Astronomy Data

struct AstronomyData: Codable {
    let sunrise: Date
    let sunset: Date
    let moonrise: Date
    let moonset: Date
    let moonPhase: Double
    let moonIllumination: Double
}

// MARK: - Tide Event

struct TideEvent: Codable {
    let time: Date
    let height: Double
    let type: String  // "high" ou "low"
}

// MARK: - Extensions (Computed Properties)

extension MarineData {
    var windSpeedKnots: Int { Int(windSpeed * 1.944) }
    var gustKnots: Int? { gust.map { Int($0 * 1.944) } }
    var windDirectionText: String {
        let dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
        return dirs[Int((windDirection + 22.5) / 45.0) % 8]
    }
    var windFormatted: String {
        if let g = gustKnots { return "\(windSpeedKnots) kts (\(g)) \(windDirectionText)" }
        return "\(windSpeedKnots) kts \(windDirectionText)"
    }
    var airTemperatureFormatted: String { String(format: "%.1f°C", airTemperature) }
    var waterTemperatureFormatted: String? { waterTemperature.map { String(format: "%.1f°C", $0) } }
    var seaState: String {
        guard let h = waveHeight else { return "N/A" }
        switch h {
        case ..<0.1: return "Calme"
        case 0.1..<0.5: return "Belle"
        case 0.5..<1.25: return "Peu agitée"
        case 1.25..<2.5: return "Agitée"
        case 2.5..<4.0: return "Forte"
        default: return "Très forte"
        }
    }
    var waveFormatted: String? {
        guard let h = waveHeight else { return nil }
        if let p = wavePeriod { return String(format: "%.1fm / %.0fs", h, p) }
        return String(format: "%.1fm", h)
    }
    var swellFormatted: String? {
        guard let h = swellHeight else { return nil }
        if let p = swellPeriod { return String(format: "%.1fm / %.0fs", h, p) }
        return String(format: "%.1fm", h)
    }
    var currentFormatted: String? {
        guard let s = currentSpeed else { return nil }
        let kts = Int(s * 1.944)
        if let d = currentDirection {
            let dirs = ["N", "NE", "E", "SE", "S", "SO", "O", "NO"]
            return "\(kts) kts \(dirs[Int((d + 22.5) / 45.0) % 8])"
        }
        return "\(kts) kts"
    }
    var visibilityFormatted: String {
        guard let v = visibility else { return "N/A" }
        if v > 10 { return "Excellente (>\(Int(v))km)" }
        if v > 5 { return "Bonne (\(Int(v))km)" }
        if v > 2 { return "Moyenne (\(Int(v))km)" }
        return "Médiocre (<\(Int(v))km)"
    }
    var precipitationFormatted: String? {
        guard let p = precipitation else { return nil }
        if p < 0.1 { return "Aucune" }
        if p < 2.5 { return "Faible" }
        if p < 10 { return "Modérée" }
        return "Forte"
    }
    var cloudCoverFormatted: String? {
        guard let c = cloudCover else { return nil }
        if c < 10 { return "Dégagé" }
        if c < 30 { return "Peu nuageux" }
        if c < 70 { return "Nuageux" }
        return "Très nuageux"
    }
    var pressureFormatted: String? { pressure.map { String(format: "%.0f hPa", $0) } }
    var humidityFormatted: String? { humidity.map { String(format: "%.0f%%", $0) } }
    var isFavorable: Bool {
        windSpeedKnots < 15 && (visibility ?? 0) > 5 && (waveHeight ?? 0) < 1.25
    }
}

extension AstronomyData {
    var moonPhaseName: String {
        switch moonPhase {
        case 0..<0.0625, 0.9375...1.0: return "Nouvelle lune"
        case 0.0625..<0.1875: return "Premier croissant"
        case 0.1875..<0.3125: return "Premier quartier"
        case 0.3125..<0.4375: return "Gibbeuse croissante"
        case 0.4375..<0.5625: return "Pleine lune"
        case 0.5625..<0.6875: return "Gibbeuse décroissante"
        case 0.6875..<0.8125: return "Dernier quartier"
        default: return "Dernier croissant"
        }
    }
    var moonEmoji: String {
        switch moonPhase {
        case 0..<0.0625, 0.9375...1.0: return "🌑"
        case 0.0625..<0.1875: return "🌒"
        case 0.1875..<0.3125: return "🌓"
        case 0.3125..<0.4375: return "🌔"
        case 0.4375..<0.5625: return "🌕"
        case 0.5625..<0.6875: return "🌖"
        case 0.6875..<0.8125: return "🌗"
        default: return "🌘"
        }
    }
}

extension TideEvent {
    var tideType: TideType {
        type == "high" ? .high : .low
    }
    
    enum TideType {
        case high, low
    }
}
