//
//  SHOMService.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 18/01/2026.
//
//  Module 3 : Navigation
//  Service de récupération des données de marée via SHOM
//

import Foundation
import CoreLocation

/// Service de gestion des données de marée SHOM
@Observable
class SHOMService {
    
    // MARK: - Properties
    private let baseURL = "https://services.data.shom.fr/hdm/spm/hlt"
    
    /// Dernières données de marée
    var dernieresMarees: [DonneesMaree] = []
    
    /// Indicateur de chargement
    var isLoading = false
    
    /// Dernière erreur
    var lastError: SHOMError?
    
    // MARK: - Ports de Nouvelle-Calédonie
    static let portsNC: [PortMaree] = [
        PortMaree(nom: "Nouméa", code: "NOUMEA", latitude: -22.2758, longitude: 166.4580),
        PortMaree(nom: "Koumac", code: "KOUMAC", latitude: -20.5667, longitude: 164.2833),
        PortMaree(nom: "Thio", code: "THIO", latitude: -21.6167, longitude: 166.2167),
        PortMaree(nom: "Lifou", code: "LIFOU", latitude: -20.9167, longitude: 167.2333)
    ]
    
    // MARK: - Public Methods
    
    /// Récupère les horaires de marée pour un port
    /// - Parameters:
    ///   - port: Code du port SHOM
    ///   - date: Date pour laquelle récupérer les marées
    /// - Returns: Tableau de données de marée
    func fetchHorairesMaree(port: String, date: Date = Date()) async throws -> [DonneesMaree] {
        isLoading = true
        defer { isLoading = false }
        
        // Format de date SHOM : YYYY-MM-DD
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        // Construction URL
        let urlString = "\(baseURL)?harborName=\(port)&duration=1&date=\(dateString)"
        
        guard let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            throw SHOMError.invalidURL
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw SHOMError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw SHOMError.httpError(statusCode: httpResponse.statusCode)
            }
            
            // Décodage de la réponse SHOM
            let shomResponse = try JSONDecoder().decode(SHOMResponse.self, from: data)
            
            // Conversion vers notre modèle
            let marees = convertToMarees(from: shomResponse)
            
            self.dernieresMarees = marees
            return marees
            
        } catch let error as SHOMError {
            lastError = error
            throw error
        } catch {
            let shomError = SHOMError.networkError(error)
            lastError = shomError
            throw shomError
        }
    }
    
    /// Trouve le port le plus proche d'une position
    /// - Parameters:
    ///   - latitude: Latitude
    ///   - longitude: Longitude
    /// - Returns: Port le plus proche
    func trouverPortLePlusProche(latitude: Double, longitude: Double) -> PortMaree {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        
        return SHOMService.portsNC.min(by: { port1, port2 in
            let loc1 = CLLocation(latitude: port1.latitude, longitude: port1.longitude)
            let loc2 = CLLocation(latitude: port2.latitude, longitude: port2.longitude)
            
            return location.distance(from: loc1) < location.distance(from: loc2)
        }) ?? SHOMService.portsNC[0]
    }
    
    /// Détermine la phase de marée actuelle
    /// - Parameter marees: Données de marée
    /// - Returns: Phase de marée actuelle
    func determinerPhaseMaree(marees: [DonneesMaree]) -> PhaseMaree {
        let now = Date()
        
        // Trouver la marée précédente et la suivante
        let mareesPrecedentes = marees.filter { $0.date <= now }.sorted { $0.date > $1.date }
        let mareesSuivantes = marees.filter { $0.date > now }.sorted { $0.date < $1.date }
        
        guard let precedente = mareesPrecedentes.first,
              let suivante = mareesSuivantes.first else {
            return .etaleHaut
        }
        
        // Déterminer si montante ou descendante
        if precedente.type == .basseMer && suivante.type == .pleineMer {
            return .montante
        } else if precedente.type == .pleineMer && suivante.type == .basseMer {
            return .descendante
        } else if precedente.type == .pleineMer {
            return .etaleHaut
        } else {
            return .etaleBas
        }
    }
    
    /// Calcule le coefficient de marée (approximatif)
    /// - Parameter marees: Données de marée
    /// - Returns: Coefficient estimé (20-120)
    func calculerCoefficient(marees: [DonneesMaree]) -> Int {
        // Trouver la pleine mer et la basse mer les plus proches
        let now = Date()
        let pleineMer = marees.filter { $0.type == .pleineMer && abs($0.date.timeIntervalSince(now)) < 6*3600 }
            .min { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) }
        
        let basseMer = marees.filter { $0.type == .basseMer && abs($0.date.timeIntervalSince(now)) < 6*3600 }
            .min { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) }
        
        guard let pm = pleineMer, let bm = basseMer else {
            return 70 // Valeur moyenne par défaut
        }
        
        // Marnage (différence de hauteur)
        let marnage = abs(pm.hauteur - bm.hauteur)
        
        // Estimation du coefficient (formule simplifiée)
        // Marnage typique NC : 1.0-1.8m
        // Coefficient : 20-120
        let coefficient = Int((marnage / 1.8) * 100)
        
        return max(20, min(120, coefficient))
    }
    
    // MARK: - Private Methods
    
    private func convertToMarees(from response: SHOMResponse) -> [DonneesMaree] {
        return response.data.map { item in
            DonneesMaree(
                date: ISO8601DateFormatter().date(from: item.time) ?? Date(),
                hauteur: item.height,
                type: item.type == "PM" ? .pleineMer : .basseMer
            )
        }
    }
}

// MARK: - Models

struct PortMaree: Identifiable {
    let id = UUID()
    let nom: String
    let code: String
    let latitude: Double
    let longitude: Double
}

struct DonneesMaree {
    let date: Date
    let hauteur: Double  // en mètres
    let type: TypeMaree
    
    enum TypeMaree {
        case pleineMer
        case basseMer
    }
}

// MARK: - SHOM Response Models

struct SHOMResponse: Codable {
    let data: [SHOMMaree]
}

struct SHOMMaree: Codable {
    let time: String  // ISO 8601
    let height: Double
    let type: String  // "PM" ou "BM"
}

// MARK: - SHOM Error

enum SHOMError: LocalizedError {
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

// MARK: - Sample Usage
extension SHOMService {
    static func exemple() async {
        let service = SHOMService()
        
        do {
            let marees = try await service.fetchHorairesMaree(port: "NOUMEA")
            print("Marées Nouméa :")
            for maree in marees {
                print("- \(maree.date) : \(maree.hauteur)m (\(maree.type))")
            }
            
            let phase = service.determinerPhaseMaree(marees: marees)
            print("Phase actuelle : \(phase)")
            
            let coefficient = service.calculerCoefficient(marees: marees)
            print("Coefficient : \(coefficient)")
            
        } catch {
            print("Erreur : \(error.localizedDescription)")
        }
    }
}
