//
//  CoordinateFormatter.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//
//  Utilitaires de formatage des coordonnées GPS
//

import Foundation
import CoreLocation

struct CoordinateFormatter {
    
    // MARK: - Format Types
    
    enum CoordinateFormat {
        case decimalDegrees        // -22.2758, 166.4580
        case degreesMinutes        // 22°16.548'S, 166°27.480'E
        case degreesMinutesSeconds // 22°16'32.9"S, 166°27'28.8"E
    }
    
    // MARK: - Formatting Methods
    
    /// Formate une coordonnée en décimal (DD.DDDD°)
    static func formatDecimalDegrees(
        latitude: Double,
        longitude: Double,
        decimals: Int = 4
    ) -> String {
        let latString = String(format: "%.\(decimals)f", latitude)
        let lonString = String(format: "%.\(decimals)f", longitude)
        return "\(latString), \(lonString)"
    }
    
    /// Formate latitude seule en décimal
    static func formatLatitude(_ latitude: Double, decimals: Int = 4) -> String {
        let hemisphere = latitude >= 0 ? "N" : "S"
        let absLat = abs(latitude)
        return String(format: "%.\(decimals)f°%@", absLat, hemisphere)
    }
    
    /// Formate longitude seule en décimal
    static func formatLongitude(_ longitude: Double, decimals: Int = 4) -> String {
        let hemisphere = longitude >= 0 ? "E" : "O"
        let absLon = abs(longitude)
        return String(format: "%.\(decimals)f°%@", absLon, hemisphere)
    }
    
    /// Formate en degrés-minutes (DD°MM.MMM')
    static func formatDegreesMinutes(
        latitude: Double,
        longitude: Double
    ) -> String {
        let latDM = convertToDegreesMinutes(latitude)
        let lonDM = convertToDegreesMinutes(longitude)
        
        let latHemisphere = latitude >= 0 ? "N" : "S"
        let lonHemisphere = longitude >= 0 ? "E" : "O"
        
        let latString = String(format: "%d°%.3f'%@", latDM.degrees, latDM.minutes, latHemisphere)
        let lonString = String(format: "%d°%.3f'%@", lonDM.degrees, lonDM.minutes, lonHemisphere)
        
        return "\(latString), \(lonString)"
    }
    
    /// Formate en degrés-minutes-secondes (DD°MM'SS.S")
    static func formatDegreesMinutesSeconds(
        latitude: Double,
        longitude: Double
    ) -> String {
        let latDMS = convertToDegreesMinutesSeconds(latitude)
        let lonDMS = convertToDegreesMinutesSeconds(longitude)
        
        let latHemisphere = latitude >= 0 ? "N" : "S"
        let lonHemisphere = longitude >= 0 ? "E" : "O"
        
        let latString = String(format: "%d°%d'%.1f\"%@", latDMS.degrees, latDMS.minutes, latDMS.seconds, latHemisphere)
        let lonString = String(format: "%d°%d'%.1f\"%@", lonDMS.degrees, lonDMS.minutes, lonDMS.seconds, lonHemisphere)
        
        return "\(latString), \(lonString)"
    }
    
    /// Formate selon le format spécifié
    static func format(
        latitude: Double,
        longitude: Double,
        format: CoordinateFormat = .decimalDegrees
    ) -> String {
        switch format {
        case .decimalDegrees:
            return formatDecimalDegrees(latitude: latitude, longitude: longitude)
        case .degreesMinutes:
            return formatDegreesMinutes(latitude: latitude, longitude: longitude)
        case .degreesMinutesSeconds:
            return formatDegreesMinutesSeconds(latitude: latitude, longitude: longitude)
        }
    }
    
    /// Formate depuis CLLocationCoordinate2D
    static func format(
        coordinate: CLLocationCoordinate2D,
        format: CoordinateFormat = .decimalDegrees
    ) -> String {
        self.format(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            format: format
        )
    }
    
    /// Formate depuis CLLocation
    static func format(
        location: CLLocation,
        format: CoordinateFormat = .decimalDegrees
    ) -> String {
        self.format(coordinate: location.coordinate, format: format)
    }
    
