//
//  RainbowCircle.swift
//  Go les Picots - Module 1 Phase 2
//
//  Pastille arc-en-ciel pour le sélecteur de couleurs personnalisées
//
//  Created: 2024-12-26
//

import SwiftUI

/// Pastille circulaire avec un dégradé arc-en-ciel
struct RainbowCircle: View {
    
    var size: CGFloat = 30
    var showBorder: Bool = true
    
    var body: some View {
        Circle()
            .fill(
                AngularGradient(
                    gradient: Gradient(colors: [
                        .red,
                        .orange,
                        .yellow,
                        .green,
                        .blue,
                        .indigo,
                        .purple,
                        .red  // Boucle pour continuité
                    ]),
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(
                        showBorder ? Color.gray.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

/// Pastille arc-en-ciel alternative avec dégradé radial (effet métallique)
struct RainbowCircleRadial: View {
    
    var size: CGFloat = 30
    var showBorder: Bool = true
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        .white,
                        .yellow,
                        .orange,
                        .red,
                        .purple,
                        .blue
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: size / 2
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .stroke(
                        showBorder ? Color.gray.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
            )
    }
}

/// Pastille arc-en-ciel holographique (avec effet de lumière)
struct RainbowCircleHolographic: View {
    
    var size: CGFloat = 30
    var showBorder: Bool = true
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Base arc-en-ciel
            Circle()
                .fill(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .red,
                            .orange,
                            .yellow,
                            .green,
                            .cyan,
                            .blue,
                            .purple,
                            .pink,
                            .red
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    )
                )
            
            // Surbrillance pour effet holographique
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            .white.opacity(0.6),
                            .clear
                        ]),
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: size * 0.6
                    )
                )
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(rotation))
        .overlay(
            Circle()
                .stroke(
                    showBorder ? Color.gray.opacity(0.3) : Color.clear,
                    lineWidth: 1
                )
        )
        .onAppear {
            withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

// MARK: - Preview

#Preview("Pastilles Arc-en-ciel") {
    VStack(spacing: 30) {
        Text("Styles de pastilles arc-en-ciel")
            .font(.headline)
        
        HStack(spacing: 30) {
            VStack {
                RainbowCircle(size: 50)
                Text("Angulaire")
                    .font(.caption)
            }
            
            VStack {
                RainbowCircleRadial(size: 50)
                Text("Radial")
                    .font(.caption)
            }
            
            VStack {
                RainbowCircleHolographic(size: 50)
                Text("Holographique")
                    .font(.caption)
            }
        }
        
        Divider()
        
        Text("Tailles variées")
            .font(.headline)
        
        HStack(spacing: 20) {
            RainbowCircle(size: 20)
            RainbowCircle(size: 30)
            RainbowCircle(size: 40)
            RainbowCircle(size: 50)
        }
        
        Divider()
        
        Text("Dans une liste")
            .font(.headline)
        
        List {
            ForEach(1...5, id: \.self) { index in
                HStack {
                    if index % 2 == 0 {
                        RainbowCircle(size: 24)
                    } else {
                        RainbowCircleHolographic(size: 24)
                    }
                    Text("Couleur personnalisée \(index)")
                    Spacer()
                    Text("Perso")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
        .frame(height: 250)
    }
    .padding()
}
#Preview("Comparaison avec couleurs normales") {
    List {
        Section("Couleurs prédéfinies") {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 30, height: 30)
                Text("Rouge")
            }
            
            HStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                Text("Bleu")
            }
            
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 30, height: 30)
                Text("Vert")
            }
        }
        
        Section("Couleurs personnalisées arc-en-ciel") {
            HStack {
                RainbowCircle(size: 30)
                Text("Holographique")
                Spacer()
                Text("Perso")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            HStack {
                RainbowCircleHolographic(size: 30)
                Text("Iridescent")
                Spacer()
                Text("Perso")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            HStack {
                RainbowCircleRadial(size: 30)
                Text("Multicolore")
                Spacer()
                Text("Perso")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
        }
    }
}

