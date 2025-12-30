//
//  Jiggingchoicesheet.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 30/12/2025.
//

import SwiftUI

// MARK: - Sheet de Choix Jigging Fast vs Slow

struct JiggingChoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedType: TypeDeNage?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header avec principes clés
                headerSection
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Carte Fast Jigging
                        fastJiggingCard
                        
                        // Carte Slow Jigging
                        slowJiggingCard
                    }
                    .padding()
                }
            }
            .navigationTitle("Quel type de jigging ?")
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
    
    // MARK: - Header avec principes
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "FFBC42"))
                    .font(.title2)
                
                Text("Principe clé")
                    .font(.headline)
                    .foregroundColor(Color(hex: "FFBC42"))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Le moment de l'attaque détermine le choix :")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 16) {
                    // Fast Jigging
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Fast Jigging")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("↑")
                            .font(.caption)
                        Text("Attaque en montée")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "0277BD"))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Slow Jigging
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.title)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Slow Jigging")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("↓")
                            .font(.caption)
                        Text("Attaque en descente")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "FFBC42"))
                            .multilineTextAlignment(.center)
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
    
    // MARK: - Carte Fast Jigging
    
    private var fastJiggingCard: some View {
        Button(action: {
            selectedType = .fastJigging
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Titre
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(Color(hex: "0277BD"))
                        .font(.title2)
                    
                    Text("Fast Jigging")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                // Caractéristiques techniques
                VStack(alignment: .leading, spacing: 6) {
                    CharacteristicRow(icon: "bolt.fill", text: "Tirées 1-2m explosives et rythmées")
                    CharacteristicRow(icon: "speedometer", text: "6-12 tours moulinet rapide constant")
                    CharacteristicRow(icon: "waveform.path", text: "Jig compact dense, signal intense")
                    CharacteristicRow(icon: "figure.run", text: "Physique, engageant, sélectif")
                }
                .padding(.leading, 4)
                
                Divider()
                
                // Principe hydrodynamique
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Principe hydrodynamique")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                    }
                    
                    Text("Le jig vibre fortement, file droit ou en léger S. Signal hydrodynamique intense imitant une proie paniquée fuyant vers la surface. L'attaque se déclenche pendant la remontée par réflexe de poursuite, non par opportunisme.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 4)
                }
                
                Divider()
                
                // Animation par profondeur
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.caption)
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Animation par profondeur")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 30-100m : Tirée 80-120cm + 6-8 tours, jigs 80-200g")
                            .font(.caption)
                        Text("• 100-250m : Tirée 120-180cm + 8-10 tours, jigs 200-400g")
                            .font(.caption)
                        Text("• >250m : Tirée 180-250cm + 10-12 tours, jigs 400-800g")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                }
                
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
                        
                        Text("Poissons actifs, chasses visibles, courant établi, oxygénation forte. Carangues GT, wahoo, thons, bonites, barracudas, sérioles. Passes lagune 30-100m, DCP offshore 100-400m. Sessions courtes 15-20min (fatigant).")
                            .font(.caption)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                }
                
                // Matériel recommandé
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Matériel : PE 3-6, ratio 5.5:1+, jigs stick compacts, câble acier")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                // Règle d'or
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "FFBC42"))
                    Text("Le fast jigging ne convainc pas : il provoque. Pas de réaction rapide = mauvais moment.")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color(hex: "FFBC42"))
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
    
    // MARK: - Carte Slow Jigging
    
    private var slowJiggingCard: some View {
        Button(action: {
            selectedType = .slowJigging
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Titre
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(Color(hex: "FFBC42"))
                        .font(.title2)
                    
                    Text("Slow Jigging")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                
                // Caractéristiques techniques
                VStack(alignment: .leading, spacing: 6) {
                    CharacteristicRow(icon: "leaf.fill", text: "Levée lente 30-60cm, descente accompagnée")
                    CharacteristicRow(icon: "tortoise.fill", text: "1/8 à 1/2 tour lent avec relâchement")
                    CharacteristicRow(icon: "sparkles", text: "Jig plat/asymétrique papillonnant")
                    CharacteristicRow(icon: "figure.walk", text: "Finesse, précision, confiance dans le leurre")
                }
                .padding(.leading, 4)
                
                Divider()
                
                // Principe hydrodynamique
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Principe hydrodynamique")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                    }
                    
                    Text("Le jig (centre de gravité décentré) papillonne, décroche latéralement, change d'axe et expose alternativement ses flancs. Animation fondée sur la chute contrôlée : le désordre vient du jig, pas du pêcheur. 70% des touches pendant la descente.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 4)
                }
                
                Divider()
                
                // Animation par profondeur
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Animation par profondeur")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .textCase(.uppercase)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• 20-50m : Pitch 1/8 tour, jigs 40-80g planants, rythme rapide")
                            .font(.caption)
                        Text("• 50-150m : Pitch 1/4 tour, jigs 100-250g hybrides, long fall 3-4s")
                            .font(.caption)
                        Text("• >150m : Pitch 1/2 tour, jigs 250-400g+ longs/plats, pauses longues")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    .padding(.leading, 4)
                }
                
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
                        
                        Text("Poissons calés, peu actifs, méfiants ou éduqués. Courant modéré, dérive lente, verticalité cruciale. Vivaneaux, pagres, denti, mérous, loches. Lagune sud 20-100m, DCP 50-150m, offshore 150-300m+.")
                            .font(.caption)
                            .foregroundColor(Color(hex: "FFBC42"))
                    }
                }
                
                // Matériel recommandé
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text("Matériel : PE 1-3 slow action, tresse PE 1-2.5, ratio 5:1 lent, jigs plats glow")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                
                // Règle d'or
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "FFBC42"))
                    Text("Si vous sentez trop votre jig, vous pêchez trop vite. Le contrôle excessif tue l'efficacité.")
                        .font(.caption2)
                        .italic()
                        .foregroundColor(Color(hex: "FFBC42"))
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

// MARK: - Preview

struct JiggingChoiceSheet_Previews: PreviewProvider {
    static var previews: some View {
        JiggingChoiceSheet(selectedType: .constant(nil))
    }
}
