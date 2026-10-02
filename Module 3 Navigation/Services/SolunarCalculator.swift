// SolunarCalculator.swift
// Go Les Picots V.4
//
// Calcul solunaire local, pur Swift, zéro dépendance externe.
// Algorithmes : Jean Meeus, "Astronomical Algorithms" (2e éd., 1998)
// Chapitres utilisés : 7 (JDE), 15 (lever/coucher/transit), 47 (position lune), 48 (phase)
//
// Précision visée : ±1–2 min sur les transits, ±2–3 min sur lever/coucher.
// Acceptable pour usage pêche.
//
// Ce fichier est un service de calcul pur.
// Pas de réseau, pas de CoreData, pas de @Published.

import Foundation

// MARK: - Types publics

/// Phase lunaire avec bonus de qualité associé.
enum MoonPhase: String, CaseIterable {
    case newMoon         = "Nouvelle Lune"
    case waxingCrescent  = "Premier Croissant"
    case firstQuarter    = "Premier Quartier"
    case waxingGibbous   = "Gibbeuse Croissante"
    case fullMoon        = "Pleine Lune"
    case waningGibbous   = "Gibbeuse Décroissante"
    case lastQuarter     = "Dernier Quartier"
    case waningCrescent  = "Dernier Croissant"

    /// Bonus ajouté au qualityScore (0–3).
    var qualityBonus: Int {
        switch self {
        case .newMoon, .fullMoon:           return 3
        case .firstQuarter, .lastQuarter:   return 1
        default:                            return 0
        }
    }

    /// Nom court pour l'affichage UI.
    var shortName: String {
        switch self {
        case .newMoon:          return "🌑"
        case .waxingCrescent:   return "🌒"
        case .firstQuarter:     return "🌓"
        case .waxingGibbous:    return "🌔"
        case .fullMoon:         return "🌕"
        case .waningGibbous:    return "🌖"
        case .lastQuarter:      return "🌗"
        case .waningCrescent:   return "🌘"
        }
    }
}

/// Résultat complet pour une journée solunaire.
struct SolunarDay {
    let date: Date                        // Jour de référence (minuit local)
    let moonRise: Date?                   // Lever de lune
    let moonSet: Date?                    // Coucher de lune
    let moonTransit: Date?                // Transit (midi lunaire)
    let moonAntiTransit: Date?            // Anti-transit (minuit lunaire) — peut appartenir au lendemain
    let majorPeriods: [DateInterval]      // 2 périodes × 2h
    let minorPeriods: [DateInterval]      // 2 périodes × 1h
    let moonPhase: MoonPhase
    let moonIllumination: Double          // 0.0 → 1.0
    let moonAge: Double                   // Jours depuis nouvelle lune
    let qualityScore: Int                 // 0–10
}

// MARK: - Calculateur principal

/// Calcule les données solunaires pour une date et des coordonnées GPS données.
/// Toutes les dates en sortie sont en UTC ; la conversion en heure locale est à la charge de l'appelant ou de la vue.
enum SolunarCalculator {

    // MARK: Point d'entrée public

