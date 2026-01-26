//
//  StormglassCache.swift
//  Go Les Picots V.4
//
//  Système de cache pour limiter les appels API Stormglass (10/jour max)
//  Cache valide pendant 3 heures pour les données marines
//  Cache valide pendant 24h pour astronomie et marées
//

import Foundation

class StormglassCache {
    
    static let shared = StormglassCache()
    
    private init() {}
    
    // MARK: - Cache Storage
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let stormglassCache = urls[0].appendingPathComponent("StormglassCache", isDirectory: true)
        
        // Créer le dossier si nécessaire
        if !fileManager.fileExists(atPath: stormglassCache.path) {
            try? fileManager.createDirectory(at: stormglassCache, withIntermediateDirectories: true)
        }
        
        return stormglassCache
    }
    
    // MARK: - Marine Data Cache
    
    func getMarineData(latitude: Double, longitude: Double) -> MarineData? {
        let key = "marine_\(latitude)_\(longitude)"
        return loadFromCache(key: key, expirationMinutes: 180) // 3h
    }
    
    func setMarineData(_ data: MarineData, latitude: Double, longitude: Double) {
        let key = "marine_\(latitude)_\(longitude)"
        saveToCache(data: data, key: key)
    }
    
    // MARK: - Forecast Cache
    
    func getForecast(latitude: Double, longitude: Double, days: Int) -> [MarineData]? {
        let key = "forecast_\(latitude)_\(longitude)_\(days)"
        return loadFromCache(key: key, expirationMinutes: 180) // 3h
    }
    
    func setForecast(_ data: [MarineData], latitude: Double, longitude: Double, days: Int) {
        let key = "forecast_\(latitude)_\(longitude)_\(days)"
        saveToCache(data: data, key: key)
    }
    
    // MARK: - Astronomy Cache
    
    func getAstronomy(latitude: Double, longitude: Double, date: Date) -> AstronomyData? {
        let dateString = dateFormatter.string(from: date)
        let key = "astronomy_\(latitude)_\(longitude)_\(dateString)"
        return loadFromCache(key: key, expirationMinutes: 1440) // 24h
    }
    
    func setAstronomy(_ data: AstronomyData, latitude: Double, longitude: Double, date: Date) {
        let dateString = dateFormatter.string(from: date)
        let key = "astronomy_\(latitude)_\(longitude)_\(dateString)"
        saveToCache(data: data, key: key)
    }
    
    // MARK: - Tides Cache
    
    func getTides(latitude: Double, longitude: Double, date: Date) -> [TideEvent]? {
        let dateString = dateFormatter.string(from: date)
        let key = "tides_\(latitude)_\(longitude)_\(dateString)"
        return loadFromCache(key: key, expirationMinutes: 1440) // 24h
    }
    
    func setTides(_ data: [TideEvent], latitude: Double, longitude: Double, date: Date) {
        let dateString = dateFormatter.string(from: date)
        let key = "tides_\(latitude)_\(longitude)_\(dateString)"
        saveToCache(data: data, key: key)
    }
    
    // MARK: - Generic Storage Methods
    
    private func loadFromCache<T: Codable>(key: String, expirationMinutes: Int) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // Vérifier expiration via date de modification fichier
        if let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            let expirationDate = modificationDate.addingTimeInterval(TimeInterval(expirationMinutes * 60))
            if Date() > expirationDate {
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try? decoder.decode(T.self, from: data)
    }
    
    private func saveToCache<T: Codable>(data: T, key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let encoded = try? encoder.encode(data) else {
            return
        }
        
        try? encoded.write(to: fileURL)
    }
    
    // MARK: - Utilities
    
    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }
    
    func cleanExpired() {
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return
        }
        
        let now = Date()
        for file in files {
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let modificationDate = attributes[.modificationDate] as? Date {
                // Supprimer si > 24h (durée max)
                if now.timeIntervalSince(modificationDate) > 24 * 3600 {
                    try? fileManager.removeItem(at: file)
                }
            }
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
