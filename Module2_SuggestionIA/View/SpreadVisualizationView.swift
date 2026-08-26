//
//  SpreadVisualizationView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  VERSION FINALE avec affichage complet :
//  ✅ Nom du leurre + Marque + Couleur (rond coloré)
//  ✅ TOUTES les couleurs de l'enum Couleur mappées
//  ✅ Rôle et justification
//
//  Created: 2024-12-05
//  Updated: 2024-12-12 - Corrections types
//

import SwiftUI

struct SpreadVisualizationView: View {
    let configuration: SuggestionEngine.ConfigurationSpread
    
    @State private var animationProgress: CGFloat = 0
    @State private var selectedPosition: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Titre
                VStack(spacing: 8) {
                    Text("🚤 CONFIGURATION TRAÎNE")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0277BD"))
                    
                    Text("\(configuration.nombreLignes) ligne(s) - Distance moyenne: \(Int(configuration.distanceMoyenne))m")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                
                // Schéma visuel
                spreadDiagram
                    .frame(height: 500)
                    .padding()
                
                // Légende
                legendeSection
                
                // Liste détaillée
                detailsSection
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(hex: "F5F5F5"))
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5)) {
                animationProgress = 1.0
            }
        }
    }
    
    // MARK: - Spread Diagram
    
    private var spreadDiagram: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            
            ZStack {
                // Eau (fond)
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.3),
                                Color.blue.opacity(0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(20)
                
                // Vagues décoratives
                ForEach(0..<5) { i in
                    Wave(offset: CGFloat(i) * 60)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .offset(y: CGFloat(i) * 80 - 100)
                }
                
                // Lignes de pêche
                ForEach(configuration.suggestions) { suggestion in
                    if let position = suggestion.positionSpread, let distance = suggestion.distanceSpread {
                        LignePecheView(
                            suggestion: suggestion,
                            position: position,
                            distance: distance,
                            centerX: centerX,
                            maxHeight: height,
                            animationProgress: animationProgress,
                            isSelected: selectedPosition == suggestion.id,
                            onTap: {
                                withAnimation {
                                    selectedPosition = (selectedPosition == suggestion.id) ? nil : suggestion.id
                                }
                            }
                        )
                    }
                }
                
                // Bateau (toujours au-dessus)
                BateauView()
                    .frame(width: 80, height: 100)
                    .position(x: centerX, y: 50)
                    .scaleEffect(animationProgress)
                    .opacity(animationProgress)
                
                // ⚡ INDICATEUR DE VITESSE (coin supérieur gauche)
                VitesseIndicatorView(
                    vitesseRecommandee: configuration.vitesseRecommandee,
                    plageMin: configuration.vitessePlageMin,
                    plageMax: configuration.vitessePlageMax,
                    justification: configuration.justificationVitesse,
                    ajustements: configuration.ajustementsVitesse
                )
                .position(x: 80, y: 10)  // Coin supérieur gauche
                .scaleEffect(animationProgress * 0.8)
                .opacity(animationProgress)
            }
        }
    }
    
    // MARK: - Légende
    
    private var legendeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("📍 POSITIONS")
                .font(.headline)
                .foregroundColor(Color(hex: "0277BD"))
            
            ForEach(configuration.suggestions) { suggestion in
                if let position = suggestion.positionSpread {
                    LegendRow(suggestion: suggestion, position: position)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Détails
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🎣 DÉTAILS DES POSITIONS")
                .font(.headline)
                .foregroundColor(Color(hex: "0277BD"))
            
            ForEach(configuration.suggestions) { suggestion in
                if let position = suggestion.positionSpread {
                    PositionDetailCard(suggestion: suggestion, position: position)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Ligne de Pêche Animée

struct LignePecheView: View {
    let suggestion: SuggestionEngine.SuggestionResult
    let position: PositionSpread
    let distance: Int
    let centerX: CGFloat
    let maxHeight: CGFloat
    let animationProgress: CGFloat
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        let coords = calculerCoordonnees()
        
        ZStack {
            // Ligne
            Path { path in
                // ✅ Point de départ selon la position
                let startPoint = coords.startPoint
                path.move(to: startPoint)
                path.addLine(to: CGPoint(x: coords.x, y: coords.y))
            }
            .trim(from: 0, to: animationProgress)
            .stroke(
                couleurPosition,
                style: StrokeStyle(lineWidth: isSelected ? 3 : 2, lineCap: .round, dash: [5, 5])
            )
            .shadow(color: couleurPosition.opacity(0.5), radius: isSelected ? 8 : 4)
            
            // Leurre (point final)
            Button(action: onTap) {
                PastilleNumeroPosition(
                    leurre: suggestion.leurre,
                    position: position,
                    couleurPosition: couleurPosition,
                    diametre: isSelected ? 40 : 30
                )
                .shadow(color: couleurPosition.opacity(0.5), radius: 8)
            }
            .position(x: coords.x, y: coords.y)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
            
            // Label distance
            Text("\(distance)m")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(couleurPosition)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 2)
                .position(x: coords.labelX, y: coords.labelY)
                .opacity(animationProgress)
            
            // ➕ Info détaillée enrichie (si sélectionné)
            if isSelected {
                VStack(alignment: .leading, spacing: 6) {
                    Text(position.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.leurre.nom)
                            .font(.caption)
                            .fontWeight(.semibold)
                        
                        Text(suggestion.leurre.marque)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            CouleurPastille(leurre: suggestion.leurre, isPrincipal: true, size: 8)
                            Text(suggestion.leurre.couleurPrincipaleAffichage.nom)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text(position.caracteristiques)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(10)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.15), radius: 5)
                .position(x: coords.x + 80, y: coords.y - 40)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func calculerCoordonnees() -> (x: CGFloat, y: CGFloat, labelX: CGFloat, labelY: CGFloat, startPoint: CGPoint) {
        let baseY: CGFloat = 80
        let zonePeche = maxHeight - baseY - 50
        
        // ✅ CONFIGURATION RÉELLE DE TRAÎNE :
        // - Short Corner : TRIBORD (droite), proche (10-20m)
        // - Long Corner : BÂBORD (gauche), loin (30-50m)
        // - Short Rigger : TRIBORD (droite), tangon (40-60m)
        // - Long Rigger : BÂBORD (gauche), tangon (50-70m)
        // - Shotgun : CENTRE, très loin (70-100m)
        
        let distanceMax: CGFloat = 100.0
        let distanceFactor = CGFloat(distance) / distanceMax
        let y = baseY + zonePeche * distanceFactor
        
        var x = centerX
        var labelX = centerX
        var startPoint = CGPoint(x: centerX, y: 80)  // Par défaut : centre arrière bateau
        let labelY = y - 20
        
        // Largeur du bateau : ~60px, donc les angles sont à ±30px du centre
        let demiLargeurBateau: CGFloat = 30
        
        switch position {
        case .shortCorner:
            // ✅ Short Corner : TRIBORD (droite), part de l'angle arrière droit
            startPoint = CGPoint(x: centerX + demiLargeurBateau, y: 80)
            x = centerX + 40  // S'écarte vers tribord (droite)
            labelX = centerX - 40
            
        case .longCorner:
            // ✅ Long Corner : BÂBORD (gauche), part de l'angle arrière gauche
            startPoint = CGPoint(x: centerX - demiLargeurBateau, y: 80)
            x = centerX - 40  // S'écarte vers bâbord (gauche)
            labelX = centerX + 40
            
        case .shortRigger:
            // ✅ Short Rigger : TRIBORD (droite), tangon droit
            startPoint = CGPoint(x: centerX + 50, y: 70)  // Tangon droit, un peu plus haut
            x = centerX + 120  // Écart important pour le tangon
            labelX = x + 40
            
        case .longRigger:
            // ✅ Long Rigger : BÂBORD (gauche), tangon gauche
            startPoint = CGPoint(x: centerX - 50, y: 70)  // Tangon gauche, un peu plus haut
            x = centerX - 120  // Écart important symétrique
            labelX = x - 40
            
        case .shotgun:
            // ✅ Shotgun : CENTRE, très loin
            startPoint = CGPoint(x: centerX, y: 80)
            x = centerX  // Reste dans l'axe
            labelX = centerX + 50
            
        case .libre:
            // ✅ Position libre : CENTRE, variable
            startPoint = CGPoint(x: centerX, y: 80)
            x = centerX
        }
        
        return (x, y, labelX, labelY, startPoint)
    }
    
    private var couleurPosition: Color {
        switch position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .shortRigger, .longRigger: return .orange
        case .shotgun: return .red
        case .libre: return .gray
        }
    }
}

// MARK: - Bateau

struct BateauView: View {
    var body: some View {
        ZStack {
            // Corps du bateau
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.white, Color.gray.opacity(0.3)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 60, height: 80)
            
            // Proue
            Triangle()
                .fill(Color.white)
                .frame(width: 60, height: 20)
                .offset(y: -50)
            
            // Cabine
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(hex: "0277BD"))
                .frame(width: 40, height: 25)
                .offset(y: -10)
            
            // Détails
            VStack(spacing: 2) {
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 8, height: 8)
                
                Text("⬆️")
                    .font(.title3)
            }
            .offset(y: -20)
            
            // Sillage
            ForEach(0..<3) { i in
                Capsule()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 30 + CGFloat(i) * 10, height: 3)
                    .offset(y: 50 + CGFloat(i) * 10)
            }
        }
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Vague décorative

struct Wave: Shape {
    let offset: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height: CGFloat = 20
        
        path.move(to: CGPoint(x: 0, y: height / 2))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset / 100) * .pi * 4)
            let y = height / 2 + sine * (height / 4)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

