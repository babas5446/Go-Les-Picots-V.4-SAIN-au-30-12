//
//  NavigationCoordinator.swift
//  Go Les Picots V.4
//
//  Coordinateur pour gérer la navigation entre les vues
//  et le passage des résultats de suggestions
//
//  Created: 2024-12-16
//
//  Session 8 — sortie du module en une frappe :
//  - fermerModule est un drapeau momentané, levé par fermerModuleComplet() et
//    abaissé par SuggestionInputView dès qu'elle l'a consommé. La feuille du
//    module est pilotée par un @State privé à ModuleButton, hors de portée de
//    ContentView : ce drapeau est le seul chemin disponible pour l'atteindre.
//  - Les deux présentations ne sont pas refermées ensemble. Le fullScreenCover
//    des résultats retombe d'abord, la feuille du module ensuite. Refermer deux
//    présentations empilées dans le même cycle est exactement ce qui avait
//    produit les instabilités de showResults relevées en session 4.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NavigationCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var showResults: Bool = false
    @Published var suggestions: [SuggestionEngine.SuggestionResult] = []
    @Published var configuration: SuggestionEngine.ConfigurationSpread?

    /// Demande de fermeture de la feuille du module Suggestion IA.
    ///
    /// Consommé par SuggestionInputView, qui le remet à false avant d'appeler
    /// son propre dismiss(). Un drapeau resté levé refermerait le module dès sa
    /// réouverture suivante.
    @Published var fermerModule: Bool = false
    
    // MARK: - Methods
    
    /// Présente les résultats de suggestions
    func presentResults(suggestions: [SuggestionEngine.SuggestionResult], configuration: SuggestionEngine.ConfigurationSpread?) {
        print("📱 NavigationCoordinator.presentResults() appelé")
        print("   - \(suggestions.count) suggestions")
        print("   - Configuration: \(configuration != nil ? "présente" : "absente")")
        
        self.suggestions = suggestions
        self.configuration = configuration
        self.showResults = true
        
        print("✅ NavigationCoordinator - showResults défini à: \(self.showResults)")
    }
    
    /// Ferme la vue des résultats et revient au formulaire de saisie.
    ///
    /// C'est le chemin du bouton « Modifier » : les conditions restent saisies,
    /// une relance ne demande que les ajustements souhaités.
    func dismissResults() {
        print("🔚 NavigationCoordinator.dismissResults() appelé")
        
        withAnimation {
            self.showResults = false
        }
        
        // Nettoyer après un délai pour éviter les problèmes d'animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.suggestions = []
            self.configuration = nil
        }
    }

    /// Ferme les résultats puis le module entier.
    ///
    /// C'est le chemin du bouton « Fermer ». Le délai n'est pas un confort
    /// d'animation : il laisse le fullScreenCover se retirer avant que la
    /// feuille sous-jacente ne reçoive à son tour l'ordre de disparaître.
    /// Le formulaire de saisie réapparaît brièvement, comportement admis.
    func fermerModuleComplet() {
        print("🔚 NavigationCoordinator.fermerModuleComplet() appelé")

        dismissResults()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.fermerModule = true
        }
    }
}

// MARK: - Note on Type Definitions
// SuggestionResult, ConfigurationSpread, and ScoringDetails are defined as nested types
// inside the SuggestionEngine class. They are accessed as:
// - SuggestionEngine.SuggestionResult
// - SuggestionEngine.ConfigurationSpread
// - SuggestionEngine.ScoringDetails
