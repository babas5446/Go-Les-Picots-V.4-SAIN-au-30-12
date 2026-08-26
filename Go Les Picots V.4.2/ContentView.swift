//
//  ContentView.swift
//  Go Les Picots V.4
//
//  MODULE 0 - Écran d'accueil
//
//  V4 — Adaptations SwiftData :
//  - BoiteLeurresViewModel renommé boiteVM (conflit nom variable/type → Circular reference)
//  - @Query var leurres pour passer la liste à ExportImportView
//  - chargerLeurres() supprimé → alert OK suffit
//
//  Session 8 — les résultats de suggestion ne sont plus présentés d'ici.
//
//  Le fullScreenCover posé sur ContentView présentait les résultats depuis une
//  branche plus haute que la feuille du module. Deux présentations ne peuvent
//  pas coexister sur cette branche : iOS retirait la feuille de saisie avant
//  d'afficher les résultats. Au moment où l'on appuyait sur « Modifier », le
//  formulaire n'existait plus — les deux boutons ramenaient donc à l'accueil,
//  non par erreur de câblage mais faute de destination.
//
//  La présentation migre dans SuggestionInputView. Les résultats s'empilent
//  alors sur le formulaire, qui survit, et la barre de navigation se rend
//  correctement puisqu'elle appartient au NavigationStack du module.
//
//  Le .onChange de débogage sur showResults part avec le cover : il n'a plus
//  d'objet ici.
//
//  Le NavigationView racine reste en place — son rendu en colonnes sur iPad
//  sera traité séparément, une fois ce correctif validé.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    // ✅ V4 : renommé boiteVM — évite le Circular reference (variable ≠ type)
    @StateObject private var boiteVM             = BoiteLeurresViewModel()
    @StateObject private var suggestionEngine:     SuggestionEngine
    @StateObject private var navigationCoordinator = NavigationCoordinator()

    @State private var showingDiagnostic = false
    @State private var showExportImport  = false

    // ✅ V4 : @Query pour passer la liste à ExportImportView
    @Query private var leurres: [Leurre]

    init() {
        let vm = BoiteLeurresViewModel()
        _boiteVM        = StateObject(wrappedValue: vm)
        _suggestionEngine = StateObject(wrappedValue: SuggestionEngine(BoiteLeurresViewModel: vm))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HomeBannerView()

                ModuleGridView(
                    boiteVM: boiteVM,
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
        // ✅ V4 : chargerLeurres() supprimé — bouton OK suffit
        .alert("Erreur", isPresented: $boiteVM.showError) {
            Button("OK", role: .cancel) {
                boiteVM.errorMessage = nil
            }
        } message: {
            if let msg = boiteVM.errorMessage { Text(msg) }
        }
        .sheet(isPresented: $showingDiagnostic) {
            DiagnosticView()
        }
        .sheet(isPresented: $showExportImport) {
            // ✅ V4 : leurres passé depuis @Query
            ExportImportView(viewModel: boiteVM, leurres: leurres)
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
    var id: String { title }
    let title:    String
    let iconName: String
    let color:    Color
}

// MARK: - Grille des modules

struct ModuleGridView: View {
    let boiteVM:              BoiteLeurresViewModel
    let suggestionEngine:     SuggestionEngine
    let navigationCoordinator: NavigationCoordinator

    let modules: [ModuleItem] = [
        ModuleItem(title: "Ma Boîte",         iconName: "BoitePhysique",  color: Color(hex: "0277BD")),
        ModuleItem(title: "Suggestion IA",    iconName: "BoiteIA",        color: Color(hex: "FFBC42")),
        ModuleItem(title: "Statistiques",       iconName: "Statistiques",     color: Color(hex: "0277BD")),
        ModuleItem(title: "Marée·Solunaire",  iconName: "Meteo",          color: Color(hex: "FFBC42")),
        ModuleItem(title: "Bibliothèque",     iconName: "Bibliotheque",   color: Color(hex: "0277BD")),
        ModuleItem(title: "Journal Sorties",     iconName: "Journal_icon",   color: Color(hex: "FFBC42"))
    ]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ], spacing: 20) {
            ForEach(modules) { module in
                ModuleButton(
                    module: module,
                    boiteVM: boiteVM,
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
    let module:               ModuleItem
    let boiteVM:              BoiteLeurresViewModel
    let suggestionEngine:     SuggestionEngine
    let navigationCoordinator: NavigationCoordinator

    @State private var showingModule = false

    var body: some View {
        Button(action: { showingModule = true }) {
            VStack(spacing: 12) {
                Image(module.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

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
        .fullScreenCover(isPresented: $showingModule) {
            if module.title == "Ma Boîte" {
                NavigationStack {
                    BoiteView()
                        .environmentObject(boiteVM)
                }
            } else if module.title == "Suggestion IA" {
                NavigationStack {
                    SuggestionInputView(
                        suggestionEngine: suggestionEngine,
                        navigationCoordinator: navigationCoordinator
                    )
                }
            } else if module.title == "Statistiques" {
                NavigationStack { StatistiquesView() }
            } else if module.title == "Marée·Solunaire" {
                NavigationStack { SolunarView() }
            } else if module.title == "Bibliothèque" {
                NavigationStack { BibliothequeMenuView() }
            } else if module.title == "Journal Sorties" {
                NavigationStack { JournalView() }
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