    /// Calcule le `SolunarDay` pour la date et la position données.
    /// - Parameters:
    ///   - date: Jour de référence (n'importe quelle heure, on utilise le jour calendaire).
    ///   - latitude: Latitude en degrés décimaux (positif = Nord).
    ///   - longitude: Longitude en degrés décimaux (positif = Est).
    ///   - timeZone: Fuseau horaire local (pour délimiter les frontières de journée). Défaut : TimeZone.current.
    static func calculate(
        for date: Date,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone = .current
    ) -> SolunarDay {

        // Bornes du jour calendaire local (minuit → minuit)
        let (dayStart, dayEnd) = localDayBounds(for: date, timeZone: timeZone)

        // --- Position et phase lunaire au midi du jour ---
        let midDay = dayStart.addingTimeInterval(12 * 3600)
        let jdeMid = julianEphemerisDay(from: midDay)
        let (illumination, ageInDays, phaseAngle) = moonPhaseData(jde: jdeMid)
        // moonPhaseFromAngle attend une position dans le cycle (0° = nouvelle
        // lune, 180° = pleine lune). L'angle de phase de Meeus suit la
        // convention inverse (i = 0° à la pleine lune) : 180° − i ≈ élongation.
        let phase = moonPhaseFromAngle(normalizeDeg(180.0 - phaseAngle))

        // --- Lever / coucher / transit de la lune ---
        // On cherche dans une fenêtre ±36h pour être sûr de couvrir les cas limites.
        let moonRise   = findMoonEvent(.rise,    near: midDay, lat: latitude, lon: longitude, timeZone: timeZone, dayStart: dayStart, dayEnd: dayEnd)
        let moonSet    = findMoonEvent(.set,      near: midDay, lat: latitude, lon: longitude, timeZone: timeZone, dayStart: dayStart, dayEnd: dayEnd)
        let moonTransit = findMoonEvent(.transit, near: midDay, lat: latitude, lon: longitude, timeZone: timeZone, dayStart: dayStart, dayEnd: dayEnd)

        // Anti-transit : passage au méridien inférieur tombant dans le jour
        // calendaire demandé (nil les rares jours qui n'en comptent pas).
        let moonAntiTransit = findAntiTransit(lat: latitude, lon: longitude, dayStart: dayStart, dayEnd: dayEnd)

        // --- Périodes solunaires ---
        let majorPeriods = buildMajorPeriods(transit: moonTransit, antiTransit: moonAntiTransit)
        let minorPeriods = buildMinorPeriods(rise: moonRise, set: moonSet)

        // --- Score de qualité ---
        let quality = computeQualityScore(
            phase: phase,
            majors: majorPeriods,
            minors: minorPeriods,
            dayStart: dayStart,
            dayEnd: dayEnd
        )

        return SolunarDay(
            date: dayStart,
            moonRise: moonRise,
            moonSet: moonSet,
            moonTransit: moonTransit,
            moonAntiTransit: moonAntiTransit,
            majorPeriods: majorPeriods,
            minorPeriods: minorPeriods,
            moonPhase: phase,
            moonIllumination: illumination,
            moonAge: ageInDays,
            qualityScore: quality
        )
    }

    // MARK: - Bornes du jour calendaire local

    private static func localDayBounds(for date: Date, timeZone: TimeZone) -> (Date, Date) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    // MARK: - Jour Julien Éphéméride (Meeus Ch. 7)

    /// Convertit une Date Swift en Jour Julien Éphéméride (JDE).
    /// On néglige ΔT (différence TT−UTC ≈ 70 s) : erreur < 1 min sur les transits lunaires.
    static func julianEphemerisDay(from date: Date) -> Double {
        let jde = date.timeIntervalSince1970 / 86400.0 + 2440587.5
        return jde
    }

    /// Convertit un JDE en Date Swift.
    static func dateFromJDE(_ jde: Double) -> Date {
        let ti = (jde - 2440587.5) * 86400.0
        return Date(timeIntervalSince1970: ti)
    }

    // MARK: - Position de la Lune (Meeus Ch. 47)

