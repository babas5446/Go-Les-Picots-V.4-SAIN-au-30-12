//
//  MeteoService.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Service de récupération des conditions météorologiques via OpenWeatherMap
//

import Foundation
import CoreLocation

/// Service de gestion des données météorologiques
@Observable
class MeteoService {
    
    // MARK: - Properties
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    /// Dernières conditions météo récupérées
    var dernieresConditions: ConditionsMeteo?
    
    /// Indicateur de chargement
    var isLoading = false
    
    /// Dernière erreur
    var lastError: MeteoError?
    
    // MARK: - Initializer
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    // MARK: - Public Methods
    
    /// Récupère les conditions météo actuelles pour une position
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    /// - Returns: ConditionsMeteo
    func fetchConditionsActuelles(latitude: Double, longitude: Double) async throws -> ConditionsMeteo {
        isLoading = true
        defer { isLoading = false }
        
        // URL de l'API OpenWeatherMap
        let urlString = "\(baseURL)/weather?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=fr"
        
        guard let url = URL(string: urlString) else {
            throw MeteoError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MeteoError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw MeteoError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Décodage de la réponse OpenWeatherMap
            let owmResponse = try JSONDecoder().decode(OpenWeatherMapResponse.self, from: data)
            
            // Conversion vers notre modèle ConditionsMeteo
            let conditions = convertToConditionsMeteo(from: owmResponse)
            
            self.dernieresConditions = conditions
            return conditions
            
        } catch let error as MeteoError {
            lastError = error
            throw error
        } catch {
            let meteoError = MeteoError.networkError(error)
            lastError = meteoError
            throw meteoError
        }
    }
    
    /// Récupère les prévisions météo pour les 5 prochains jours
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    /// - Returns: Tableau de ConditionsMeteo (par période de 3h)
    func fetchPrevisions(latitude: Double, longitude: Double) async throws -> [ConditionsMeteoPreview] {
        isLoading = true
        defer { isLoading = false }
        
        let urlString = "\(baseURL)/forecast?lat=\(latitude)&lon=\(longitude)&appid=\(apiKey)&units=metric&lang=fr"
        
        guard let url = URL(string: urlString) else {
            throw MeteoError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw MeteoError.invalidResponse
            }
            
            let forecastResponse = try JSONDecoder().decode(OpenWeatherMapForecastResponse.self, from: data)
            
            // Conversion vers notre format
            let previsions = forecastResponse.list.map { item in
                ConditionsMeteoPreview(
                    date: Date(timeIntervalSince1970: TimeInterval(item.dt)),
                    conditions: convertToConditionsMeteo(from: item)
                )
            }
            
            return previsions
            
        } catch {
            throw MeteoError.networkError(error)
        }
    }
    
    // MARK: - Private Methods
    
    /// Convertit la réponse OpenWeatherMap vers notre modèle ConditionsMeteo
    private func convertToConditionsMeteo(from response: OpenWeatherMapResponse) -> ConditionsMeteo {
        
        // Conversion vitesse vent (m/s -> nœuds)
        let forceVentKts = Int((response.wind.speed * 1.94384).rounded())
        
        // Conversion direction vent (degrés -> enum)
        let directionVent = convertDegreesToDirection(response.wind.deg)
        
        // État de la mer basé sur vitesse vent
        let etatMer = determineEtatMer(forceVent: forceVentKts)
        
        // Visibilité
        let visibilite = convertVisibility(response.visibility)
        
        return ConditionsMeteo(
            forceVent: forceVentKts,
            directionVent: directionVent,
            etatMer: etatMer,
            hauteurHoule: nil, // Non fourni par OpenWeatherMap basic
            visibilite: visibilite,
            coefficientMaree: nil, // À récupérer via SHOM
            phaseMaree: nil, // À récupérer via SHOM
            heureMareeHaute: nil,
            heureMareeBasse: nil,
            temperatureAir: response.main.temp,
            temperatureEau: nil, // Nécessite API marine spécifique
            pressionAtmospherique: Double(response.main.pressure)
        )
    }
    
    /// Convertit les données forecast vers ConditionsMeteo
    private func convertToConditionsMeteo(from item: ForecastItem) -> ConditionsMeteo {
        let forceVentKts = Int((item.wind.speed * 1.94384).rounded())
        let directionVent = convertDegreesToDirection(item.wind.deg)
        let etatMer = determineEtatMer(forceVent: forceVentKts)
        let visibilite = convertVisibility(item.visibility)
        
        return ConditionsMeteo(
            forceVent: forceVentKts,
            directionVent: directionVent,
            etatMer: etatMer,
            hauteurHoule: nil,
            visibilite: visibilite,
            coefficientMaree: nil,
            phaseMaree: nil,
            heureMareeHaute: nil,
            heureMareeBasse: nil,
            temperatureAir: item.main.temp,
            temperatureEau: nil,
            pressionAtmospherique: Double(item.main.pressure)
        )
    }
    
    /// Convertit des degrés en direction vent
    private func convertDegreesToDirection(_ degrees: Int) -> DirectionVent {
        switch degrees {
        case 0..<23, 338...360: return .nord
        case 23..<68: return .nordEst
        case 68..<113: return .est
        case 113..<158: return .sudEst
        case 158..<203: return .sud
        case 203..<248: return .sudOuest
        case 248..<293: return .ouest
        case 293..<338: return .nordOuest
        default: return .nord
        }
    }
    
    /// Détermine l'état de la mer en fonction de la force du vent
    /// ✅ CORRIGÉ : Utilise les valeurs de l'enum EtatMer de Leurre.swift
    private func determineEtatMer(forceVent: Int) -> EtatMer {
        switch forceVent {
        case 0..<1: return .calme          // ✅ Terme de Leurre.swift
        case 1..<7: return .peuAgitee      // ✅
        case 7..<11: return .peuAgitee     // ✅
        case 11..<17: return .agitee       // ✅
        case 17..<22: return .formee       // ✅
        default: return .formee            // ✅
        }
    }
    
    /// Convertit la visibilité en mètres vers notre enum
    private func convertVisibility(_ meters: Int) -> Visibilite {
        switch meters {
        case 10000...: return .excellente
        case 5000..<10000: return .bonne
        case 2000..<5000: return .moyenne
        default: return .médiocre
        }
    }
    /// Récupère les conditions complètes (météo + marée)
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    ///   - shomService: Service SHOM pour les marées
    /// - Returns: ConditionsMeteo enrichies avec données marée
    func fetchConditionsCompletes(
        latitude: Double,
        longitude: Double,
        shomService: SHOMService
    ) async throws -> ConditionsMeteo {
        // 1. Récupérer la météo
        var conditions = try await fetchConditionsActuelles(latitude: latitude, longitude: longitude)
        
        // 2. Trouver le port le plus proche
        let port = shomService.trouverPortLePlusProche(latitude: latitude, longitude: longitude)
        
        // 3. Récupérer les données de marée
        do {
            let marees = try await shomService.fetchHorairesMaree(port: port.code)
            
            // 4. Enrichir les conditions avec les données marée
            let phase = shomService.determinerPhaseMaree(marees: marees)
            let coefficient = shomService.calculerCoefficient(marees: marees)
            
            // Trouver les heures de marée
            let now = Date()
            let prochainePM = marees.first { $0.type == .pleineMer && $0.date > now }
            let prochaineBM = marees.first { $0.type == .basseMer && $0.date > now }
            
            // Créer une nouvelle instance avec les données marée
            return ConditionsMeteo(
                forceVent: conditions.forceVent,
                directionVent: conditions.directionVent,
                etatMer: conditions.etatMer,
                hauteurHoule: conditions.hauteurHoule,
                visibilite: conditions.visibilite,
                coefficientMaree: coefficient,
                phaseMaree: phase,
                heureMareeHaute: prochainePM?.date,
                heureMareeBasse: prochaineBM?.date,
                temperatureAir: conditions.temperatureAir,
                temperatureEau: conditions.temperatureEau,
                pressionAtmospherique: conditions.pressionAtmospherique
            )
            
        } catch {
            // Si erreur SHOM, retourner quand même la météo
            print("⚠️ Impossible de récupérer les données de marée : \(error.localizedDescription)")
            return conditions
        }
    }
}

