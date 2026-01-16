//
//  CouleurCustom.swift
//  Go les Picots - Module 1 Phase 2
//
//  Modèle pour les couleurs personnalisées créées par l'utilisateur
//  Version V2 - Simple et robuste
//
//  Created: 2024-12-22
//

import Foundation
import SwiftUI
import Combine

// MARK: - Modèle de Couleur Personnalisée

/// Représente une couleur créée par l'utilisateur
struct CouleurCustom: Identifiable, Codable, Hashable {
    let id: UUID
    var nom: String
    var red: Double       // 0.0 à 1.0
    var green: Double     // 0.0 à 1.0
    var blue: Double      // 0.0 à 1.0
    var contraste: Contraste
    var dateCreation: Date
    var isRainbow: Bool   // 🌈 Si true, affiche arc-en-ciel au lieu de la couleur
    
    init(nom: String, red: Double, green: Double, blue: Double, contraste: Contraste, isRainbow: Bool = false) {
        self.id = UUID()
        self.nom = nom
        self.red = red
        self.green = green
        self.blue = blue
        self.contraste = contraste
        self.dateCreation = Date()
        self.isRainbow = isRainbow
    }
    
    /// Couleur SwiftUI pour affichage (utilisé uniquement si !isRainbow)
    var swiftUIColor: Color {
        Color(red: red, green: green, blue: blue)
    }
    
    /// 🆕 Luminosité perçue (ITU-R BT.709) - 0.0 (noir) à 1.0 (blanc)
    var luminositePercue: Double {
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }
    
    /// 🆕 Vérifie si c'est une couleur claire (luminosité > 0.5)
    var estClaire: Bool {
        return luminositePercue > 0.5
    }
    
    /// 🆕 Vérifie si c'est une couleur foncée (luminosité < 0.3)
    var estFoncee: Bool {
        return luminositePercue < 0.3
    }
    
    /// 🆕 Description de la luminosité pour l'utilisateur
    var descriptionLuminosite: String {
        if isRainbow { return "Multicolore" }
        if luminositePercue > 0.7 { return "Très clair" }
        if luminositePercue > 0.5 { return "Clair" }
        if luminositePercue > 0.3 { return "Moyen" }
        if luminositePercue > 0.15 { return "Foncé" }
        return "Très foncé"
    }
    
    /// Initialisation depuis une Color SwiftUI
    init?(nom: String, from color: Color, contraste: Contraste, isRainbow: Bool = false) {
        // Si arc-en-ciel, utiliser des valeurs neutres (ne seront pas affichées)
        if isRainbow {
            self.id = UUID()
            self.nom = nom
            self.red = 0.5
            self.green = 0.5
            self.blue = 0.5
            self.contraste = contraste
            self.dateCreation = Date()
            self.isRainbow = true
            return
        }
        
        // Sinon, extraire les composantes de la couleur
        guard let uiColor = UIColor(color).cgColor.components,
              uiColor.count >= 3 else {
            return nil
        }
        
        self.id = UUID()
        self.nom = nom
        self.red = Double(uiColor[0])
        self.green = Double(uiColor[1])
        self.blue = Double(uiColor[2])
        self.contraste = contraste
        self.dateCreation = Date()
        self.isRainbow = false
    }
    
    // MARK: - Decodable avec valeur par défaut pour isRainbow
    
    enum CodingKeys: String, CodingKey {
        case id, nom, red, green, blue, contraste, dateCreation, isRainbow
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        nom = try container.decode(String.self, forKey: .nom)
        red = try container.decode(Double.self, forKey: .red)
        green = try container.decode(Double.self, forKey: .green)
        blue = try container.decode(Double.self, forKey: .blue)
        contraste = try container.decode(Contraste.self, forKey: .contraste)
        dateCreation = try container.decode(Date.self, forKey: .dateCreation)
        
        // 🔧 Migration : si isRainbow n'existe pas dans le JSON, utiliser false
        isRainbow = try container.decodeIfPresent(Bool.self, forKey: .isRainbow) ?? false
    }
}

// MARK: - Manager de Couleurs Personnalisées

/// Gestionnaire singleton pour les couleurs personnalisées
class CouleurCustomManager: ObservableObject {
    
    static let shared = CouleurCustomManager()
    
    @Published var couleursCustom: [CouleurCustom] = []
    
    private let userDefaultsKey = "couleursCustomV2"
    
    private init() {
        charger()
    }
    
    // MARK: - Persistance
    
    func charger() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📦 Aucune couleur personnalisée à charger")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            couleursCustom = try decoder.decode([CouleurCustom].self, from: data)
            print("✅ \(couleursCustom.count) couleur(s) personnalisée(s) chargée(s)")
        } catch {
            print("❌ Erreur chargement couleurs: \(error)")
            couleursCustom = []
        }
    }
    
    private func sauvegarder() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(couleursCustom)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 \(couleursCustom.count) couleur(s) sauvegardée(s)")
        } catch {
            print("❌ Erreur sauvegarde couleurs: \(error)")
        }
    }
    
    // MARK: - CRUD
    
    func ajouter(_ couleur: CouleurCustom) {
        couleursCustom.append(couleur)
        sauvegarder()
        print("➕ Couleur ajoutée: \(couleur.nom)")
    }
    
    func supprimer(_ couleur: CouleurCustom) {
        couleursCustom.removeAll { $0.id == couleur.id }
        sauvegarder()
        print("🗑️ Couleur supprimée: \(couleur.nom)")
    }
    
    func modifier(_ couleur: CouleurCustom) {
        if let index = couleursCustom.firstIndex(where: { $0.id == couleur.id }) {
            couleursCustom[index] = couleur
            sauvegarder()
            print("✏️ Couleur modifiée: \(couleur.nom)")
        }
    }
    
    // MARK: - Recherche
    
    func rechercher(texte: String) -> [CouleurCustom] {
        guard !texte.isEmpty else { return couleursCustom }
        
        let recherche = texte.lowercased()
        return couleursCustom.filter { couleur in
            couleur.nom.lowercased().contains(recherche)
        }
    }
    
    func nomExiste(_ nom: String) -> Bool {
        return couleursCustom.contains { $0.nom.lowercased() == nom.lowercased() }
    }
}
