//
//  SuggestionResultView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Vue des résultats avec justifications et spread
//
//  Created: 2024-12-05
//

import SwiftUI

struct SuggestionResultView: View {
    let suggestions: [SuggestionResult]
    let configuration: ConfigurationSpread?
    
    @Environment(\.dismiss) var dismiss
    @State private var selectedTab = 0
    @State private var expandedCards: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // En-tête statistiques
                headerStats
                
                // Tabs
                tabSelector
                
                // Contenu
                TabView(selection: $selectedTab) {
                    // Tab 1 : Top suggestions
                    topSuggestionsView
                        .tag(0)
                    
                    // Tab 2 : Spread visuel
                    spreadVisuelView
                        .tag(1)
                    
                    // Tab 3 : Toutes suggestions
                    toutesS uggestionsView
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .background(Color(hex: "F5F5F5"))
            .navigationTitle("Résultats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header Stats
    
    private var headerStats: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatBadge(
                    valeur: "\(suggestions.count)",
                    label: "Leurres",
                    couleur: Color(hex: "0277BD")
                )
                
                StatBadge(
                    valeur: "\(suggestionsExcellentes.count)",
                    label: "Excellents",
                    couleur: Color(hex: "FFBC42")
                )
                
                if let config = configuration {
                    StatBadge(
                        valeur: "\(config.spreadComplet.count)",
                        label: "Lignes",
                        couleur: Color(hex: "0277BD")
                    )
                }
            }
            
            if let config = configuration {
                Text(config.strategieSpread)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var suggestionsExcellentes: [SuggestionResult] {
        suggestions.filter { $0.scoreTotal >= 80 }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Top",
                icon: "star.fill",
                isSelected: selectedTab == 0,
                action: { withAnimation { selectedTab = 0 } }
            )
            
            TabButton(
                title: "Spread",
                icon: "map.fill",
                isSelected: selectedTab == 1,
                action: { withAnimation { selectedTab = 1 } }
            )
            
            TabButton(
                title: "Tous",
                icon: "list.bullet",
                isSelected: selectedTab == 2,
                action: { withAnimation { selectedTab = 2 } }
            )
        }
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
    }
    
    // MARK: - Top Suggestions View
    
    private var topSuggestionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("🏆 MEILLEURES RECOMMANDATIONS")
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
                    .padding(.top)
                
                ForEach(suggestions.prefix(5)) { suggestion in
                    SuggestionCard(
                        suggestion: suggestion,
                        isExpanded: expandedCards.contains(suggestion.id),
                        onToggle: {
                            withAnimation {
                                if expandedCards.contains(suggestion.id) {
                                    expandedCards.remove(suggestion.id)
                                } else {
                                    expandedCards.insert(suggestion.id)
                                }
                            }
                        }
                    )
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
    
    // MARK: - Spread Visuel View
    
    private var spreadVisuelView: some View {
        Group {
            if let config = configuration {
                SpreadVisualizationView(configuration: config)
            } else {
                EmptySpreadView()
            }
        }
    }
    
    // MARK: - Toutes Suggestions View
    
    private var toutesSuggestionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("📋 TOUTES LES SUGGESTIONS (\(suggestions.count))")
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
                    .padding(.top)
                
                ForEach(suggestions) { suggestion in
                    SuggestionCardCompact(suggestion: suggestion)
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
    }
}

// MARK: - Suggestion Card (Expandable)

struct SuggestionCard: View {
    let suggestion: SuggestionResult
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (toujours visible)
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    // Badge score
                    VStack(spacing: 4) {
                        Text("\(Int(suggestion.scoreTotal))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("/100")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 60, height: 60)
                    .background(couleurScore(suggestion.scoreTotal))
                    .cornerRadius(12)
                    
                    // Info leurre
                    VStack(alignment: .leading, spacing: 4) {
                        Text(suggestion.leurre.nom)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(suggestion.leurre.marque)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            EtoilesView(nombre: suggestion.niveauEtoiles)
                            
                            Text(suggestion.niveauQualite)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(couleurScore(suggestion.scoreTotal).opacity(0.2))
                                .foregroundColor(couleurScore(suggestion.scoreTotal))
                                .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Color(hex: "0277BD"))
                }
                .padding()
            }
            .buttonStyle(PlainButtonStyle())
            
