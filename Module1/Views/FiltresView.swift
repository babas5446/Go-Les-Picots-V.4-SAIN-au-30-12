//
//  FiltresView.swift
//  Go les Picots V.4 — Module 1
//
//  Vue des filtres avancés.
//
//  V4 — Adaptation SwiftData :
//  - viewModel.leurres supprimé — totalLeurres passé en paramètre depuis BoiteView
//

import SwiftUI

struct FiltresView: View {
    @ObservedObject var viewModel: BoiteLeurresViewModel
    @Environment(\.dismiss) var dismiss

    /// Total des leurres non filtrés — fourni par @Query dans BoiteView.
    var totalLeurres: Int

    var body: some View {
        NavigationView {
            Form {
                Section("Type de leurre") {
                    Picker("Type", selection: $viewModel.filtreTypeLeurre) {
                        Text("Tous").tag(nil as TypeLeurre?)
                        ForEach(TypeLeurre.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon).tag(type as TypeLeurre?)
                        }
                    }
                }

                Section("Type de pêche") {
                    Picker("Pêche", selection: $viewModel.filtreTypePeche) {
                        Text("Tous").tag(nil as TypePeche?)
                        ForEach(TypePeche.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type as TypePeche?)
                        }
                    }
                }

                Section("Zone de pêche") {
                    Picker("Zone", selection: $viewModel.filtreZone) {
                        Text("Toutes").tag(nil as Zone?)
                        ForEach(Zone.allCases, id: \.self) { zone in
                            Label(zone.displayName, systemImage: zone.icon).tag(zone as Zone?)
                        }
                    }
                }

                Section("Contraste") {
                    Picker("Contraste", selection: $viewModel.filtreContraste) {
                        Text("Tous").tag(nil as Contraste?)
                        ForEach(Contraste.allCases, id: \.self) { contraste in
                            Text(contraste.displayName).tag(contraste as Contraste?)
                        }
                    }
                }

                Section("Statistiques") {
                    HStack {
                        Text("Total leurres")
                        Spacer()
                        // ✅ V4 : totalLeurres reçu en paramètre depuis BoiteView (@Query)
                        Text("\(totalLeurres)")
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
