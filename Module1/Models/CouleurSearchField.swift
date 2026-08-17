//
//  CouleurSearchField.swift
//  Go les Picots - Module 1 Phase 2
//
//  Champ de recherche avec autocomplétion pour les couleurs
//  V2 : Support des couleurs prédéfinies ET personnalisées
//
//  Created: 2024-12-22
//

import SwiftUI

// MARK: - Type unifié pour représenter une couleur (prédéfinie ou custom)

enum AnyCouleur: Identifiable, Hashable {
    case predefinie(Couleur)
    case custom(CouleurCustom)
    
    var id: String {
        switch self {
        case .predefinie(let c): return "pred_\(c.rawValue)"
        case .custom(let c): return "custom_\(c.id.uuidString)"
        }
    }
    
    var nom: String {
        switch self {
        case .predefinie(let c): return c.displayName
        case .custom(let c): return c.nom
        }
    }
    
    var swiftUIColor: Color {
        switch self {
        case .predefinie(let c): return c.swiftUIColor
        case .custom(let c): return c.swiftUIColor
        }
    }
    
    var contraste: Contraste {
        switch self {
        case .predefinie(let c): return c.contrasteNaturel
        case .custom(let c): return c.contraste
        }
    }
    
    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
    
    // 🌈 NOUVEAU : Vérifie si c'est une couleur arc-en-ciel
    var isRainbow: Bool {
        if case .custom(let c) = self {
            return c.isRainbow
        }
        return false
    }
}

/// Vue de champ de recherche avec autocomplétion pour sélectionner une couleur
struct CouleurSearchField: View {
    
    @Binding var couleurSelectionnee: Couleur
    @Binding var couleurCustomSelectionnee: CouleurCustom?  // 🆕 Pour stocker la couleur custom
    let titre: String
    
    @State private var searchText: String = ""
    @State private var showSuggestions: Bool = false
    @State private var showCreateSheet: Bool = false
    