    /// Position écliptique simplifiée de la Lune.
    /// Retourne (longitude écliptique °, latitude écliptique °, distance km).
    static func moonPosition(jde: Double) -> (lon: Double, lat: Double, dist: Double) {
        let T = (jde - 2451545.0) / 36525.0

        // Anomalie moyenne du Soleil
        let M_sun = 357.5291092 + 35999.0502909 * T - 0.0001536 * T * T + T * T * T / 24490000.0

        // Longitude moyenne de la Lune
        let L0 = 218.3164477 + 481267.88123421 * T - 0.0015786 * T * T + T * T * T / 538841.0 - T * T * T * T / 65194000.0

        // Anomalie moyenne de la Lune
        let M_moon = 134.9633964 + 477198.8675055 * T + 0.0087414 * T * T + T * T * T / 69699.0 - T * T * T * T / 14712000.0

        // Argument de latitude de la Lune
        let F = 93.2720950 + 483202.0175233 * T - 0.0036539 * T * T - T * T * T / 3526000.0 + T * T * T * T / 863310000.0

        // Élongation moyenne de la Lune
        let D = 297.8501921 + 445267.1114034 * T - 0.1851675 * T * T + T * T * T / 545868.0 - T * T * T * T / 113065000.0

        let Msr = deg2rad(M_sun)
        let Mmr = deg2rad(M_moon)
        let Fr  = deg2rad(F)
        let Dr  = deg2rad(D)

        // Principaux termes de longitude écliptique (μas → ° après /1e6)
        // Source : Meeus Table 47.A (termes principaux)
        var sumL: Double = 0
        sumL += 6288774 * sin(Mmr)
        sumL += 1274027 * sin(2 * Dr - Mmr)
        sumL +=  658314 * sin(2 * Dr)
        sumL +=  213618 * sin(2 * Mmr)
        sumL -=  185116 * sin(Msr)
        sumL -=  114332 * sin(2 * Fr)
        sumL +=   58793 * sin(2 * Dr - 2 * Mmr)
        sumL +=   57066 * sin(2 * Dr - Msr - Mmr)
        sumL +=   53322 * sin(2 * Dr + Mmr)
        sumL +=   45758 * sin(2 * Dr - Msr)
        sumL -=   40923 * sin(Msr - Mmr)
        sumL -=   34720 * sin(Dr)
        sumL -=   30383 * sin(Msr + Mmr)
        sumL +=   15327 * sin(2 * Dr - 2 * Fr)
        sumL -=   12528 * sin(Mmr + 2 * Fr)
        sumL +=   10980 * sin(Mmr - 2 * Fr)
        sumL +=   10675 * sin(4 * Dr - Mmr)
        sumL +=   10034 * sin(3 * Mmr)
        sumL +=    8548 * sin(4 * Dr - 2 * Mmr)
        sumL -=    7888 * sin(2 * Dr + Msr - Mmr)
        sumL -=    6766 * sin(2 * Dr + Msr)
        sumL -=    5163 * sin(Dr - Mmr)
        sumL +=    4987 * sin(Dr + Msr)
        sumL +=    4036 * sin(2 * Dr - Msr + Mmr)
        sumL +=    3994 * sin(2 * Dr + 2 * Mmr)
        sumL +=    3861 * sin(4 * Dr)
        sumL +=    3665 * sin(2 * Dr - 3 * Mmr)
        sumL -=    2689 * sin(Msr - 2 * Mmr)
        sumL -=    2602 * sin(2 * Dr - Mmr + 2 * Fr)
        sumL +=    2390 * sin(2 * Dr - Msr - 2 * Mmr)
        sumL -=    2348 * sin(Dr + Mmr)
        sumL +=    2236 * sin(2 * Dr - 2 * Msr)
        sumL -=    2120 * sin(Msr + 2 * Mmr)
        sumL -=    2069 * sin(2 * Msr)
        sumL +=    2048 * sin(2 * Dr - 2 * Msr - Mmr)
        sumL -=    1773 * sin(2 * Dr + Mmr - 2 * Fr)
        sumL -=    1595 * sin(2 * Dr + 2 * Fr)
        sumL +=    1215 * sin(4 * Dr - Msr - Mmr)
        sumL -=    1110 * sin(2 * Mmr + 2 * Fr)
        sumL -=     892 * sin(3 * Dr - Mmr)
        sumL -=     810 * sin(2 * Dr + Msr + Mmr)
        sumL +=     759 * sin(4 * Dr - Msr - 2 * Mmr)
        sumL -=     713 * sin(2 * Msr - Mmr)
        sumL -=     700 * sin(2 * Dr + 2 * Msr - Mmr)
        sumL +=     691 * sin(2 * Dr + Msr - 2 * Mmr)
        sumL +=     596 * sin(2 * Dr - Msr - 2 * Fr)
        sumL +=     549 * sin(4 * Dr + Mmr)
        sumL +=     537 * sin(4 * Mmr)
        sumL +=     520 * sin(4 * Dr - Msr)
        sumL -=     487 * sin(Dr - 2 * Mmr)
        sumL -=     399 * sin(2 * Dr + Msr - 2 * Fr)
        sumL -=     381 * sin(2 * Mmr - 2 * Fr)
        sumL +=     351 * sin(Dr + Msr + Mmr)
        sumL -=     340 * sin(3 * Dr - 2 * Mmr)
        sumL +=     330 * sin(4 * Dr - 3 * Mmr)
        sumL +=     327 * sin(2 * Dr - Msr + 2 * Mmr)
        sumL -=     323 * sin(2 * Msr + Mmr)
        sumL +=     299 * sin(Dr + Msr - Mmr)
        sumL +=     294 * sin(2 * Dr + 3 * Mmr)

        let longitude = normalizeDeg(L0 + sumL / 1_000_000.0)

        // Principaux termes de latitude écliptique (Meeus Table 47.B)
        var sumB: Double = 0
        sumB += 5128122 * sin(Fr)
        sumB +=  280602 * sin(Mmr + Fr)
        sumB +=  277693 * sin(Mmr - Fr)
        sumB +=  173237 * sin(2 * Dr - Fr)
        sumB +=   55413 * sin(2 * Dr - Mmr + Fr)
        sumB +=   46271 * sin(2 * Dr - Mmr - Fr)
        sumB +=   32573 * sin(2 * Dr + Fr)
        sumB +=   17198 * sin(2 * Mmr + Fr)
        sumB +=    9266 * sin(2 * Dr + Mmr - Fr)
        sumB +=    8822 * sin(2 * Mmr - Fr)
        sumB +=    8216 * sin(2 * Dr - Msr - Fr)
        sumB +=    4324 * sin(2 * Dr - 2 * Mmr - Fr)
        sumB +=    4200 * sin(2 * Dr + Mmr + Fr)
        sumB -=    3359 * sin(2 * Dr + Msr - Fr)
        sumB +=    2463 * sin(2 * Dr - Msr - Mmr + Fr)
        sumB +=    2211 * sin(2 * Dr - Msr + Fr)
        sumB +=    2065 * sin(2 * Dr - Msr - Mmr - Fr)
        sumB -=    1870 * sin(Msr - Mmr - Fr)
        sumB +=    1828 * sin(4 * Dr - Mmr - Fr)
        sumB -=    1794 * sin(Msr + Fr)
        sumB -=    1749 * sin(3 * Fr)
        sumB -=    1565 * sin(Msr - Mmr + Fr)
        sumB -=    1491 * sin(Dr + Fr)
        sumB -=    1475 * sin(Msr + Mmr + Fr)
        sumB -=    1410 * sin(Msr + Mmr - Fr)
        sumB -=    1344 * sin(Msr - Fr)
        sumB -=    1335 * sin(Dr - Fr)
        sumB +=    1107 * sin(3 * Mmr + Fr)
        sumB +=    1021 * sin(4 * Dr - Fr)
        sumB +=     833 * sin(4 * Dr - Mmr + Fr)
        sumB +=     777 * sin(Mmr - 3 * Fr)
        sumB +=     671 * sin(4 * Dr - 2 * Mmr + Fr)
        sumB +=     607 * sin(2 * Dr - 3 * Fr)
        sumB +=     596 * sin(2 * Dr + 2 * Mmr - Fr)
        sumB +=     491 * sin(2 * Dr - Msr + Mmr - Fr)
        sumB -=     451 * sin(2 * Dr - 2 * Mmr + Fr)
        sumB +=     439 * sin(3 * Mmr - Fr)
        sumB +=     422 * sin(2 * Dr + 2 * Mmr + Fr)
        sumB +=     421 * sin(2 * Dr - 3 * Mmr - Fr)
        sumB -=     366 * sin(2 * Dr + Msr - Mmr + Fr)
        sumB -=     351 * sin(2 * Dr + Msr + Fr)
        sumB +=     331 * sin(4 * Dr + Fr)
        sumB +=     315 * sin(2 * Dr - Msr + Mmr + Fr)
        sumB +=     302 * sin(2 * Dr - 2 * Msr - Fr)
        sumB -=     283 * sin(Mmr + 3 * Fr)
        sumB -=     229 * sin(2 * Dr + Msr + Mmr - Fr)
        sumB +=     223 * sin(Dr + Msr - Fr)
        sumB +=     223 * sin(Dr + Msr + Fr)
        sumB -=     220 * sin(Msr - 2 * Mmr - Fr)
        sumB -=     220 * sin(2 * Dr + Msr - Mmr - Fr)
        sumB -=     185 * sin(Dr + Mmr + Fr)
        sumB +=     181 * sin(2 * Dr - Msr - 2 * Mmr + Fr)
        sumB -=     177 * sin(Msr + 2 * Mmr - Fr)
        sumB +=     176 * sin(4 * Dr - 2 * Mmr - Fr)
        sumB +=     166 * sin(4 * Dr - Msr - Mmr - Fr)
        sumB -=     164 * sin(Dr + Mmr - Fr)
        sumB +=     132 * sin(4 * Dr + Mmr - Fr)
        sumB -=     119 * sin(Dr - Mmr - Fr)
        sumB +=     115 * sin(4 * Dr - Msr - Fr)
        sumB +=     107 * sin(2 * Dr - 2 * Msr + Fr)

        let latitude = sumB / 1_000_000.0

        // Distance (km) — termes principaux Meeus Table 47.A
        var sumR: Double = 0
        sumR += -20905355 * cos(Mmr)
        sumR +=  -3699111 * cos(2 * Dr - Mmr)
        sumR +=  -2955968 * cos(2 * Dr)
        sumR +=   -569925 * cos(2 * Mmr)
        sumR +=    48888 * cos(Msr)
        sumR +=    -3149 * cos(2 * Fr)
        sumR +=   246158 * cos(2 * Dr - 2 * Mmr)
        sumR +=   -152138 * cos(2 * Dr - Msr - Mmr)
        sumR +=   -170733 * cos(2 * Dr + Mmr)
        sumR +=   -204586 * cos(2 * Dr - Msr)
        sumR +=   -129620 * cos(Msr - Mmr)
        sumR +=   108743 * cos(Dr)
        sumR +=   104755 * cos(Msr + Mmr)
        sumR +=    10321 * cos(2 * Dr - 2 * Fr)
        sumR +=    79661 * cos(Mmr - 2 * Fr)
        sumR +=   -34782 * cos(4 * Dr - Mmr)
        sumR +=   -23210 * cos(3 * Mmr)
        sumR +=   -21636 * cos(4 * Dr - 2 * Mmr)
        sumR +=    24208 * cos(2 * Dr + Msr - Mmr)
        sumR +=    30824 * cos(2 * Dr + Msr)
        sumR +=    -8379 * cos(Dr - Mmr)
        sumR +=   -16675 * cos(Dr + Msr)
        sumR +=   -12831 * cos(2 * Dr - Msr + Mmr)
        sumR +=   -10445 * cos(2 * Dr + 2 * Mmr)
        sumR +=   -11650 * cos(4 * Dr)
        sumR +=    14403 * cos(2 * Dr - 3 * Mmr)
        sumR +=    -7003 * cos(Msr - 2 * Mmr)
        sumR +=    10056 * cos(2 * Dr - Msr - 2 * Mmr)
        sumR +=     6322 * cos(Dr + Mmr)
        sumR +=    -9884 * cos(2 * Dr - 2 * Msr)
        sumR +=     5751 * cos(Msr + 2 * Mmr)
        sumR +=    -4950 * cos(2 * Dr - 2 * Msr - Mmr)
        sumR +=     4130 * cos(2 * Dr + Mmr - 2 * Fr)
        sumR +=    -3958 * cos(4 * Dr - Msr - Mmr)
        sumR +=     3258 * cos(3 * Dr - Mmr)
        sumR +=     2616 * cos(2 * Dr + Msr + Mmr)
        sumR +=    -1897 * cos(4 * Dr - Msr - 2 * Mmr)
        sumR +=    -2117 * cos(2 * Msr - Mmr)
        sumR +=     2354 * cos(2 * Dr + 2 * Msr - Mmr)
        sumR +=    -1423 * cos(4 * Dr + Mmr)
        sumR +=    -1117 * cos(4 * Mmr)
        sumR +=    -1571 * cos(4 * Dr - Msr)
        sumR +=    -1739 * cos(Dr - 2 * Mmr)
        sumR +=    -4421 * cos(2 * Mmr - 2 * Fr)
        sumR +=     1165 * cos(2 * Msr + Mmr)
        sumR +=     8752 * cos(2 * Dr - Mmr - 2 * Fr)

        let distance = 385000.56 + sumR / 1000.0

        return (longitude, latitude, distance)
    }

