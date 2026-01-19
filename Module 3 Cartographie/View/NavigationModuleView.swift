//
//  NavigationModuleView.swift
//  Go Les Picots V.4
//
//  Module Navigation - Vue principale avec TabView 4 rubriques
//

import SwiftUI

struct NavigationModuleView: View {
    // MARK: - Properties
    @State private var selectedTab: Int = 0
    
    // MARK: - Body
    var body: some View {
        TabView(selection: $selectedTab) {
            // RUBRIQUE 1 : Météo & Solunaire
            MeteoSolunaireView()
                .tabItem {
                    Label("Météo", image: "Meteo-icon") // Remplacez "icone_meteo" par le nom de votre asset
                }
                .tag(0)
            
            // RUBRIQUE 2 : Carte & Spots
            CarteSpotsView()
                .tabItem {
                    Label("Carte", image: "Carte-icon") // Remplacez "icone_carte" par le nom de votre asset
                }
                .tag(1)
            
            // RUBRIQUE 3 : Mes Sorties
            MesSortiesView()
                .tabItem {
                    Label("Sorties", image: "Journal-icon") // Remplacez "icone_sorties" par le nom de votre asset
                }
                .tag(2)
            
            // RUBRIQUE 4 : Statistiques
            StatistiquesView()
                .tabItem {
                    Label("Stats", image: "Stats_icon") // Remplacez "icone_stats" par le nom de votre asset
                }
                .tag(3)
        }
        .accentColor(Color(red: 1.0, green: 0.49, blue: 0.31)) // Orange corail pour onglet actif
    }
}

// MARK: - Preview
#Preview {
    NavigationModuleView()
}
