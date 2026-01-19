//
//  MareesPecheService.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 19/01/2026.
//
//  Service de récupération des données depuis mareespeche.com
//

import Foundation
import SwiftUI

@Observable
class MareesPecheService {
    
    var isLoading = false
    var lastError: String?
    
    // MARK: - Ports Nouvelle-Calédonie
    
    enum PortNC: String, CaseIterable {
        case noumea = "noumea"
        case koumac = "koumac"
        case thio = "thio"
        case lifou = "lifou"
        case hienghene = "hienghene"
        case pouebo = "pouebo"
        
        var displayName: String {
            rawValue.capitalized
        }
        
        var url: String {
            "https://mareespeche.com/nc/grande-terre/\(rawValue)"
        }
        
        var coordinates: (latitude: Double, longitude: Double) {
            switch self {
            case .noumea: return (-22.2758, 166.4580)
            case .koumac: return (-20.5667, 164.2833)
            case .thio: return (-21.6167, 166.2167)
            case .lifou: return (-20.9167, 167.2333)
            case .hienghene: return (-20.7000, 165.0000)
            case .pouebo: return (-20.4000, 164.6000)
            }
        }
    }
    
    // MARK: - Modèles de données
    
    struct DonneesCompletes {
        let port: String
        let date: Date
        let marees: [InfoMaree]
        let meteo: InfoMeteo?
        let soleil: InfoSoleil?
        let lune: InfoLune?
        
        struct InfoMaree: Identifiable {
            let id = UUID()
            let heure: Date
            let hauteur: Double  // en mètres
            let coefficient: Int
            let type: TypeMaree
            
            enum TypeMaree: String {
                case pleineMer = "PM"
                case basseMer = "BM"
                
                var displayName: String {
                    switch self {
                    case .pleineMer: return "Pleine mer"
                    case .basseMer: return "Basse mer"
                    }
                }
                
                var emoji: String {
                    switch self {
                    case .pleineMer: return "🔵"
                    case .basseMer: return "🔴"
                    }
                }
            }
            
            var heureFormatee: String {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: heure)
            }
        }
        
        struct InfoMeteo {
            let temperature: Double?
            let vent: String?
            let conditions: String?
        }
        
        struct InfoSoleil {
            let lever: Date
            let coucher: Date
        }
        
