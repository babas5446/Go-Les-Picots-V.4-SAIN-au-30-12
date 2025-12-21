//
//  FiltresView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue des filtres avancés
//
//  Created: 2024-12-04
//

import SwiftUI

struct FiltresView: View {
    @ObservedObject var viewModel: LeureViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Type de leurre
                Section("Type de leurre") {
                    Picker("Type", selection: $viewModel.filtreType) {
                        Text("Tous").tag(nil as TypeLeurre?)
                        ForEach(TypeLeurre.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.displayName)").tag(type as TypeLeurre?)
                        }
                    }
                }
                
                // Catégorie de pêche
                Section("Zone de pêche") {
                    Picker("Zone", selection: $viewModel.filtreCategorie) {
                        Text("Toutes").tag(nil as CategoriePeche?)
                        ForEach(CategoriePeche.allCases, id: \.self) { categorie in
                            Text(categorie.displayName).tag(categorie as CategoriePeche?)
                        }
                    }
                }
                
                // Espèce cible
                Section("Espèce cible") {
                    Picker("Espèce", selection: $viewModel.filtreEspece) {
                        Text("Toutes").tag(nil as Espece?)
                        ForEach(Espece.allCases, id: \.self) { espece in
                            Text(espece.displayName).tag(espece as Espece?)
                        }
                    }
                }
                
                // Statistiques
                Section("Statistiques") {
                    HStack {
                        Text("Total leurres")
                        Spacer()
                        Text("\(viewModel.nombreTotal)")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    
                    HStack {
                        Text("Résultats filtrés")
                        Spacer()
                        Text("\(viewModel.nombreFiltres)")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "FFBC42"))
                    }
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Réinitialiser") {
                        viewModel.reinitialiserFiltres()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
