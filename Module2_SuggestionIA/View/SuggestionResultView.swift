//
//  SuggestionResultView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  VERSION FINALE avec affichage complet :
//  ✅ Couleur + Marque affichées dans toutes les cards
//  ✅ Rond coloré pour chaque couleur
//  ✅ CORRECTION : Calcul niveau qualité depuis score
//
//  Created: 2024-12-05
//  Updated: 2024-12-09 - Ajout affichage couleur + correction niveauQualite
//

import SwiftUI

// MARK: - Helpers

private func qualiteDepuisScore(_ score: Double) -> String {
    switch score {
    case 90...100: return "Exceptionnel"
    case 80..<90: return "Excellent"
    case 70..<80: return "Très bon"
    case 60..<70: return "Bon"
    case 50..<60: return "Correct"
    default: return "Faible"
    }
}

struct SuggestionResultView: View {
    let suggestions: [SuggestionEngine.SuggestionResult]
    let configuration: SuggestionEngine.ConfigurationSpread?
    
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
                    
                    // Tab 3 : Schéma interactif
                    schemaInteractifView
                        .tag(2)
                    
                    // Tab 4 : Toutes suggestions
                    toutesSuggestionsView
                        .tag(3)
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
                        valeur: "\(config.nombreLignes)",
                        label: "Lignes",
                        couleur: Color(hex: "0277BD")
                    )
                }
            }
            
            if let config = configuration {
                Text("Distance moyenne: \(Int(config.distanceMoyenne))m")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var suggestionsExcellentes: [SuggestionEngine.SuggestionResult] {
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
                title: "Schéma",
                icon: "photo.fill",
                isSelected: selectedTab == 2,
                action: { withAnimation { selectedTab = 2 } }
            )
            
            TabButton(
                title: "Tous",
                icon: "list.bullet",
                isSelected: selectedTab == 3,
                action: { withAnimation { selectedTab = 3 } }
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
    
    // MARK: - Schéma Interactif View
    
    private var schemaInteractifView: some View {
        Group {
            if let config = configuration {
                SpreadSchemaView(configuration: config)
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
    let suggestion: SuggestionEngine.SuggestionResult
    let isExpanded: Bool
    let onToggle: () -> Void
    @StateObject private var viewModel = LeureViewModel()
    
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
                        
                        // ➕ NOUVEAU : Couleur avec rond
                        HStack(spacing: 4) {
                            CouleurPastille(leurre: suggestion.leurre, isPrincipal: true, size: 10)
                            Text(suggestion.leurre.couleurPrincipaleAffichage.nom)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 8) {
                            EtoilesView(nombre: min(5, max(1, Int(suggestion.scoreTotal / 20))))
                            
                            // ✅ CORRECTION : Calcul niveau qualité depuis score
                            Text(qualiteDepuisScore(suggestion.scoreTotal))
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
                    
                    // 📸 PHOTO DU LEURRE
                    if let image = viewModel.chargerPhoto(pourLeurre: suggestion.leurre) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 250)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.horizontal)
                    }
                    
                    // Modèle (si disponible)
                    if let modele = suggestion.leurre.modele, !modele.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                                .foregroundColor(Color(hex: "0277BD"))
                            Text("Modèle : \(modele)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                    
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
                        valeur: {
                            if let profMin = suggestion.leurre.profondeurNageMin,
                               let profMax = suggestion.leurre.profondeurNageMax {
                                return "\(Int(profMin))-\(Int(profMax))m"
                            }
                            return "-"
                        }()
                    )
                    CaracBadge(
                        label: "Vitesse",
                        valeur: {
                            if let vitMin = suggestion.leurre.vitesseTraineMin,
                               let vitMax = suggestion.leurre.vitesseTraineMax {
                                return "\(Int(vitMin))-\(Int(vitMax))kts"
                            }
                            return "-"
                        }()
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
    let suggestion: SuggestionEngine.SuggestionResult
    
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
                
                HStack(spacing: 4) {
                    Text(suggestion.leurre.marque)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(suggestion.leurre.longueur))cm")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // ➕ NOUVEAU : Couleur
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 3) {
                        CouleurPastille(leurre: suggestion.leurre, isPrincipal: true, size: 6)
                        Text(suggestion.leurre.couleurPrincipaleAffichage.nom)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                EtoilesView(nombre: min(5, max(1, Int(suggestion.scoreTotal / 20))))
            }
            
            Spacer()
            
            if let position = suggestion.positionSpread {
                VStack(alignment: .trailing, spacing: 2) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(hex: "0277BD"))
                    Text(position.displayName)
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

// MARK: - ✅ Fonction Couleur (identique à SpreadVisualizationView)

private func couleurPourAffichage(_ couleur: Couleur) -> Color {
    switch couleur {
    // 🔵 Naturelles
    case .bleuArgente: return Color(red: 0.3, green: 0.6, blue: 0.9)
    case .bleuBlanc: return Color(red: 0.5, green: 0.7, blue: 1.0)
    case .vertArgente: return Color(red: 0.2, green: 0.7, blue: 0.5)
    case .vertDore: return Color(red: 0.4, green: 0.7, blue: 0.2)
    case .sardine: return Color(red: 0.7, green: 0.8, blue: 0.9)
    case .maquereau: return Color(red: 0.2, green: 0.6, blue: 0.5)
    case .argente: return Color.gray.opacity(0.6)
    case .argenteBleu: return Color(red: 0.6, green: 0.7, blue: 0.9)
    case .blanc: return Color.white
    case .transparent: return Color.gray.opacity(0.3)
    
    // 🌸 Flashy
    case .roseFuchsia: return Color(red: 1.0, green: 0.0, blue: 0.5)
    case .rose: return .pink
    case .roseFluo: return Color(red: 1.0, green: 0.2, blue: 0.7)
    case .chartreuse: return Color(red: 0.5, green: 1.0, blue: 0.0)
    case .orange: return .orange
    case .jaune: return .yellow
    case .jauneFluo: return Color(red: 1.0, green: 1.0, blue: 0.0)
    case .roseHolographique: return Color(red: 1.0, green: 0.5, blue: 0.8)
    case .jauneHolographique: return Color(red: 1.0, green: 0.9, blue: 0.3)
    
    // ⚫ Sombres
    case .noir: return .black
    case .noirViolet: return Color(red: 0.2, green: 0.0, blue: 0.3)
    case .noirBleu: return Color(red: 0.0, green: 0.1, blue: 0.3)
    case .bleuNoir: return Color(red: 0.1, green: 0.1, blue: 0.3)
    case .vertNoir: return Color(red: 0.0, green: 0.2, blue: 0.1)
    case .violetFonce: return Color(red: 0.3, green: 0.0, blue: 0.5)
    case .bleuFonce: return Color(red: 0.0, green: 0.2, blue: 0.6)
    case .noirRouge: return Color(red: 0.3, green: 0.0, blue: 0.1)
    case .violet: return .purple
    
    // 🎨 Contrastées
    case .bleuNoirGris: return Color(red: 0.2, green: 0.3, blue: 0.4)
    case .violetNoir: return Color(red: 0.3, green: 0.0, blue: 0.4)
    case .roseBlanc: return Color(red: 1.0, green: 0.7, blue: 0.8)
    case .rougeJaune: return Color(red: 1.0, green: 0.5, blue: 0.0)
    case .orangeJaune: return Color(red: 1.0, green: 0.7, blue: 0.0)
    case .blancRouge: return Color(red: 1.0, green: 0.3, blue: 0.3)
    case .blancOrange: return Color(red: 1.0, green: 0.6, blue: 0.4)
    case .vertBlanc: return Color(red: 0.5, green: 0.9, blue: 0.6)
    case .roseBleu: return Color(red: 0.7, green: 0.4, blue: 0.9)
    
    // 🟤 Autres
    case .brun: return Color(red: 0.6, green: 0.4, blue: 0.2)
    case .beige: return Color(red: 0.9, green: 0.9, blue: 0.7)
    case .marron: return Color(red: 0.4, green: 0.2, blue: 0.1)
    case .vert: return .green
    case .vertOlive: return Color(red: 0.5, green: 0.5, blue: 0.2)
    case .bleu: return .blue
    case .blow: return Color(red: 0.5, green: 0.8, blue: 1.0)
    case .rouge: return .red
    case .or: return Color(red: 1.0, green: 0.84, blue: 0.0)
    }
}