    // MARK: - Phase lunaire (Meeus Ch. 48)

    /// Retourne (illumination 0–1, âge jours, angle de phase °).
    static func moonPhaseData(jde: Double) -> (illumination: Double, age: Double, phaseAngle: Double) {
        let T = (jde - 2451545.0) / 36525.0

        // Anomalie moyenne du Soleil
        let M_sun = normalizeDeg(357.5291092 + 35999.0502909 * T)
        // Anomalie moyenne de la Lune
        let M_moon = normalizeDeg(134.9633964 + 477198.8675055 * T)
        // Élongation de la Lune
        let D = normalizeDeg(297.8501921 + 445267.1114034 * T)

        // Angle de phase i (Meeus eq. 48.4)
        let Dr = deg2rad(D)
        let Msr = deg2rad(M_sun)
        let Mmr = deg2rad(M_moon)

        var i = 180.0 - D
            - 6.289 * sin(Mmr)
            + 2.100 * sin(Msr)
            - 1.274 * sin(2 * Dr - Mmr)
            - 0.658 * sin(2 * Dr)
            - 0.214 * sin(2 * Mmr)
            - 0.110 * sin(Dr)

        i = normalizeDeg(i)

        // Illumination k (Meeus eq. 48.1)
        let illumination = (1.0 + cos(deg2rad(i))) / 2.0

        // Âge lunaire : fraction du cycle synodique × 29.530589 jours
        // On utilise l'élongation normalisée comme proxy
        let age = (D / 360.0) * 29.530589

        return (illumination, age, i)
    }

