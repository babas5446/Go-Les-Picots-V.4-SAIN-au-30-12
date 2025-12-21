//
//  AjouterLeurreView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Formulaire simple pour ajouter un leurre
//
//  Created: 2024-12-04
//

import SwiftUI

struct AjouterLeurreView: View {
    @ObservedObject var viewModel: LeureViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Formulaire d'ajout de leurre")
                .font(.headline)
                .navigationTitle("Ajouter un leurre")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Ajouter") {
                            // TODO: Implémenter l'ajout
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}

struct EditerLeurreView: View {
    let leurre: Leurre
    @ObservedObject var viewModel: LeureViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Text("Formulaire d'édition de leurre")
                .font(.headline)
                .navigationTitle("Modifier")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Enregistrer") {
                            // TODO: Implémenter la modification
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
        }
    }
}