// MARK: - Légende Row Enrichie

struct LegendRow: View {
    let suggestion: SuggestionEngine.SuggestionResult
    let position: PositionSpread
    
    var body: some View {
        HStack(spacing: 12) {
            PastilleNumeroPosition(
                leurre: suggestion.leurre,
                position: position,
                couleurPosition: couleurPosition,
                diametre: 22
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(position.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(suggestion.leurre.nom)
                    .font(.caption)
                    .fontWeight(.medium)
                
                // ➕ Marque et couleur
                HStack(spacing: 8) {
                    Text(suggestion.leurre.marque)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        CouleurPastille(leurre: suggestion.leurre, isPrincipal: true, size: 8)
                        Text(suggestion.leurre.couleurPrincipaleAffichage.nom)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text("\(suggestion.distanceSpread ?? 0)m")
                .font(.caption)
                .fontWeight(.bold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(couleurPosition.opacity(0.2))
                .foregroundColor(couleurPosition)
                .cornerRadius(8)
        }
    }
    
    private var couleurPosition: Color {
        switch position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .shortRigger, .longRigger: return .orange
        case .shotgun: return .red
        case .libre: return .gray
        }
    }
}

// MARK: - Position Detail Card

struct PositionDetailCard: View {
    let suggestion: SuggestionEngine.SuggestionResult
    let position: PositionSpread
    @State private var isExpanded = false
    @StateObject private var viewModel = BoiteLeurresViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(couleurPosition)
                        .frame(width: 12, height: 12)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(position.displayName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // ➕ Nom + Marque + Couleur
                        HStack(spacing: 8) {
                            Text(suggestion.leurre.nom)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Text(suggestion.leurre.marque)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 3) {
                                CouleurPastille(leurre: suggestion.leurre, isPrincipal: true, size: 6)
                                Text(suggestion.leurre.couleurPrincipaleAffichage.nom)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text(position.caracteristiques)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(couleurPosition)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    // 📸 PHOTO DU LEURRE (si disponible)
                    if let photoData = suggestion.leurre.photoData,
                       let image = UIImage(data: photoData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                            .padding(.bottom, 8)
                    }
                    
                    HStack {
                        Label("\(suggestion.distanceSpread ?? 0)m", systemImage: "arrow.right")
                            .font(.caption)
                        
                        Spacer()
                    }
                    
                    Text(suggestion.justificationPosition)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(couleurPosition.opacity(0.1))
                        .cornerRadius(8)
                    
                    HStack(spacing: 8) {
                        DetailBadge(label: "Longueur", value: "\(Int(suggestion.leurre.longueur))cm")
                        if let profMin = suggestion.leurre.profondeurNageMin, let profMax = suggestion.leurre.profondeurNageMax {
                            DetailBadge(label: "Profondeur", value: "\(Int(profMin))-\(Int(profMax))m")
                        }
                        if let vitMin = suggestion.leurre.vitesseTraineMin, let vitMax = suggestion.leurre.vitesseTraineMax {
                            DetailBadge(label: "Vitesse", value: "\(Int(vitMin))-\(Int(vitMax))kts")
                        }
                    }
                }
            }
        }
        .padding()
        .background(couleurPosition.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var couleurPosition: Color {
        switch position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .shortRigger, .longRigger: return .orange
        case .shotgun: return .red
        case .libre: return .gray
        }
    }
}

struct DetailBadge: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(6)
    }
}

