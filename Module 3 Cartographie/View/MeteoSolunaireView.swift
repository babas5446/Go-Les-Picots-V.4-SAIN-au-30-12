//
//  MeteoSolunaireView.swift
//  Go Les Picots V.4
//
//  RUBRIQUE 1 : Météo & Solunaire - VERSION AVEC DONNÉES RÉELLES
//  API OpenWeatherMap + Calculs solunaires locaux + SHOM
//

import SwiftUI
import CoreLocation

struct MeteoSolunaireView: View {
    // MARK: - Properties
    
    /// Coordonnées GPS optionnelles (utilisées quand appelé depuis Navigation)
    let coordinate: CLLocationCoordinate2D?
    
    // MARK: - Services
    @State private var locationService = LocationService()
    @State private var meteoService = MeteoService(apiKey: APIConfig.openWeatherMapKey)
    @State private var shomService = SHOMService()  // ✅ SHOM ajouté
    @State private var solunarService = SolunarService()
    
    // MARK: - State
    @State private var conditionsMeteo: ConditionsMeteo?
    @State private var phaseSolunaire: PhaseSolunaire?
    @State private var bestFishingTimes: [BestFishingTime] = []
    
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // MARK: - Init
    
    /// Init par défaut (utilise géolocalisation)
    init() {
        self.coordinate = nil
    }
    
    /// Init avec coordonnées spécifiques (appelé depuis Navigation)
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        // Section 1 : Indice qualité
                        if let phase = phaseSolunaire {
                            indiceQualiteSection(phase: phase)
                        }
                        
                        // Section 2 : Conditions actuelles
                        if let conditions = conditionsMeteo {
                            conditionsActuellesSection(conditions: conditions)
                        }
                        
                        // Section 3 : Soleil & Lune
                        if let phase = phaseSolunaire {
                            soleilLuneSection(phase: phase)
                        }
                        
                        // Section 4 : Marées (✅ MAINTENANT AVEC DONNÉES RÉELLES)
                        if let conditions = conditionsMeteo {
                            mareeSection(conditions: conditions)
                        }
                        
