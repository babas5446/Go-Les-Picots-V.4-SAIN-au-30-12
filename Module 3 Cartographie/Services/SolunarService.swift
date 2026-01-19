//
//  SolunarService.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Service de calcul des phases lunaires et périodes solunaires (calcul local)
//

import Foundation
import CoreLocation

/// Service de calcul des données solunaires et lunaires
@Observable
class SolunarService {
    
    // MARK: - Properties
    
    /// Dernières données solunaires calculées
    var dernieresPhaseSolunaire: PhaseSolunaire?
    
    // MARK: - Public Methods
    
    /// Calcule les données solunaires pour une date et position donnée
    /// - Parameters:
    ///   - date: Date pour laquelle calculer
    ///   - coordinate: Coordonnées géographiques
    /// - Returns: PhaseSolunaire complète
    func calculatePhaseSolunaire(for date: Date, at coordinate: CLLocationCoordinate2D) -> PhaseSolunaire {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        
        // Calcul phase lune
        let (phase, illumination) = calculateMoonPhase(for: date)
        
        // Calcul lever/coucher soleil
        let (sunrise, sunset) = calculateSunriseSunset(
            for: date,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        // Calcul lever/coucher lune
        let (moonrise, moonset) = calculateMoonriseMoonset(
            for: date,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        // Calcul périodes d'activité
        let periodesMajeures = calculateMajorPeriods(
            for: date,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        
        let periodesMineurs = calculateMinorPeriods(
            moonrise: moonrise,
            moonset: moonset,
            date: date
        )
        
        let phaseSolunaire = PhaseSolunaire(
            phaseLune: phase,
            pourcentageIllumination: illumination,
            leverSoleil: sunrise,
            coucherSoleil: sunset,
            leverLune: moonrise,
            coucherLune: moonset,
            periodesMajeures: periodesMajeures,
            periodesMineurs: periodesMineurs
        )
        
        self.dernieresPhaseSolunaire = phaseSolunaire
        return phaseSolunaire
    }
    
    /// Calcule les phases solunaires pour plusieurs jours
    /// - Parameters:
    ///   - startDate: Date de début
    ///   - days: Nombre de jours
    ///   - coordinate: Coordonnées
    /// - Returns: Tableau de PhaseSolunaire
    func calculatePhaseSolunaireRange(startDate: Date, days: Int, at coordinate: CLLocationCoordinate2D) -> [PhaseSolunaire] {
        var phases: [PhaseSolunaire] = []
        let calendar = Calendar.current
        
        for day in 0..<days {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                let phase = calculatePhaseSolunaire(for: date, at: coordinate)
                phases.append(phase)
            }
        }
        
        return phases
    }
    
    // MARK: - Moon Phase Calculations
    
    /// Calcule la phase de la lune et son pourcentage d'illumination
    /// Algorithme basé sur les cycles lunaires
    private func calculateMoonPhase(for date: Date) -> (PhaseLune, Double) {
        // Nouvelle lune de référence : 6 janvier 2000, 18:14 UTC
        let referenceNewMoon = Date(timeIntervalSince1970: 947182440)
        let synodicMonth = 29.53058867 // Durée cycle lunaire en jours
        
        let daysSinceReference = date.timeIntervalSince(referenceNewMoon) / 86400
        let cycles = daysSinceReference / synodicMonth
        let phase = cycles.truncatingRemainder(dividingBy: 1.0)
        
        // Calcul pourcentage illumination
        let illumination = (1 - cos(phase * 2 * .pi)) / 2 * 100
        
        // Détermination phase lunaire
        let lunPhase: PhaseLune
        switch phase {
        case 0..<0.03, 0.97...1.0:
            lunPhase = .nouvelleLune
        case 0.03..<0.22:
            lunPhase = .premierCroissant
        case 0.22..<0.28:
            lunPhase = .premierQuartier
        case 0.28..<0.47:
            lunPhase = .gibbeuseCroissante
        case 0.47..<0.53:
            lunPhase = .pleineLune
        case 0.53..<0.72:
            lunPhase = .gibbeuseDecroissante
        case 0.72..<0.78:
            lunPhase = .dernierQuartier
        default:
            lunPhase = .dernierCroissant
        }
        
        return (lunPhase, illumination)
    }
    
    // MARK: - Sun Calculations
    
    /// Calcule lever et coucher du soleil
    /// Algorithme simplifié basé sur la position géographique
    private func calculateSunriseSunset(for date: Date, latitude: Double, longitude: Double) -> (Date, Date) {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Calcul déclinaison solaire
        let declination = -23.45 * cos((360.0 / 365.0) * Double(dayOfYear + 10) * .pi / 180) * .pi / 180
        
        // Calcul angle horaire lever/coucher
        let latRad = latitude * .pi / 180
        let hourAngle = acos(-tan(latRad) * tan(declination))
        
        // Conversion en heures (approximation)
        let sunriseHour = 12.0 - (hourAngle * 180 / .pi) / 15.0 - (longitude / 15.0)
        let sunsetHour = 12.0 + (hourAngle * 180 / .pi) / 15.0 - (longitude / 15.0)
        
        // Création des dates avec gestion sécurisée
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let baseDate = calendar.date(from: components) else {
            // Fallback : retourner des valeurs par défaut si la création échoue
            return (date, date)
        }
        
        guard let sunrise = calendar.date(
            bySettingHour: Int(sunriseHour),
            minute: Int((sunriseHour.truncatingRemainder(dividingBy: 1)) * 60),
            second: 0,
            of: baseDate
        ) else {
            return (baseDate, baseDate)
        }
        
        guard let sunset = calendar.date(
            bySettingHour: Int(sunsetHour),
            minute: Int((sunsetHour.truncatingRemainder(dividingBy: 1)) * 60),
            second: 0,
            of: baseDate
        ) else {
            return (sunrise, sunrise)
        }
        
        return (sunrise, sunset)
    }
    
    /// Calcule lever et coucher de la lune
    /// Algorithme simplifié
    private func calculateMoonriseMoonset(for date: Date, latitude: Double, longitude: Double) -> (Date?, Date?) {
        let calendar = Calendar.current
        
        // Approximation : décalage de ~50 minutes par jour par rapport au soleil
        let (sunrise, sunset) = calculateSunriseSunset(for: date, latitude: latitude, longitude: longitude)
        
        let (moonPhase, _) = calculateMoonPhase(for: date)
        
        // Décalage en fonction de la phase
        let dayOffset = moonPhase == .pleineLune ? 12.0 : 0.0
        
        let moonrise = calendar.date(byAdding: .minute, value: Int(dayOffset * 60), to: sunrise)
        let moonset = calendar.date(byAdding: .minute, value: Int(dayOffset * 60), to: sunset)
        
        return (moonrise, moonset)
    }
    
    // MARK: - Solunar Period Calculations
    
    /// Calcule les périodes majeures d'activité
    /// Basé sur le passage de la lune au méridien (transit supérieur et inférieur)
    private func calculateMajorPeriods(for date: Date, latitude: Double, longitude: Double) -> [PeriodeActivite] {
        let calendar = Calendar.current
        
        // Calcul position lune
        let (_, _) = calculateMoonPhase(for: date)
        
        // Transit lunaire supérieur (lune au sud)
        // Approximation : milieu entre lever et coucher
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let baseDate = calendar.date(from: components),
              let midday = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: baseDate) else {
            return []
        }
        
        // Ajustement en fonction longitude (4 minutes par degré)
        let longitudeOffset = Int(longitude * 4)
        guard let transit = calendar.date(byAdding: .minute, value: longitudeOffset, to: midday) else {
            return []
        }
        
        // Période majeure 1 : autour du transit supérieur (durée ~2h)
        guard let periode1Debut = calendar.date(byAdding: .hour, value: -1, to: transit),
              let periode1Fin = calendar.date(byAdding: .hour, value: 1, to: transit) else {
            return []
        }
        
        // Période majeure 2 : transit inférieur (12h plus tard)
        guard let transitInferieur = calendar.date(byAdding: .hour, value: 12, to: transit),
              let periode2Debut = calendar.date(byAdding: .hour, value: -1, to: transitInferieur),
              let periode2Fin = calendar.date(byAdding: .hour, value: 1, to: transitInferieur) else {
            return [
                PeriodeActivite(type: .majeure, heureDebut: periode1Debut, heureFin: periode1Fin)
            ]
        }
        
        return [
            PeriodeActivite(type: .majeure, heureDebut: periode1Debut, heureFin: periode1Fin),
            PeriodeActivite(type: .majeure, heureDebut: periode2Debut, heureFin: periode2Fin)
        ]
    }
    
    /// Calcule les périodes mineures d'activité
    /// Basé sur lever et coucher de lune
    private func calculateMinorPeriods(moonrise: Date?, moonset: Date?, date: Date) -> [PeriodeActivite] {
        guard let rise = moonrise, let set = moonset else {
            return []
        }
        
        let calendar = Calendar.current
        
        // Période mineure au lever de lune (durée ~1h)
        guard let periode1Debut = calendar.date(byAdding: .minute, value: -30, to: rise),
              let periode1Fin = calendar.date(byAdding: .minute, value: 30, to: rise) else {
            return []
        }
        
        // Période mineure au coucher de lune (durée ~1h)
        guard let periode2Debut = calendar.date(byAdding: .minute, value: -30, to: set),
              let periode2Fin = calendar.date(byAdding: .minute, value: 30, to: set) else {
            return [
                PeriodeActivite(type: .mineure, heureDebut: periode1Debut, heureFin: periode1Fin)
            ]
        }
        
        return [
            PeriodeActivite(type: .mineure, heureDebut: periode1Debut, heureFin: periode1Fin),
            PeriodeActivite(type: .mineure, heureDebut: periode2Debut, heureFin: periode2Fin)
        ]
    }
    
    // MARK: - Best Fishing Times
    
    /// Trouve les meilleures périodes de pêche pour une date
    /// - Parameters:
    ///   - date: Date
    ///   - coordinate: Position
    /// - Returns: Tableau de périodes triées par qualité
    func findBestFishingTimes(for date: Date, at coordinate: CLLocationCoordinate2D) -> [BestFishingTime] {
        let phase = calculatePhaseSolunaire(for: date, at: coordinate)
        
        var times: [BestFishingTime] = []
        
        // Périodes majeures (score plus élevé)
        for periode in phase.periodesMajeures {
            times.append(BestFishingTime(
                periode: periode,
                score: calculateFishingScore(periode: periode, phaseSolunaire: phase),
                raison: "Période majeure - Transit lunaire"
            ))
        }
        
        // Périodes mineures
        for periode in phase.periodesMineurs {
            times.append(BestFishingTime(
                periode: periode,
                score: calculateFishingScore(periode: periode, phaseSolunaire: phase),
                raison: "Période mineure - Lever/coucher lune"
            ))
        }
        
        // Tri par score décroissant
        return times.sorted { $0.score > $1.score }
    }
    
    /// Calcule un score de qualité pour une période
    private func calculateFishingScore(periode: PeriodeActivite, phaseSolunaire: PhaseSolunaire) -> Int {
        var score = 0
        
        // Score de base selon type période
        score += periode.type == .majeure ? 60 : 40
        
        // Bonus phase lunaire
        switch phaseSolunaire.phaseLune {
        case .nouvelleLune, .pleineLune:
            score += 30
        case .premierQuartier, .dernierQuartier:
            score += 20
        default:
            score += 10
        }
        
        // Bonus illumination extrême
        if phaseSolunaire.pourcentageIllumination > 90 || phaseSolunaire.pourcentageIllumination < 10 {
            score += 10
        }
        
        return min(score, 100)
    }
}

// MARK: - Best Fishing Time Model
struct BestFishingTime: Identifiable {
    let id = UUID()
    let periode: PeriodeActivite
    let score: Int  // 0-100
    let raison: String
    
