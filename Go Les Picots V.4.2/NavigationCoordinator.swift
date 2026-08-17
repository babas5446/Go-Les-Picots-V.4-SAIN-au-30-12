//
//  NavigationCoordinator.swift
//  Go Les Picots V.4
//
//  Coordinateur pour gérer la navigation entre les vues
//  et le passage des résultats de suggestions
//
//  Created: 2024-12-16
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
    
    /// Ferme la vue des résultats
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
}

// MARK: - Note on Type Definitions
// SuggestionResult, ConfigurationSpread, and ScoringDetails are defined as nested types
// inside the SuggestionEngine class. They are accessed as:
// - SuggestionEngine.SuggestionResult
// - SuggestionEngine.ConfigurationSpread  
// - SuggestionEngine.ScoringDetails