// MARK: - Meteo Error
enum MeteoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse du serveur invalide"
        case .httpError(let code):
            return "Erreur HTTP \(code)"
        case .networkError(let error):
            return "Erreur réseau : \(error.localizedDescription)"
        case .decodingError(let error):
            return "Erreur de décodage : \(error.localizedDescription)"
        }
    }
}

// MARK: - OpenWeatherMap Response Models

struct OpenWeatherMapResponse: Codable {
    let coord: Coord
    let weather: [Weather]
    let main: Main
    let visibility: Int
    let wind: Wind
    let clouds: Clouds
    let dt: Int
    let sys: Sys
    let name: String
    
    struct Coord: Codable {
        let lon: Double
        let lat: Double
    }
    
    struct Weather: Codable {
        let id: Int
        let main: String
        let description: String
        let icon: String
    }
    
    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let temp_min: Double
        let temp_max: Double
        let pressure: Int
        let humidity: Int
    }
    
    struct Wind: Codable {
        let speed: Double
        let deg: Int
        let gust: Double?
    }
    
    struct Clouds: Codable {
        let all: Int
    }
    
    struct Sys: Codable {
        let country: String
        let sunrise: Int
        let sunset: Int
    }
}

struct OpenWeatherMapForecastResponse: Codable {
    let list: [ForecastItem]
}

struct ForecastItem: Codable {
    let dt: Int
    let main: OpenWeatherMapResponse.Main
    let weather: [OpenWeatherMapResponse.Weather]
    let wind: OpenWeatherMapResponse.Wind
    let visibility: Int
    let clouds: OpenWeatherMapResponse.Clouds
}

// MARK: - Preview Helper
struct ConditionsMeteoPreview {
    let date: Date
    let conditions: ConditionsMeteo
}

// MARK: - Sample Usage
extension MeteoService {
    /// Coordonnées Nouméa pour tests
    static let noumea = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
    
    /// Exemple d'utilisation
    static func exemple() async {
        let service = MeteoService(apiKey: "VOTRE_CLE_API_ICI")
        
        do {
            let conditions = try await service.fetchConditionsActuelles(
                latitude: noumea.latitude,
                longitude: noumea.longitude
            )
            print("Vent : \(conditions.ventComplet ?? "N/A")")
            print("Température : \(conditions.temperatureAirFormatee ?? "N/A")")
            print("État mer : \(conditions.etatMer?.displayName ?? "N/A")")
        } catch {
            print("Erreur : \(error.localizedDescription)")
        }
    }
}