    /// Détermine la phase lunaire à partir de l'angle de phase écliptique.
    /// L'angle de phase i ∈ [0°, 360°] est converti en position dans le cycle.
    static func moonPhaseFromAngle(_ phaseAngle: Double) -> MoonPhase {
        // phaseAngle = angle de phase i (0° = nouvelle lune, 180° = pleine lune)
        // On a besoin de l'élongation D pour distinguer croissant/décroissant.
        // Approximation : on utilise directement l'âge lunaire (0–29.53 j).
        // Cette fonction est appelée avec phaseAngle = i (angle de phase).
        // i ~ 0° → nouvelle lune ; i ~ 180° → pleine lune.
        // Pour distinguer croissant/décroissant, on se base sur i > 180° = décroissant.

        // Attention : l'angle de phase i retourné par moonPhaseData est dans [0°, 360°].
        // Convention : i < 180° = croissant, i > 180° = décroissant.
        let normalized = phaseAngle.truncatingRemainder(dividingBy: 360.0)

        switch normalized {
        case 0..<10:     return .newMoon
        case 10..<80:    return .waxingCrescent
        case 80..<100:   return .firstQuarter
        case 100..<170:  return .waxingGibbous
        case 170..<190:  return .fullMoon
        case 190..<260:  return .waningGibbous
        case 260..<280:  return .lastQuarter
        case 280..<350:  return .waningCrescent
        default:         return .newMoon  // 350–360°
        }
    }