    @ObservedObject private var customManager = CouleurCustomManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Label
            Text(titre)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Champ de recherche
            HStack(spacing: 12) {
                // Aperçu couleur actuelle (ou arc-en-ciel si custom rainbow)
                Group {
                    // ✅ CORRECTION : Utiliser couleurCustomSelectionnee au lieu de chercher par nom
                    if let customCouleur = couleurCustomSelectionnee, customCouleur.isRainbow {
                        RainbowCircle(size: 30)
                    } else if let customCouleur = couleurCustomSelectionnee {
                        Circle()
                            .fill(customCouleur.swiftUIColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Circle()
                            .fill(couleurSelectionnee.swiftUIColor)
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                // TextField
                TextField("Rechercher...", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()
                    .onChange(of: searchText) { newValue in
                        showSuggestions = !newValue.isEmpty
                    }
                
                // Bouton effacer
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        showSuggestions = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // Nom de la couleur actuelle
            HStack {
                Text(couleurCustomSelectionnee?.nom ?? couleurSelectionnee.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if couleurCustomSelectionnee != nil {
                    Text("(Perso)")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(3)
                }
            }
            
            // Liste de suggestions
            if showSuggestions && !allSuggestions.isEmpty {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(allSuggestions) { suggestion in
                            Button {
                                selectionnerCouleur(suggestion)
                            } label: {
                                HStack {
                                    // 🌈 Afficher arc-en-ciel ou couleur normale
                                    if suggestion.isRainbow {
                                        RainbowCircle(size: 24)
                                    } else {
                                        Circle()
                                            .fill(suggestion.swiftUIColor)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                    
                                    Text(suggestion.nom)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Badge pour couleurs custom
                                    if suggestion.isCustom {
                                        Text("Perso")
                                            .font(.caption2)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.blue.opacity(0.2))
                                            .foregroundColor(.blue)
                                            .cornerRadius(4)
                                    }
                                    
                                    if estSelectionnee(suggestion) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            
                            if suggestion.id != allSuggestions.last?.id {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            
            // Bouton "Créer nouvelle couleur"
            if !searchText.isEmpty && !nomExisteDeja {
                Button {
                    showCreateSheet = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Créer la couleur \"\(searchText)\"")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateCouleurView(nomSuggere: searchText) { nouvelleCouleur in
                customManager.ajouter(nouvelleCouleur)
                searchText = nouvelleCouleur.nom
                showSuggestions = false
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// Toutes les couleurs disponibles (prédéfinies + custom)
    private var allCouleurs: [AnyCouleur] {
        var couleurs: [AnyCouleur] = Couleur.allCases.map { .predefinie($0) }
        couleurs.append(contentsOf: customManager.couleursCustom.map { .custom($0) })
        return couleurs
    }
    
    /// Suggestions filtrées
    private var allSuggestions: [AnyCouleur] {
        guard !searchText.isEmpty else { return [] }
        
        let recherche = searchText.lowercased()
        return allCouleurs.filter { couleur in
            couleur.nom.lowercased().contains(recherche)
        }
    }
    
    /// Vérifie si le nom existe déjà
    private var nomExisteDeja: Bool {
        let recherche = searchText.lowercased()
        return allCouleurs.contains { $0.nom.lowercased() == recherche }
    }
    
    // MARK: - Actions
    
    private func selectionnerCouleur(_ couleur: AnyCouleur) {
        switch couleur {
        case .predefinie(let c):
            couleurSelectionnee = c
            couleurCustomSelectionnee = nil  // Réinitialiser la couleur custom
            searchText = c.displayName
        case .custom(let c):
            // Stocker la couleur custom ET mapper vers une couleur prédéfinie de fallback
            couleurCustomSelectionnee = c
            let couleurFallback = trouverCouleurProcheDepuisCustom(c)
            couleurSelectionnee = couleurFallback
            searchText = c.nom
            print("✅ Couleur custom '\(c.nom)' sélectionnée (fallback: '\(couleurFallback.displayName)')")
        }
        
        showSuggestions = false
    }
    
    /// Trouve la couleur prédéfinie la plus proche d'une couleur custom
    private func trouverCouleurProcheDepuisCustom(_ custom: CouleurCustom) -> Couleur {
        // Si arc-en-ciel, retourner une couleur flashy par défaut
        if custom.isRainbow {
            return .chartreuse
        }
        
        // Chercher par contraste similaire
        let couleursAvecContraste = Couleur.allCases.filter { 
            $0.contrasteNaturel == custom.contraste 
        }
        
        if !couleursAvecContraste.isEmpty {
            // Trouver la couleur avec les valeurs RGB les plus proches
            let couleurProche = couleursAvecContraste.min(by: { c1, c2 in
                distanceRGB(entre: custom, et: c1) < distanceRGB(entre: custom, et: c2)
            })
            return couleurProche ?? couleursAvecContraste.first!
        }
        
        // Fallback : chercher la couleur la plus proche par distance RGB
        return Couleur.allCases.min(by: { c1, c2 in
            distanceRGB(entre: custom, et: c1) < distanceRGB(entre: custom, et: c2)
        }) ?? .blanc
    }
    
    /// Calcule la distance RGB entre une couleur custom et une couleur prédéfinie
    private func distanceRGB(entre custom: CouleurCustom, et predefined: Couleur) -> Double {
        let uiColor = UIColor(predefined.swiftUIColor)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let dr = custom.red - Double(r)
        let dg = custom.green - Double(g)
        let db = custom.blue - Double(b)
        
        return sqrt(dr*dr + dg*dg + db*db)
    }
    
    private func estSelectionnee(_ couleur: AnyCouleur) -> Bool {
        switch couleur {
        case .predefinie(let c):
            return c == couleurSelectionnee
        case .custom(let custom):
            // Une couleur custom est "sélectionnée" si son nom correspond au texte de recherche
            // et si elle mappe vers la couleur actuellement sélectionnée
            let couleurMappee = trouverCouleurProcheDepuisCustom(custom)
            return searchText.lowercased() == custom.nom.lowercased() && 
                   couleurMappee == couleurSelectionnee
        }
    }
}

// MARK: - Vue de Création de Couleur

struct CreateCouleurView: View {
    
    let nomSuggere: String
    let onCreation: (CouleurCustom) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var nom: String
    @State private var couleur: Color = .blue
    @State private var contraste: Contraste = .naturel
    @State private var useRainbow: Bool = false  // 🌈 NOUVEAU
    
    init(nomSuggere: String = "", onCreation: @escaping (CouleurCustom) -> Void) {
        self.nomSuggere = nomSuggere
        self.onCreation = onCreation
        self._nom = State(initialValue: nomSuggere)
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
                        // ColorPicker classique
                        ColorPicker("Couleur", selection: $couleur, supportsOpacity: false)
                    } else {
                        // Info arc-en-ciel
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("La pastille affichera un dégradé arc-en-ciel multicolore")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
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
                } footer: {
                    if useRainbow {
                        Text("💡 Parfait pour les leurres holographiques ou multicolores")
                    }
                }
                
                Section {
                    Picker("Type de contraste", selection: $contraste) {
                        ForEach(Contraste.allCases, id: \.self) { c in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(c.displayName)
                                    .font(.body)
                                Text(c.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(c)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Caractéristiques")
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
        
        if useRainbow {
            // 🌈 Créer une couleur arc-en-ciel
            if let nouvelleCouleur = CouleurCustom(nom: nomFinal, from: .white, contraste: contraste, isRainbow: true) {
                onCreation(nouvelleCouleur)
                dismiss()
            }
        } else {
            // Créer une couleur normale
            if let nouvelleCouleur = CouleurCustom(nom: nomFinal, from: couleur, contraste: contraste, isRainbow: false) {
                onCreation(nouvelleCouleur)
                dismiss()
            }
        }
    }
}

// MARK: - Preview

#Preview("Search Field") {
    @Previewable @State var couleur: Couleur = .bleuArgente
    @Previewable @State var couleurCustom: CouleurCustom? = nil  // 🆕
    
    Form {
        CouleurSearchField(
            couleurSelectionnee: $couleur,
            couleurCustomSelectionnee: $couleurCustom,  // 🆕
            titre: "Couleur principale"
        )
    }
}

#Preview("Create View") {
    CreateCouleurView(nomSuggere: "Vert pomme") { couleur in
        print("Créée: \(couleur.nom)")
    }
}