        struct InfoLune {
            let phase: String
            let illumination: Int  // pourcentage
            let lever: Date?
            let coucher: Date?
        }
    }
    
    // MARK: - Fetch données
    
    func fetchDonnees(port: PortNC = .noumea, date: Date = Date()) async throws -> DonneesCompletes {
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: port.url) else {
            throw MareesPecheError.invalidURL
        }
        
        print("📡 Fetching data from: \(url)")
        
        do {
            // Configuration de la requête avec timeout
            var request = URLRequest(url: url)
            request.timeoutInterval = 15.0
            request.httpMethod = "GET"
            request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw MareesPecheError.invalidResponse
            }
            
            guard httpResponse.statusCode == 200 else {
                throw MareesPecheError.httpError(statusCode: httpResponse.statusCode)
            }
            
            guard let html = String(data: data, encoding: .utf8) else {
                throw MareesPecheError.encodingError
            }
            
            print("✅ HTML récupéré (\(html.count) caractères)")
            
            // Parser le HTML
            let donnees = try parseHTML(html, port: port, date: date)
            
            return donnees
            
        } catch {
            lastError = error.localizedDescription
            print("❌ Erreur: \(error)")
            throw error
        }
    }
    
    // MARK: - Parsing HTML
    
    private func parseHTML(_ html: String, port: PortNC, date: Date) throws -> DonneesCompletes {
        var marees: [DonneesCompletes.InfoMaree] = []
        
        // 🔍 PARSING DES HORAIRES DE MARÉE
        // Structure typique : <td>12:34</td><td>1.8m</td><td>PM</td><td>78</td>
        
        // Pattern regex pour extraire les données de marée
        let mareePattern = #"<tr[^>]*>[\s\S]*?<td[^>]*>(\d{1,2}h\d{2}|\d{1,2}:\d{2})</td>[\s\S]*?<td[^>]*>([\d.]+)\s*m</td>[\s\S]*?<td[^>]*>(PM|BM|Haute|Basse)</td>[\s\S]*?<td[^>]*>(\d+)</td>"#
        
        if let regex = try? NSRegularExpression(pattern: mareePattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: html, range: NSRange(html.startIndex..., in: html))
            
            print("🔍 Trouvé \(matches.count) correspondances de marée")
            
            for match in matches {
                if match.numberOfRanges >= 5,
                   let heureRange = Range(match.range(at: 1), in: html),
                   let hauteurRange = Range(match.range(at: 2), in: html),
                   let typeRange = Range(match.range(at: 3), in: html),
                   let coefRange = Range(match.range(at: 4), in: html) {
                    
                    let heureStr = String(html[heureRange])
                    let hauteurStr = String(html[hauteurRange])
                    let typeStr = String(html[typeRange])
                    let coefStr = String(html[coefRange])
                    
                    print("  📋 Marée: \(heureStr) | \(hauteurStr)m | \(typeStr) | Coef: \(coefStr)")
                    
                    // Convertir les données
                    if let heure = parseHeure(heureStr, date: date),
                       let hauteur = Double(hauteurStr),
                       let coefficient = Int(coefStr) {
                        
                        let type: DonneesCompletes.InfoMaree.TypeMaree
                        if typeStr.uppercased().contains("PM") || typeStr.lowercased().contains("haute") {
                            type = .pleineMer
                        } else {
                            type = .basseMer
                        }
                        
                        let maree = DonneesCompletes.InfoMaree(
                            heure: heure,
                            hauteur: hauteur,
                            coefficient: coefficient,
                            type: type
                        )
                        marees.append(maree)
                    }
                }
            }
        }
        
        print("✅ Marées parsées: \(marees.count)")
        
        // Parser méteo (optionnel)
        let meteo = parseMeteo(html)
        
        // Parser soleil (optionnel)
        let soleil = parseSoleil(html, date: date)
        
        // Parser lune (optionnel)
        let lune = parseLune(html)
        
        return DonneesCompletes(
            port: port.displayName,
            date: date,
            marees: marees,
            meteo: meteo,
            soleil: soleil,
            lune: lune
        )
    }
    
    // MARK: - Helpers de parsing
    
    private func parseHeure(_ heureStr: String, date: Date) -> Date? {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Pacific/Noumea")
        
        // Support des formats "12h34" ou "12:34"
        let cleanedStr = heureStr.replacingOccurrences(of: "h", with: ":")
        formatter.dateFormat = "HH:mm"
        
        if let time = formatter.date(from: cleanedStr) {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
            
            var fullComponents = dateComponents
            fullComponents.hour = timeComponents.hour
            fullComponents.minute = timeComponents.minute
            fullComponents.timeZone = TimeZone(identifier: "Pacific/Noumea")
            
            return calendar.date(from: fullComponents)
        }
        return nil
    }
    
    private func parseMeteo(_ html: String) -> DonneesCompletes.InfoMeteo? {
        // TODO: Parser les données météo si présentes
        return nil
    }
    
    private func parseSoleil(_ html: String, date: Date) -> DonneesCompletes.InfoSoleil? {
        // TODO: Parser lever/coucher soleil si présents
        return nil
    }
    
    private func parseLune(_ html: String) -> DonneesCompletes.InfoLune? {
        // TODO: Parser phase lunaire si présente
        return nil
    }
    
    // MARK: - Trouver le port le plus proche
    
    func trouverPortLePlusProche(latitude: Double, longitude: Double) -> PortNC {
        var portLePlusProche = PortNC.noumea
        var distanceMin = Double.infinity
        
        for port in PortNC.allCases {
            let coords = port.coordinates
            let distance = sqrt(
                pow(coords.latitude - latitude, 2) +
                pow(coords.longitude - longitude, 2)
            )
            
            if distance < distanceMin {
                distanceMin = distance
                portLePlusProche = port
            }
        }
        
        return portLePlusProche
    }
}

// MARK: - Erreurs

enum MareesPecheError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case encodingError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .invalidResponse:
            return "Réponse serveur invalide"
        case .httpError(let code):
            return "Erreur HTTP \(code)"
        case .encodingError:
            return "Erreur d'encodage"
        case .parsingError:
            return "Erreur de parsing HTML"
        }
    }
}
