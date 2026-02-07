//
//  FishingSpot.swift
//  Go Les Picots V.4
//
//  Modèle de données pour les spots de pêche
//  Compatible SwiftData pour persistance locale
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class FishingSpot {
    
    // MARK: - Propriétés essentielles (V1)
    
    /// Identifiant unique du spot
    var id: UUID
    
    /// Nom du spot (obligatoire)
    var name: String
    
    /// Latitude (format décimal)
    var latitude: Double
    
    /// Longitude (format décimal)
    var longitude: Double
    
    /// Date et heure de création
    var createdAt: Date
    
    /// Notes libres de l'utilisateur (optionnel)
    var notes: String?
    
    // MARK: - Propriétés enrichies (V2) - Préparées mais non utilisées
    
    /// Profondeur estimée en mètres (optionnel)
    var depth: Double?
    
    /// Catégorie du spot (stockage raw value)
    var categoryRawValue: String?
    
    /// Espèces ciblées (stockage JSON string)
    var targetSpeciesJSON: String?
    
    /// IDs des leurres efficaces sur ce spot (stockage JSON string)
    var successfulLuresJSON: String?
    
    /// Chemins des photos associées (stockage JSON string)
    var photosJSON: String?
    
    // MARK: - Propriétés calculées
    
    /// Coordonnées CLLocationCoordinate2D pour MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Catégorie typée (V2)
    var category: SpotCategory? {
        get {
            guard let raw = categoryRawValue else { return nil }
            return SpotCategory(rawValue: raw)
        }
        set {
            categoryRawValue = newValue?.rawValue
        }
    }
    
    /// Espèces ciblées typées (V2)
    var targetSpecies: [String] {
        get {
            guard let json = targetSpeciesJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                targetSpeciesJSON = json
            }
        }
    }
    
    /// IDs leurres efficaces typés (V2)
    var successfulLures: [UUID] {
        get {
            guard let json = successfulLuresJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([UUID].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                successfulLuresJSON = json
            }
        }
    }
    
    /// Chemins photos typés (V2)
    var photos: [String] {
        get {
            guard let json = photosJSON,
                  let data = json.data(using: .utf8),
                  let array = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return array
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let json = String(data: data, encoding: .utf8) {
                photosJSON = json
            }
        }
    }
    
    /// Âge du spot (en jours depuis création)
    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// Indicateur spot récent (< 7 jours)
    var isRecent: Bool {
        ageInDays < 7
    }
    
    /// Vérification si le spot est en Nouvelle-Calédonie
    var isInNewCaledonia: Bool {
        // Bounding box approximative Nouvelle-Calédonie
        // Latitude: -22.7 à -19.5
        // Longitude: 163.5 à 168.5
        let latInRange = latitude >= -22.7 && latitude <= -19.5
        let lonInRange = longitude >= 163.5 && longitude <= 168.5
        return latInRange && lonInRange
    }
    
    // MARK: - Initialisation
    
    /// Initialisation complète
    init(
        id: UUID = UUID(),
        name: String,
        latitude: Double,
        longitude: Double,
        createdAt: Date = Date(),
        notes: String? = nil,
        depth: Double? = nil,
        category: SpotCategory? = nil,
        targetSpecies: [String] = [],
        successfulLures: [UUID] = [],
        photos: [String] = []
    ) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.notes = notes
        self.depth = depth
        self.categoryRawValue = category?.rawValue
        
        // Encodage JSON pour propriétés V2
        if !targetSpecies.isEmpty,
           let data = try? JSONEncoder().encode(targetSpecies),
           let json = String(data: data, encoding: .utf8) {
            self.targetSpeciesJSON = json
        }
        
        if !successfulLures.isEmpty,
           let data = try? JSONEncoder().encode(successfulLures),
           let json = String(data: data, encoding: .utf8) {
            self.successfulLuresJSON = json
        }
        
        if !photos.isEmpty,
           let data = try? JSONEncoder().encode(photos),
           let json = String(data: data, encoding: .utf8) {
            self.photosJSON = json
        }
    }
    
    /// Initialisation simplifiée V1 (nom + coords uniquement)
    convenience init(name: String, coordinate: CLLocationCoordinate2D, notes: String? = nil) {
        self.init(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            notes: notes
        )
    }
    
    // MARK: - Méthodes utilitaires
    
    /// Distance depuis une position donnée (en mètres)
    func distance(from location: CLLocation) -> CLLocationDistance {
        let spotLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: spotLocation)
    }
    
    /// Distance formatée depuis une position donnée
    func formattedDistance(from location: CLLocation) -> String {
        let meters = distance(from: location)
        if meters < 1000 {
            return String(format: "%.0f m", meters)
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
    
    /// Coordonnées formatées
    func formattedCoordinates(_ format: CoordinateFormatter.CoordinateFormat = .decimalDegrees) -> String {
        CoordinateFormatter.format(latitude: latitude, longitude: longitude, format: format)
    }
    
    /// Coordonnées compactes
    func coordinatesCompact() -> String {
        CoordinateFormatter.formatCompact(latitude: latitude, longitude: longitude)
    }
    
    /// Coordonnées détaillées
    func coordinatesDetailed() -> String {
        CoordinateFormatter.formatDetailed(latitude: latitude, longitude: longitude)
    }
    
    /// URL Google Maps du spot
    var googleMapsURL: URL? {
        CoordinateFormatter.googleMapsURL(latitude: latitude, longitude: longitude)
    }

    /// URL Navionics du spot
    var navionicsURL: URL? {
        CoordinateFormatter.navionicsURL(latitude: latitude, longitude: longitude)
    }
    
    /// Copie du spot (pour édition)
    func copy() -> FishingSpot {
        FishingSpot(
            id: self.id,
            name: self.name,
            latitude: self.latitude,
            longitude: self.longitude,
            createdAt: self.createdAt,
            notes: self.notes,
            depth: self.depth,
            category: self.category,
            targetSpecies: self.targetSpecies,
            successfulLures: self.successfulLures,
            photos: self.photos
        )
    }
}

// MARK: - Preview Helpers
// Note: @Model fournit automatiquement Identifiable, Hashable, Codable
// Ne PAS ajouter d'extensions pour ces protocoles

#if DEBUG
extension FishingSpot {
    /// Spot de test pour previews
    static var preview: FishingSpot {
        FishingSpot(
            name: "Passe Boulari",
            latitude: -22.2758,
            longitude: 166.4580,
            notes: "Fond sableux 15m\nCourant fort à marée montante\nBon pour becs de cane et wahoos"
        )
    }
    
    /// Collection de spots de test
    static var previews: [FishingSpot] {
        [
            FishingSpot(
                name: "Passe Boulari",
                latitude: -22.2758,
                longitude: 166.4580,
                createdAt: Date().addingTimeInterval(-86400 * 3), // 3 jours
                notes: "Fond sableux 15m"
            ),
            FishingSpot(
                name: "Îlot Maître",
                latitude: -22.3241,
                longitude: 166.4112,
                createdAt: Date().addingTimeInterval(-86400 * 14), // 14 jours
                notes: "Bon pour mérous, marée haute"
            ),
            FishingSpot(
                name: "Tombant Tabou",
                latitude: -22.1983,
                longitude: 166.5021,
                createdAt: Date().addingTimeInterval(-3600 * 2), // 2 heures
                notes: nil
            )
        ]
    }
}
#endif
