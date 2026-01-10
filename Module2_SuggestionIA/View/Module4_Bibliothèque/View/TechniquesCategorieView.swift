//
//  TechniquesCategorieView.swift
//  Go Les Picots V.4
//
//  Module 4 - Sprint 3 : Vue catégorie de techniques
//  Affiche les fiches d'une catégorie groupées par niveau
//
//  Created by LANES Sebastien on 05/01/2026.
//

import SwiftUI

struct TechniquesCategorieView: View {
    
    let categorie: CategorieTechnique
    
    private let database = TechniqueDatabase.shared
    
    private var fiches: [FicheTechnique] {
        database.obtenirFichesParCategorie(categorie)
    }
    
    private var accentColor: Color {
        switch categorie {
        case .montage: return .blue
        case .animation: return .orange
        case .strategie: return .green
        case .equipement: return .purple
        }
    }
    
    // Grouper les fiches par niveau
    private var fichesParNiveau: [(NiveauDifficulte, [FicheTechnique])] {
        let niveaux: [NiveauDifficulte] = [.debutant, .intermediaire, .avance]
        return niveaux.compactMap { niveau in
            let fichesDuNiveau = fiches.filter { $0.niveauDifficulte == niveau }
            return fichesDuNiveau.isEmpty ? nil : (niveau, fichesDuNiveau)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // Banner
                BannerView(
                    iconName: iconNameForCategorie(),
                    title: categorie.rawValue,
                    subtitle: descriptionForCategorie(),
                    accentColor: accentColor
                )
                .padding(.horizontal)
                
                // MARK: - Fiches groupées par niveau
                
                VStack(spacing: 24) {
                    ForEach(fichesParNiveau, id: \.0) { niveau, fichesNiveau in
                        VStack(alignment: .leading, spacing: 12) {
                            // En-tête niveau
                            HStack {
                                Image(systemName: iconForNiveau(niveau))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(colorForNiveau(niveau))
                                
                                Text(niveau.rawValue)
                                    .font(.headline)
                                    .foregroundColor(colorForNiveau(niveau))
                                
                                Spacer()
                                
                                Text("\(fichesNiveau.count)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(colorForNiveau(niveau))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            
                            // Cartes des fiches
                            VStack(spacing: 12) {
                                ForEach(fichesNiveau) { fiche in
                                    NavigationLink(destination: TechniqueDetailView(fiche: fiche)) {
                                        TechniqueCard(fiche: fiche, accentColor: accentColor)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
        .navigationTitle(categorie.rawValue)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Helpers
    
    private func iconNameForCategorie() -> String {
        switch categorie {
        case .montage: return "link.circle.fill"
        case .animation: return "waveform.path"
        case .strategie: return "map.fill"
        case .equipement: return "wrench.and.screwdriver.fill"
        }
    }
    
    private func descriptionForCategorie() -> String {
        switch categorie {
        case .montage: return "Bas de ligne, palangre, spread et montages"
        case .animation: return "Techniques d'animation des leurres"
        case .strategie: return "Stratégies et lecture des conditions"
        case .equipement: return "Choix et entretien du matériel"
        }
    }
    
    private func iconForNiveau(_ niveau: NiveauDifficulte) -> String {
        switch niveau {
        case .debutant: return "star.fill"
        case .intermediaire: return "star.leadinghalf.filled"
        case .avance: return "star.circle.fill"
        }
    }
    
    private func colorForNiveau(_ niveau: NiveauDifficulte) -> Color {
        switch niveau {
        case .debutant: return .green
        case .intermediaire: return .orange
        case .avance: return .red
        }
    }
}

// MARK: - Composant TechniqueCard

struct TechniqueCard: View {
    let fiche: FicheTechnique
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(fiche.titre)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 12) {
                        // Badge niveau
                        HStack(spacing: 4) {
                            Image(systemName: iconForNiveau(fiche.niveauDifficulte))
                                .font(.system(size: 10))
                            Text(fiche.niveauDifficulte.rawValue)
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(colorForNiveau(fiche.niveauDifficulte))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(colorForNiveau(fiche.niveauDifficulte).opacity(0.15))
                        .cornerRadius(6)
                        
                        // Durée
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 10))
                            Text(fiche.dureeApprentissage)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            // Description courte
            Text(fiche.description.components(separatedBy: ".").first ?? fiche.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Nombre d'étapes
            HStack(spacing: 4) {
                Image(systemName: "list.number")
                    .font(.system(size: 12))
                Text("\(fiche.etapesDetaillees.count) étapes")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(accentColor)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(accentColor.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func iconForNiveau(_ niveau: NiveauDifficulte) -> String {
        switch niveau {
        case .debutant: return "star.fill"
        case .intermediaire: return "star.leadinghalf.filled"
        case .avance: return "star.circle.fill"
        }
    }
    
    private func colorForNiveau(_ niveau: NiveauDifficulte) -> Color {
        switch niveau {
        case .debutant: return .green
        case .intermediaire: return .orange
        case .avance: return .red
        }
    }
}

#Preview {
    NavigationView {
        TechniquesCategorieView(categorie: .montage)
    }
}
