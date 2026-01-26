//
//  StormglassService.swift
//  Go Les Picots V.4
//
//  Service API Stormglass.io pour données marines
//  Documentation : https://docs.stormglass.io
//
//  ⚠️ Les modèles (MarineData, AstronomyData, TideEvent) sont dans MarineModels.swift
//

import Foundation
import CoreLocation

/// Service pour récupérer les données marines de Stormglass.io
class StormglassService {
    
    private let apiKey: String
    private let baseURL = "https://api.stormglass.io/v2"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Fetch Weather Data
    
    /// Récupère les conditions marines actuelles (avec cache 3h)
    func fetchMarineData(latitude: Double, longitude: Double) async throws -> MarineData {
        // Vérifier le cache d'abord
        if let cached = StormglassCache.shared.getMarineData(latitude: latitude, longitude: longitude) {
            print("✅ Cache HIT - Marine data")
            return cached
        }
        
        print("🌐 Cache MISS - Appel API Marine data")
        
        // Endpoint Weather pour conditions actuelles
        let urlString = "\(baseURL)/weather/point"
        guard var components = URLComponents(string: urlString) else {
            throw StormglassError.invalidURL
        }
        
        // Paramètres COMPLETS
        let now = Date()
        let endTime = now.addingTimeInterval(3600) // +1h
        
        // Tous les paramètres marines disponibles
        let params = [
            // Vent
            "windSpeed", "windDirection", "gust",
            // Température
            "airTemperature", "waterTemperature",
            // Mer
            "waveHeight", "wavePeriod", "waveDirection",
            "swellHeight", "swellPeriod", "swellDirection",
            // Courant
            "currentSpeed", "currentDirection",
            // Pression & Visibilité
            "pressure", "visibility",
            // Météo
            "precipitation", "cloudCover", "humidity"
        ].joined(separator: ",")
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "params", value: params),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: now)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endTime))
        ]
        
        guard let url = components.url else {
            throw StormglassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StormglassError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StormglassError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let weatherResponse = try decoder.decode(StormglassWeatherResponse.self, from: data)
        
        // Convertir en MarineData
        let marineData = try convertToMarineData(weatherResponse)
        
        // Sauvegarder dans le cache
        StormglassCache.shared.setMarineData(marineData, latitude: latitude, longitude: longitude)
        
        return marineData
    }
    
    // MARK: - Fetch Forecast (Prévisions multi-jours)
    
    /// Récupère les prévisions marines sur plusieurs jours (avec cache 3h)
    func fetchForecast(latitude: Double, longitude: Double, days: Int = 7) async throws -> [MarineData] {
        // Vérifier le cache d'abord
        if let cached = StormglassCache.shared.getForecast(latitude: latitude, longitude: longitude, days: days) {
            print("✅ Cache HIT - Forecast \(days) days")
            return cached
        }
        
        print("🌐 Cache MISS - Appel API Forecast")
        
        let urlString = "\(baseURL)/weather/point"
        guard var components = URLComponents(string: urlString) else {
            throw StormglassError.invalidURL
        }
        
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .day, value: days, to: now)!
        
        let params = [
            "windSpeed", "windDirection", "gust",
            "airTemperature", "waterTemperature",
            "waveHeight", "wavePeriod", "waveDirection",
            "swellHeight", "swellPeriod", "swellDirection",
            "currentSpeed", "currentDirection",
            "pressure", "visibility",
            "precipitation", "cloudCover", "humidity"
        ].joined(separator: ",")
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "params", value: params),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: now)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endTime))
        ]
        
        guard let url = components.url else {
            throw StormglassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StormglassError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StormglassError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let weatherResponse = try decoder.decode(StormglassWeatherResponse.self, from: data)
        
        // Convertir toutes les heures en MarineData
        let forecast = try weatherResponse.hours.map { hour in
            try convertToMarineData(hour: hour)
        }
        
        // Sauvegarder dans le cache
        StormglassCache.shared.setForecast(forecast, latitude: latitude, longitude: longitude, days: days)
        
        return forecast
    }
    
    // MARK: - Fetch Astronomy Data (Soleil & Lune)
    
    /// Récupère les données astronomiques (avec cache 24h)
    func fetchAstronomyData(latitude: Double, longitude: Double, date: Date = Date()) async throws -> AstronomyData {
        // Vérifier le cache d'abord
        if let cached = StormglassCache.shared.getAstronomy(latitude: latitude, longitude: longitude, date: date) {
            print("✅ Cache HIT - Astronomy data")
            return cached
        }
        
        print("🌐 Cache MISS - Appel API Astronomy")
        
        let urlString = "\(baseURL)/astronomy/point"
        guard var components = URLComponents(string: urlString) else {
            throw StormglassError.invalidURL
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: startOfDay)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endOfDay))
        ]
        
        guard let url = components.url else {
            throw StormglassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StormglassError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StormglassError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let astronomyResponse = try decoder.decode(StormglassAstronomyResponse.self, from: data)
        
        guard let dayData = astronomyResponse.data.first else {
            throw StormglassError.noData
        }
        
        let astronomyData = AstronomyData(
            sunrise: dayData.astronomy.sunrise,
            sunset: dayData.astronomy.sunset,
            moonrise: dayData.astronomy.moonrise,
            moonset: dayData.astronomy.moonset,
            moonPhase: dayData.astronomy.moonPhase.current.value,
            moonIllumination: dayData.astronomy.moonFraction.current.value * 100
        )
        
        // Sauvegarder dans le cache
        StormglassCache.shared.setAstronomy(astronomyData, latitude: latitude, longitude: longitude, date: date)
        
        return astronomyData
    }
    
    // MARK: - Fetch Tide Data
    
    /// Récupère les données de marées (avec cache 24h)
    func fetchTideData(latitude: Double, longitude: Double, date: Date = Date()) async throws -> [TideEvent] {
        // Vérifier le cache d'abord
        if let cached = StormglassCache.shared.getTides(latitude: latitude, longitude: longitude, date: date) {
            print("✅ Cache HIT - Tide data")
            return cached
        }
        
        print("🌐 Cache MISS - Appel API Tides")
        
        let urlString = "\(baseURL)/tide/extremes/point"
        guard var components = URLComponents(string: urlString) else {
            throw StormglassError.invalidURL
        }
        
        // Date début et fin (24h)
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lng", value: String(longitude)),
            URLQueryItem(name: "start", value: ISO8601DateFormatter().string(from: startOfDay)),
            URLQueryItem(name: "end", value: ISO8601DateFormatter().string(from: endOfDay))
        ]
        
        guard let url = components.url else {
            throw StormglassError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw StormglassError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw StormglassError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let tideResponse = try decoder.decode(StormglassTideResponse.self, from: data)
        
        let tides = tideResponse.data.map { extreme in
            TideEvent(
                time: extreme.time,
                height: extreme.height,
                type: extreme.type
            )
        }
        
        // Sauvegarder dans le cache
        StormglassCache.shared.setTides(tides, latitude: latitude, longitude: longitude, date: date)
        
        return tides
    }
    
    // MARK: - Conversion
    
    private func convertToMarineData(_ response: StormglassWeatherResponse) throws -> MarineData {
        guard let firstHour = response.hours.first else {
            throw StormglassError.noData
        }
        return try convertToMarineData(hour: firstHour)
    }
    
    private func convertToMarineData(hour: WeatherHour) throws -> MarineData {
        return MarineData(
            windSpeed: hour.windSpeed?.sg ?? 0,
            windDirection: hour.windDirection?.sg ?? 0,
            gust: hour.gust?.sg,
            airTemperature: hour.airTemperature?.sg ?? 0,
            waterTemperature: hour.waterTemperature?.sg,
            waveHeight: hour.waveHeight?.sg,
            wavePeriod: hour.wavePeriod?.sg,
            waveDirection: hour.waveDirection?.sg,
            swellHeight: hour.swellHeight?.sg,
            swellPeriod: hour.swellPeriod?.sg,
            swellDirection: hour.swellDirection?.sg,
            currentSpeed: hour.currentSpeed?.sg,
            currentDirection: hour.currentDirection?.sg,
            pressure: hour.pressure?.sg,
            visibility: hour.visibility?.sg,
            humidity: hour.humidity?.sg,
            precipitation: hour.precipitation?.sg,
            cloudCover: hour.cloudCover?.sg,
            timestamp: hour.time
        )
    }
}

