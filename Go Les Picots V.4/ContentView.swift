//
//  ContentView.swift
//  Go Les Picots V.4
//
//  MODULE 0 - Écran d'accueil
//  VERSION CORRIGÉE avec NavigationCoordinator
//
//  Created by LANES Sebastien on 04/12/2025.
//  Updated: 2024-12-05 (correction navigation Module 2)
//

import SwiftUI

struct ContentView: View {
    // ViewModels partagés pour l'app
    
    @StateObject private var leureViewModel = LeureViewModel()
    @StateObject private var suggestionEngine: SuggestionEngine
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    // État pour le diagnostic
    @State private var showingDiagnostic = false
    
    init() {
        let lvm = LeureViewModel()
        _leureViewModel = StateObject(wrappedValue: lvm)
        _suggestionEngine = StateObject(wrappedValue: SuggestionEngine(leureViewModel: lvm))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // BANDEAU EN HAUT
                BannerView()
                
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
                    Button(action: { showingDiagnostic = true }) {
                        Image(systemName: "wrench.and.screwdriver")
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
        .onChange(of: navigationCoordinator.showResults) { oldValue, newValue in
            print("🔄 ContentView - showResults changed: \(oldValue) → \(newValue)")
            print("📊 ContentView - Nombre de suggestions: \(navigationCoordinator.suggestions.count)")
        }
    }
}

// MARK: - Bandeau
struct BannerView: View {
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
        ModuleItem(
            title: "Cartographie",
            iconName: "Navigation",
            color: Color(hex: "0277BD")
        ),
        ModuleItem(
            title: "Bibliothèque",
            iconName: "Bibliotheque",
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
            if module.title == "Ma Boîte" || module.title == "Suggestion IA" {
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
                
                // Badge "Nouveau" pour Module 2
                if module.title == "Suggestion IA" {
                    Text("NOUVEAU")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "FFBC42"))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
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
