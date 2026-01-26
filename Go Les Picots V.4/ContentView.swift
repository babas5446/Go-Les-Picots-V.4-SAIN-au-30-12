//
//  ContentView.swift
//  Go Les Picots V.4
//
//  MODULE 0 - Écran d'accueil
//  VERSION AVEC STORMGLASS
//

import SwiftUI

struct ContentView: View {
    // ViewModels partagés pour l'app
    
    @StateObject private var leureViewModel = LeureViewModel()
    @StateObject private var suggestionEngine: SuggestionEngine
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    // État pour le diagnostic
    @State private var showingDiagnostic = false
    @State private var showExportImport = false

    
    init() {
        let lvm = LeureViewModel()
        _leureViewModel = StateObject(wrappedValue: lvm)
        _suggestionEngine = StateObject(wrappedValue: SuggestionEngine(leureViewModel: lvm))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // BANDEAU EN HAUT
                HomeBannerView()
                
                // GRILLE 2x2 DES MODULES
                ModuleGridView(
                    leureViewModel: leureViewModel,
                    suggestionEngine: suggestionEngine,
                    navigationCoordinator: navigationCoordinator
                )
                .padding(.top, 30)
                
                Spacer()
            }
            .background(Color(hex: "F5F5F5"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showExportImport = true
                        } label: {
                            Label("Export/Import", systemImage: "arrow.up.arrow.down.circle")
                        }
                        
                        Divider()
                        
                        Button {
                            showingDiagnostic = true
                        } label: {
                            Label("Diagnostic", systemImage: "wrench.and.screwdriver")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                }
            }
        }
        // ✅ FULLSCREEN COVER AU NIVEAU RACINE
        .fullScreenCover(isPresented: $navigationCoordinator.showResults) {
            NavigationStack {
                if !navigationCoordinator.suggestions.isEmpty {
                    SuggestionResultView(
                        suggestions: navigationCoordinator.suggestions,
                        configuration: navigationCoordinator.configuration
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Fermer") {
                                navigationCoordinator.dismissResults()
                            }
                        }
                    }
                } else {
                    VStack {
                        ProgressView()
                        Text("Chargement des résultats...")
                            .padding()
                    }
                }
            }
        }
        .alert("Erreur de chargement", isPresented: $leureViewModel.showError) {
            Button("OK", role: .cancel) { }
            Button("Recharger") {
                leureViewModel.chargerLeurres()
            }
        } message: {
            if let errorMessage = leureViewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .sheet(isPresented: $showingDiagnostic) {
            DiagnosticView()
        }
        .sheet(isPresented: $showExportImport) {
            ExportImportView(viewModel: leureViewModel)
        }
        .onChange(of: navigationCoordinator.showResults) { oldValue, newValue in
            print("🔄 ContentView - showResults changed: \(oldValue) → \(newValue)")
            print("📊 ContentView - Nombre de suggestions: \(navigationCoordinator.suggestions.count)")
        }
    }
}

// MARK: - Bandeau
struct HomeBannerView: View {
    var body: some View {
        Image("Banner")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity)
            .frame(height: 200)
    }
}

// MARK: - Modèle de données
struct ModuleItem: Identifiable {
    let id = UUID()
    let title: String
    let iconName: String
    let color: Color
}

// MARK: - Grille des 4 modules
struct ModuleGridView: View {
    let leureViewModel: LeureViewModel
    let suggestionEngine: SuggestionEngine
    let navigationCoordinator: NavigationCoordinator
    
    let modules : [ModuleItem] = [
        // Ligne 1
        ModuleItem(
            title: "Ma Boîte",
            iconName: "BoitePhysique",
            color: Color(hex: "0277BD")
        ),
        ModuleItem(
            title: "Suggestion IA",
            iconName: "BoiteIA",
            color: Color(hex: "FFBC42")
        ),
        // Ligne 2
        ModuleItem(
            title: "Navigation",
            iconName: "Navigation",
            color: Color(hex: "0277BD")
        ),
        ModuleItem(
            title: "Météo",
            iconName: "Meteo",
            color: Color(hex: "FFBC42")
        ),
        // Ligne 3
        ModuleItem(
            title: "Bibliothèque",
            iconName: "Bibliotheque",
            color: Color(hex: "0277BD")
        ),
        ModuleItem(
            title: "Statistiques",
            iconName: "Statistiques",
            color: Color(hex: "FFBC42")
        )
    ]
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ], spacing: 20) {
            ForEach(modules) { module in
                ModuleButton(
                    module: module,
                    leureViewModel: leureViewModel,
                    suggestionEngine: suggestionEngine,
                    navigationCoordinator: navigationCoordinator
                )
            }
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Bouton de module
struct ModuleButton: View {
    let module: ModuleItem
    let leureViewModel: LeureViewModel
    let suggestionEngine: SuggestionEngine
    let navigationCoordinator: NavigationCoordinator
    
    @State private var showingModule = false
    
    var body: some View {
        Button(action: {
            // Tous les modules sont maintenant actifs
            if module.title == "Ma Boîte" ||
               module.title == "Suggestion IA" ||
               module.title == "Navigation" ||
               module.title == "Météo" ||
               module.title == "Bibliothèque" ||
               module.title == "Statistiques" {
                showingModule = true
            }
        }) {
            VStack(spacing: 12) {
                // Icône
                Image(module.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                // Label
                Text(module.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "0277BD"))
                    .multilineTextAlignment(.center)
                
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingModule) {
            if module.title == "Ma Boîte" {
                NavigationStack {
                    BoiteView()
                        .environmentObject(leureViewModel)
                }
            } else if module.title == "Suggestion IA" {
                NavigationStack {
                    SuggestionInputView(
                        suggestionEngine: suggestionEngine,
                        navigationCoordinator: navigationCoordinator
                    )
                }
            } else if module.title == "Navigation" {
                NavigationStack {
                    NavigationMapView()
                }
            } else if module.title == "Météo" {
                // 🆕 MODULE MÉTÉO AVEC STORMGLASS
                MeteoSolunaireView()
            } else if module.title == "Bibliothèque" {
                NavigationStack {
                    BibliothequeMenuView()
                }
            } else if module.title == "Statistiques" {
                NavigationStack {
                    StatistiquesView()
                }
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
