//
//  CreerCouleurView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Interface pour créer une nouvelle couleur personnalisée
//  Modal avec ColorPicker et choix du contraste
//
//  Created: 2024-12-22
//

import SwiftUI

struct CreerCouleurView: View {
    
    let nomSuggere: String
    let onCreation: (CouleurCustom) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var nom: String
    @State private var couleur: Color = .blue
    @State private var contraste: Contraste = .naturel
    
    init(nomSuggere: String = "", onCreation: @escaping (CouleurCustom) -> Void) {
        self.nomSuggere = nomSuggere
        self.onCreation = onCreation
        self._nom = State(initialValue: nomSuggere)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section Nom
                Section {
                    TextField("Nom de la couleur", text: $nom)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Nom")
                } footer: {
                    Text("Donnez un nom descriptif (ex: Vert pomme, Bleu océan)")
                }
                
                // Section Couleur
                Section {
                    ColorPicker("Choisir la couleur", selection: $couleur, supportsOpacity: false)
                    
                    // Aperçu
                    HStack {
                        Text("Aperçu")
                        Spacer()
                        RoundedRectangle(cornerRadius: 12)
                            .fill(couleur)
                            .frame(width: 120, height: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                } header: {
                    Text("Couleur")
                }
                
                // Section Contraste
                Section {
                    Picker("Type de contraste", selection: $contraste) {
                        ForEach(Contraste.allCases, id: \.self) { c in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(c.displayName)
                                    .font(.body)
                                Text(c.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(c)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Contraste")
                } footer: {
                    Text("Le contraste détermine dans quelles conditions cette couleur est efficace")
                }
            }
            .navigationTitle("Nouvelle couleur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer") {
                        creer()
                    }
                    .disabled(nom.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func creer() {
        let nomFinal = nom.trimmingCharacters(in: .whitespaces)
        guard !nomFinal.isEmpty else { return }
        
        if let nouvelleCouleur = CouleurCustom(nom: nomFinal, from: couleur, contraste: contraste) {
            onCreation(nouvelleCouleur)
            dismiss()
        }
    }
}

#Preview {
    CreerCouleurView(nomSuggere: "Vert pomme") { couleur in
        print("Couleur créée: \(couleur.nom)")
    }
}
