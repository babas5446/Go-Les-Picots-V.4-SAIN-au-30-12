//
//  Wobblingchoicesheet.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 29/12/2025.
//

import SwiftUI

// MARK: - Sheet de Choix Wobbling Large vs Serré

struct WobblingChoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: TypeDeNage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header avec astuce
                headerSection
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Carte Wobbling Large
                        wobblingLargeCard
                        
                        // Carte Wobbling Serré
                        wobblingSerréCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Quel type de wobbling ?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header avec astuce
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "FFBC42"))
                    .font(.title2)
                
                Text("Astuce")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FFBC42"))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("La largeur de la bavette influence l'amplitude du wobbling et la résistance.")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    // Bavette large
                    VStack(spacing: 4) {
                        Image(systemName: "rectangle.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Bavette large")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("↓")
                            .font(.caption)
                        Text("Wobbling large")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Bavette étroite
                    VStack(spacing: 4) {
                        Image(systemName: "rectangle.portrait.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Bavette étroite")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("↓")
                            .font(.caption)
                        Text("Wobbling serré")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "FFBC42"))
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(hex: "FFF9E6"))
        .cornerRadius(12)
        .padding()
    }
    
    // MARK: - Carte Wobbling Large
    
    private var wobblingLargeCard: some View {
        Button(action: {
            selectedType = .wobblingLarge
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Titre
                HStack {
                    Image(systemName: "water.waves")
                        .foregroundColor(Color(hex: "0277BD"))
                        .font(.title2)
                    
                    Text("Wobbling Large")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                // Caractéristiques techniques
                VStack(alignment: .leading, spacing: 6) {
                    CharacteristicRow(icon: "waveform", text: "Amplitude élevée, fréquence basse")
                    CharacteristicRow(icon: "arrow.left.and.right", text: "Balayage large gauche-droite")
                    CharacteristicRow(icon: "speaker.wave.3.fill", text: "Déplace beaucoup d'eau")
                }
                .padding(.leading, 4)
                
                Divider()
                
                // Description
                Text(TypeDeNage.wobblingLarge.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                
                // Conditions idéales
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Conditions idéales")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(TypeDeNage.wobblingLarge.conditionsIdeales)
                            .font(.caption)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "0277BD"), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Carte Wobbling Serré
    
    private var wobblingSerréCard: some View {
        Button(action: {
            selectedType = .wobblingSerré
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Titre
                HStack {
                    Image(systemName: "water.waves")
                        .foregroundColor(Color(hex: "FFBC42"))
                        .font(.title2)
                    
                    Text("Wobbling Serré")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                // Caractéristiques techniques
                VStack(alignment: .leading, spacing: 6) {
                    CharacteristicRow(icon: "waveform.path", text: "Amplitude faible, fréquence élevée")
                    CharacteristicRow(icon: "arrow.up.and.down", text: "Tremblement plutôt qu'ondulation")
                    CharacteristicRow(icon: "line.horizontal.3.decrease", text: "Signature discrète mais continue")
                }
                .padding(.leading, 4)
                
                Divider()
                
                // Description
                Text(TypeDeNage.wobblingSerré.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Divider()
                
                // Conditions idéales
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Conditions idéales")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                        
                        Text(TypeDeNage.wobblingSerré.conditionsIdeales)
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFBC42"))
                    }
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "FFBC42"), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Composant Ligne de Caractéristique

struct CharacteristicRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

struct WobblingChoiceSheet_Previews: PreviewProvider {
    static var previews: some View {
        WobblingChoiceSheet(selectedType: .constant(nil))
    }
}
