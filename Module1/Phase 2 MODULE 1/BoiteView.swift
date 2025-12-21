//
//  BoiteView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue principale de la boîte à leurres
//  Affichage en liste ou grille des 63 leurres
//
//  MODIFIÉ: 2024-12-10 - Intégration LeurreFormView (Phase 2)
//

import SwiftUI

struct BoiteView: View {
    
    @StateObject private var viewModel = LeureViewModel()
    @State private var modeAffichage: ModeAffichage = .liste
    @State private var showingFiltres = false
    @State private var showingAjouterLeurre = false
    
    enum ModeAffichage {
        case liste
        case grille
    }
    
    var body: some View {
        ZStack {
            // Fond
            Color(hex: "F5F5F5")
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Chargement...")
                    .scaleEffect(1.5)
            } else if let error = viewModel.errorMessage {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                    Button("Réessayer") {
                        viewModel.chargerLeurres()  // ← Nom de méthode mis à jour
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                VStack(spacing: 0) {
                    // Barre de recherche et filtres
                    barreRecherche
                    
                    // En-tête avec statistiques
                    enTeteStatistiques
                    
                    // Contenu principal
                    if viewModel.leurresFiltres.isEmpty {
                        vuVide
                    } else {
                        contenuPrincipal
                    }
                }
            }
        }
        .navigationTitle("Ma Boîte à Leurres")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            // Bouton + pour ajouter rapidement
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAjouterLeurre = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            
            // Menu options
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { modeAffichage = .liste }) {
                        Label("Liste", systemImage: modeAffichage == .liste ? "checkmark" : "")
                    }
                    Button(action: { modeAffichage = .grille }) {
                        Label("Grille", systemImage: modeAffichage == .grille ? "checkmark" : "")
                    }
                    Divider()
                    Button(action: { showingFiltres = true }) {
                        Label("Filtres", systemImage: "line.3.horizontal.decrease.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingFiltres) {
            FiltresView(viewModel: viewModel)
        }
        // ═══════════════════════════════════════════════════════════
        // MODIFICATION PHASE 2 : Utiliser LeurreFormView au lieu de AjouterLeurreView
        // ═══════════════════════════════════════════════════════════
        .sheet(isPresented: $showingAjouterLeurre) {
            LeurreFormView(viewModel: viewModel, mode: .creation)
        }
    }
    
    // MARK: - Barre de recherche
    
    private var barreRecherche: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Rechercher un leurre...", text: $viewModel.filtreRecherche)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !viewModel.filtreRecherche.isEmpty {
                    Button(action: { viewModel.filtreRecherche = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color.white)
            .cornerRadius(10)
            
            Button(action: { showingFiltres = true }) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.title2)
                    .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - En-tête statistiques
    
    private var enTeteStatistiques: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.leurresFiltres.count)")  // ← Utiliser .count directement
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color(hex: "0277BD"))
                Text("leurres")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Tri
            Menu {
                ForEach(LeureViewModel.TriOption.allCases, id: \.self) { option in
                    Button(action: {
                        if viewModel.triActuel == option {
                            viewModel.triCroissant.toggle()
                        } else {
                            viewModel.triActuel = option
                            viewModel.triCroissant = true
                        }
                    }) {
                        HStack {
                            Text(option.displayName)
                            if viewModel.triActuel == option {
                                Image(systemName: viewModel.triCroissant ? "arrow.up" : "arrow.down")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text("Tri : \(viewModel.triActuel.displayName)")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(Color.white)
    }
    
    // MARK: - Contenu principal
    
    @ViewBuilder
    private var contenuPrincipal: some View {
        switch modeAffichage {
        case .liste:
            listeView
        case .grille:
            grilleView
        }
    }
    
    // MARK: - Vue Liste
    
    private var listeView: some View {
        List {
            ForEach(viewModel.leurresFiltres) { leurre in
                NavigationLink(destination: LeurreDetailView(leurre: leurre, viewModel: viewModel)) {
                    LeurreCellule(leurre: leurre, viewModel: viewModel)
                }
                .listRowBackground(Color.white)
            }
            .onDelete(perform: viewModel.supprimerLeurres)
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - Vue Grille
    
    private var grilleView: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(viewModel.leurresFiltres) { leurre in
                    NavigationLink(destination: LeurreDetailView(leurre: leurre, viewModel: viewModel)) {
                        LeurreCarteGrille(leurre: leurre, viewModel: viewModel)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding()
        }
    }
    
    // MARK: - Vue vide
    
    private var vuVide: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(viewModel.filtreRecherche.isEmpty && viewModel.filtreTypeLeurre == nil && viewModel.filtreTypePeche == nil
                 ? "Aucun leurre dans votre boîte"
                 : "Aucun résultat")
                .font(.headline)
                .foregroundColor(.gray)
            
            if !viewModel.filtreRecherche.isEmpty || viewModel.filtreTypeLeurre != nil || viewModel.filtreTypePeche != nil {
                Button("Réinitialiser les filtres") {
                    viewModel.reinitialiserFiltres()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Ajouter un leurre") {
                    showingAjouterLeurre = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Cellule Liste

struct LeurreCellule: View {
    let leurre: Leurre
    let viewModel: LeureViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo ou placeholder
            photoOuPlaceholder
            
            VStack(alignment: .leading, spacing: 6) {
                Text(leurre.nom)
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
                    .lineLimit(1)
                
                Text(leurre.marque)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                HStack(spacing: 12) {
                    Label("\(Int(leurre.longueur))cm", systemImage: "ruler")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let profondeur = leurre.profondeurFormatee {
                        Label(profondeur, systemImage: "arrow.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Badge type de pêche
                HStack(spacing: 6) {
                    Text(leurre.typePeche.displayName)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0277BD").opacity(0.15))
                        .foregroundColor(Color(hex: "0277BD"))
                        .cornerRadius(8)
                    
                    if let contraste = leurre.contraste {
                        Text(contraste.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: "FFBC42").opacity(0.2))
                            .foregroundColor(Color(hex: "FFBC42"))
                            .cornerRadius(8)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    @ViewBuilder
    private var photoOuPlaceholder: some View {
        if let photoPath = leurre.photoPath,
           let image = viewModel.chargerPhoto(pourLeurre: leurre) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "E0E0E0"))
                    .frame(width: 70, height: 70)
                Text(leurre.typeLeurre.icon)
                    .font(.system(size: 32))
            }
        }
    }
}

// MARK: - Carte Grille

struct LeurreCarteGrille: View {
    let leurre: Leurre
    let viewModel: LeureViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo ou placeholder
            ZStack(alignment: .topTrailing) {
                photoOuPlaceholder
                
                // Badge contraste
                if let contraste = leurre.contraste {
                    Text(contraste.displayName)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0277BD").opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(8)
                }
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(leurre.nom)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "0277BD"))
                    .lineLimit(2)
                    .frame(height: 36)
                
                Text(leurre.marque)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(Int(leurre.longueur))cm", systemImage: "ruler")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if let profondeur = leurre.profondeurFormatee {
                        Label(profondeur, systemImage: "arrow.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var photoOuPlaceholder: some View {
        if let photoPath = leurre.photoPath,
           let image = viewModel.chargerPhoto(pourLeurre: leurre) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 140)
                .clipped()
        } else {
            ZStack {
                Rectangle()
                    .fill(Color(hex: "E0E0E0"))
                    .frame(height: 140)
                Text(leurre.typeLeurre.icon)
                    .font(.system(size: 50))
            }
        }
    }
}

// MARK: - Preview

struct BoiteView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            BoiteView()
        }
    }
}