    // MARK: - Déclinaison et ascension droite de la Lune

    /// Convertit longitude/latitude écliptique en coordonnées équatoriales (α, δ).
    /// Meeus Ch. 13.
    static func eclipticToEquatorial(lon: Double, lat: Double, jde: Double) -> (ra: Double, dec: Double) {
        // Obliquité de l'écliptique (Meeus eq. 22.2, approximation)
        let T = (jde - 2451545.0) / 36525.0
        let epsilon = 23.439291111 - 0.013004167 * T - 0.0000001639 * T * T + 0.0000005036 * T * T * T

        let lonR = deg2rad(lon)
        let latR = deg2rad(lat)
        let epsR = deg2rad(epsilon)

        let sinLon = sin(lonR)
        let cosLon = cos(lonR)
        let sinLat = sin(latR)
        let cosLat = cos(latR)
        let tanLat = tan(latR)
        let sinEps = sin(epsR)
        let cosEps = cos(epsR)

        let ra  = atan2(sinLon * cosEps - tanLat * sinEps, cosLon)
        let dec = asin(sinLat * cosEps + cosLat * sinEps * sinLon)

        return (normalizeDeg(rad2deg(ra)), rad2deg(dec))
    }

    // MARK: - Angle horaire et altitude

    /// Temps Sidéral de Greenwich à 0h UT pour un JDE donné (Meeus eq. 12.4).
    static func greenwichSiderealTime(jde: Double) -> Double {
        let T = (jde - 2451545.0) / 36525.0
        var theta = 100.4606184 + 36000.7700536 * T + 0.000387933 * T * T - T * T * T / 38710000.0
        return normalizeDeg(theta)
    }

    /// Altitude de la Lune (°) pour un lieu et un instant donnés.
    static func moonAltitude(jde: Double, latitude: Double, longitude: Double) -> Double {
        let (lon, lat, _) = moonPosition(jde: jde)
        let (ra, dec) = eclipticToEquatorial(lon: lon, lat: lat, jde: jde)

        // Temps Sidéral Local
        let theta0 = greenwichSiderealTime(jde: jde)
        // Correction pour l'heure (fraction de jour)
        let ut_hours = (jde - floor(jde) - 0.5) * 24.0
        let thetaLocal = normalizeDeg(theta0 + 360.985647 * (jde - floor(jde) - 0.5) / 1.0 + longitude)

        // Angle horaire H (°)
        let H = normalizeDeg(thetaLocal - ra)
        let Hr = deg2rad(H > 180 ? H - 360 : H)
        let decR = deg2rad(dec)
        let latR = deg2rad(latitude)

        // Altitude (sans réfraction)
        let sinAlt = sin(latR) * sin(decR) + cos(latR) * cos(decR) * cos(Hr)
        var altitude = rad2deg(asin(sinAlt))

        // Réfraction atmosphérique (Meeus Ch. 16, formule simplifiée)
        if altitude > -0.5 {
            let refraction = 1.02 / tan(deg2rad(altitude + 10.3 / (altitude + 5.11))) / 60.0
            altitude += refraction
        }

        return altitude
    }

    // MARK: - Recherche des événements lunaires (Meeus Ch. 15)

    private enum LunarEvent { case rise, set, transit }

    /// Parallaxe horizontale équatoriale de la Lune (°).
    private static func moonParallax(distance: Double) -> Double {
        return rad2deg(asin(6378.14 / distance))
    }

