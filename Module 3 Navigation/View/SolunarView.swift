// SolunarView.swift
// Go Les Picots V.4
//
// Vue solunaire principale.
// Calcul local pur via SolunarCalculator — zéro appel réseau.
// Navigation par flèches ◀ ▶, timeline 24h en haut de vue.
// Section marées via TideSectionView (scraping cabaigne.net).
//
// Coordonnées Nouméa codées en constantes pour la V4.
// Externalisables via un service de localisation GPS en V5.

import SwiftUI

// MARK: - Constantes

private enum Noumea {
    static let latitude:  Double = -22.2758
    static let longitude: Double = 166.4580
    static let timeZone: TimeZone = TimeZone(identifier: "Pacific/Noumea")!
}

// MARK: - Vue principale

struct SolunarView: View {

    // MARK: État

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var solunarDay: SolunarDay?
    @State private var isCalculating: Bool = false
    @StateObject private var tideService = TideService()

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // 1. Navigation date + score
                dateNavigationHeader

                // 2. Timeline 24h
                if let day = solunarDay {
                    timelineView(day: day)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    timelinePlaceholder
                }

                Divider().padding(.vertical, 12)

                // 3. Corps principal
                if isCalculating {
                    calculatingView
                } else if let day = solunarDay {
                    mainContent(day: day)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Solunaire")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: selectedDate) {
            await computeSolunar()
        }
    }

    // MARK: - En-tête navigation + score

    private var dateNavigationHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    shiftDate(by: -1)
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(formattedDate(selectedDate))
                        .font(.headline)
                        .foregroundColor(.primary)
                    if isToday(selectedDate) {
                        Text("Aujourd'hui")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button {
                    shiftDate(by: +1)
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal, 20)

            // Score poissons
            if let day = solunarDay {
                fishScoreView(score: day.qualityScore)
            } else {
                fishScoreView(score: nil)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
    }

    // MARK: - Score poissons

    private func fishScoreView(score: Int?) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Image(systemName: "fish.fill")
                    .font(.title3)
                    .foregroundColor(fishColor(score: score, index: index))
            }
            if let score = score {
                Text("\(score)/10")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
            }
        }
    }

    private func fishColor(score: Int?, index: Int) -> Color {
        guard let score = score else { return Color.gray.opacity(0.3) }
        let filled = Int((Double(score) / 2.0).rounded())
        guard index < filled else { return Color.gray.opacity(0.3) }
        switch score {
        case 8...10: return .green
        case 4...7:  return .orange
        default:     return .red
        }
    }

    // MARK: - Timeline 24h

    private func timelineView(day: SolunarDay) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Activité sur 24h")
                .font(.caption)
                .foregroundColor(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                        .frame(height: 28)

                    ForEach(Array(day.allPeriods.enumerated()), id: \.offset) { _, period in
                        periodBlock(
                            interval: period.interval,
                            isMajor: period.isMajor,
                            totalWidth: geo.size.width,
                            dayStart: day.date
                        )
                    }

                    if isToday(selectedDate) {
                        nowMarker(totalWidth: geo.size.width, dayStart: day.date)
                    }
                }
                .frame(height: 28)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .frame(height: 28)

            HStack {
                Text("0h")
                Spacer()
                Text("6h")
                Spacer()
                Text("12h")
                Spacer()
                Text("18h")
                Spacer()
                Text("24h")
            }
            .font(.system(size: 9))
            .foregroundColor(.secondary)
        }
    }

    private var timelinePlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Activité sur 24h")
                .font(.caption)
                .foregroundColor(.secondary)
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
                .frame(height: 28)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func periodBlock(
        interval: DateInterval,
        isMajor: Bool,
        totalWidth: CGFloat,
        dayStart: Date
    ) -> some View {
        let dayDuration: Double = 86400
        let startOffset = max(0, interval.start.timeIntervalSince(dayStart))
        let endOffset   = min(dayDuration, interval.end.timeIntervalSince(dayStart))
        guard endOffset > startOffset else { return AnyView(EmptyView()) }
        let x = CGFloat(startOffset / dayDuration) * totalWidth
        let w = CGFloat((endOffset - startOffset) / dayDuration) * totalWidth
        let color: Color = isMajor ? Color.green.opacity(0.85) : Color.green.opacity(0.40)
        return AnyView(
            Rectangle()
                .fill(color)
                .frame(width: max(w, 4), height: 28)
                .offset(x: x)
        )
    }

    private func nowMarker(totalWidth: CGFloat, dayStart: Date) -> some View {
        let elapsed  = Date().timeIntervalSince(dayStart)
        let fraction = min(max(elapsed / 86400, 0), 1)
        let x = CGFloat(fraction) * totalWidth
        return AnyView(
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 28)
                .offset(x: x)
        )
    }

    // MARK: - Spinner calcul

    private var calculatingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Calcul en cours…")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    // MARK: - Contenu principal

    private func mainContent(day: SolunarDay) -> some View {
        VStack(spacing: 16) {
            moonPhaseSection(day: day)
            moonTimesSection(day: day)
            periodsSection(day: day)
            TideSectionView(
                tideService: tideService,
                solunarDay: day,
                selectedDate: selectedDate
            )
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }

    // MARK: - Phase lunaire

    private func moonPhaseSection(day: SolunarDay) -> some View {
        SolunarCard {
            HStack(spacing: 16) {
                Text(day.moonPhase.shortName)
                    .font(.system(size: 48))

                VStack(alignment: .leading, spacing: 4) {
                    Text(day.moonPhase.rawValue)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Label(
                            String(format: "%.0f %%", day.moonIllumination * 100),
                            systemImage: "moon.fill"
                        )
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text(String(format: "%.1f j", day.moonAge))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
        }
    }

    // MARK: - Lever / coucher / transit

    private func moonTimesSection(day: SolunarDay) -> some View {
        SolunarCard {
            VStack(spacing: 12) {
                HStack {
                    moonTimeItem(label: "Lever", time: day.moonRise, icon: "arrow.up.circle")
                    Spacer()
                    moonTimeItem(label: "Coucher", time: day.moonSet, icon: "arrow.down.circle")
                }
                Divider()
                HStack {
                    moonTimeItem(label: "Transit", time: day.moonTransit, icon: "scope")
                    Spacer()
                    antiTransitItem(day: day)
                }
            }
        }
    }

    private func moonTimeItem(label: String, time: Date?, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(time.map { formattedTime($0) } ?? "—")
                .font(.title3)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
    }

    private func antiTransitItem(day: SolunarDay) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Anti-transit", systemImage: "arrow.down.to.line")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(day.moonAntiTransit.map { formattedTime($0) } ?? "—")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                if let at = day.moonAntiTransit, isNextDay(at, relativeTo: day.date) {
                    Text("J+1")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Périodes solunaires

    private func periodsSection(day: SolunarDay) -> some View {
        SolunarCard {
            VStack(alignment: .leading, spacing: 4) {
                Text("Périodes solunaires")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.bottom, 4)

                ForEach(Array(day.allPeriods.enumerated()), id: \.offset) { _, period in
                    periodRow(
                        interval: period.interval,
                        isMajor: period.isMajor,
                        isBest: day.bestMajorPeriod == period.interval
                    )
                    if period.interval != day.allPeriods.last?.interval {
                        Divider()
                    }
                }
            }
        }
    }

    private func periodRow(interval: DateInterval, isMajor: Bool, isBest: Bool) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(isMajor ? Color.green : Color.green.opacity(0.4))
                .frame(width: 6, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(isMajor ? "Période majeure" : "Période mineure")
                        .font(.subheadline)
                        .fontWeight(isMajor ? .semibold : .regular)
                    if isBest {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundColor(.yellow)
                    }
                }
                Text("\(formattedTime(interval.start)) – \(formattedTime(interval.end))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }

            Spacer()

            Text(isMajor ? "2 h" : "1 h")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Calcul asynchrone

    @MainActor
    private func computeSolunar() async {
        isCalculating = true
        solunarDay = nil
        let dateToCompute = selectedDate
        let result = await Task.detached(priority: .userInitiated) {
            SolunarCalculator.calculate(
                for: dateToCompute,
                latitude: Noumea.latitude,
                longitude: Noumea.longitude,
                timeZone: Noumea.timeZone
            )
        }.value
        solunarDay = result
        isCalculating = false
    }

    // MARK: - Navigation date

    private func shiftDate(by days: Int) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Noumea.timeZone
        if let newDate = cal.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }

    // MARK: - Formatage

    private func formattedDate(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "EEEE d MMMM yyyy"
        fmt.timeZone = Noumea.timeZone
        return fmt.string(from: date).capitalized
    }

    private func formattedTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "fr_FR")
        fmt.dateFormat = "HH:mm"
        fmt.timeZone = Noumea.timeZone
        return fmt.string(from: date)
    }

    private func isToday(_ date: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Noumea.timeZone
        return cal.isDateInToday(date)
    }

    private func isNextDay(_ date: Date, relativeTo reference: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = Noumea.timeZone
        return !cal.isDate(date, inSameDayAs: reference)
    }
}

// MARK: - Composant carte réutilisable

private struct SolunarCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        SolunarView()
    }
}