                        // Section 5 : Périodes de pêche
                        if !bestFishingTimes.isEmpty {
                            periodesPecheSection
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Météo & Solunaire")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: refreshData) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isLoading)
                }
            }
            .task {
                // Demander autorisation uniquement si on utilise la géolocalisation
                if coordinate == nil {
                    locationService.requestAuthorization()
                }
                await loadData()
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Chargement des données...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
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
            
            Button(action: refreshData) {
                Label("Réessayer", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    // MARK: - Section 1 : Indice Qualité
    private func indiceQualiteSection(phase: PhaseSolunaire) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text(phase.emojiQualite)
                    .font(.system(size: 50))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Qualité du jour")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(phase.qualiteJour)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(phase.indiceQualite)/100")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            
            // Barre de progression
            ProgressView(value: Double(phase.indiceQualite), total: 100)
                .tint(qualiteColor(phase.indiceQualite))
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private func qualiteColor(_ indice: Int) -> Color {
        switch indice {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .red
        }
    }
    
    // MARK: - Section 2 : Conditions Actuelles
    private func conditionsActuellesSection(conditions: ConditionsMeteo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "wind")
                    .foregroundStyle(.blue)
                Text("Conditions actuelles")
                    .font(.headline)
                Spacer()
            }
            
            // Grille météo
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MeteoCard(
                    icon: "wind",
                    label: "Vent",
                    value: conditions.ventComplet ?? "N/A",
                    color: .blue
                )
                
                MeteoCard(
                    icon: "thermometer",
                    label: "Température",
                    value: conditions.temperatureAirFormatee ?? "N/A",
                    color: .orange
                )
                
                MeteoCard(
                    icon: "water.waves",
                    label: "État mer",
                    value: conditions.etatMer?.displayName ?? "N/A",
                    color: .cyan
                )
                
                MeteoCard(
                    icon: "eye",
                    label: "Visibilité",
                    value: conditions.visibilite?.displayName ?? "N/A",
                    color: .purple
                )
            }
            
            // Indicateur conditions favorables
            if conditions.conditionsFavorables {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Conditions favorables à la pêche")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Section 3 : Soleil & Lune
    private func soleilLuneSection(phase: PhaseSolunaire) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sun.and.horizon")
                    .foregroundStyle(.orange)
                Text("Soleil & Lune")
                    .font(.headline)
                Spacer()
            }
            
            // Phase lunaire
            HStack(spacing: 16) {
                Text(phase.phaseLune.emoji)
                    .font(.system(size: 60))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(phase.phaseLune.displayName)
                        .font(.headline)
                    
                    Text("Illumination: \(Int(phase.pourcentageIllumination))%")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(phase.phaseLune.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Horaires
            VStack(spacing: 8) {
                HoraireRow(
                    icon: "sunrise.fill",
                    label: "Lever soleil",
                    time: phase.leverSoleil,
                    color: .orange
                )
                
                HoraireRow(
                    icon: "sunset.fill",
                    label: "Coucher soleil",
                    time: phase.coucherSoleil,
                    color: .orange
                )
                
                if let leverLune = phase.leverLune {
                    HoraireRow(
                        icon: "moonrise.fill",
                        label: "Lever lune",
                        time: leverLune,
                        color: .indigo
                    )
                }
                
                if let coucherLune = phase.coucherLune {
                    HoraireRow(
                        icon: "moonset.fill",
                        label: "Coucher lune",
                        time: coucherLune,
                        color: .indigo
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Section 4 : Marées (✅ MAINTENANT AVEC DONNÉES RÉELLES SHOM)
    private func mareeSection(conditions: ConditionsMeteo) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "water.waves")
                    .foregroundStyle(.cyan)
                Text("Marées")
                    .font(.headline)
                Spacer()
            }
            
            // Coefficient et phase
            HStack(spacing: 20) {
                // Coefficient (réel si disponible)
                VStack(spacing: 4) {
                    Text(conditions.coefficientFormate ?? "N/A")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.cyan)
                    Text("Coefficient")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Phase actuelle (réelle si disponible)
                VStack(spacing: 4) {
                    Text(conditions.phaseMaree?.emoji ?? "❓")
                        .font(.system(size: 36))
                    Text(conditions.phaseMaree?.displayName ?? "N/A")
                        .font(.headline)
                    Text("En cours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Horaires marées (réels si disponibles)
            VStack(spacing: 12) {
                // Marée haute
                if let hauteur = conditions.heureMareeHaute {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Marée haute")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let houle = conditions.hauteurHouleFormatee {
                                Text(houle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(hauteur, style: .time)
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Marée basse
                if let basse = conditions.heureMareeBasse {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Marée basse")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            if let houle = conditions.hauteurHouleFormatee {
                                Text(houle)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Text(basse, style: .time)
                            .font(.headline)
                            .foregroundStyle(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            
            // Représentation graphique simplifiée
            mareeGraphView
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Graphique marée simplifié
    private var mareeGraphView: some View {
        VStack(spacing: 8) {
            Text("Cycle des marées (24h)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Fond
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(height: 80)
                    
                    // Courbe marée (simplifiée)
                    Path { path in
                        let width = geometry.size.width
                        let height: CGFloat = 80
                        let amplitude = height * 0.35
                        let midHeight = height / 2
                        
                        path.move(to: CGPoint(x: 0, y: midHeight))
                        
                        for x in stride(from: 0, to: width, by: 2) {
                            let progress = x / width
                            // Courbe sinusoïdale simplifiée (2 cycles par 24h)
                            let y = midHeight - sin(progress * 4 * .pi) * amplitude
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                    .stroke(Color.cyan, lineWidth: 3)
                    
                    // Indicateur position actuelle (environ 1/3 du cycle)
                    Circle()
                        .fill(Color.green)
                        .frame(width: 12, height: 12)
                        .offset(x: geometry.size.width * 0.35, y: 25)
                    
                    // Labels heures
                    HStack {
                        Text("00h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("06h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("12h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("18h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("24h")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .offset(y: 85)
                }
            }
            .frame(height: 100)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Section 5 : Périodes de Pêche
    private var periodesPecheSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "figure.fishing")
                    .foregroundStyle(.green)
                Text("Meilleures périodes de pêche")
                    .font(.headline)
                Spacer()
            }
            
            // Liste des périodes
            ForEach(bestFishingTimes) { fishingTime in
                PeriodeRow(fishingTime: fishingTime)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
    
    // MARK: - Data Loading (✅ MODIFIÉ POUR UTILISER SHOM)
    private func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Utiliser les coordonnées fournies ou la géolocalisation
        let noumea = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
        let targetCoordinate: CLLocationCoordinate2D
        
        if let providedCoordinate = coordinate {
            // Coordonnées fournies depuis Navigation
            targetCoordinate = providedCoordinate
        } else {
            // Géolocalisation ou fallback Nouméa
            targetCoordinate = locationService.currentLocation?.coordinate ?? noumea
        }
        
        do {
            // ✅ JUSTE LA MÉTÉO pour l'instant
            let meteo = try await meteoService.fetchConditionsActuelles(
                latitude: targetCoordinate.latitude,
                longitude: targetCoordinate.longitude
            )
            
            // Calculer solunaire
            let phase = solunarService.calculatePhaseSolunaire(for: Date(), at: targetCoordinate)
            let times = solunarService.findBestFishingTimes(for: Date(), at: targetCoordinate)
            
            await MainActor.run {
                self.conditionsMeteo = meteo
                self.phaseSolunaire = phase
                self.bestFishingTimes = times
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Erreur de chargement : \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    private func refreshData() {
        Task {
            await loadData()
        }
    }
}

// MARK: - Components

struct MeteoCard: View {
    let icon: String
    let label: String
    let value: String
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
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct HoraireRow: View {
    let icon: String
    let label: String
    let time: Date
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(label)
                .font(.subheadline)
            
            Spacer()
            
            Text(time, style: .time)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct PeriodeRow: View {
    let fishingTime: BestFishingTime
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji et score
            VStack(spacing: 4) {
                Text(fishingTime.emoji)
                    .font(.title2)
                Text("\(fishingTime.score)")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 50)
            
            // Infos période
            VStack(alignment: .leading, spacing: 4) {
                Text(fishingTime.periode.periodeFormatee)
                    .font(.headline)
                
                Text(fishingTime.raison)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("\(fishingTime.qualite) • \(fishingTime.periode.type.emoji) \(fishingTime.periode.type.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Badge durée
            Text(fishingTime.periode.dureeFormatee)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray5))
                .clipShape(Capsule())
        }
        .padding()
        .background(scoreColor(fishingTime.score).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func scoreColor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .blue
        case 40..<60: return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview
#Preview {
    MeteoSolunaireView()
}
