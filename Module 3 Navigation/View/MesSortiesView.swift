//
//  MesSortiesView.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 18/01/2026.
//
//  RUBRIQUE 3 : Mes Sorties - VERSION MINIMALISTE
//  Liste sorties, création, détail sortie, export GPX
//

import SwiftUI

struct MesSortiesView: View {
    // MARK: - Properties
    @State private var showingNewSortie = false
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Placeholder en attendant intégration
                    placeholderContent
                }
                .padding()
            }
            .navigationTitle("Mes Sorties")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingNewSortie = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingNewSortie) {
                // TODO: Vue création nouvelle sortie
                Text("Formulaire nouvelle sortie")
            }
        }
    }
    
    // MARK: - Placeholder Content
    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.fishing")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("Mes Sorties")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Contenu à venir")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRowSorties(icon: "list.bullet", text: "Liste des sorties de pêche")
                FeatureRowSorties(icon: "plus.circle", text: "Création nouvelle sortie")
                FeatureRowSorties(icon: "info.circle", text: "Détail sortie : spots, prises, durée")
                FeatureRowSorties(icon: "square.and.arrow.up", text: "Export GPX vers Navionics")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 40)
    }
}

// MARK: - Feature Row Component
struct FeatureRowSorties: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview {
    MesSortiesView()
}
