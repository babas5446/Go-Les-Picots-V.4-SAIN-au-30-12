//
//  LeureViewModel.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  ViewModel principal pour la gestion des leurres
//  Charge les 63 leurres depuis le JSON
//
//  Created: 2024-12-04
//

import Foundation
import SwiftUI

class LeureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var leurres: [Leurre] = []
    @Published var leurresFiltres: [Leurre] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Filtres
    @Published var filtreRecherche: String = "" {
        didSet {
            appliquerFiltres()
        }
    }
    
    @Published var filtreType: TypeLeurre? {
        didSet {
            appliquerFiltres()
        }
    }
    
    @Published var filtreCategorie: CategoriePeche? {
        didSet {
            appliquerFiltres()
        }
    }
    
    @Published var filtreEspece: Espece? {
        didSet {
            appliquerFiltres()
        }
    }
    
    // MARK: - Tri
    enum TriOption: String, CaseIterable {
        case nom = "Nom"
        case taille = "Taille"
        case marque = "Marque"
        case dateAjout = "Date d'ajout"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    @Published var triActuel: TriOption = .nom {
        didSet {
            appliquerTri()
        }
    }
    
    @Published var triCroissant: Bool = true {
        didSet {
            appliquerTri()
        }
    }
    
    // MARK: - Initialisation
    init() {
        chargerLeuresDepuisJSON()
    }
    
    // MARK: - Chargement des données
    
    /// Charge les 63 leurres depuis le fichier JSON
    func chargerLeuresDepuisJSON() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "leurres_database_COMPLET", withExtension: "json") else {
            errorMessage = "Fichier JSON introuvable"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let database = try decoder.decode(LeureDatabase.self, from: data)
            
            DispatchQueue.main.async {
                self.leurres = database.leurres
                self.leurresFiltres = database.leurres
                self.appliquerTri()
                self.isLoading = false
                print("✅ \(database.leurres.count) leurres chargés avec succès")
            }
            
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Erreur de chargement: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Erreur: \(error)")
            }
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Ajoute un nouveau leurre
    func ajouterLeurre(_ leurre: Leurre) {
        leurres.append(leurre)
        appliquerFiltres()
        sauvegarderDonnees()
    }
    
    /// Met à jour un leurre existant
    func modifierLeurre(_ leurre: Leurre) {
        if let index = leurres.firstIndex(where: { $0.id == leurre.id }) {
            leurres[index] = leurre
            appliquerFiltres()
            sauvegarderDonnees()
        }
    }
    
    /// Supprime un leurre
    func supprimerLeurre(_ leurre: Leurre) {
        leurres.removeAll { $0.id == leurre.id }
        appliquerFiltres()
        sauvegarderDonnees()
    }
    
    /// Supprime plusieurs leurres
    func supprimerLeurres(at offsets: IndexSet) {
        let leurresToDelete = offsets.map { leurresFiltres[$0] }
        leurres.removeAll { leurre in
            leurresToDelete.contains { $0.id == leurre.id }
        }
        appliquerFiltres()
        sauvegarderDonnees()
    }
    
    // MARK: - Filtrage
    
    /// Applique tous les filtres actifs
    private func appliquerFiltres() {
        var resultats = leurres
        
        // Filtre par recherche texte
        if !filtreRecherche.isEmpty {
            resultats = resultats.filter { leurre in
                leurre.nom.localizedCaseInsensitiveContains(filtreRecherche) ||
                leurre.marque.localizedCaseInsensitiveContains(filtreRecherche) ||
                leurre.especesCibles.contains { espece in
                    espece.displayName.localizedCaseInsensitiveContains(filtreRecherche)
                }
            }
        }
        
        // Filtre par type
        if let type = filtreType {
            resultats = resultats.filter { $0.type == type }
        }
        
        // Filtre par catégorie
        if let categorie = filtreCategorie {
            resultats = resultats.filter { $0.categoriePeche.contains(categorie) }
        }
        
        // Filtre par espèce
        if let espece = filtreEspece {
            resultats = resultats.filter { $0.especesCibles.contains(espece) }
        }
        
        leurresFiltres = resultats
        appliquerTri()
    }
    
    /// Réinitialise tous les filtres
    func reinitialiserFiltres() {
        filtreRecherche = ""
        filtreType = nil
        filtreCategorie = nil
        filtreEspece = nil
    }
    
    // MARK: - Tri
    
    /// Applique le tri sélectionné
    private func appliquerTri() {
        switch triActuel {
        case .nom:
            leurresFiltres.sort { triCroissant ? $0.nom < $1.nom : $0.nom > $1.nom }
        case .taille:
            leurresFiltres.sort { triCroissant ? $0.longueur < $1.longueur : $0.longueur > $1.longueur }
        case .marque:
            leurresFiltres.sort { triCroissant ? $0.marque < $1.marque : $0.marque > $1.marque }
        case .dateAjout:
            leurresFiltres.sort { triCroissant ? $0.dateAjout < $1.dateAjout : $0.dateAjout > $1.dateAjout }
        }
    }
    
    // MARK: - Recherche & Statistiques
    
    /// Nombre total de leurres
    var nombreTotal: Int {
        return leurres.count
    }
    
    /// Nombre de leurres filtrés
    var nombreFiltres: Int {
        return leurresFiltres.count
    }
    
    /// Statistiques par type
    func statistiquesParType() -> [TypeLeurre: Int] {
        return Dictionary(grouping: leurres, by: { $0.type })
            .mapValues { $0.count }
    }
    
    /// Statistiques par catégorie
    func statistiquesParCategorie() -> [CategoriePeche: Int] {
        var stats: [CategoriePeche: Int] = [:]
        leurres.forEach { leurre in
            leurre.categoriePeche.forEach { categorie in
                stats[categorie, default: 0] += 1
            }
        }
        return stats
    }
    
    /// Recherche de leurres pour une espèce donnée
    func leuresParEspece(_ espece: Espece) -> [Leurre] {
        return leurres.filter { $0.especesCibles.contains(espece) }
    }
    
    /// Recherche de leurres pour une zone donnée
    func leuresParZone(_ zone: CategoriePeche) -> [Leurre] {
        return leurres.filter { $0.categoriePeche.contains(zone) }
    }
    
    // MARK: - Sauvegarde (UserDefaults ou Core Data)
    
    /// Sauvegarde les modifications (à implémenter selon besoin)
    private func sauvegarderDonnees() {
        // TODO: Implémenter la sauvegarde en Core Data ou UserDefaults
        // Pour l'instant, les modifications sont en mémoire uniquement
        print("💾 Sauvegarde des données (à implémenter)")
    }
}

