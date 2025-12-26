//
//  GestionCouleursCustomView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Vue de gestion des couleurs personnalisées
//  - Liste, création, modification, suppression
//
//  Created: 2024-12-22
//

import SwiftUI

struct GestionCouleursCustomView: View {
    
    @ObservedObject private var manager = CouleurCustomManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var showCreateSheet = false
    @State private var couleurAModifier: CouleurCustom?
    
    var body: some View {
        NavigationStack {
            Group {
                if manager.couleursCustom.isEmpty {
                    vueVide
                } else {
                    listeCouleurs
                }
            }
            .navigationTitle("Couleurs personnalisées")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCouleurView { nouvelleCouleur in
                    manager.ajouter(nouvelleCouleur)
                }
            }
            .sheet(item: $couleurAModifier) { couleur in
                EditCouleurView(couleur: couleur) { couleurModifiee in
                    manager.modifier(couleurModifiee)
                }
            }
        }
    }
    
    // MARK: - Vue vide
    
    private var vueVide: some View {
        VStack(spacing: 20) {
            Image(systemName: "paintpalette")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucune couleur personnalisée")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Créez vos propres couleurs pour mieux décrire vos leurres")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showCreateSheet = true
            } label: {
                Label("Créer une couleur", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 20)
        }
        .padding()
    }
    
    // MARK: - Liste des couleurs
    
    private var listeCouleurs: some View {
        List {
            Section {
                ForEach(manager.couleursCustom) { couleur in
                    Button {
                        couleurAModifier = couleur
                    } label: {
                        HStack(spacing: 12) {
                            // 🌈 Aperçu couleur ou arc-en-ciel
                            if couleur.isRainbow {
                                RainbowCircle(size: 50, showBorder: true)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(couleur.swiftUIColor)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(couleur.nom)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Text(couleur.contraste.displayName)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(formatDate(couleur.dateCreation))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: supprimerCouleurs)
            } header: {
                Text("\(manager.couleursCustom.count) couleur(s)")
            } footer: {
                Text("Glissez vers la gauche pour supprimer une couleur")
            }
        }
    }
    
    // MARK: - Actions
    
    private func supprimerCouleurs(at offsets: IndexSet) {
        for index in offsets {
            let couleur = manager.couleursCustom[index]
            manager.supprimer(couleur)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Vue d'Édition

struct EditCouleurView: View {
    
    let couleurOriginale: CouleurCustom
    let onSave: (CouleurCustom) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var nom: String
    @State private var couleur: Color
    @State private var contraste: Contraste
    @State private var useRainbow: Bool  // 🌈 NOUVEAU
    
    init(couleur: CouleurCustom, onSave: @escaping (CouleurCustom) -> Void) {
        self.couleurOriginale = couleur
        self.onSave = onSave
        
        self._nom = State(initialValue: couleur.nom)
        self._couleur = State(initialValue: couleur.swiftUIColor)
        self._contraste = State(initialValue: couleur.contraste)
        self._useRainbow = State(initialValue: couleur.isRainbow)  // 🌈 Initialiser
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom de la couleur", text: $nom)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Identification")
                }
                
                Section {
                    // 🌈 Toggle pour activer l'arc-en-ciel
                    Toggle(isOn: $useRainbow) {
                        HStack(spacing: 8) {
                            RainbowCircle(size: 24)
                            Text("Pastille arc-en-ciel")
                                .fontWeight(.medium)
                        }
                    }
                    .tint(Color.purple)
                    
                    if !useRainbow {
                        ColorPicker("Couleur", selection: $couleur, supportsOpacity: false)
                    }
                    
                    // Aperçu
                    HStack {
                        Text("Aperçu")
                        Spacer()
                        
                        if useRainbow {
                            RainbowCircleHolographic(size: 50)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(couleur)
                                .frame(width: 100, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                } header: {
                    Text("Apparence")
                }
                
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
                    Text("Caractéristiques")
                }
                
                Section {
                    Button(role: .destructive) {
                        supprimer()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Supprimer la couleur", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Modifier la couleur")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        sauvegarder()
                    }
                    .disabled(nom.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func sauvegarder() {
        let nomFinal = nom.trimmingCharacters(in: .whitespaces)
        guard !nomFinal.isEmpty else { return }
        
        if useRainbow {
            // 🌈 Sauvegarder avec arc-en-ciel
            if let couleurModifiee = CouleurCustom(nom: nomFinal, from: .white, contraste: contraste, isRainbow: true) {
                var mutable = couleurOriginale
                mutable.nom = couleurModifiee.nom
                mutable.contraste = couleurModifiee.contraste
                mutable.isRainbow = true
                
                onSave(mutable)
                dismiss()
            }
        } else {
            // Sauvegarder couleur normale
            if let couleurModifiee = CouleurCustom(nom: nomFinal, from: couleur, contraste: contraste, isRainbow: false) {
                var mutable = couleurOriginale
                mutable.nom = couleurModifiee.nom
                mutable.red = couleurModifiee.red
                mutable.green = couleurModifiee.green
                mutable.blue = couleurModifiee.blue
                mutable.contraste = couleurModifiee.contraste
                mutable.isRainbow = false
                
                onSave(mutable)
                dismiss()
            }
        }
    }
    
    private func supprimer() {
        CouleurCustomManager.shared.supprimer(couleurOriginale)
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    GestionCouleursCustomView()
}
