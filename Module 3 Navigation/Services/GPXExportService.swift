//
//  GPXExportService.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//
//  Service de génération et export de fichiers GPX
//  Format GPX 1.1 compatible Navionics Boating
//

import Foundation
import CoreLocation

final class GPXExportService {
    
    // MARK: - Public Methods
    
    /// Génère un fichier GPX depuis une liste de spots
    /// - Parameters:
    ///   - spots: Liste des spots à exporter
    ///   - includeName: Inclure nom dans metadata (défaut: true)
    /// - Returns: URL du fichier GPX temporaire
    func generateGPXFile(
        from spots: [FishingSpot],
        includeName: Bool = true
    ) throws -> URL {
        guard !spots.isEmpty else {
            throw GPXError.noSpotsToExport
        }
        
        let gpxContent = generateGPXContent(from: spots, includeName: includeName)
        let fileURL = try saveToTemporaryFile(content: gpxContent)
        
        return fileURL
    }
    
    /// Génère le contenu GPX (XML string)
    func generateGPXContent(
        from spots: [FishingSpot],
        includeName: Bool = true
    ) -> String {
        var xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="Go Les Picots V.4" xmlns="http://www.topografix.com/GPX/1/1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
        """
        
        // Metadata
        xml += "\n  <metadata>"
        if includeName {
            xml += "\n    <name>Spots de pêche - Go Les Picots</name>"
        }
        xml += "\n    <desc>Export de \(spots.count) spot\(spots.count > 1 ? "s" : "") de pêche</desc>"
        xml += "\n    <time>\(currentTimeISO8601())</time>"
        xml += "\n  </metadata>"
        
        // Waypoints (spots)
        for spot in spots {
            xml += generateWaypointXML(for: spot)
        }
        
        xml += "\n</gpx>"
        
        return xml
    }
    
    /// Génère un nom de fichier unique
    func generateFileName() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmm"
        dateFormatter.locale = Locale(identifier: "fr_FR")
        dateFormatter.timeZone = TimeZone(identifier: "Pacific/Noumea")
        
        let timestamp = dateFormatter.string(from: Date())
        return "spots_pêche_\(timestamp).gpx"
    }
    
    /// Exporte un seul spot
    func exportSingleSpot(_ spot: FishingSpot) throws -> URL {
        try generateGPXFile(from: [spot], includeName: false)
    }
    
    // MARK: - Private Methods
    
    private func generateWaypointXML(for spot: FishingSpot) -> String {
        var xml = "\n  <wpt lat=\"\(spot.latitude)\" lon=\"\(spot.longitude)\">"
        
        // Nom du spot
        xml += "\n    <name>\(escapeXML(spot.name))</name>"
        
        // Timestamp
        xml += "\n    <time>\(iso8601String(from: spot.createdAt))</time>"
        
        // Description (notes si présentes)
        if let notes = spot.notes, !notes.isEmpty {
            xml += "\n    <desc>\(escapeXML(notes))</desc>"
        }
        
        // Symbole pour apps marines
        xml += "\n    <sym>fishing</sym>"
        
        // Type (pour compatibilité Garmin/Navionics)
        xml += "\n    <type>Fishing Spot</type>"
        
        // Extensions personnalisées (optionnel - pour données enrichies V2)
        if let category = spot.category {
            xml += "\n    <extensions>"
            xml += "\n      <category>\(category.displayName)</category>"
            if let depth = spot.depth {
                xml += "\n      <depth>\(depth)</depth>"
            }
            xml += "\n    </extensions>"
        }
        
        xml += "\n  </wpt>"
        
        return xml
    }
    
    private func saveToTemporaryFile(content: String) throws -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = generateFileName()
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            throw GPXError.fileWriteFailed(error.localizedDescription)
        }
    }
    
    private func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
    
    private func iso8601String(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Pacific/Noumea")
        return formatter.string(from: date)
    }
    
    private func currentTimeISO8601() -> String {
        iso8601String(from: Date())
    }
}

// MARK: - GPXError

enum GPXError: LocalizedError {
    case noSpotsToExport
    case fileWriteFailed(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noSpotsToExport:
            return "Aucun spot à exporter"
        case .fileWriteFailed(let message):
            return "Échec de l'écriture du fichier: \(message)"
        case .invalidData:
            return "Données invalides"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noSpotsToExport:
            return "Sélectionnez au moins un spot à exporter"
        case .fileWriteFailed:
            return "Vérifiez l'espace disponible sur votre appareil"
        case .invalidData:
            return "Vérifiez les données du spot"
        }
    }
}

// MARK: - Preview & Testing

#if DEBUG
extension GPXExportService {
    /// Exemple de contenu GPX généré
    static func previewGPXContent() -> String {
        let service = GPXExportService()
        let spots = FishingSpot.previews
        return service.generateGPXContent(from: spots)
    }
    
    /// Test de génération
    static func testExport() throws -> URL {
        let service = GPXExportService()
        let spots = FishingSpot.previews
        return try service.generateGPXFile(from: spots)
    }
}
#endif