    var qualite: String {
        switch score {
        case 80...100: return "Excellent"
        case 60..<80: return "Très bon"
        case 40..<60: return "Bon"
        default: return "Moyen"
        }
    }
    
    var emoji: String {
        switch score {
        case 80...100: return "🌟"
        case 60..<80: return "⭐️"
        case 40..<60: return "✨"
        default: return "💫"
        }
    }
}

// MARK: - Sample Usage
extension SolunarService {
    /// Coordonnées Nouméa
    static let noumea = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
    
    static func exemple() {
        let service = SolunarService()
        
        // Calcul pour aujourd'hui à Nouméa
        let phase = service.calculatePhaseSolunaire(for: Date(), at: noumea)
        
        print("Phase lune: \(phase.phaseLune.displayName) \(phase.phaseLune.emoji)")
        print("Illumination: \(Int(phase.pourcentageIllumination))%")
        print("Indice qualité jour: \(phase.indiceQualite)/100 - \(phase.qualiteJour)")
        print("\nLever soleil: \(phase.leverSoleil)")
        print("Coucher soleil: \(phase.coucherSoleil)")
        
        print("\nPériodes majeures:")
        for periode in phase.periodesMajeures {
            print("  \(periode.periodeFormatee) (\(periode.dureeFormatee))")
        }
        
        print("\nPériodes mineures:")
        for periode in phase.periodesMineurs {
            print("  \(periode.periodeFormatee) (\(periode.dureeFormatee))")
        }
        
        // Meilleures heures de pêche
        let bestTimes = service.findBestFishingTimes(for: Date(), at: noumea)
        print("\nMeilleures périodes de pêche:")
        for time in bestTimes {
            print("  \(time.emoji) \(time.periode.periodeFormatee) - \(time.qualite) (\(time.score)/100)")
            print("     \(time.raison)")
        }
    }
}
