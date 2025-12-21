//
//  SpreadSchemaView.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  Vue interactive du spread avec image de référence et bulles cliquables
//  Base design: 1024 × 1536 (taille exacte de l'image fournie)
//
//  Created: 2024-12-19
//

import SwiftUI
import UIKit

/// Affiche le schéma (image) + bulles superposées (tap => surimpression fiche).
/// Base design: 1024 × 1536 (taille exacte de l'image fournie).
struct SpreadSchemaView: View {
    let configuration: SuggestionEngine.ConfigurationSpread
    
    // Taille de référence du template
    private let designSize = CGSize(width: 1024, height: 1536)
    
    // ✅ COORDONNÉES EXACTES DES BULLES BLANCHES (générées par ImageCoordinatePickerView)
    // Mapping parfait avec votre image spread_template_ok
    private let bubbles: [BubbleSpec] = [
        // 0L - Libre (position libre gauche)
        .init(id: "0L", position: .libre, center: CGPoint(x: 255, y: 555), diameter: 165,
              imageName: "lure_0_left", title: "Libre (gauche)", subtitle: "Bulle additionnelle",
              notes: "La meilleure suggestion"),
        
        // 1 - Short Corner (tribord, proche)
        .init(id: "1", position: .shortCorner, center: CGPoint(x: 892, y: 492), diameter: 168,
              imageName: "lure_1", title: "1 — Short Corner", subtitle: "Sortie courte",
              notes: "Agressif ou grande taille."),
        
        // 2 - Long Corner (bâbord, loin)
        .init(id: "2", position: .longCorner, center: CGPoint(x: 627, y: 824), diameter: 156,
              imageName: "lure_2", title: "2 — Long Corner", subtitle: "Sortie longue",
              notes: "Discret ou naturel."),
        
        // 3 - Short Rigger (tribord, tangon)
        .init(id: "3", position: .shortRigger, center: CGPoint(x: 991, y: 953), diameter: 164,
              imageName: "lure_3", title: "3 — Short Rigger", subtitle: "Rigger court",
              notes: "Flashy."),
        
        // 4 - Long Rigger (bâbord, tangon)
        .init(id: "4", position: .longRigger, center: CGPoint(x: 256, y: 955), diameter: 165,
              imageName: "lure_4", title: "4 — Long Rigger", subtitle: "Rigger long",
              notes: "Flashy."),
        
        // 5 - Shotgun (centre, très loin)
        .init(id: "5", position: .shotgun, center: CGPoint(x: 770, y: 1200), diameter: 164,
              imageName: "lure_5", title: "5 — Shotgun", subtitle: "Très arrière",
              notes: "Discret, contrasté, teaser éventuel, etc.")
    ]
    
