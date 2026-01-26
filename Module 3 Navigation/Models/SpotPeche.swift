//
//  SpotPeche.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Modèle représentant un spot de pêche géolocalisé
//

import Foundation
import CoreLocation

/// Spot de pêche géolocalisé avec métadonnées
struct SpotPeche: Identifiable, Codable {
    // MARK: - Properties
    let id: UUID
    
    // Géolocalisation
    let latitude: Double
    let longitude: Double
    
    // Identification
    let nom: String
    let dateEnregistrement: Date
    
    // Contexte pêche
    let profondeur: Double?  // mètres
    let leurresUtilises: [UUID]  // références vers LureData.id (Module 2)
    
    // Observations
    let notes: String?
    
    // MARK: - Computed Properties
    
    /// Coordonnées CLLocationCoordinate2D pour MapKit
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Location pour calculs de distance
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    /// Profondeur formatée pour affichage
    var profondeurFormatee: String {
        guard let prof = profondeur else { return "Profondeur inconnue" }
        return String(format: "%.1f m", prof)
    }
    
    // MARK: - Initializer
    init(
        id: UUID = UUID(),
        latitude: Double,
        longitude: Double,
        nom: String,
        dateEnregistrement: Date = Date(),
        profondeur: Double? = nil,
        leurresUtilises: [UUID] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.latitude = latitude
        self.longitude = longitude
        self.nom = nom
        self.dateEnregistrement = dateEnregistrement
        self.profondeur = profondeur
        self.leurresUtilises = leurresUtilises
        self.notes = notes
    }
    
    // MARK: - Methods
    
    /// Calcule la distance vers un autre spot (en km)
    func distance(to other: SpotPeche) -> Double {
        let distance = location.distance(from: other.location)
        return distance / 1000.0 // conversion en km
    }
    
    /// Vérifie si le spot est dans une zone donnée (rayon en km)
    func isInRadius(_ radiusKm: Double, from center: CLLocationCoordinate2D) -> Bool {
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let distance = location.distance(from: centerLocation)
        return distance <= (radiusKm * 1000.0)
    }
}

// MARK: - Equatable
extension SpotPeche: Equatable {
    static func == (lhs: SpotPeche, rhs: SpotPeche) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension SpotPeche: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data (pour tests et previews)
extension SpotPeche {
    static let sample1 = SpotPeche(
        latitude: -22.2758,
        longitude: 166.4580,
        nom: "Passe de Boulari",
        profondeur: 15.5,
        leurresUtilises: [],
        notes: "Bon spot à marée montante"
    )
    
    static let sample2 = SpotPeche(
        latitude: -22.3015,
        longitude: 166.4420,
        nom: "Ilot Maître",
        profondeur: 8.0,
        leurresUtilises: [],
        notes: "Nombreuses carangues"
    )
    
    static let sampleSpots: [SpotPeche] = [sample1, sample2]
}