// MARK: - ✅ FONCTION COMPLÈTE : Toutes les couleurs de l'enum

// MARK: - ✅ FONCTION COMPLÈTE : Toutes les couleurs de l'enum

/// Convertit les couleurs de leurre (enum Couleur) en couleurs d'affichage SwiftUI
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
    case .blow: return Color(red: 0.5, green: 0.8, blue: 1.0) // "Glow" bleu
    case .rouge: return .red
    case .or: return Color(red: 1.0, green: 0.84, blue: 0.0)
    }
}

// MARK: - Indicateur de Vitesse

/// Affiche un speedomètre compact, tap pour toggle les détails
private struct VitesseIndicatorView: View {
    let vitesseRecommandee: Double
    let plageMin: Double
    let plageMax: Double
    let justification: String
    let ajustements: [String]
    
    @State private var showDetails = false
    
    init(vitesseRecommandee: Double, plageMin: Double, plageMax: Double, justification: String = "", ajustements: [String] = []) {
        self.vitesseRecommandee = vitesseRecommandee
        self.plageMin = plageMin
        self.plageMax = plageMax
        self.justification = justification
        self.ajustements = ajustements
    }
    
    var body: some View {
        ZStack {
            // Speedomètre compact (toujours visible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showDetails.toggle()  // Toggle : tap pour ouvrir/fermer
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "speedometer")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(String(format: "%.1f", vitesseRecommandee))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("kts")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(hex: "0277BD"))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Détails (au tap)
            if showDetails {
                // Fond pour capturer les taps en dehors du popup
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showDetails = false
                        }
                    }
                
                VStack(spacing: 0) {
                    // Flèche pointant vers le speedomètre
                    TrianglePointer()
                        .fill(Color.white)
                        .frame(width: 20, height: 10)
                        .offset(y: 5)
                    
                    // Carte détaillée
                    VStack(spacing: 12) {
                        // En-tête
                        HStack(spacing: 8) {
                            Image(systemName: "speedometer")
                                .font(.title3)
                                .foregroundColor(Color(hex: "0277BD"))
                            
                            Text("VITESSE RECOMMANDÉE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "0277BD"))
                            
                            Spacer()
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showDetails = false
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        Divider()
                        
                        // Valeur principale + plage
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", vitesseRecommandee))
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "0277BD"))
                                Text("kts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Plage: \(String(format: "%.1f", plageMin)) - \(String(format: "%.1f", plageMax)) kts")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Barre visuelle
                        GeometryReader { geometry in
                            let maxSpeed: CGFloat = 15.0
                            let minPosition = CGFloat(plageMin) / maxSpeed * geometry.size.width
                            let maxPosition = CGFloat(plageMax) / maxSpeed * geometry.size.width
                            let recommandeePosition = CGFloat(vitesseRecommandee) / maxSpeed * geometry.size.width
                            
                            ZStack(alignment: .leading) {
                                // Fond
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .cornerRadius(4)
                                
                                // Zone recommandée
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(hex: "0277BD").opacity(0.3),
                                                Color(hex: "0277BD").opacity(0.6)
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: maxPosition - minPosition)
                                    .offset(x: minPosition)
                                    .cornerRadius(4)
                                
                                // Indicateur vitesse optimale
                                Circle()
                                    .fill(Color(hex: "0277BD"))
                                    .frame(width: 14, height: 14)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2.5)
                                    )
                                    .shadow(color: Color(hex: "0277BD").opacity(0.4), radius: 3)
                                    .offset(x: recommandeePosition - 7)
                            }
                        }
                        .frame(height: 8)
                        
                        // Labels
                        HStack {
                            Text("0")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("15 kts")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        // Justification technique (résumé 3-4 lignes max)
                        if !justification.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "info.circle.fill")
                                        .font(.caption2)
                                        .foregroundColor(Color(hex: "0277BD"))
                                    Text("POURQUOI")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color(hex: "0277BD"))
                                }
                                
                                // Prendre seulement la première phrase (technique pro)
                                Text(justificationCourte)
                                    .font(.caption2)
                                    .foregroundColor(.primary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "0277BD").opacity(0.05))
                            .cornerRadius(6)
                        }
                        
                        // Ajustements recommandés
                        if !ajustements.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.caption2)
                                        .foregroundColor(.orange)
                                    Text("AJUSTEMENTS")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(ajustements, id: \.self) { ajustement in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text("•")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                            Text(ajustement)
                                                .font(.caption2)
                                                .foregroundColor(.primary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                }
                            }
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.orange.opacity(0.05))
                            .cornerRadius(6)
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                }
                .frame(width: 280)
                .offset(y: 40)
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(100)
                .onTapGesture {
                    // Capture le tap sur le popup pour éviter qu'il ferme
                }
            }
        }
    }
    
    // Raccourci la justification pour le popup (max 3 lignes)
    private var justificationCourte: String {
        let phrases = justification.components(separatedBy: ". ")
        if phrases.count > 1 {
            return phrases[0] + "."
        }
        return justification
    }
}