    @State private var selectedSuggestion: SuggestionEngine.SuggestionResult? = nil
    @State private var animationProgress: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / designSize.width,
                            geo.size.height / designSize.height)
            
            let renderedSize = CGSize(width: designSize.width * scale,
                                      height: designSize.height * scale)
            
            ZStack {
                // Fond (le schéma)
                Group {
                    if let uiImage = UIImage(named: "spread_template_ok") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(designSize, contentMode: .fit)
                            .frame(width: renderedSize.width, height: renderedSize.height)
                            .opacity(animationProgress)
                    } else {
                        // Fallback : vue générée si l'image n'existe pas
                        VStack(spacing: 0) {
                            SpreadTemplateFallback(size: renderedSize)
                                .opacity(animationProgress)
                            
                            // Message informatif plus visible
                            Text("⚠️ Image 'spread_template_ok' non trouvée dans Assets")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(8)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(8)
                                .padding(.top, -80)
                        }
                    }
                }
                
                // Bulles tappables
                ForEach(bubbles) { bubble in
                    if let suggestion = suggestionPourPosition(bubble.position) {
                        BubbleSlot(
                            spec: bubble,
                            suggestion: suggestion,
                            scale: scale,
                            animationProgress: animationProgress
                        ) {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.95)) {
                                selectedSuggestion = suggestion
                            }
                        }
                    }
                }
                
                // ⚡ INDICATEUR DE VITESSE (coin supérieur gauche)
                VitesseIndicatorView(
                    vitesseRecommandee: configuration.vitesseRecommandee,
                    plageMin: configuration.vitessePlageMin,
                    plageMax: configuration.vitessePlageMax,
                    justification: configuration.justificationVitesse,
                    ajustements: configuration.ajustementsVitesse
                )
                .position(x: 70, y: 30)  // Coin supérieur gauche
                .scaleEffect(animationProgress)
                .opacity(animationProgress)
                
                // Surimpression fiche
                if let suggestion = selectedSuggestion {
                    ZStack {
                        Color.black.opacity(0.35)
                            .ignoresSafeArea()
                            .onTapGesture { dismiss() }
                        
                        LeurreDetailSheet(suggestion: suggestion)
                            .padding(20)
                            .onTapGesture { dismiss() }
                    }
                    .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                animationProgress = 1.0
            }
        }
    }
    
    private func suggestionPourPosition(_ position: PositionSpread) -> SuggestionEngine.SuggestionResult? {
        return configuration.suggestions.first { $0.positionSpread == position }
    }
    
    private func dismiss() {
        withAnimation(.spring(response: 0.20, dampingFraction: 0.98)) {
            selectedSuggestion = nil
        }
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
            .buttonStyle(ScaleButtonStyle())
            
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
                            
                            Text("VITESSE TRAÎNE")
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
                        VStack(spacing: 6) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", vitesseRecommandee))
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: "0277BD"))
                                Text("kts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Plage: \(String(format: "%.1f", plageMin)) - \(String(format: "%.1f", plageMax)) kts")
                                .font(.caption)
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
                                    .cornerRadius(3)
                                
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
                                    .cornerRadius(3)
                                
                                // Indicateur vitesse optimale
                                Circle()
                                    .fill(Color(hex: "0277BD"))
                                    .frame(width: 12, height: 12)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                                    .shadow(color: Color(hex: "0277BD").opacity(0.4), radius: 3)
                                    .offset(x: recommandeePosition - 6)
                            }
                        }
                        .frame(height: 6)
                        
                        // Labels
                        HStack {
                            Text("0")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("15")
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

// MARK: - Models

private struct BubbleSpec: Identifiable {
    let id: String
    let position: PositionSpread
    let center: CGPoint      // pixels dans le design 1024×1536
    let diameter: CGFloat    // pixels dans le design 1024×1536
    let imageName: String?   // Nom de l'image du leurre (optionnel)
    let title: String?       // Titre personnalisé (optionnel)
    let subtitle: String?    // Sous-titre (optionnel)
    let notes: String?       // Notes additionnelles (optionnel)
    
    // Initializer avec valeurs par défaut pour rétrocompatibilité
    init(id: String, position: PositionSpread, center: CGPoint, diameter: CGFloat,
         imageName: String? = nil, title: String? = nil, subtitle: String? = nil, notes: String? = nil) {
        self.id = id
        self.position = position
        self.center = center
        self.diameter = diameter
        self.imageName = imageName
        self.title = title
        self.subtitle = subtitle
        self.notes = notes
    }
}

// MARK: - Bubble view

private struct BubbleSlot: View {
    let spec: BubbleSpec
    let suggestion: SuggestionEngine.SuggestionResult
    let scale: CGFloat
    let animationProgress: CGFloat
    let onTap: () -> Void
    
    var body: some View {
        let x = spec.center.x * scale
        let y = spec.center.y * scale
        let d = spec.diameter * scale
        
        Button(action: onTap) {
            ZStack {
                // Cercle de fond
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                couleurPosition.opacity(0.8),
                                couleurPosition
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: d / 2
                        )
                    )
                    .frame(width: d, height: d)
                    .shadow(color: couleurPosition.opacity(0.5), radius: 8, x: 0, y: 4)
                
                // Contenu
                VStack(spacing: 4) {
                    Text(spec.position.emoji)
                        .font(.system(size: d * 0.25))
                    
                    Text(spec.position.displayName)
                        .font(.system(size: d * 0.08, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    
                    Text("\(suggestion.distanceSpread ?? 0)m")
                        .font(.system(size: d * 0.10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(d * 0.1)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(width: d, height: d)
        .position(x: x, y: y)
        .scaleEffect(animationProgress)
        .opacity(animationProgress)
    }
    
    private var couleurPosition: Color {
        switch spec.position {
        case .libre: return .gray
        case .shortCorner: return .green
        case .longCorner: return .blue
        case .shortRigger: return .orange
        case .longRigger: return Color(red: 1.0, green: 0.6, blue: 0.0)  // Orange foncé
        case .shotgun: return .red
        }
    }
}

// MARK: - Fiche détaillée du leurre

private struct LeurreDetailSheet: View {
    let suggestion: SuggestionEngine.SuggestionResult
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // En-tête
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if let position = suggestion.positionSpread {
                            HStack(spacing: 8) {
                                Text(position.emoji)
                                    .font(.title)
                                Text(position.displayName)
                                    .font(.title3)
                                    .fontWeight(.bold)
                            }
                        }
                        
                        Text(suggestion.leurre.nom)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(suggestion.leurre.marque)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Score
                    VStack(spacing: 4) {
                        Text("\(Int(suggestion.scoreTotal))")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                        Text("/100")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 80, height: 80)
                    .background(couleurScore(suggestion.scoreTotal))
                    .cornerRadius(16)
                }
                
                Divider()
                
                // Couleur
                HStack(spacing: 12) {
                    Text("Couleur")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(couleurPourAffichage(suggestion.leurre.couleurPrincipale))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        Text(suggestion.leurre.couleurPrincipale.displayName)
                            .font(.subheadline)
                    }
                }
                
                // Caractéristiques
                VStack(alignment: .leading, spacing: 12) {
                    Text("Caractéristiques")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        SpreadCaracBadge(label: "Longueur", valeur: "\(Int(suggestion.leurre.longueur))cm")
                        
                        if let profMin = suggestion.leurre.profondeurNageMin,
                           let profMax = suggestion.leurre.profondeurNageMax {
                            SpreadCaracBadge(label: "Profondeur", valeur: "\(Int(profMin))-\(Int(profMax))m")
                        }
                        
                        if let vitMin = suggestion.leurre.vitesseTraineMin,
                           let vitMax = suggestion.leurre.vitesseTraineMax {
                            SpreadCaracBadge(label: "Vitesse", valeur: "\(Int(vitMin))-\(Int(vitMax))kts")
                        }
                    }
                }
                
                Divider()
                
                // Scores détaillés
                VStack(alignment: .leading, spacing: 16) {
                    Text("Évaluation")
                        .font(.headline)
                    
                    ScoreBar(
                        titre: "TECHNIQUE",
                        score: Int(suggestion.scoreTechnique),
                        max: 40,
                        couleur: Color(hex: "0277BD")
                    )
                    
                    ScoreBar(
                        titre: "COULEUR",
                        score: Int(suggestion.scoreCouleur),
                        max: 30,
                        couleur: Color(hex: "FFBC42")
                    )
                    
                    ScoreBar(
                        titre: "CONDITIONS",
                        score: Int(suggestion.scoreConditions),
                        max: 30,
                        couleur: .green
                    )
                }
                
                Divider()
                
                // Justifications
                VStack(alignment: .leading, spacing: 12) {
                    Text("Justifications")
                        .font(.headline)
                    
                    JustificationBox(
                        titre: "Technique",
                        texte: suggestion.justificationTechnique,
                        couleur: Color(hex: "0277BD")
                    )
                    
                    JustificationBox(
                        titre: "Couleur",
                        texte: suggestion.justificationCouleur,
                        couleur: Color(hex: "FFBC42")
                    )
                    
                    JustificationBox(
                        titre: "Conditions",
                        texte: suggestion.justificationConditions,
                        couleur: .green
                    )
                }
                
                Divider()
                
                // Astuce pro
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ASTUCE PRO")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                        
                        Text(suggestion.astucePro)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                // Distance
                if let distance = suggestion.distanceSpread {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Distance recommandée : \(distance)m")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding()
                    .background(Color(hex: "0277BD").opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: 600)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
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

// MARK: - Composants UI

private struct SpreadCaracBadge: View {
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

private struct ScoreBar: View {
    let titre: String
    let score: Int
    let max: Int
    let couleur: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(titre)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(couleur)
                
                Spacer()
                
                Text("\(score)/\(max)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(couleur)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(couleur.opacity(0.2))
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(couleur)
                        .frame(width: geometry.size.width * CGFloat(score) / CGFloat(max), height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

private struct JustificationBox: View {
    let titre: String
    let texte: String
    let couleur: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(titre.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(couleur)
            
            Text(texte)
                .font(.caption)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(couleur.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Style de bouton avec animation de pression

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Fonction couleur (réutilisée)

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

// MARK: - Template Fallback (si l'image n'existe pas)
private struct SpreadTemplateFallback: View {
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Fond eau
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.3),
                    Color.blue.opacity(0.1)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Vagues décoratives
            ForEach(0..<8) { i in
                SpreadWave(offset: CGFloat(i) * 40)
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .offset(y: CGFloat(i) * size.height / 8 - size.height / 4)
            }
            
            // Bateau
            BateauView()
                .frame(width: size.width * 0.08, height: size.width * 0.1)
                .position(x: size.width * 0.5, y: size.height * 0.15)
            
            // Lignes guides
            VStack(spacing: 0) {
                ForEach(1..<6) { i in
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 1)
                    Spacer()
                }
            }
            
            // Texte d'information
            VStack {
                Spacer()
                Text("⚠️ Template d'image non trouvé")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(8)
                    .padding()
            }
        }
        .frame(width: size.width, height: size.height)
        .cornerRadius(20)
    }
}

private struct SpreadWave: Shape {
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


