//
//  BoiteView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue principale de la boîte à leurres
//  Affichage en liste ou grille des 63 leurres
//
//  Created: 2024-12-04
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
                        viewModel.chargerLeuresDepuisJSON()
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
                    Button(action: { showingAjouterLeurre = true }) {
                        Label("Ajouter", systemImage: "plus.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingFiltres) {
            FiltresView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingAjouterLeurre) {
            AjouterLeurreView(viewModel: viewModel)
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
                Text("\(viewModel.nombreFiltres)")
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
                    LeurreCellule(leurre: leurre)
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
                        LeurreCarteGrille(leurre: leurre)
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
            
            Text(viewModel.filtreRecherche.isEmpty && viewModel.filtreType == nil && viewModel.filtreCategorie == nil
                 ? "Aucun leurre dans votre boîte"
                 : "Aucun résultat")
                .font(.headline)
                .foregroundColor(.gray)
            
            if !viewModel.filtreRecherche.isEmpty || viewModel.filtreType != nil || viewModel.filtreCategorie != nil {
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo ou placeholder
            if let photoData = leurre.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: "E0E0E0"))
                        .frame(width: 70, height: 70)
                    Text(leurre.type.icon)
                        .font(.system(size: 32))
                }
            }
            
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
                    
                    Label(leurre.profondeurFormatee, systemImage: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Badges espèces principales
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(leurre.especesCibles.prefix(3), id: \.self) { espece in
                            Text(espece.displayName)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(hex: "FFBC42").opacity(0.2))
                                .foregroundColor(Color(hex: "FFBC42"))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Carte Grille

struct LeurreCarteGrille: View {
    let leurre: Leurre
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo ou placeholder
            ZStack(alignment: .topTrailing) {
                if let photoData = leurre.photo, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .clipped()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "E0E0E0"))
                            .frame(height: 140)
                        Text(leurre.type.icon)
                            .font(.system(size: 50))
                    }
                }
                
                // Badge contraste
                Text(leurre.contraste.displayName)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(leurre.contraste.color.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
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
                    
                    Label(leurre.profondeurFormatee, systemImage: "arrow.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
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