            // Détails (si expandé)
            if isExpanded {
                VStack(alignment: .leading, spacing: 16) {
                    Divider()
                    
                    // Position spread
                    if let position = suggestion.positionSpread,
                       let distance = suggestion.distanceSpread {
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(Color(hex: "FFBC42"))
                            Text(position.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("(\(distance)m)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
                    // Caractéristiques
                    HStack(spacing: 16) {
                        CaracBadge(
                            label: "Longueur",
                            valeur: "\(Int(suggestion.leurre.longueur))cm"
                        )
                        CaracBadge(
                            label: "Profondeur",
                            valeur: suggestion.leurre.profondeurFormatee
                        )
                        CaracBadge(
                            label: "Vitesse",
                            valeur: suggestion.leurre.vitesseFormatee
                        )
                    }
                    .padding(.horizontal)
                    
                    // Justifications
                    JustificationSection(
                        titre: "TECHNIQUE",
                        score: Int(suggestion.scoreTechnique),
                        max: 40,
                        texte: suggestion.justificationTechnique,
                        couleur: Color(hex: "0277BD")
                    )
                    
                    JustificationSection(
                        titre: "COULEUR",
                        score: Int(suggestion.scoreCouleur),
                        max: 30,
                        texte: suggestion.justificationCouleur,
                        couleur: Color(hex: "FFBC42")
                    )
                    
                    JustificationSection(
                        titre: "CONDITIONS",
                        score: Int(suggestion.scoreConditions),
                        max: 30,
                        texte: suggestion.justificationConditions,
                        couleur: .green
                    )
                    
                    // Astuce pro
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("ASTUCE PRO")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                            
                            Text(suggestion.astucePro)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
    
    private func couleurScore(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 70..<80: return Color(hex: "FFBC42")
        case 60..<70: return .blue
        default: return .gray
        }
    }
}

// MARK: - Suggestion Card Compact

struct SuggestionCardCompact: View {
    let suggestion: SuggestionResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Score
            Text("\(Int(suggestion.scoreTotal))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(couleurScore(suggestion.scoreTotal))
                .cornerRadius(10)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(suggestion.leurre.nom)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text("\(suggestion.leurre.marque) • \(Int(suggestion.leurre.longueur))cm")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                EtoilesView(nombre: suggestion.niveauEtoiles)
            }
            
            Spacer()
            
            if let position = suggestion.positionSpread {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(hex: "0277BD"))
                    Text(position.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func couleurScore(_ score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 70..<80: return Color(hex: "FFBC42")
        case 60..<70: return .blue
        default: return .gray
        }
    }
}

// MARK: - Composants

struct StatBadge: View {
    let valeur: String
    let label: String
    let couleur: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(valeur)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(couleur)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(isSelected ? Color(hex: "0277BD") : .gray)
            .background(isSelected ? Color(hex: "0277BD").opacity(0.1) : Color.clear)
        }
    }
}

struct EtoilesView: View {
    let nombre: Int
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<nombre, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

struct CaracBadge: View {
    let label: String
    let valeur: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(valeur)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(8)
    }
}

struct JustificationSection: View {
    let titre: String
    let score: Int
    let max: Int
    let texte: String
    let couleur: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(titre)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(couleur)
                
                Spacer()
                
                Text("\(score)/\(max)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(couleur)
            }
            
            // Barre de progression
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(couleur.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(couleur)
                        .frame(width: geometry.size.width * CGFloat(score) / CGFloat(max), height: 4)
                        .cornerRadius(2)
                }
            }
            .frame(height: 4)
            
            Text(texte)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(couleur.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct EmptySpreadView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "map")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Aucun spread configuré")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}