    /// Cherche lever, coucher ou transit dans la fenêtre du jour calendaire local.
    private static func findMoonEvent(
        _ event: LunarEvent,
        near date: Date,
        lat: Double,
        lon: Double,
        timeZone: TimeZone,
        dayStart: Date,
        dayEnd: Date
    ) -> Date? {

        // Horizons : pour lever/coucher, altitude cible = −0.833° (réfraction standard)
        // Pour transit : cherche le maximum d'altitude.
        // Méthode : balayage à pas de 5 min sur [dayStart − 2h, dayEnd + 2h], puis bissection.

        let windowStart = dayStart.addingTimeInterval(-7200)
        let windowEnd   = dayEnd.addingTimeInterval(7200)
        let step: TimeInterval = 300   // 5 minutes
        let targetAlt: Double = -0.833  // horizon apparent

        var prevAlt: Double = moonAltitude(jde: julianEphemerisDay(from: windowStart), latitude: lat, longitude: lon)
        var prevDate = windowStart
        var candidates: [(Date, Double)] = []  // (crossing_time, direction: +1 montée, -1 descente)
        var prevSign = prevAlt >= targetAlt

        var t = windowStart.addingTimeInterval(step)
        while t <= windowEnd {
            let jde  = julianEphemerisDay(from: t)
            let alt  = moonAltitude(jde: jde, latitude: lat, longitude: lon)
            let sign = alt >= targetAlt

            if sign != prevSign {
                // Bissection pour affiner le crossing
                var lo = prevDate
                var hi = t
                for _ in 0..<8 {
                    let mid = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
                    let midAlt = moonAltitude(jde: julianEphemerisDay(from: mid), latitude: lat, longitude: lon)
                    if (midAlt >= targetAlt) == prevSign { lo = mid } else { hi = mid }
                }
                let crossing = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
                let dir = sign ? 1.0 : -1.0   // +1 = montée, -1 = descente
                candidates.append((crossing, dir))
            }

            prevAlt  = alt
            prevSign = sign
            prevDate = t
            t = t.addingTimeInterval(step)
        }

        switch event {
        case .rise:
            // Premier crossing montant dans la fenêtre du jour
            let rising = candidates.filter { $0.0 >= dayStart && $0.0 < dayEnd && $0.1 > 0 }
            return rising.min(by: { $0.0 < $1.0 })?.0

        case .set:
            // Premier crossing descendant dans la fenêtre du jour
            let setting = candidates.filter { $0.0 >= dayStart && $0.0 < dayEnd && $0.1 < 0 }
            return setting.min(by: { $0.0 < $1.0 })?.0

        case .transit:
            // Maximum d'altitude dans la fenêtre du jour
            return findTransitTime(near: date, lat: lat, lon: lon, dayStart: dayStart, dayEnd: dayEnd)
        }
    }

    /// Cherche le transit (maximum local d'altitude) dans le jour calendaire.
    private static func findTransitTime(
        near date: Date,
        lat: Double,
        lon: Double,
        dayStart: Date,
        dayEnd: Date
    ) -> Date? {
        extremumLocal(maximum: true, lat: lat, lon: lon, dayStart: dayStart, dayEnd: dayEnd)
    }

    // MARK: - Anti-transit

    /// Cherche l'anti-transit (minimum local d'altitude, passage au méridien
    /// inférieur) dans le jour calendaire. L'ancienne version retenait le
    /// minimum absolu sur 72 h, donc souvent celui d'un autre jour.
    private static func findAntiTransit(lat: Double, lon: Double, dayStart: Date, dayEnd: Date) -> Date? {
        extremumLocal(maximum: false, lat: lat, lon: lon, dayStart: dayStart, dayEnd: dayEnd)
    }

