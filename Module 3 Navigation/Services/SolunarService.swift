//
//  SolunarService.swift
//  Go Les Picots V.4
//
//  Service API Solunar.org pour périodes optimales de pêche
//  Documentation : https://solunar.org/#usage
//  Endpoint : https://api.solunar.org/solunar/latitude,longitude,date,tz
//

import Foundation
import CoreLocation

class SolunarService {
    
    private let baseURL = "https://api.solunar.org/solunar"
    
    // MARK: - Fetch Solunar Data
    
    /// Récupère les périodes solunaires pour une date et position
    /// - Parameters:
    ///   - latitude: Latitude (Nord positif, Sud négatif)
    ///   - longitude: Longitude (Est positif, Ouest négatif)
    ///   - date: Date pour les calculs
    ///   - timezone: Fuseau horaire (+11 pour Nouméa)
    func fetchSolunarData(
        latitude: Double,
        longitude: Double,
        date: Date = Date(),
        timezone: Int = 11
    ) async throws -> SolunarData {
        
        // Vérifier le cache d'abord
        if let cached = SolunarCache.shared.getSolunarData(latitude: latitude, longitude: longitude, date: date) {
            print("✅ Cache HIT - Solunar data")
            return cached
        }
        
        print("🌐 Cache MISS - Appel API Solunar")
        
        // Format date : yyyyMMdd
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        
        // Construction URL : latitude,longitude,date,tz
        let urlString = "\(baseURL)/\(latitude),\(longitude),\(dateString),\(timezone)"
        
        guard let url = URL(string: urlString) else {
            throw SolunarError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SolunarError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw SolunarError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        let solunarResponse = try decoder.decode(SolunarResponse.self, from: data)
        
        // Convertir en SolunarData
        let solunarData = convertToSolunarData(solunarResponse, date: date)
        
        // Sauvegarder dans le cache (24h)
        SolunarCache.shared.setSolunarData(solunarData, latitude: latitude, longitude: longitude, date: date)
        
        return solunarData
    }
    
    // MARK: - Conversion
    
    private func convertToSolunarData(_ response: SolunarResponse, date: Date) -> SolunarData {
        let calendar = Calendar.current
        
        // Convertir les heures Solunar en Date
        // ⚠️ Les heures > 24 signifient le lendemain (ex: 29:27 = 05:27 J+1)
        
        let sunrise = convertSolunarTime(response.sunRise, response.sunRiseDec, on: date)
        let sunset = convertSolunarTime(response.sunSet, response.sunSetDec, on: date)
        let sunTransit = convertSolunarTime(response.sunTransit, response.sunTransitDec, on: date)
        
        let moonrise = convertSolunarTime(response.moonRise, response.moonRiseDec, on: date)
        let moonset = convertSolunarTime(response.moonSet, response.moonSetDec, on: date)
        let moonTransit = convertSolunarTime(response.moonTransit, response.moonTransitDec, on: date)
        let moonUnder = convertSolunarTime(response.moonUnder, response.moonUnderDec, on: date)
        
        // Périodes majeures
        var majorPeriods: [SolunarPeriod] = []
        
        if let start = convertSolunarTime(response.major1Start, response.major1StartDec, on: date),
           let end = convertSolunarTime(response.major1Stop, response.major1StopDec, on: date) {
            majorPeriods.append(SolunarPeriod(
                start: start,
                end: end,
                type: .major,
                score: 90,
                description: "Transit lunaire (lune au zénith)"
            ))
        }
        
        if let start = convertSolunarTime(response.major2Start, response.major2StartDec, on: date),
           let end = convertSolunarTime(response.major2Stop, response.major2StopDec, on: date) {
            majorPeriods.append(SolunarPeriod(
                start: start,
                end: end,
                type: .major,
                score: 85,
                description: "Lune sous l'horizon (opposé zénith)"
            ))
        }
        
        // Périodes mineures
        var minorPeriods: [SolunarPeriod] = []
        
        if let start = convertSolunarTime(response.minor1Start, response.minor1StartDec, on: date),
           let end = convertSolunarTime(response.minor1Stop, response.minor1StopDec, on: date) {
            minorPeriods.append(SolunarPeriod(
                start: start,
                end: end,
                type: .minor,
                score: 70,
                description: "Lever de lune"
            ))
        }
        
        if let start = convertSolunarTime(response.minor2Start, response.minor2StartDec, on: date),
           let end = convertSolunarTime(response.minor2Stop, response.minor2StopDec, on: date) {
            minorPeriods.append(SolunarPeriod(
                start: start,
                end: end,
                type: .minor,
                score: 65,
                description: "Coucher de lune"
            ))
        }
        
        // Convertir hourlyRating en dictionnaire Int -> Int
        var hourlyRatings: [Int: Int] = [:]
        if let ratings = response.hourlyRating {
            for (hour, score) in ratings {
                if let h = Int(hour) {
                    hourlyRatings[h] = score
                }
            }
        }
        
        return SolunarData(
            date: date,
            sunrise: sunrise,
            sunset: sunset,
            sunTransit: sunTransit,
            moonrise: moonrise,
            moonset: moonset,
            moonTransit: moonTransit,
            moonUnder: moonUnder,
            moonPhase: response.moonPhase ?? "Unknown",
            moonIllumination: response.moonIllumination ?? 0,
            majorPeriods: majorPeriods,
            minorPeriods: minorPeriods,
            dayRating: response.dayRating,
            hourlyRating: hourlyRatings
        )
    }
    
    /// Convertit une heure Solunar en Date
    /// Les heures > 24 indiquent le lendemain (ex: 29:27 = 05:27 J+1)
    private func convertSolunarTime(_ timeString: String?, _ decimalTime: Double?, on date: Date) -> Date? {
        guard let decimal = decimalTime else { return nil }
        
        let calendar = Calendar.current
        var targetDate = date
        var hours = Int(decimal)
        let minutes = Int((decimal - Double(hours)) * 60)
        
        // Si heure > 24, c'est le lendemain
        if hours >= 24 {
            hours -= 24
            targetDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return calendar.date(bySettingHour: hours, minute: minutes, second: 0, of: targetDate)
    }
}

// MARK: - Models

struct SolunarData: Codable {
    let date: Date
    
    // Soleil
    let sunrise: Date?
    let sunset: Date?
    let sunTransit: Date?
    
    // Lune
    let moonrise: Date?
    let moonset: Date?
    let moonTransit: Date?
    let moonUnder: Date?
    let moonPhase: String
    let moonIllumination: Double  // 0-1
    
    // Périodes
    let majorPeriods: [SolunarPeriod]
    let minorPeriods: [SolunarPeriod]
    
    // Ratings
    let dayRating: Int            // 0-5
    let hourlyRating: [Int: Int]  // Heure -> Score 0-100
    
    var globalScore: Int {
        // Convertir dayRating (0-5) en score 0-100
        Int((Double(dayRating) / 5.0) * 100)
    }
    
    var qualityText: String {
        switch dayRating {
        case 5: return "Exceptionnelle"
        case 4: return "Excellente"
        case 3: return "Très bonne"
        case 2: return "Bonne"
        case 1: return "Moyenne"
        default: return "Faible"
        }
    }
    
    var qualityEmoji: String {
        switch dayRating {
        case 5: return "🌟"
        case 4: return "⭐️"
        case 3: return "✨"
        case 2: return "💫"
        case 1: return "⚡️"
        default: return "〰️"
        }
    }
    
    var allPeriods: [SolunarPeriod] {
        (majorPeriods + minorPeriods).sorted { $0.start < $1.start }
    }
    
    var moonPhaseFrench: String {
        switch moonPhase {
        case "New Moon": return "Nouvelle lune"
        case "Waxing Crescent": return "Premier croissant"
        case "First Quarter": return "Premier quartier"
        case "Waxing Gibbous": return "Gibbeuse croissante"
        case "Full Moon": return "Pleine lune"
        case "Waning Gibbous": return "Gibbeuse décroissante"
        case "Last Quarter": return "Dernier quartier"
        case "Waning Crescent": return "Dernier croissant"
        default: return moonPhase
        }
    }
    
    var moonEmoji: String {
        switch moonPhase {
        case "New Moon": return "🌑"
        case "Waxing Crescent": return "🌒"
        case "First Quarter": return "🌓"
        case "Waxing Gibbous": return "🌔"
        case "Full Moon": return "🌕"
        case "Waning Gibbous": return "🌖"
        case "Last Quarter": return "🌗"
        case "Waning Crescent": return "🌘"
        default: return "🌙"
        }
    }
}

struct SolunarPeriod: Codable, Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let type: PeriodType
    let score: Int
    let description: String
    
    enum PeriodType: String, Codable {
        case major = "Majeure"
        case minor = "Mineure"
        
        var emoji: String {
            self == .major ? "🌟" : "⭐️"
        }
    }
    
    var duration: TimeInterval {
        end.timeIntervalSince(start)
    }
    
    var durationFormatted: String {
        let minutes = Int(duration / 60)
        return "\(minutes) min"
    }
    
    var timeFormatted: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private enum CodingKeys: String, CodingKey {
        case start, end, type, score, description
    }
}

// MARK: - API Response

struct SolunarResponse: Codable {
    // Soleil
    let sunRise: String?
    let sunSet: String?
    let sunTransit: String?
    let sunRiseDec: Double?
    let sunSetDec: Double?
    let sunTransitDec: Double?
    
