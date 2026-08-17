//
//  TraceGPSService.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Gestion de la trace GPS pendant une sortie de pêche.
//
//  Responsabilités :
//  - Demande d'autorisation localisation (whenInUse)
//  - Enregistrement d'un PointGPS toutes les 30 secondes
//  - Rattachement des points à la Sortie en cours via ModelContext
//  - Export GPX depuis les PointGPS d'une Sortie
//
//  Usage :
//  - Déclenchement manuel via demarrerTrace(sortie:) / arreterTrace()
//  - Pas d'enregistrement en background
//

import Foundation
import CoreLocation
import SwiftData
import Combine

@MainActor
final class TraceGPSService: NSObject, ObservableObject {

    // MARK: - État observable

    @Published var enregistrement: Bool = false
    @Published var autorisationRefusee: Bool = false
    @Published var dernierPoint: CLLocationCoordinate2D?

    // MARK: - Privé

    private let locationManager: CLLocationManager
    private var context: ModelContext?
    private var sortieEnCours: Sortie?
    private var timer: Timer?

    private let intervalle: TimeInterval = 30

    // MARK: - Initialisation

    override init() {
        self.locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - API publique

    /// Démarre l'enregistrement de la trace GPS pour une sortie donnée.
    func demarrerTrace(sortie: Sortie, context: ModelContext) {
        guard !enregistrement else { return }

        self.context     = context
        self.sortieEnCours = sortie

        let statut = locationManager.authorizationStatus
        if statut == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            // Le démarrage effectif se fera dans le delegate après autorisation
            return
        }

        guard statut == .authorizedWhenInUse || statut == .authorizedAlways else {
            autorisationRefusee = true
            return
        }

        demarrerEnregistrement()
    }

    /// Arrête l'enregistrement de la trace GPS.
    func arreterTrace() {
        timer?.invalidate()
        timer = nil
        locationManager.stopUpdatingLocation()
        enregistrement   = false
        sortieEnCours    = nil
        context          = nil
    }

    // MARK: - Export GPX

    /// Génère un fichier GPX depuis les points d'une Sortie.
    /// Retourne l'URL du fichier dans le répertoire temporaire.
    func exporterGPX(sortie: Sortie) throws -> URL {
        let points = sortie.pointsGPS.sorted { $0.timestamp < $1.timestamp }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]

        var gpx = """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1"
             creator="Go Les Picots V.4"
             xmlns="http://www.topografix.com/GPX/1/1">
          <trk>
            <name>\(sortie.nomSpot.isEmpty ? "Sortie du \(formatDate(sortie.date))" : sortie.nomSpot)</name>
            <trkseg>
        """

        for point in points {
            gpx += """

                  <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                    <time>\(dateFormatter.string(from: point.timestamp))</time>
                  </trkpt>
        """
        }

        gpx += """

            </trkseg>
          </trk>
        </gpx>
        """

        let nomFichier = "trace_\(formatDateFichier(sortie.date)).gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(nomFichier)
        try gpx.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - Privé — enregistrement

    private func demarrerEnregistrement() {
        locationManager.startUpdatingLocation()
        enregistrement = true

        // Premier point immédiat
        enregistrerPoint()

        // Puis toutes les 30 secondes
        timer = Timer.scheduledTimer(
            withTimeInterval: intervalle,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                self?.enregistrerPoint()
            }
        }
    }

    private func enregistrerPoint() {
        guard
            let location = locationManager.location,
            let sortie   = sortieEnCours,
            let context  = context
        else { return }

        let point = PointGPS(
            timestamp: Date(),
            latitude:  location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        point.sortie = sortie
        sortie.pointsGPS.append(point)
        context.insert(point)

        try? context.save()

        dernierPoint = location.coordinate
    }

    // MARK: - Privé — formatage dates

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        f.locale    = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }

    private func formatDateFichier(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}

// MARK: - CLLocationManagerDelegate

extension TraceGPSService: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.autorisationRefusee = false
                // Démarre si une sortie attend l'autorisation
                if self.sortieEnCours != nil && !self.enregistrement {
                    self.demarrerEnregistrement()
                }
            case .denied, .restricted:
                self.autorisationRefusee = true
                self.arreterTrace()
            default:
                break
            }
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Échec silencieux — la trace continue avec les points déjà enregistrés
        print("❌ TraceGPSService : \(error.localizedDescription)")
    }
}
