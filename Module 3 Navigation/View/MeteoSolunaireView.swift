//
//  MeteoSolunaireView.swift
//  Go Les Picots V.4
//
//  MÉTÉO MARINE COMPLÈTE avec Stormglass.io
//  - Prévisions horaires 24h
//  - Prévisions 7 jours (scroll horizontal J à J+7)
//  - Vraies données astronomiques (lever/coucher soleil/lune)
//

import SwiftUI
import CoreLocation

struct MeteoSolunaireView: View {
    
    // MARK: - Services
    private let stormglassService: StormglassService
    private let solunarService = SolunarService()
    
    // Position Nouméa par défaut
    private let coordinate = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
    
    // MARK: - Initializer
    init() {
        self.stormglassService = StormglassService(apiKey: APIConfig.stormglassKey)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            TabView {
                ForEach(0..<8) { dayOffset in
                    DayPageView(
                        dayOffset: dayOffset,
                        coordinate: coordinate,
                        stormglassService: stormglassService,
                        solunarService: solunarService
                    )
                    .tag(dayOffset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .navigationTitle("Météo & Solunaire")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

// MARK: - DayPageView (Page pour chaque jour)

struct DayPageView: View {
    let dayOffset: Int
    let coordinate: CLLocationCoordinate2D
    let stormglassService: StormglassService
    let solunarService: SolunarService
    
    @State private var currentData: MarineData?
    @State private var hourlyForecast: [MarineData] = []
    @State private var tideEvents: [TideEvent] = []
    @State private var solunarData: SolunarData?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isGraphFullScreen = false
    
    var targetDate: Date {
        Calendar.current.date(byAdding: .day, value: dayOffset, to: Date()) ?? Date()
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // DATE DU JOUR EN HAUT
                Text(targetDate, format: .dateTime.weekday(.wide).day().month().year())
                    .font(.title2)
                    .fontWeight(.bold)
                    .environment(\.locale, Locale(identifier: "fr_FR"))
                    .padding(.top)
                
                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(error)
                } else {
                    // Section 1 : Indice qualité pêche
                    if solunarData != nil {
                        indiceQualiteSection
                    }
                    
                    // Section 2 : Conditions (actuelles si J=0, prévisions sinon)
                    if currentData != nil {
                        conditionsSection
                    }
                    
                    // Section 3 : Prévisions horaires 24h
                    if !hourlyForecast.isEmpty {
                        previsionsHorairesSection
                    }
                    // Section 4 : Marées du jour
                    if !tideEvents.isEmpty {
                        mareeSection
                    }
                    
                    // Section 5 : Périodes solunaires
                    if solunarData != nil {
                        periodesSolunairesSection
                    }
                    
                    // Section 5 : Soleil & Lune
                    if solunarData != nil {
                        soleilLuneSection
                    }
                }
            }
            .padding()
        }
        .task {
            await loadDataForDay()
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
            
            Button(action: { Task { await loadDataForDay() } }) {
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
    
    // MARK: - Section 2 : Conditions
    private var conditionsSection: some View {
        Group {
            if let data = currentData {
                VStack(alignment: .leading, spacing: 16) {
                    // Header avec timestamp
                    HStack {
                        Image(systemName: "wind")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(dayOffset == 0 ? "Conditions actuelles" : "Prévisions du jour")
                                .font(.headline)
                            Text(data.timestamp, style: .time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .environment(\.locale, Locale(identifier: "fr_FR"))
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
                        
                        // Températures air + eau regroupées
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
                    
                    // MÉTÉO & ATMOSPHÈRE (sans pression)
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
                        
                        MeteoCard(
                            icon: "eye",
                            label: "Visibilité",
                            value: data.visibilityFormatted,
                            detail: nil,
                            color: .green
                        )
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
    
    // MARK: - Section 5 : Soleil & Lune
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
                    
                    // Timeline horizontale PLEINE LARGEUR avec infos lunaires
                    HStack(spacing: 0) {
                        // COLONNE SOLEIL
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text("☀️").font(.system(size: 16))
                                Text("Soleil")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack(spacing: 20) {
                                // Lever soleil
                                VStack(spacing: 4) {
                                    if let sunrise = solunar.sunrise {
                                        Text(sunrise, format: .dateTime.hour().minute())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.orange)
                                            .environment(\.locale, Locale(identifier: "fr_FR"))
                                    }
                                    
                                    Image(systemName: "sunrise.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    
                                    Text("Lever")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Coucher soleil
                                VStack(spacing: 4) {
                                    if let sunset = solunar.sunset {
                                        Text(sunset, format: .dateTime.hour().minute())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.orange)
                                            .environment(\.locale, Locale(identifier: "fr_FR"))
                                    }
                                    
                                    Image(systemName: "sunset.fill")
                                        .font(.title2)
                                        .foregroundStyle(.orange)
                                    
                                    Text("Coucher")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .frame(height: 80)
                        
                        // COLONNE LUNE
                        VStack(spacing: 8) {
                            HStack(spacing: 4) {
                                Text(solunar.moonEmoji).font(.system(size: 16))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(solunar.moonPhaseFrench)
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(.primary)
                                    Text("Illumination: \(Int(solunar.moonIllumination * 100))%")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            HStack(spacing: 20) {
                                // Lever lune
                                VStack(spacing: 4) {
                                    if let moonrise = solunar.moonrise {
                                        Text(moonrise, format: .dateTime.hour().minute())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.purple)
                                            .environment(\.locale, Locale(identifier: "fr_FR"))
                                    } else {
                                        Text("--:--")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.purple)
                                    }
                                    
                                    Image(systemName: "moonrise.fill")
                                        .font(.title2)
                                        .foregroundStyle(.purple)
                                    
                                    Text("Lever")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                
                                // Coucher lune
                                VStack(spacing: 4) {
                                    if let moonset = solunar.moonset {
                                        Text(moonset, format: .dateTime.hour().minute())
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.purple)
                                            .environment(\.locale, Locale(identifier: "fr_FR"))
                                    } else {
                                        Text("--:--")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundStyle(.purple)
                                    }
                                    
                                    Image(systemName: "moonset.fill")
                                        .font(.title2)
                                        .foregroundStyle(.purple)
                                    
                                    Text("Coucher")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            }
        }
    }
    
    // MARK: - Section 6 : Marées du jour
    private var mareeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "water.waves")
                    .foregroundStyle(.cyan)
                Text("Marées du jour")
                    .font(.headline)
                Spacer()
            }
            
            // Afficher toutes les marées du jour cible
            ForEach(Array(todayTides), id: \.time) { tide in
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
                    
                    Text(tide.time, format: .dateTime.hour().minute())
                        .font(.headline)
                        .foregroundStyle(tide.type == "high" ? .blue : .orange)
                        .environment(\.locale, Locale(identifier: "fr_FR"))
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
    
    // Helper pour récupérer les marées du jour cible uniquement
    private var todayTides: [TideEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: targetDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return tideEvents.filter { tide in
            tide.time >= startOfDay && tide.time < endOfDay
        }.sorted { $0.time < $1.time }
    }
    
    // MARK: - Tide Helpers
    
    private var currentTideState: String {
        guard tideEvents.count >= 2 else { return "N/A" }
        let now = targetDate
        
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
    
    // MARK: - Data Loading
    private func loadDataForDay() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Charger données pour targetDate
            let forecast = try await stormglassService.fetchForecast(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                days: dayOffset + 2
            )
            
            // Filtrer les 24h de ce jour
            let startOfDay = Calendar.current.startOfDay(for: targetDate)
            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
            
            let dayForecast = forecast.filter { data in
                data.timestamp >= startOfDay && data.timestamp < endOfDay
            }
            
            // Récupérer les marées avec une plage étendue pour couvrir tous les jours affichés
            let tides = try await stormglassService.fetchTideData(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            // Pour le graphique du jour, on filtre sur 24h + marge
            
            
            // Inclure quelques heures avant pour continuité du graphique
            let graphStart = Calendar.current.date(byAdding: .hour, value: -6, to: startOfDay)!
            let graphEnd = Calendar.current.date(byAdding: .hour, value: 6, to: endOfDay)!
            
            let dayTides = tides.filter { tide in
                tide.time >= graphStart && tide.time < graphEnd
            }
            
            let solunar = try await solunarService.fetchSolunarData(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                date: targetDate,
                timezone: 11
            )
            
            await MainActor.run {
                self.currentData = dayForecast.first
                self.hourlyForecast = dayForecast
                self.tideEvents = dayTides
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

// MARK: - Composants Visuels

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

// MARK: - Graphique Marée Compact

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
                
                // Axe Y
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
                
                // Points colorés soleil/lune
                SunMoonDotsFixed(sunrise: sunrise, sunset: sunset, moonrise: moonrise, moonset: moonset, width: graphWidth, height: graphHeight)
                    .offset(x: 45, y: 0)
                
                // Courbe sinusoïdale
                TideCurveSinusoidal(tides: tides, width: graphWidth, height: graphHeight)
                    .offset(x: 45, y: 5)
                
                // Points marées
                ForEach(Array(tides.prefix(6).enumerated()), id: \.offset) { _, tide in
                    TidePoint24h(tide: tide, width: graphWidth, height: graphHeight)
                        .offset(x: 45, y: 5)
                }
                
                // Axe X
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
            
            // Lune LEVER = EN HAUT (VIOLET)
            if let rise = moonrise {
                Circle().fill(Color.purple).frame(width: 12, height: 12)
                    .offset(x: width * timeToPosition(rise), y: 5)
            }
            
            // Lune COUCHER = EN BAS (VIOLET)
            if let set = moonset {
                Circle().fill(Color.purple).frame(width: 12, height: 12)
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
        let fillRatio = (info.height + 1) / 3.0
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
                
                // TEMPÉRATURE
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

// MARK: - Timeline Components

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
            
            // Événements
            HStack(spacing: 20) {
                ForEach(events.indices, id: \.self) { index in
                    let event = events[index]
                    if let time = event.time {
                        VStack(spacing: 4) {
                            Text(time, format: .dateTime.hour().minute())
                                .font(.headline)
                                .foregroundStyle(event.color)
                                .environment(\.locale, Locale(identifier: "fr_FR"))
                            
                            Image(systemName: event.icon)
                                .font(.title)
                                .foregroundStyle(event.color)
                            
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
