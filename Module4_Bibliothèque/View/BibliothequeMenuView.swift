//
//  BibliothequeMenuView.swift
//  Go Les Picots V.4
//
//  Module 4 : Menu principal Bibliothèque
//  Point d'entrée avec 3 sections : Espèces / Techniques / Tuto de Pro
//
//  Created by LANES Sebastien on 02/01/2026.
//

import SwiftUI

struct BibliothequeMenuView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // En-tête
                    VStack(spacing: 8) {
                        Image("Bibliotheque")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                        
                        Text("Bibliothèque")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Votre bibliothèque de pêche")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.horizontal)
                    
                    // MARK: - Les 3 cartes principales
                    
                    VStack(spacing: 16) {
                        // Carte 1 : Espèces
                        NavigationLink(destination: EspecesListView()) {
                            MenuCard(
                                iconName: "Bibliotheque2_icon",
                                title: "Bibliothèque d'espèces",
                                description: "Identification, habitat et techniques de pêche",
                                accentColor: Color.blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Carte 2 : Techniques de pêche
                        NavigationLink(destination: TechniquesListView()) {
                            MenuCard(
                                iconName: "Techniques_icon",
                                title: "Techniques de pêche",
                                description: "Traîne, jigging, montages et stratégies",
                                accentColor: Color.orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Carte 3 : Tuto de Pro
                        NavigationLink(destination: TutoProListView()) {
                            MenuCard(
                                iconName: "TutoDePro_icon",
                                title: "Tuto de Pro",
                                description: "Vidéos CPS et conseils d'experts",
                                accentColor: Color.green
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 40)
                }
            }
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Composant MenuCard

struct MenuCard: View {
    let iconName: String
    let title: String
    let description: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône personnalisée
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
                .padding(12)
                .background(accentColor.opacity(0.15))
                .cornerRadius(12)
            
            // Contenu texte
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Chevron de navigation
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
    BibliothequeMenuView()
}