    // Lune
    let moonRise: String?
    let moonSet: String?
    let moonTransit: String?
    let moonUnder: String?
    let moonRiseDec: Double?
    let moonSetDec: Double?
    let moonTransitDec: Double?
    let moonUnderDec: Double?
    
    // Phase lunaire
    let moonPhase: String?
    let moonIllumination: Double?
    
    // Périodes mineures
    let minor1Start: String?
    let minor1Stop: String?
    let minor1StartDec: Double?
    let minor1StopDec: Double?
    let minor2Start: String?
    let minor2Stop: String?
    let minor2StartDec: Double?
    let minor2StopDec: Double?
    
    // Périodes majeures
    let major1Start: String?
    let major1Stop: String?
    let major1StartDec: Double?
    let major1StopDec: Double?
    let major2Start: String?
    let major2Stop: String?
    let major2StartDec: Double?
    let major2StopDec: Double?
    
    // Ratings
    let dayRating: Int
    let hourlyRating: [String: Int]?
    
    // Metadata
    let time: String?
    let timeZone: Int?
    let date: String?
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Cache

class SolunarCache {
    static let shared = SolunarCache()
    private init() {}
    
    private var cache: [String: CacheEntry] = [:]
    
    private struct CacheEntry {
        let data: SolunarData
        let timestamp: Date
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 24 * 3600 // 24h
        }
    }
    
    func getSolunarData(latitude: Double, longitude: Double, date: Date) -> SolunarData? {
        let key = cacheKey(latitude: latitude, longitude: longitude, date: date)
        
        guard let entry = cache[key], !entry.isExpired else {
            cache.removeValue(forKey: key)
            return nil
        }
        
        return entry.data
    }
    
    func setSolunarData(_ data: SolunarData, latitude: Double, longitude: Double, date: Date) {
        let key = cacheKey(latitude: latitude, longitude: longitude, date: date)
        cache[key] = CacheEntry(data: data, timestamp: Date())
    }
    
    func clearAll() {
        cache.removeAll()
    }
    
    private func cacheKey(latitude: Double, longitude: Double, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: date)
        return "solunar_\(latitude)_\(longitude)_\(dateString)"
    }
}

// MARK: - Errors

enum SolunarError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide"
        case .httpError(let code):
            return "Erreur HTTP \(code)"
        }
    }
}
