//
//  SpreadVisualizationView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Visualisation graphique sophistiquée du spread de pêche
//  avec bateau, lignes, distances et animations
//
//  Created: 2024-12-05
//

import SwiftUI

struct SpreadVisualizationView: View {
    let configuration: ConfigurationSpread
    
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
                    
                    Text(configuration.strategieSpread)
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
                ForEach(configuration.spreadComplet) { position in
                    LignePecheView(
                        position: position,
                        centerX: centerX,
                        maxHeight: height,
                        animationProgress: animationProgress,
                        isSelected: selectedPosition == position.id,
                        onTap: {
                            withAnimation {
                                selectedPosition = (selectedPosition == position.id) ? nil : position.id
                            }
                        }
                    )
                }
                
                // Bateau (toujours au-dessus)
                BateauView()
                    .frame(width: 80, height: 100)
                    .position(x: centerX, y: 50)
                    .scaleEffect(animationProgress)
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
            
            ForEach(configuration.spreadComplet) { position in
                LegendRow(position: position)
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
            
            ForEach(configuration.spreadComplet) { position in
                PositionDetailCard(position: position)
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
    let position: PositionSpreadAttribuee
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
                path.move(to: CGPoint(x: centerX, y: 60))
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
                ZStack {
                    Circle()
                        .fill(couleurPosition)
                        .frame(width: isSelected ? 40 : 30, height: isSelected ? 40 : 30)
                        .shadow(color: couleurPosition.opacity(0.5), radius: 8)
                    
                    Text(position.iconeRole)
                        .font(.system(size: isSelected ? 24 : 18))
                }
            }
            .position(x: coords.x, y: coords.y)
            .scaleEffect(animationProgress)
            .opacity(animationProgress)
            
            // Label distance
            Text("\(position.distance)m")
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
            
            // Info détaillée (si sélectionné)
            if isSelected {
                VStack(alignment: .leading, spacing: 4) {
                    Text(position.position.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                    Text(position.leurre.nom)
                        .font(.caption2)
                    Text(position.role)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 4)
                .position(x: coords.x + 60, y: coords.y - 30)
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private func calculerCoordonnees() -> (x: CGFloat, y: CGFloat, labelX: CGFloat, labelY: CGFloat) {
        let baseY: CGFloat = 80
        let distanceFactor = CGFloat(position.distance) / 100.0
        let y = baseY + (maxHeight - baseY - 50) * distanceFactor
        
        var x = centerX
        var labelX = centerX
        var labelY = y - 20
        
        switch position.position {
        case .shortCorner:
            x = centerX
            labelX = centerX + 40
            
        case .longCorner:
            x = centerX
            labelX = centerX - 40
            
        case .riggerBabord, .rigger:
            x = centerX - 80
            labelX = x - 40
            
        case .riggerTribord:
            x = centerX + 80
            labelX = x + 40
            
        case .shotgun:
            x = centerX
            labelX = centerX + 50
            
        case .libre:
            x = centerX
        }
        
        return (x, y, labelX, labelY)
    }
    
    private var couleurPosition: Color {
        switch position.position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .riggerBabord, .riggerTribord, .rigger: return .orange
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

// MARK: - Légende Row

struct LegendRow: View {
    let position: PositionSpreadAttribuee
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(couleurPosition)
                .frame(width: 20, height: 20)
                .overlay(
                    Text(position.iconeRole)
                        .font(.caption2)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(position.position.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(position.leurre.nom)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(position.distance)m")
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
        switch position.position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .riggerBabord, .riggerTribord, .rigger: return .orange
        case .shotgun: return .red
        case .libre: return .gray
        }
    }
}

// MARK: - Position Detail Card

struct PositionDetailCard: View {
    let position: PositionSpreadAttribuee
    @State private var isExpanded = false
    
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
                        Text(position.position.displayName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(position.leurre.nom) • \(position.role)")
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
                    
                    HStack {
                        Label("\(position.distance)m", systemImage: "arrow.right")
                            .font(.caption)
                        
                        Spacer()
                        
                        Text(position.leurre.marque)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(position.justification)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(couleurPosition.opacity(0.1))
                        .cornerRadius(8)
                    
                    HStack(spacing: 8) {
                        DetailBadge(label: "Longueur", value: "\(Int(position.leurre.longueur))cm")
                        DetailBadge(label: "Profondeur", value: position.leurre.profondeurFormatee)
                        DetailBadge(label: "Vitesse", value: position.leurre.vitesseFormatee)
                    }
                }
            }
        }
        .padding()
        .background(couleurPosition.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var couleurPosition: Color {
        switch position.position {
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .riggerBabord, .riggerTribord, .rigger: return .orange
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