// MARK: - Stormglass Response Models

struct StormglassWeatherResponse: Codable {
    let hours: [WeatherHour]
}

struct WeatherHour: Codable {
    let time: Date
    
    // Vent
    let windSpeed: SourceValue?
    let windDirection: SourceValue?
    let gust: SourceValue?
    
    // Température
    let airTemperature: SourceValue?
    let waterTemperature: SourceValue?
    
    // Houle et Vagues
    let waveHeight: SourceValue?
    let wavePeriod: SourceValue?
    let waveDirection: SourceValue?
    let swellHeight: SourceValue?
    let swellPeriod: SourceValue?
    let swellDirection: SourceValue?
    
    // Courant
    let currentSpeed: SourceValue?
    let currentDirection: SourceValue?
    
    // Atmosphère
    let pressure: SourceValue?
    let visibility: SourceValue?
    let humidity: SourceValue?
    
    // Précipitations & Nuages
    let precipitation: SourceValue?
    let cloudCover: SourceValue?
}

struct SourceValue: Codable {
    let sg: Double  // Stormglass value
}

struct StormglassTideResponse: Codable {
    let data: [TideExtreme]
}

struct TideExtreme: Codable {
    let time: Date
    let height: Double
    let type: String  // "high" ou "low"
}

// MARK: - Astronomy Response

struct StormglassAstronomyResponse: Codable {
    let data: [AstronomyDay]
}

struct AstronomyDay: Codable {
    let time: Date
    let astronomy: AstronomyDetails
}

struct AstronomyDetails: Codable {
    let sunrise: Date
    let sunset: Date
    let moonrise: Date
    let moonset: Date
    let moonPhase: MoonPhaseValue
    let moonFraction: MoonFractionValue
}

struct MoonPhaseValue: Codable {
    let current: ValueWrapper
}

struct MoonFractionValue: Codable {
    let current: ValueWrapper
}

struct ValueWrapper: Codable {
    let value: Double
}

// MARK: - Errors

enum StormglassError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse invalide"
        case .httpError(let code):
            return "Erreur HTTP \(code)"
        case .noData:
            return "Aucune donnée disponible"
        }
    }
}