// Triangle pour la flèche du popup
private struct TrianglePointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Helper : Pastille de couleur avec support Custom et Rainbow

/// Affiche une pastille de couleur (standard ou rainbow custom)
struct CouleurPastille: View {
    let leurre: Leurre
    let isPrincipal: Bool
    let size: CGFloat
    
    init(leurre: Leurre, isPrincipal: Bool = true, size: CGFloat = 8) {
        self.leurre = leurre
        self.isPrincipal = isPrincipal
        self.size = size
    }
    
    var body: some View {
        let info = isPrincipal ? leurre.couleurPrincipaleAffichage : leurre.couleurSecondaireAffichage
        
        Group {
            if let colorInfo = info {
                if colorInfo.isRainbow {
                    RainbowCircle(size: size, showBorder: true)
                } else {
                    Circle()
                        .fill(colorInfo.color)
                        .frame(width: size, height: size)
                        .overlay(
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: size > 10 ? 1 : 0.5)
                        )
                }
            } else if !isPrincipal {
                // Couleur secondaire absente : ne rien afficher
                EmptyView()
            }
        }
    }
}
// MARK: - Pastille numérotée : couleur du leurre + anneau de position

/// Disque à la couleur principale du leurre suggéré, cerclé de la couleur
/// de position, portant le numéro de position du gabarit.
struct PastilleNumeroPosition: View {
    let leurre: Leurre
    let position: PositionSpread
    let couleurPosition: Color
    let diametre: CGFloat

    var body: some View {
        let info = leurre.couleurPrincipaleAffichage
        let epaisseur = max(2, diametre * 0.10)
        let couleurTexte: Color =
            (info.isRainbow || !leurre.estCouleurPrincipaleClaire) ? .white : .black

        ZStack {
            if info.isRainbow {
                RainbowCircle(size: diametre, showBorder: false)
            } else {
                Circle()
                    .fill(info.color)
                    .frame(width: diametre, height: diametre)
            }

            Circle()
                .stroke(couleurPosition, lineWidth: epaisseur)
                .frame(width: diametre - epaisseur, height: diametre - epaisseur)

            Text(position.numero)
                .font(.system(size: diametre * 0.46, weight: .heavy, design: .rounded))
                .foregroundColor(couleurTexte)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(width: diametre, height: diametre)
    }
}