    // MARK: - Conversion Helpers
    
    private static func convertToDegreesMinutes(_ decimal: Double) -> (degrees: Int, minutes: Double) {
        let absDecimal = abs(decimal)
        let degrees = Int(absDecimal)
        let minutes = (absDecimal - Double(degrees)) * 60.0
        return (degrees, minutes)
    }
    
    private static func convertToDegreesMinutesSeconds(_ decimal: Double) -> (degrees: Int, minutes: Int, seconds: Double) {
        let absDecimal = abs(decimal)
        let degrees = Int(absDecimal)
        let minutesDecimal = (absDecimal - Double(degrees)) * 60.0
        let minutes = Int(minutesDecimal)
        let seconds = (minutesDecimal - Double(minutes)) * 60.0
        return (degrees, minutes, seconds)
    }
    
    // MARK: - Display Helpers
    
    /// Formate pour affichage compact (carte)
    static func formatCompact(latitude: Double, longitude: Double) -> String {
        formatDecimalDegrees(latitude: latitude, longitude: longitude, decimals: 2)
    }
    
    /// Formate pour affichage détaillé (fiche spot)
    static func formatDetailed(latitude: Double, longitude: Double) -> String {
        formatDecimalDegrees(latitude: latitude, longitude: longitude, decimals: 6)
    }
    
    /// Formate pour clipboard (copie simple)
    static func formatForClipboard(latitude: Double, longitude: Double) -> String {
        "\(latitude), \(longitude)"
    }
    
    /// Génère URL Google Maps
    static func googleMapsURL(latitude: Double, longitude: Double) -> URL? {
        let urlString = "https://www.google.com/maps?q=\(latitude),\(longitude)"
        return URL(string: urlString)
    }
    
    /// Génère URL Navionics (deep link)
    static func navionicsURL(latitude: Double, longitude: Double) -> URL? {
        // Format: navionics://goto?lat=X&lon=Y
        let urlString = "navionics://goto?lat=\(latitude)&lon=\(longitude)"
        return URL(string: urlString)
    }
    
    /// Génère URL Navionics Web (fallback si app non installée)
    static func navionicsWebURL(latitude: Double, longitude: Double, zoom: Int = 14) -> URL? {
        let urlString = "https://webapp.navionics.com/?lang=fr#@\(zoom),\(latitude),\(longitude)"
        return URL(string: urlString)
    }
}

// MARK: - Extensions

extension CLLocationCoordinate2D {
    /// Formate les coordonnées
    func formatted(_ format: CoordinateFormatter.CoordinateFormat = .decimalDegrees) -> String {
        CoordinateFormatter.format(coordinate: self, format: format)
    }
    
    /// Formate compact
    var formattedCompact: String {
        CoordinateFormatter.formatCompact(latitude: latitude, longitude: longitude)
    }
    
    /// Formate détaillé
    var formattedDetailed: String {
        CoordinateFormatter.formatDetailed(latitude: latitude, longitude: longitude)
    }
    
    /// URL Google Maps
    var googleMapsURL: URL? {
        CoordinateFormatter.googleMapsURL(latitude: latitude, longitude: longitude)
    }
    
    /// URL Navionics
    var navionicsURL: URL? {
        CoordinateFormatter.navionicsURL(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Preview Examples

#if DEBUG
extension CoordinateFormatter {
    static var exampleFormats: [(String, String)] {
        let lat = -22.2758
        let lon = 166.4580
        
        return [
            ("Décimal", formatDecimalDegrees(latitude: lat, longitude: lon)),
            ("Degrés-Minutes", formatDegreesMinutes(latitude: lat, longitude: lon)),
            ("Degrés-Minutes-Secondes", formatDegreesMinutesSeconds(latitude: lat, longitude: lon)),
            ("Compact", formatCompact(latitude: lat, longitude: lon)),
            ("Détaillé", formatDetailed(latitude: lat, longitude: lon))
        ]
    }
}
#endif