// MARK: - Structure Database

struct LeureDatabase: Codable {
    let metadata: Metadata
    let leurres: [Leurre]
    
    struct Metadata: Codable {
        let version: String
        let dateCreation: String
        let nombreTotal: Int
        let description: String
        let proprietaire: String
        let source: String
    }
}

// MARK: - Extension pour aide au développement

extension LeureViewModel {
    
    /// Génère un leurre de test
    static func leurreTest() -> Leurre {
        return Leurre(
            id: 999,
            nom: "Test Leurre",
            marque: "Test",
            type: .poissonNageur,
            categoriePeche: [.lagon],
            longueur: 12.0,
            poids: 15.0,
            couleurPrincipale: .bleuArgente,
            contraste: .naturel,
            actionNage: .moderate,
            profondeurMin: 2.0,
            profondeurMax: 4.0,
            vitesseMinimale: 4.0,
            vitesseOptimale: 6.0,
            vitesseMaximale: 8.0,
            especesCibles: [.carangue, .thon],
            positionsSpread: [.longCorner],
            conditionsOptimales: ConditionsOptimales(
                moments: [.matinee, .midi],
                etatMer: [.calme],
                turbidite: [.claire],
                maree: [.montante],
                phasesLunaires: [.pleineLune]
            )
        )
    }
}
