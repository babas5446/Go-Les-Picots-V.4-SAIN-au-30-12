// TideCurveView.swift
// Go Les Picots V.4
//
// Courbe sinusoïdale des marées superposée aux périodes solunaires.
// Interpolation cosinus entre étales consécutifs.
// Axe Y fixe : -1.0 m → 2.0 m (marnage NC max 1.6 m).
// Fond : zone jour (bleu clair) / nuit (gris foncé) calculée depuis lever/coucher soleil.
// Points étales : vert = haute mer, rouge = basse mer.
// Icônes poissons aux périodes solunaires majeures/mineures.
// Ligne "maintenant" : rouge, uniquement si date = aujourd'hui.

import SwiftUI

// MARK: - Vue principale

struct TideCurveView: View {

    let tideDay: CabaigneDay?
    let solunarDay: SolunarDay?
    let selectedDate: Date
    let onRefresh: () -> Void

    private let timeZone = TimeZone(identifier: "Pacific/Noumea")!

    // Axe Y fixe
    private let yMin: Double = -1.0
    private let yMax: Double =  2.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            // En-tête : titre + bouton actualiser
            HStack {
                Text("Marées")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                }
            }

            if let day = tideDay {
                // Graphique
                GeometryReader { geo in
                    ZStack {
                        // 1. Fond jour / nuit
                        dayNightBackground(geo: geo, day: day)

                        // 2. Courbe de marée
                        tideCurve(geo: geo, events: day.events)

                        // 3. Points étales
                        ForEach(day.events) { event in
                            tideEventMarker(event: event, geo: geo, events: day.events)
                        }

                        // 4. Icônes poissons (périodes solunaires)
                        if let sol = solunarDay {
                            solunarFishMarkers(geo: geo, solunar: sol)
                        }

                        // 5. Ligne "maintenant"
                        if isToday(selectedDate) {
                            nowLine(geo: geo)
                        }

                        // 6. Axe Y — labels hauteur
                        yAxisLabels(geo: geo)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 0.5)
                    )
                }
                .frame(height: 160)

                // Axe X — labels heures
                xAxisLabels

                // Légende compacte
                legendRow

            } else {
                // Placeholder
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 160)
                    .overlay(
                        Text("Données non disponibles pour ce jour")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
        }
    }

    // MARK: - Fond jour / nuit

    @ViewBuilder
    private func dayNightBackground(geo: GeometryProxy, day: CabaigneDay) -> some View {
        let w = geo.size.width
        let h = geo.size.height

        // Fond de base : nuit (gris)
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(width: w, height: h)

        // Zone jour : bleu très clair
        if let rise = day.sunrise, let set = day.sunset {
            let x1 = xPos(for: rise, width: w)
            let x2 = xPos(for: set,  width: w)
            let dayWidth = max(0, x2 - x1)

            Rectangle()
                .fill(Color.blue.opacity(0.08))
                .frame(width: dayWidth, height: h)
                // Le ZStack centre la bande : on décale son CENTRE en x1 + largeur/2.
                .offset(x: x1 + dayWidth / 2 - w / 2)

            // Marqueurs lever/coucher soleil
            solarMarker(x: x1, width: w, height: h, isRise: true)
            solarMarker(x: x2, width: w, height: h, isRise: false)
        }
    }

    @ViewBuilder
    private func solarMarker(x: CGFloat, width: CGFloat, height: CGFloat, isRise: Bool) -> some View {
        VStack(spacing: 0) {
            Image(systemName: isRise ? "sunrise.fill" : "sunset.fill")
                .font(.system(size: 10))
                .foregroundColor(.orange)
            Rectangle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: 1, height: height - 14)
        }
        .frame(height: height)
        .offset(x: x - width / 2)   // largeur réelle du graphique, et non celle de l'écran
    }

    // MARK: - Courbe de marée

    @ViewBuilder
    private func tideCurve(geo: GeometryProxy, events: [CabaigneEvent]) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        let sorted = events.sorted { $0.time < $1.time }

        if sorted.count >= 2 {
            Path { path in
                // Points de la courbe : interpolation cosinus entre chaque paire d'étales
                let allPoints = interpolatedPoints(events: sorted, width: w, height: h)
                guard let first = allPoints.first else { return }

                path.move(to: first)
                for pt in allPoints.dropFirst() {
                    path.addLine(to: pt)
                }
            }
            .stroke(Color.blue, lineWidth: 2)

            // Zone remplie sous la courbe
            Path { path in
                let allPoints = interpolatedPoints(events: sorted, width: w, height: h)
                guard let first = allPoints.first else { return }

                path.move(to: CGPoint(x: first.x, y: h))
                path.addLine(to: first)
                for pt in allPoints.dropFirst() {
                    path.addLine(to: pt)
                }
                path.addLine(to: CGPoint(x: allPoints.last?.x ?? w, y: h))
                path.closeSubpath()
            }
            .fill(Color.blue.opacity(0.15))
        }
    }

    /// Génère les points de la courbe par interpolation cosinus entre étales.
    private func interpolatedPoints(
        events: [CabaigneEvent],
        width: CGFloat,
        height: CGFloat,
        stepsPerSegment: Int = 40
    ) -> [CGPoint] {
        var points: [CGPoint] = []

        // Extension de la courbe avant le premier étale et après le dernier
        // en utilisant les étales virtuels (inverse du premier/dernier connu)
        var extended = events

        // Étale virtuel avant minuit : inverse du premier étale, décalé d'une demi-période (~6h)
        if let first = events.first {
            let halfPeriod: TimeInterval = 6 * 3600
            let virtualTime = first.time.addingTimeInterval(-halfPeriod)
            let virtualHeight = first.isHigh ? 0.2 : 1.4  // approximation NC
            extended.insert(CabaigneEvent(time: virtualTime, isHigh: !first.isHigh, height: virtualHeight), at: 0)
        }

        // Étale virtuel après minuit : inverse du dernier
        if let last = events.last {
            let halfPeriod: TimeInterval = 6 * 3600
            let virtualTime = last.time.addingTimeInterval(halfPeriod)
            let virtualHeight = last.isHigh ? 0.2 : 1.4
            extended.append(CabaigneEvent(time: virtualTime, isHigh: !last.isHigh, height: virtualHeight))
        }

        for i in 0..<(extended.count - 1) {
            let e1 = extended[i]
            let e2 = extended[i + 1]

            for step in 0...stepsPerSegment {
                let t = Double(step) / Double(stepsPerSegment)  // 0 → 1
                // Interpolation cosinus : f(t) = (1 - cos(π·t)) / 2
                let cosT = (1.0 - cos(.pi * t)) / 2.0
                let h1 = e1.height
                let h2 = e2.height
                let interpolatedHeight = h1 + (h2 - h1) * cosT

                let x = xPos(for: e1.time, width: width) +
                    CGFloat(t) * (xPos(for: e2.time, width: width) - xPos(for: e1.time, width: width))
                let y = yPos(for: interpolatedHeight, height: height)

                // On ne trace que les points dans la fenêtre [0, width]
                if x >= 0 && x <= width {
                    points.append(CGPoint(x: x, y: y))
                }
            }
        }

        return points
    }

    // MARK: - Marqueurs étales

    @ViewBuilder
    private func tideEventMarker(
        event: CabaigneEvent,
        geo: GeometryProxy,
        events: [CabaigneEvent]
    ) -> some View {
        let x = xPos(for: event.time, width: geo.size.width)
        let y = yPos(for: event.height, height: geo.size.height)
        let color: Color = event.isHigh ? .green : .red

        // Étiquette heure + hauteur — au-dessus pour haute mer, en dessous pour basse mer
        let labelOffset: CGFloat = event.isHigh ? -28 : 14

        ZStack {
            // Point
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
                .position(x: x, y: y)

            // Étiquette
            VStack(spacing: 1) {
                Text(formattedTime(event.time))
                    .font(.system(size: 9, weight: .semibold))
                    .monospacedDigit()
                Text(String(format: "%.2f m", event.height))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .foregroundColor(color)
            .position(x: x, y: y + labelOffset)
        }
    }

    // MARK: - Icônes poissons (activité solunaire)

    @ViewBuilder
    private func solunarFishMarkers(geo: GeometryProxy, solunar: SolunarDay) -> some View {
        let h = geo.size.height
        let w = geo.size.width

        ForEach(Array(solunar.allPeriods.enumerated()), id: \.offset) { _, period in
            let centerTime = period.interval.start.addingTimeInterval(period.interval.duration / 2)
            let x = xPos(for: centerTime, width: w)
            guard x >= 0 && x <= w else { return AnyView(EmptyView()) }

            let fontSize: CGFloat = period.isMajor ? 14 : 10
            let opacity: Double   = period.isMajor ? 0.85 : 0.55

            return AnyView(
                Text("🐟")
                    .font(.system(size: fontSize))
                    .opacity(opacity)
                    .position(x: x, y: h - 12)
            )
        }
    }

    // MARK: - Ligne "maintenant"

    @ViewBuilder
    private func nowLine(geo: GeometryProxy) -> some View {
        let x = xPos(for: Date(), width: geo.size.width)
        guard x >= 0 && x <= geo.size.width else { return AnyView(EmptyView()) }

        return AnyView(
            Rectangle()
                .fill(Color.red.opacity(0.8))
                .frame(width: 1.5, height: geo.size.height)
                .position(x: x, y: geo.size.height / 2)
        )
    }

    // MARK: - Labels axe Y

    @ViewBuilder
    private func yAxisLabels(geo: GeometryProxy) -> some View {
        let w = geo.size.width
        let h = geo.size.height
        let levels: [Double] = [-1.0, 0.0, 0.5, 1.0, 1.5, 2.0]

        ForEach(levels, id: \.self) { level in
            let y = yPos(for: level, height: h)
            HStack(spacing: 2) {
                Text(String(format: "%.0f", level))
                    .font(.system(size: 7))
                    .foregroundColor(.secondary)
                    .frame(width: 14, alignment: .trailing)
                Rectangle()
                    .fill(Color(.systemGray4).opacity(0.4))
                    .frame(width: w - 14, height: 0.5)
            }
            .position(x: w / 2, y: y)
        }
    }

    // MARK: - Axe X

    private var xAxisLabels: some View {
        HStack {
            ForEach([0, 4, 8, 12, 16, 20, 24], id: \.self) { hour in
                Text(hour == 0 || hour == 24 ? "\(hour)h" : "\(hour)h")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                if hour < 24 { Spacer() }
            }
        }
    }

    // MARK: - Légende

    private var legendRow: some View {
        HStack(spacing: 12) {
            Label("Haute mer", systemImage: "circle.fill")
                .foregroundColor(.green)
                .font(.caption2)
            Label("Basse mer", systemImage: "circle.fill")
                .foregroundColor(.red)
                .font(.caption2)
            Spacer()
            Text("🐟 Activité solunaire")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Utilitaires de positionnement

    /// Position X d'une Date sur la barre 0h→24h.
    private func xPos(for date: Date, width: CGFloat) -> CGFloat {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let dayStart = cal.startOfDay(for: selectedDate)
        let elapsed  = date.timeIntervalSince(dayStart)
        let fraction = elapsed / 86400.0
        return CGFloat(fraction) * width
    }

    /// Position Y d'une hauteur de marée sur l'axe Y fixe [-1, 2].
    private func yPos(for height: Double, height viewHeight: CGFloat) -> CGFloat {
        let range = yMax - yMin
        let fraction = (yMax - height) / range   // inversé : haut = haute mer
        return CGFloat(fraction) * viewHeight
    }

    // MARK: - Formatage

    private func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale    = Locale(identifier: "fr_FR")
        fmt.dateFormat = "HH:mm"
        fmt.timeZone  = timeZone
        return fmt.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal.isDateInToday(date)
    }
}

// MARK: - Section marées dans SolunarView (composant d'intégration)

/// Bloc complet "Marées" à insérer dans SolunarView.
/// Gère le sélecteur de commune et appelle TideCurveView.
struct TideSectionView: View {

    @ObservedObject var tideService: TideService
    let solunarDay: SolunarDay?
    let selectedDate: Date

    var body: some View {
        VStack(spacing: 12) {

            // En-tête : sélecteur commune
            HStack {
                Text("MARÉES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                    .tracking(1)

                Spacer()

                // Picker commune
                Menu {
                    ForEach(CabaigneCommune.all) { commune in
                        Button(commune.name) {
                            tideService.selectedCommune = commune
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(tideService.selectedCommune.name)
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.accentColor)
                }
            }

            // Message d'erreur éventuel
            if let error = tideService.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Spinner ou courbe
            if tideService.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Chargement des marées…")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                TideCurveView(
                    tideDay: tideService.tideDay(for: selectedDate),
                    solunarDay: solunarDay,
                    selectedDate: selectedDate,
                    onRefresh: {
                        Task {
                            await tideService.load(
                                for: tideService.selectedCommune,
                                forceRefresh: true
                            )
                        }
                    }
                )
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}
