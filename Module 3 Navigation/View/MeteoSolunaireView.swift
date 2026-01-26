//
//  MeteoSolunaireView.swift
//  Go Les Picots V.4
//
//  MÉTÉO MARINE COMPLÈTE avec Stormglass.io
//  - Prévisions horaires 24h
//  - Prévisions 7 jours
//  - Vraies données astronomiques (lever/coucher soleil/lune)
//

import SwiftUI
import CoreLocation

struct MeteoSolunaireView: View {
    
    // MARK: - Services
    private let stormglassService: StormglassService
    private let solunarService = SolunarService()
    
    // MARK: - State
    @State private var currentData: MarineData?
    @State private var hourlyForecast: [MarineData] = []
    @State private var tideEvents: [TideEvent] = []
    @State private var solunarData: SolunarData?
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isGraphFullScreen = false
    
    // Position Nouméa par défaut
    private let coordinate = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
    
    // MARK: - Initializer
    init() {
        self.stormglassService = StormglassService(apiKey: APIConfig.stormglassKey)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    VStack(spacing: 24) {
                        // Section 1 : Indice qualité pêche
                        if solunarData != nil {
                            indiceQualiteSection
                        }
                        
                        // Section 2 : Conditions actuelles
                        if currentData != nil {
                            conditionsActuellesSection
                        }
                        
                        // Section 3 : Prévisions horaires 24h
                        if !hourlyForecast.isEmpty {
                            previsionsHorairesSection
                        }
                        
                        // Section 4 : Périodes solunaires
                        if solunarData != nil {
                            periodesSolunairesSection
                        }
                        
                        // Section 5 : Soleil & Lune
                        if solunarData != nil {
                            soleilLuneSection
                        }
                        
                        // Section 6 : Marées
                        if !tideEvents.isEmpty {
                            mareeSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Météo & Solunaire")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { Task { await loadData() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                await loadData()
            }
            .fullScreenCover(isPresented: $isGraphFullScreen) {
                if !tideEvents.isEmpty, let solunar = solunarData {
                    FullScreenTideGraph(
                        tides: tideEvents,
                        sunrise: solunar.sunrise ?? Date(),
                        sunset: solunar.sunset ?? Date(),
                        moonrise: solunar.moonrise,
                        moonset: solunar.moonset,
                        isPresented: $isGraphFullScreen
                    )
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Chargement des données marines...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("Erreur de chargement")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { Task { await loadData() } }) {
                Label("Réessayer", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Section 1 : Indice Qualité Pêche
    private var indiceQualiteSection: some View {
        Group {
            if let solunar = solunarData {
                VStack(spacing: 12) {
                    HStack {
                        Text(solunar.qualityEmoji)
                            .font(.system(size: 50))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Qualité du jour")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text(solunar.qualityText)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("\(solunar.globalScore)/100")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    ProgressView(value: Double(solunar.globalScore), total: 100)
                        .tint(qualityColor(solunar.globalScore))
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
    
    private func qualityColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .gray
        }
    }
    
    // MARK: - Section 2 : Conditions Actuelles
    private var conditionsActuellesSection: some View {
        Group {
            if let data = currentData {
                VStack(alignment: .leading, spacing: 16) {
                    // Header avec timestamp
                    HStack {
                        Image(systemName: "wind")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Conditions actuelles")
                                .font(.headline)
                            Text(data.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                        // Indicateur favorable
                        if data.isFavorable {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.title2)
                        }
                    }
                    
                    // VENT & TEMPÉRATURE
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        MeteoCard(
                            icon: "wind",
                            label: "Vent",
                            value: data.windFormatted,
                            detail: data.gustKnots != nil ? "Rafales" : nil,
                            color: .blue
                        )
                        
                        MeteoCard(
                            icon: "thermometer",
                            label: "Temp. air",
                            value: data.airTemperatureFormatted,
                            detail: nil,
                            color: .orange
                        )
                    }
                    
                    // MER & HOULE (regroupé)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Houle + Houle de fond combinées
                        VStack(spacing: 4) {
                            Image(systemName: "water.waves")
                                .font(.title2)
                                .foregroundStyle(.cyan)
                            
                            Text("Houle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            if let wave = data.waveFormatted {
                                Text(wave)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .multilineTextAlignment(.center)
                            }
                            
                            if let swell = data.swellFormatted {
                                Text("Fond: \(swell)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(data.seaState)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // État de la marée
                        if !tideEvents.isEmpty {
                            VStack(spacing: 4) {
                                Image(systemName: currentTideIcon)
                                    .font(.title2)
                                    .foregroundStyle(currentTideColor)
                                
                                Text("Marée")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(currentTideState)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if let coef = currentTideCoefficient {
                                    Text("Coeff: \(coef)")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(currentTideColor.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    
                    // TEMPÉRATURE (regroupé)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Températures air + eau
                        VStack(spacing: 4) {
                            Image(systemName: "thermometer")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            
                            Text("Températures")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack(spacing: 8) {
                                VStack(spacing: 2) {
                                    Text("Air")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(data.airTemperatureFormatted)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                
                                if let waterTemp = data.waterTemperatureFormatted {
                                    Divider()
                                        .frame(height: 20)
                                    VStack(spacing: 2) {
                                        Text("Eau")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                        Text(waterTemp)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        MeteoCard(
                            icon: "eye",
                            label: "Visibilité",
                            value: data.visibilityFormatted,
                            detail: nil,
                            color: .green
                        )
                    }
                    
                    // MÉTÉO & ATMOSPHÈRE (regroupé)
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        // Nuages + Humidité
                        if let clouds = data.cloudCoverFormatted, let humidity = data.humidityFormatted {
                            VStack(spacing: 4) {
                                Image(systemName: "cloud.fill")
                                    .font(.title2)
                                    .foregroundStyle(.gray)
                                
                                Text("Ciel")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Text(clouds)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                if let precip = data.precipitationFormatted {
                                    Text(precip)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Text("💧 \(humidity)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        if let pressure = data.pressureFormatted {
                            MeteoCard(
                                icon: "gauge",
                                label: "Pression",
                                value: pressure,
                                detail: nil,
                                color: .brown
                            )
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Section 3 : Prévisions Horaires avec Graphique Marée
    private var previsionsHorairesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                Text("Prévisions 24 heures")
                    .font(.headline)
                Spacer()
            }
            .padding()
            
            // Graphique marée CLICABLE
            if !tideEvents.isEmpty, let solunar = solunarData {
                TideGraphCompact(
                    tides: tideEvents,
                    sunrise: solunar.sunrise ?? Date(),
                    sunset: solunar.sunset ?? Date(),
                    moonrise: solunar.moonrise,
                    moonset: solunar.moonset
                )
                .frame(height: 200)
                .padding(.horizontal)
                .onTapGesture {
                    isGraphFullScreen = true
                }
            }
            
            // Barre scrollable 24h avec fond coloré marée
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(hourlyForecast.prefix(24).enumerated()), id: \.offset) { index, data in
                        TideColoredHourCard(
                            data: data,
                            tides: tideEvents
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // Reste des sections inchangées...
    
    // MARK: - Section 4 : Périodes Solunaires
    private var periodesSolunairesSection: some View {
        Group {
            if let solunar = solunarData {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "figure.fishing")
                            .foregroundStyle(.green)
                        Text("Périodes solunaires")
                            .font(.headline)
                        Spacer()
                        
                        Text("Note: \(solunar.dayRating)/5")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    ForEach(solunar.allPeriods) { period in
                        SolunarPeriodCard(period: period)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Section 5 : Soleil & Lune (données Solunar)
    private var soleilLuneSection: some View {
        Group {
            if let solunar = solunarData {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "sun.and.horizon")
                            .foregroundStyle(.orange)
                        Text("Soleil & Lune")
                            .font(.headline)
                        Spacer()
                    }
                    
                    // Phase lunaire
                    HStack(spacing: 16) {
                        Text(solunar.moonEmoji)
                            .font(.system(size: 60))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(solunar.moonPhaseFrench)
                                .font(.headline)
                            
                            Text("Illumination: \(Int(solunar.moonIllumination * 100))%")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // Timeline 24h avec barres verticales
                    TimelineView(events: [
                        TimelineEvent(time: solunar.sunrise, label: "Lever", icon: "sunrise.fill", color: .orange, type: .sun),
                        TimelineEvent(time: solunar.sunset, label: "Coucher", icon: "sunset.fill", color: .orange, type: .sun),
                        TimelineEvent(time: solunar.moonrise, label: "Lever", icon: "moonrise.fill", color: .indigo, type: .moon),
                        TimelineEvent(time: solunar.moonset, label: "Coucher", icon: "moonset.fill", color: .indigo, type: .moon)
                    ].compactMap { $0 })
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Section 6 : Marées
    private var mareeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "water.waves")
                    .foregroundStyle(.cyan)
                Text("Marées")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(Array(tideEvents.prefix(4)), id: \.time) { tide in
                HStack {
                    Image(systemName: tide.type == "high" ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundStyle(tide.type == "high" ? .blue : .orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tide.type == "high" ? "Marée haute" : "Marée basse")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(String(format: "%.1fm", tide.height))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(tide.time, style: .time)
                        .font(.headline)
                        .foregroundStyle(tide.type == "high" ? .blue : .orange)
                }
                .padding()
                .background((tide.type == "high" ? Color.blue : Color.orange).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Tide Helpers
    
    private var currentTideState: String {
        guard tideEvents.count >= 2 else { return "N/A" }
        let now = Date()
        
        let upcoming = tideEvents.filter { $0.time > now }.first
        let previous = tideEvents.filter { $0.time <= now }.last
        
        if let prev = previous, let next = upcoming {
            return prev.type == "high" ? "Descendante" : "Montante"
        }
        return "N/A"
    }
    
    private var currentTideIcon: String {
        currentTideState == "Montante" ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }
    
    private var currentTideColor: Color {
        currentTideState == "Montante" ? .blue : .orange
    }
    
    private var currentTideCoefficient: Int? {
        guard let tide = tideEvents.first else { return nil }
        return Int(tide.height * 50)
    }
    
    private func getTideStateForHour(_ time: Date) -> String? {
        guard tideEvents.count >= 2 else { return nil }
        
        let upcoming = tideEvents.filter { $0.time > time }.first
        let previous = tideEvents.filter { $0.time <= time }.last
        
        if let prev = previous {
            return prev.type == "high" ? "Descendante" : "Montante"
        }
        return nil
    }
    
    private func getTideCoeffForHour(_ time: Date) -> Int? {
        let nearest = tideEvents.min(by: { abs($0.time.timeIntervalSince(time)) < abs($1.time.timeIntervalSince(time)) })
        return nearest.map { Int($0.height * 50) }
    }
    
    // MARK: - Data Loading
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let current = try await stormglassService.fetchMarineData(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            let forecast = try await stormglassService.fetchForecast(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                days: 2
            )
            
            let tides = try await stormglassService.fetchTideData(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            let solunar = try await solunarService.fetchSolunarData(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                date: Date(),
                timezone: 11
            )
            
            await MainActor.run {
                self.currentData = current
                self.hourlyForecast = Array(forecast.prefix(24))
                self.tideEvents = tides
                self.solunarData = solunar
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

// MARK: - Composants

struct MeteoCard: View {
    let icon: String
    let label: String
    let value: String
    let detail: String?
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            if let detail = detail {
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Graphique Marée avec Points Colorés

struct TideGraphCompact: View {
    let tides: [TideEvent]
    let sunrise, sunset: Date
    let moonrise, moonset: Date?
    
    var body: some View {
        GeometryReader { geometry in
            let graphWidth = geometry.size.width - 50
            let graphHeight = geometry.size.height - 25
            
            ZStack(alignment: .topLeading) {
                // Zones jour/nuit
                DayNightZones(sunrise: sunrise, sunset: sunset, width: graphWidth, height: graphHeight + 25)
                    .offset(x: 45, y: 0)
                
                // Axe Y SANS "hauteur"
                VStack(alignment: .trailing, spacing: 0) {
                    Text("2,0").font(.system(size: 10))
                    Spacer()
                    Text("1,3").font(.system(size: 10))
                    Spacer()
                    Text("0,5").font(.system(size: 10))
                    Spacer()
                    Text("-0,3").font(.system(size: 10))
                    Spacer()
                    Text("-1,0").font(.system(size: 10))
                }
                .frame(width: 40, height: graphHeight)
                .offset(x: 0, y: 5)
                
                // Points colorés soleil/lune (EN HAUT ou EN BAS)
                SunMoonDotsFixed(sunrise: sunrise, sunset: sunset, moonrise: moonrise, moonset: moonset, width: graphWidth, height: graphHeight)
                    .offset(x: 45, y: 0)
                
                // Courbe SINUSOÏDALE
                TideCurveSinusoidal(tides: tides, width: graphWidth, height: graphHeight)
                    .offset(x: 45, y: 5)
                
                // Points marées avec heures 24h
                ForEach(Array(tides.prefix(6).enumerated()), id: \.offset) { _, tide in
                    TidePoint24h(tide: tide, width: graphWidth, height: graphHeight)
                        .offset(x: 45, y: 5)
                }
                
                // Axe X format 0-24
                HStack(spacing: 0) {
                    ForEach([0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24], id: \.self) { hour in
                        Text("\(hour)")
                            .font(.system(size: 9))
                            .frame(width: graphWidth / 12, alignment: hour == 0 ? .leading : hour == 24 ? .trailing : .center)
                    }
                }
                .offset(x: 45, y: graphHeight + 10)
            }
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DayNightZones: View {
    let sunrise, sunset: Date
    let width, height: CGFloat
    
    var body: some View {
        let sunrisePos = timeToPosition(sunrise)
        let sunsetPos = timeToPosition(sunset)
        
        ZStack(alignment: .leading) {
            Rectangle().fill(Color.gray.opacity(0.2)).frame(width: width, height: height)
            Rectangle().fill(Color.cyan.opacity(0.15))
                .frame(width: width * (sunsetPos - sunrisePos), height: height)
                .offset(x: width * sunrisePos)
        }
    }
    
    func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60) / 24
    }
}

struct SunMoonDotsFixed: View {
    let sunrise, sunset: Date
    let moonrise, moonset: Date?
    let width, height: CGFloat
    
    var body: some View {
        ZStack {
            // Soleil LEVER = EN HAUT
            Circle().fill(Color.yellow).frame(width: 12, height: 12)
                .offset(x: width * timeToPosition(sunrise), y: 5)
            
            // Soleil COUCHER = EN BAS
            Circle().fill(Color.yellow).frame(width: 12, height: 12)
                .offset(x: width * timeToPosition(sunset), y: height - 5)
            
            // Lune LEVER = EN HAUT
            if let rise = moonrise {
                Circle().fill(Color.orange).frame(width: 12, height: 12)
                    .offset(x: width * timeToPosition(rise), y: 5)
            }
            
            // Lune COUCHER = EN BAS
            if let set = moonset {
                Circle().fill(Color.orange).frame(width: 12, height: 12)
                    .offset(x: width * timeToPosition(set), y: height - 5)
            }
        }
    }
    
    func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60) / 24
    }
}

struct TideCurveSinusoidal: View {
    let tides: [TideEvent]
    let width, height: CGFloat
    
    var body: some View {
        Path { path in
            guard tides.count >= 2 else { return }
            let sorted = tides.sorted { $0.time < $1.time }
            
            let startY = heightToY(1.3)
            path.move(to: CGPoint(x: 0, y: startY))
            
            for i in 0..<sorted.count {
                let tide = sorted[i]
                let x = width * timeToPosition(tide.time)
                let y = heightToY(tide.height)
                
                if i == 0 {
                    let controlX = x / 2
                    let controlY = (startY + y) / 2
                    path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: controlX, y: controlY))
                } else {
                    let prevTide = sorted[i - 1]
                    let prevX = width * timeToPosition(prevTide.time)
                    let prevY = heightToY(prevTide.height)
                    let midX = (prevX + x) / 2
                    
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: prevX + (midX - prevX) * 0.7, y: prevY),
                        control2: CGPoint(x: midX + (x - midX) * 0.3, y: y)
                    )
                }
            }
            
            let lastTide = sorted.last!
            let lastX = width * timeToPosition(lastTide.time)
            let lastY = heightToY(lastTide.height)
            let endY = heightToY(1.3)
            let controlX = lastX + (width - lastX) / 2
            let controlY = (lastY + endY) / 2
            
            path.addQuadCurve(to: CGPoint(x: width, y: endY), control: CGPoint(x: controlX, y: controlY))
        }
        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
    }
    
    func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60) / 24
    }
    
    func heightToY(_ h: Double) -> CGFloat {
        let minH = -1.0
        let maxH = 2.0
        let normalized = (h - minH) / (maxH - minH)
        return height * (1 - normalized)
    }
}

struct TidePoint24h: View {
    let tide: TideEvent
    let width, height: CGFloat
    
    var body: some View {
        let x = width * timeToPosition(tide.time)
        let y = heightToY(tide.height)
        
        ZStack {
            Circle().fill(tide.type == "high" ? Color.blue : Color.red)
                .frame(width: 12, height: 12)
                .offset(x: x - 6, y: y - 6)
            
            Text(tide.time, format: .dateTime.hour().minute())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(tide.type == "high" ? .blue : .red)
                .environment(\.locale, Locale(identifier: "fr_FR"))
                .offset(x: x, y: y - (tide.type == "high" ? 22 : 18))
        }
    }
    
    func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60) / 24
    }
    
    func heightToY(_ h: Double) -> CGFloat {
        let minH = -1.0
        let maxH = 2.0
        let normalized = (h - minH) / (maxH - minH)
        return height * (1 - normalized)
    }
}

struct MoonIconsBottom: View {
    let moonrise, moonset: Date
    let width: CGFloat
    
    var body: some View {
        ZStack {
            HStack(spacing: 2) {
                Text("🌙").font(.system(size: 14))
                Text("🌙").font(.system(size: 14))
            }
            .offset(x: width * timeToPosition(moonrise) - 15)
            
            HStack(spacing: 2) {
                Text("🌙").font(.system(size: 14))
                Text("🌙").font(.system(size: 14))
            }
            .offset(x: width * timeToPosition(moonset) - 15)
        }
    }
    
    func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60) / 24
    }
}

// MARK: - Carte Horaire avec Fond Coloré Marée

struct TideColoredHourCard: View {
    let data: MarineData
    let tides: [TideEvent]
    
    var tideInfo: (height: Double, coef: Int, isRising: Bool) {
        let sorted = tides.sorted { $0.time < $1.time }
        guard sorted.count >= 2 else { return (1.0, 50, true) }
        
        let before = sorted.last(where: { $0.time <= data.timestamp }) ?? sorted.first!
        let after = sorted.first(where: { $0.time > data.timestamp }) ?? sorted.last!
        
        let totalTime = after.time.timeIntervalSince(before.time)
        let elapsed = data.timestamp.timeIntervalSince(before.time)
        let ratio = totalTime > 0 ? elapsed / totalTime : 0
        
        let interpolatedHeight = before.height + (after.height - before.height) * ratio
        let coef = Int(interpolatedHeight * 50)
        let isRising = before.type == "low"
        
        return (interpolatedHeight, coef, isRising)
    }
    
    var body: some View {
        let info = tideInfo
        let fillRatio = (info.height + 1) / 3.0 // Normaliser -1 à 2m sur 0 à 1
        let bgColor = info.isRising ? Color.blue : Color.red
        
        ZStack(alignment: .bottom) {
            // Fond gris clair
                        Rectangle()
                            .fill(Color(.systemGray6))
            // Fond coloré proportionnel
            Rectangle()
                .fill(bgColor.opacity(0.3))
                .frame(width: 60, height: 120 * fillRatio)
            
            VStack(spacing: 4) {
                // HEURE FORMAT 24h
                Text(data.timestamp, format: .dateTime.hour())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.primary)
                    .environment(\.locale, Locale(identifier: "fr_FR"))
                
                //TEMPERATURE
                Text(data.airTemperatureFormatted)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.primary)
                
                // VENT + DIRECTION
                
                HStack(spacing: 2) {
                    Image(systemName: "wind")
                        .font(.system(size: 12, weight: .bold))
                    Text("\(data.windSpeedKnots) \(windDirectionText(data.windDirection))")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.blue)
                
                // HOULE
                if let wave = data.waveHeight {
                    HStack(spacing: 2) {
                        Image(systemName: "water.waves")
                            .font(.system(size: 12, weight: .bold))
                        Text(String(format: "%.1f", wave))
                            .font(.system(size: 12))
                    }
                    .foregroundStyle(.cyan)
                }
                
                // COEFFICIENT en BLANC
                Text("\(info.coef)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.vertical, 8)
        }
        .frame(width: 60, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    // Convertir degrés en direction cardinale
    private func windDirectionText(_ degrees: Double) -> String {
        switch degrees {
        case 0..<22.5, 337.5...360: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SO"
        case 247.5..<292.5: return "O"
        case 292.5..<337.5: return "NO"
        default: return ""
        }
    }
}

// MARK: - Fullscreen Graph

struct FullScreenTideGraph: View {
    let tides: [TideEvent]
    let sunrise, sunset: Date
    let moonrise, moonset: Date?
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.9).ignoresSafeArea()
            
            VStack {
                HStack {
                    Spacer()
                    Button("Fermer") {
                        isPresented = false
                    }
                    .foregroundStyle(.white)
                    .padding()
                }
                
                TideGraphCompact(
                    tides: tides,
                    sunrise: sunrise,
                    sunset: sunset,
                    moonrise: moonrise,
                    moonset: moonset
                )
                .padding()
                
                Spacer()
            }
        }
    }
}

// MARK: - Composants Timeline (inchangés)

struct TimelineEvent {
    let time: Date?
    let label: String
    let icon: String
    let color: Color
    let type: EventType
    
    enum EventType {
        case sun, moon
    }
}

struct TimelineView: View {
    let events: [TimelineEvent]
    
    var body: some View {
        VStack(spacing: 16) {
            // Légende
            HStack(spacing: 20) {
                HStack(spacing: 8) {
                    Text("☀️").font(.system(size: 18))
                    Text("Soleil")
                        .font(.caption)
                }
                HStack(spacing: 8) {
                    Text("🌙").font(.system(size: 18))
                    Text("Lune")
                        .font(.caption)
                }
            }
            .foregroundStyle(.secondary)
            
            // Événements simplifiés
            HStack(spacing: 20) {
                ForEach(events.indices, id: \.self) { index in
                    let event = events[index]
                    if let time = event.time {
                        VStack(spacing: 4) {
                            // HEURE 24H
                            Text(time, format: .dateTime.hour().minute())
                                .font(.headline)
                                .foregroundStyle(event.color)
                                .environment(\.locale, Locale(identifier: "fr_FR"))
                            
                            // ICÔNE
                            Image(systemName: event.icon)
                                .font(.title)
                                .foregroundStyle(event.color)
                            
                            // TEXTE
                            Text(event.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TimelineEventMarker: View {
    let event: TimelineEvent
    let width: CGFloat
    
    var body: some View {
        let position = timeToPosition(event.time!)
        
        VStack(spacing: 4) {
            Text(event.time!, style: .time)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(event.color)
                .environment(\.locale, Locale(identifier: "fr_FR"))
            
            VStack(spacing: 2) {
                Image(systemName: event.icon)
                    .font(.title3)
                    .foregroundStyle(event.color)
                
                Text(event.label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Rectangle()
                .fill(event.color)
                .frame(width: 2, height: 40)
        }
        .offset(x: position * width - width / 2)
    }
    
    private func timeToPosition(_ time: Date) -> CGFloat {
        let h = Calendar.current.component(.hour, from: time)
        let m = Calendar.current.component(.minute, from: time)
        return (Double(h) + Double(m) / 60.0) / 24.0
    }
}

struct SolunarPeriodCard: View {
    let period: SolunarPeriod
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(spacing: 4) {
                Text(period.type.emoji)
                    .font(.title2)
                Text("\(period.score)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(period.timeFormatted)
                    .font(.headline)
                
                Text(period.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("Période \(period.type.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(period.durationFormatted)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding()
        .background(scoreColor(period.score).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        default: return .orange
        }
    }
}

#Preview {
    MeteoSolunaireView()
}
