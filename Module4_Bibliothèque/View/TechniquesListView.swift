//
//  TechniquesListView.swift
//  Go Les Picots V.4
//
//  Module 4 - Sprint 3 : Vue principale techniques de pêche
//  Navigation par catégorie (Montages / Animations / Stratégies / Équipement)
//
//  Created by LANES Sebastien on 05/01/2026.
//

import SwiftUI

struct TechniquesListView: View {
    
    private let database = TechniqueDatabase.shared
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Banner avec icône
                BannerView(
                    iconName: "Techniques_icon",
                    title: "Techniques de pêche",
                    subtitle: "Montages, animations et stratégies",
                    accentColor: Color.orange
                )
                .padding(.horizontal)
             
                Section {
                    NavigationLink(destination: InfographieLeurreView()) {
                        InfographieCardView()
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                } header: {
                    HStack {
                        Image(systemName: "chart.bar.doc.horizontal")
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text("Guide Stratégique")
                    }
                }
                // MARK: - Les 4 catégories en cartes
                
                VStack(spacing: 16) {
                    ForEach(CategorieTechnique.allCases, id: \.self) { categorie in
                        NavigationLink(destination: TechniquesCategorieView(categorie: categorie)) {
                            CategorieCard(
                                categorie: categorie,
                                nombreFiches: database.obtenirFichesParCategorie(categorie).count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer(minLength: 40)
            }
        }
    }
}

// MARK: - Composant CategorieCard

struct CategorieCard: View {
    let categorie: CategorieTechnique
    let nombreFiches: Int
    
    var accentColor: Color {
        switch categorie {
        case .montage: return .blue
        case .animation: return .orange
        case .strategie: return .green
        case .equipement: return .purple
        }
    }
    
    var iconName: String {
        switch categorie {
        case .montage: return "link.circle.fill"
        case .animation: return "waveform.path"
        case .strategie: return "map.fill"
        case .equipement: return "wrench.and.screwdriver.fill"
        }
    }
    
    var description: String {
        switch categorie {
        case .montage: return "Bas de ligne, palangre, spread"
        case .animation: return "Traîne, jigging, popping"
        case .strategie: return "Lecture conditions, DCP, combat"
        case .equipement: return "Cannes, moulinets, entretien"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône
            Image(systemName: iconName)
                .font(.system(size: 32))
                .foregroundColor(accentColor)
                .frame(width: 60, height: 60)
                .background(accentColor.opacity(0.15))
                .cornerRadius(12)
            
            // Contenu
            VStack(alignment: .leading, spacing: 6) {
                Text(categorie.rawValue)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("\(nombreFiches) fiche\(nombreFiches > 1 ? "s" : "")")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationView {
        TechniquesListView()
    }
}
