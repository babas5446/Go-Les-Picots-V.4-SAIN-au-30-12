//
//  LocationService.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Service de géolocalisation avec gestion des permissions
//

import Foundation
import CoreLocation
import Observation

/// Service de géolocalisation
@Observable
class LocationService: NSObject {
    
    // MARK: - Properties
    private let locationManager = CLLocationManager()
    
    /// Position actuelle de l'utilisateur
    var currentLocation: CLLocation?
    
    /// Statut de l'autorisation
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Indicateur de mise à jour en cours
    var isUpdatingLocation = false
    
    /// Dernière erreur
    var lastError: LocationError?
    
    // MARK: - Initializer
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Mise à jour tous les 10m
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Demande l'autorisation de localisation
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Démarre la mise à jour de la localisation
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            lastError = .unauthorized
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    /// Arrête la mise à jour de la localisation
    func stopUpdatingLocation() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Obtient une position unique
    func requestLocation() async throws -> CLLocation {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            throw LocationError.unauthorized
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var hasResumed = false
            
            // Timeout de 10 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if !hasResumed {
                    hasResumed = true
                    continuation.resume(throwing: LocationError.timeout)
                }
            }
            
            // Demande une position unique
            Task { @MainActor in
                if let location = currentLocation, location.timestamp.timeIntervalSinceNow > -30 {
                    // Position récente disponible
                    if !hasResumed {
                        hasResumed = true
                        continuation.resume(returning: location)
                    }
                } else {
                    // Attente nouvelle position
                    locationManager.requestLocation()
                }
            }
        }
    }
    
    /// Calcule la distance entre deux positions
    func distance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1000.0 // en km
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                lastError = .denied
            case .locationUnknown:
                lastError = .locationUnknown
            default:
                lastError = .unknown(error)
            }
        } else {
            lastError = .unknown(error)
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        // Démarre automatiquement si autorisé
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            if isUpdatingLocation {
                startUpdatingLocation()
            }
        }
    }
}

// MARK: - Location Error
enum LocationError: LocalizedError {
    case unauthorized
    case denied
    case locationUnknown
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Autorisation de localisation non accordée"
        case .denied:
            return "Accès à la localisation refusé. Activez-le dans Réglages."
        case .locationUnknown:
            return "Impossible de déterminer votre position"
        case .timeout:
            return "Délai d'attente dépassé pour obtenir la position"
        case .unknown(let error):
            return "Erreur de localisation : \(error.localizedDescription)"
        }
    }
}

// MARK: - Predefined Locations (pour tests)
extension LocationService {
    /// Coordonnées prédéfinies Nouvelle-Calédonie
    static let predefinedLocations: [String: CLLocationCoordinate2D] = [
        "Nouméa": CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580),
        "Île des Pins": CLLocationCoordinate2D(latitude: -22.5889, longitude: 167.4846),
        "Bourail": CLLocationCoordinate2D(latitude: -21.5667, longitude: 165.4833),
        "Koné": CLLocationCoordinate2D(latitude: -21.0594, longitude: 164.8606),
        "Lifou": CLLocationCoordinate2D(latitude: -20.9167, longitude: 167.2667)
    ]
}
