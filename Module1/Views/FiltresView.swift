//
//  FiltresView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue des filtres avancés
//
//  Created: 2024-12-04
//  Updated: 2024-12-11 - Alignement avec LeureViewModel
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
                    Picker("Type", selection: $viewModel.filtreTypeLeurre) {
                        Text("Tous").tag(nil as TypeLeurre?)
                        ForEach(TypeLeurre.allCases, id: \.self) { type in
                            Text("\(type.icon) \(type.displayName)").tag(type as TypeLeurre?)
                        }
                    }
                }
                
                // Type de pêche
                Section("Type de pêche") {
                    Picker("Pêche", selection: $viewModel.filtreTypePeche) {
                        Text("Tous").tag(nil as TypePeche?)
                        ForEach(TypePeche.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as TypePeche?)
                        }
                    }
                }
                
                // Zone de pêche
                Section("Zone de pêche") {
                    Picker("Zone", selection: $viewModel.filtreZone) {
                        Text("Toutes").tag(nil as Zone?)
                        ForEach(Zone.allCases, id: \.self) { zone in
                            Text("\(zone.icon) \(zone.displayName)").tag(zone as Zone?)
                        }
                    }
                }
                
                // Contraste
                Section("Contraste") {
                    Picker("Contraste", selection: $viewModel.filtreContraste) {
                        Text("Tous").tag(nil as Contraste?)
                        ForEach(Contraste.allCases, id: \.self) { contraste in
                            Text(contraste.displayName).tag(contraste as Contraste?)
                        }
                    }
                }
                
                // Statistiques
                Section("Statistiques") {
                    HStack {
                        Text("Total leurres")
                        Spacer()
                        Text("\(viewModel.leurres.count)")
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    
                    HStack {
                        Text("Résultats filtrés")
                        Spacer()
                        Text("\(viewModel.leurresFiltres.count)")
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
