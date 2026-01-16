//
//  InfographieCardView.swift
//  Go les Picots - Module 4
//
//  Carte spéciale pour l'infographie dans TechniquesListView
//  Design différent des cartes de fiches techniques standard
//
//  Created: 2026-01-15
//

import SwiftUI

struct InfographieCardView: View {
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Aperçu miniature infographie
            ZStack {
                // Image miniature (si disponible)
                Image("infographie_choix_leurre")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Badge "Infographie" en overlay
                VStack {
                    HStack {
                        Spacer()
                        
                        Text("Infographie Interactive")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FFBC42"), Color(hex: "FF6F00")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)
                            .padding(12)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            // Titre et description
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.title2)
                        .foregroundColor(Color(hex: "FFBC42"))
                    
                    Text("Guide Visuel Choix Leurre")
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                Text("Infographie interactive pour choisir le leurre optimal selon les conditions de pêche")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                HStack {
                    Label("Zoomable", systemImage: "magnifyingglass")
                        .font(.caption)
                        .foregroundColor(Color(hex: "0277BD"))
                    
                    Spacer()
                    
                    Label("Légende détaillée", systemImage: "book.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "FFBC42"))
                }
                .padding(.top, 4)
            }
            .padding()
            
            // Séparateur avec chevron
            HStack {
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "FFBC42"))
                    .padding(.trailing, 20)
            }
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [Color(hex: "FFBC42"), Color(hex: "FF9800")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: Color(hex: "FFBC42").opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            InfographieCardView()
                .padding()
            
            // Pour comparaison avec carte standard
            Text("Carte standard ↓")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Exemple carte standard (placeholder)
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .overlay(
                    Text("Carte technique standard")
                        .foregroundColor(.secondary)
                )
                .padding()
        }
    }
    .background(Color(UIColor.systemGroupedBackground))
}