    /// Premier extremum LOCAL d'altitude lunaire tombant dans [dayStart, dayEnd[.
    ///
    /// Un extremum absolu sur une fenêtre de 26 h peut se trouver au bord de la
    /// fenêtre (ce n'est alors pas un passage au méridien) ou appartenir au jour
    /// voisin : seul un vrai changement de sens de variation est retenu.
    private static func extremumLocal(
        maximum: Bool,
        lat: Double,
        lon: Double,
        dayStart: Date,
        dayEnd: Date
    ) -> Date? {
        let windowStart = dayStart.addingTimeInterval(-3600)
        let windowEnd   = dayEnd.addingTimeInterval(3600)
        let step: TimeInterval = 300

        var temps: [Date] = []
        var altitudes: [Double] = []
        var t = windowStart
        while t <= windowEnd {
            temps.append(t)
            altitudes.append(moonAltitude(jde: julianEphemerisDay(from: t), latitude: lat, longitude: lon))
            t = t.addingTimeInterval(step)
        }
        guard altitudes.count >= 3 else { return nil }

        for k in 1..<(altitudes.count - 1) {
            let a0 = altitudes[k - 1], a1 = altitudes[k], a2 = altitudes[k + 1]
            let estExtremum = maximum ? (a1 >= a0 && a1 > a2) : (a1 <= a0 && a1 < a2)
            guard estExtremum else { continue }

            // Affinage par recherche ternaire entre les deux échantillons voisins
            var lo = temps[k - 1]
            var hi = temps[k + 1]
            for _ in 0..<20 {
                let m1 = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 3)
                let m2 = lo.addingTimeInterval(2 * hi.timeIntervalSince(lo) / 3)
                let b1 = moonAltitude(jde: julianEphemerisDay(from: m1), latitude: lat, longitude: lon)
                let b2 = moonAltitude(jde: julianEphemerisDay(from: m2), latitude: lat, longitude: lon)
                if maximum ? (b1 < b2) : (b1 > b2) { lo = m1 } else { hi = m2 }
            }
            let instant = lo.addingTimeInterval(hi.timeIntervalSince(lo) / 2)
            if instant >= dayStart && instant < dayEnd { return instant }
        }
        return nil
    }

    // MARK: - Construction des périodes solunaires

    private static func buildMajorPeriods(transit: Date?, antiTransit: Date?) -> [DateInterval] {
        var periods: [DateInterval] = []
        if let t = transit {
            periods.append(DateInterval(start: t.addingTimeInterval(-3600), duration: 7200))
        }
        if let at = antiTransit {
            periods.append(DateInterval(start: at.addingTimeInterval(-3600), duration: 7200))
        }
        return periods.sorted { $0.start < $1.start }
    }

    private static func buildMinorPeriods(rise: Date?, set: Date?) -> [DateInterval] {
        var periods: [DateInterval] = []
        if let r = rise {
            periods.append(DateInterval(start: r.addingTimeInterval(-1800), duration: 3600))
        }
        if let s = set {
            periods.append(DateInterval(start: s.addingTimeInterval(-1800), duration: 3600))
        }
        return periods.sorted { $0.start < $1.start }
    }

    // MARK: - Score de qualité (0–10)

    private static func computeQualityScore(
        phase: MoonPhase,
        majors: [DateInterval],
        minors: [DateInterval],
        dayStart: Date,
        dayEnd: Date
    ) -> Int {
        // Bonus de phase (0–3)
        var score = 5 + phase.qualityBonus

        // Bonus : périodes majeures qui tombent dans la journée de pêche (6h–20h)
        let fishingStart = dayStart.addingTimeInterval(6 * 3600)
        let fishingEnd   = dayStart.addingTimeInterval(20 * 3600)
        let fishingWindow = DateInterval(start: fishingStart, end: fishingEnd)

        for period in majors {
            if let _ = fishingWindow.intersection(with: period) {
                score += 1
            }
        }
        for period in minors {
            if let _ = fishingWindow.intersection(with: period) {
                score = min(score + 0, 10)  // Les mineures n'ajoutent pas de point mais pourraient à l'avenir
            }
        }

        return min(max(score, 0), 10)
    }

    // MARK: - Utilitaires trigonométriques

    static func deg2rad(_ d: Double) -> Double { d * .pi / 180.0 }
    static func rad2deg(_ r: Double) -> Double { r * 180.0 / .pi }

    /// Normalise un angle dans [0°, 360°[
    static func normalizeDeg(_ d: Double) -> Double {
        var r = d.truncatingRemainder(dividingBy: 360.0)
        if r < 0 { r += 360.0 }
        return r
    }
}

// MARK: - Extension de commodité pour les vues

extension SolunarDay {

    /// La meilleure période majeure de la journée (celle qui tombe le plus en plein jour).
    var bestMajorPeriod: DateInterval? {
        majorPeriods.max(by: { periodDaylightOverlap($0) < periodDaylightOverlap($1) })
    }

    private func periodDaylightOverlap(_ interval: DateInterval) -> TimeInterval {
        let dayStart   = date
        let fishStart  = dayStart.addingTimeInterval(6 * 3600)
        let fishEnd    = dayStart.addingTimeInterval(20 * 3600)
        let fishWindow = DateInterval(start: fishStart, end: fishEnd)
        return fishWindow.intersection(with: interval)?.duration ?? 0
    }

    /// Toutes les périodes (majeures + mineures) triées chronologiquement.
    var allPeriods: [(interval: DateInterval, isMajor: Bool)] {
        let majors = majorPeriods.map { ($0, true) }
        let minors = minorPeriods.map { ($0, false) }
        return (majors + minors).sorted { $0.0.start < $1.0.start }
    }
}
