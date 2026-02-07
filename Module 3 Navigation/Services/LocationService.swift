//
//  LocationService.swift
//  Go Les Picots V.4
//
//  Service de gestion de la localisation GPS
//

import Foundation
import CoreLocation
import Combine

@MainActor
final class LocationService: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    
    /// Position actuelle de l'utilisateur
    @Published var currentLocation: CLLocation?
    
    /// Statut d'autorisation
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    /// Indicateur de mise à jour en cours
    @Published var isUpdating: Bool = false
    
    /// Précision GPS actuelle (en mètres)
    @Published var accuracy: CLLocationAccuracy = 0
    
    /// Erreur éventuelle
    @Published var error: LocationError?
    
    // MARK: - Private Properties
    
    private let locationManager = CLLocationManager()
    private var lastUpdateTime: Date?
    
    // MARK: - Configuration
    
    /// Précision souhaitée (meilleur compromis batterie/précision)
    private let desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    /// Distance minimale pour mise à jour (en mètres)
    private let distanceFilter: CLLocationDistance = 10
    
    // MARK: - Initialisation
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
        locationManager.distanceFilter = distanceFilter
        locationManager.activityType = .otherNavigation // Pour usage bateau
        
        // Mise à jour statut initial
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Demande l'autorisation de localisation
    func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Démarre les mises à jour de localisation
    func startUpdatingLocation() {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            error = .unauthorized
            return
        }
        
        isUpdating = true
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading() // Pour direction bateau
    }
    
    /// Arrête les mises à jour de localisation
    func stopUpdatingLocation() {
        isUpdating = false
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    /// Demande une position unique (pour marquage spot sans tracking)
    func requestSingleLocation(completion: @escaping (Result<CLLocation, LocationError>) -> Void) {
        guard authorizationStatus == .authorizedWhenInUse ||
              authorizationStatus == .authorizedAlways else {
            completion(.failure(.unauthorized))
            return
        }
        
        locationManager.requestLocation()
        
        // Timeout 10 secondes
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }
            if let location = self.currentLocation {
                completion(.success(location))
            } else {
                completion(.failure(.timeout))
            }
        }
    }
    
    /// Vérifie si la localisation est disponible
    var isLocationAvailable: Bool {
        authorizationStatus == .authorizedWhenInUse ||
        authorizationStatus == .authorizedAlways
    }
    
    /// Vérifie si la précision est acceptable (< 50m)
    var isAccuracyAcceptable: Bool {
        guard let location = currentLocation else { return false }
        return location.horizontalAccuracy < 50 && location.horizontalAccuracy >= 0
    }
    
    /// Distance depuis un spot donné
    func distance(to spot: FishingSpot) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        return spot.distance(from: currentLocation)
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            
            // Démarrage auto si autorisé
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.startUpdatingLocation()
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            guard let location = locations.last else { return }
            
            // Filtrage des positions invalides
            guard location.horizontalAccuracy >= 0 else { return }
            
            self.currentLocation = location
            self.accuracy = location.horizontalAccuracy
            self.lastUpdateTime = Date()
            self.error = nil
            
            // Warning si précision médiocre
            if location.horizontalAccuracy > 100 {
                self.error = .poorAccuracy(location.horizontalAccuracy)
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.error = .unauthorized
                case .network:
                    self.error = .networkUnavailable
                case .locationUnknown:
                    self.error = .locationUnknown
                default:
                    self.error = .other(error.localizedDescription)
                }
            } else {
                self.error = .other(error.localizedDescription)
            }
        }
    }
}

// MARK: - LocationError

enum LocationError: LocalizedError {
    case unauthorized
    case networkUnavailable
    case locationUnknown
    case timeout
    case poorAccuracy(CLLocationAccuracy)
    case other(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Accès à la localisation non autorisé"
        case .networkUnavailable:
            return "Réseau indisponible pour le GPS"
        case .locationUnknown:
            return "Position inconnue"
        case .timeout:
            return "Délai de localisation dépassé"
        case .poorAccuracy(let accuracy):
            return "Précision GPS faible (±\(Int(accuracy))m)"
        case .other(let message):
            return message
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Autorisez l'accès dans Réglages > Go Les Picots > Localisation"
        case .networkUnavailable:
            return "Vérifiez votre connexion réseau"
        case .locationUnknown:
            return "Rapprochez-vous d'une fenêtre ou d'un espace dégagé"
        case .timeout:
            return "Réessayez dans quelques secondes"
        case .poorAccuracy:
            return "Rapprochez-vous d'une fenêtre pour améliorer la précision"
        case .other:
            return "Réessayez plus tard"
        }
    }
}
