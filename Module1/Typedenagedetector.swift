//
//  TypeDeNageDetector.swift
//  Go les Picots V.4
//
//  Détection automatique de types de nage dans les notes
//  Analyse les mots-clés en français et anglais
//
//  Created: 2025-12-30
//

import Foundation

struct TypeDeNageDetector {
    
    // MARK: - Dictionnaire de Mots-Clés
    
    /// Mapping mots-clés → Type de nage
    /// Les expressions plus longues sont prioritaires (ex: "wobbling large" avant "wobbling")
    static let keywords: [String: TypeDeNage] = [
        // ═══════════════════════════════════════════════════════════
        // WOBBLING (3 variantes)
        // ═══════════════════════════════════════════════════════════
        "wobbling large": .wobblingLarge,
        "wobbling ample": .wobblingLarge,
        "ondulation ample": .wobblingLarge,
        "bavette large": .wobblingLarge,
        "bavette couteau à beurre": .wobblingLarge,
        "ondulation large": .wobblingLarge,
        
        "wobbling serré": .wobblingSerré,
        "wobbling serrée": .wobblingSerré,
        "wobbling étroit": .wobblingSerré,
        "bavette étroite": .wobblingSerré,
        "bavette fine": .wobblingSerré,
        
        "wobbling": .wobbling,  // Générique (après les spécifiques)
        "wobble": .wobbling,
        "oscillation": .wobbling,
        "ondulante": .wobbling,         // ✅ AJOUTER
        "nage ondulante": .wobbling,    // ✅ AJOUTER
        "ondulation": .wobbling,        // ✅ AJOUTER
        "wobbler": .wobbling,        // ✅ AJOUTER
        
        // ═══════════════════════════════════════════════════════════
        // JIGGING (3 variantes)
        // ═══════════════════════════════════════════════════════════
        "fast jigging": .fastJigging,
        "fast jig": .fastJigging,
        "speed jigging": .fastJigging,
        "high pitch jigging": .fastJigging,
        "jigging rapide": .fastJigging,
        "jig rapide": .fastJigging,
        
        "slow jigging": .slowJigging,
        "slow jig": .slowJigging,
        "slow pitch jigging": .slowJigging,
        "jigging lent": .slowJigging,
        "jig lent": .slowJigging,
        
        "jigging": .jigging,  // Générique (après les spécifiques)
        "jig": .jigging,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES LINÉAIRES
        // ═══════════════════════════════════════════════════════════
        "nage rectiligne": .rectiligneStable,
        "rectiligne": .rectiligneStable,
        "ligne droite": .rectiligneStable,
        "nage stable": .rectiligneStable,
        "torpille": .rectiligneStable,
        
        "wobbling + rolling": .wobblingRolling,
        "wobbling rolling": .wobblingRolling,
        
        "rolling": .rolling,
        "roule": .rolling,
        "roulis": .rolling,
        "rotation": .rolling,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES ERRATIQUES
        // ═══════════════════════════════════════════════════════════
        "walk the dog": .walkTheDog,
        "walking the dog": .walkTheDog,
        "walk dog": .walkTheDog,
        "zigzag": .walkTheDog,
        "zig zag": .walkTheDog,
        "promenade chien": .walkTheDog,
        
        "darting": .darting,
        "dart": .darting,
        "éclair": .darting,
        "fulgurance": .darting,
        "erratique": .darting,           // ✅ AJOUTER
        "nage erratique": .darting,      // ✅ AJOUTER
        
        "slashing": .slashing,
        "slash": .slashing,
        "coup de queue": .slashing,
        
        "cup": .popping,
        "deep cup": .popping,
        "shallow cup": .popping,
        "chug": .popping,
        "deep chug": .popping,
        "chugger": .popping,
        "splash": .popping,
        "eclaboussure": .popping,
        "pop": .popping,
        
        "bille": .rattling,
        "rattle": .rattling,
        "one-knocker": .rattling,
        "high pitch rattle": .rattling,
        "low pitch rattle": .rattling,
        "steel rattle": .rattling,
        "rattled": .rattling,
        "son": .rattling,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES VERTICALES
        // ═══════════════════════════════════════════════════════════
        "flutter": .flutter,
        "papillonne": .flutter,
        "papillonnant": .flutter,
        "papillotement": .flutter,
        
        "falling": .falling,
        "chute": .falling,
        "tombe": .falling,
        "descente": .falling,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES ONDULANTES
        // ═══════════════════════════════════════════════════════════
        "paddle swimming": .paddleSwimming,
        "paddle": .paddleSwimming,
        "nage pagaie": .paddleSwimming,
        
        "vibration": .vibration,
        "vibre": .vibration,
        "vibrant": .vibration,
        "frémissement": .vibration,
        
        "thumping": .thumping,
        "thump": .thumping,
        "pulsation": .thumping,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES SPÉCIFIQUES TRAÎNE
        // ═══════════════════════════════════════════════════════════
        "nage de balayage": .balayageLarge,
        "balayage large": .balayageLarge,
        "balayage": .balayageLarge,
        
        "nage plongeante": .plongeanteControlee,
        "plongeant": .plongeanteControlee,
        "plonge": .plongeanteControlee,
        "diving": .plongeanteControlee,
        
        // ═══════════════════════════════════════════════════════════
        // NAGES PASSIVES
        // ═══════════════════════════════════════════════════════════
        "dérive naturelle": .deriveNaturelle,
        "dérive": .deriveNaturelle,
        "drift": .deriveNaturelle,
        
        "nage suspendue": .nageSuspendue,
        "suspendu": .nageSuspendue,
        "suspend": .nageSuspendue,
        "suspending": .nageSuspendue,
    ]
    
    // MARK: - Méthodes de Détection
    
    /// Détecte tous les types de nage mentionnés dans un texte
    /// - Parameter text: Le texte à analyser (notes utilisateur)
    /// - Returns: Liste des types détectés, triés par ordre de priorité
    static func detect(in text: String) -> [TypeDeNage] {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }
        
        let lowercased = text.lowercased()
        var detected: Set<TypeDeNage> = []
        
        // Trier les mots-clés par longueur décroissante (les plus spécifiques d'abord)
        // Ex: "wobbling large" avant "wobbling"
        let sortedKeywords = keywords.keys.sorted { $0.count > $1.count }
        
        for keyword in sortedKeywords {
            if lowercased.contains(keyword) {
                if let type = keywords[keyword] {
                    detected.insert(type)
                }
            }
        }
        
        // Filtrer les déclencheurs génériques si leurs variantes sont détectées
        let filtered = filterGenericTriggers(from: Array(detected))
        
        // Trier par ordre alphabétique pour cohérence
        return filtered.sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Détecte le premier type de nage trouvé (le plus pertinent)
    /// - Parameter text: Le texte à analyser
    /// - Returns: Le premier type détecté, ou nil
    static func detectFirst(in text: String) -> TypeDeNage? {
        return detect(in: text).first
    }
    
    /// Vérifie si un type spécifique est mentionné dans le texte
    /// - Parameters:
    ///   - type: Le type de nage à rechercher
    ///   - text: Le texte à analyser
    /// - Returns: true si le type est détecté
    static func contains(_ type: TypeDeNage, in text: String) -> Bool {
        return detect(in: text).contains(type)
    }
    
    // MARK: - Filtrage Intelligent
    
    /// Filtre les déclencheurs génériques si leurs variantes sont présentes
    /// Ex: Si "Wobbling large" est détecté, on retire "Wobbling" générique
    private static func filterGenericTriggers(from types: [TypeDeNage]) -> [TypeDeNage] {
        var filtered = types
        
        // Si une variante de Wobbling est détectée, retirer le générique
        if types.contains(.wobblingLarge) || types.contains(.wobblingSerré) {
            filtered.removeAll { $0 == .wobbling }
        }
        
        // Si une variante de Jigging est détectée, retirer le générique
        if types.contains(.fastJigging) || types.contains(.slowJigging) {
            filtered.removeAll { $0 == .jigging }
        }
        
        return filtered
    }
    
    // MARK: - Analyse Avancée
    
    /// Retourne un score de confiance pour la détection (0.0 à 1.0)
    /// Basé sur le nombre d'occurrences et la spécificité des mots-clés
    static func confidenceScore(for type: TypeDeNage, in text: String) -> Double {
        let lowercased = text.lowercased()
        var score = 0.0
        var occurrences = 0
        
        // Compter les occurrences de mots-clés pour ce type
        for (keyword, detectedType) in keywords where detectedType == type {
            if lowercased.contains(keyword) {
                occurrences += 1
                // Les mots-clés plus longs (plus spécifiques) valent plus
                let specificity = Double(keyword.count) / 20.0
                score += min(1.0, specificity)
            }
        }
        
        // Normaliser le score
        return min(1.0, score * Double(occurrences) / 3.0)
    }
    
    /// Suggère des types de nage basés sur d'autres caractéristiques du leurre
    /// (Peut être étendu pour intégration future avec le moteur IA)
    static func suggest(basedOn characteristics: LeurreCharacteristics) -> [TypeDeNage] {
        var suggestions: [TypeDeNage] = []
        
        // Exemples de règles simples
        if characteristics.hasLargeLip {
            suggestions.append(.wobblingLarge)
        }
        
        if characteristics.isVertical {
            suggestions.append(.jigging)
        }
        
        return suggestions
    }
}

// MARK: - Structures d'Aide

/// Caractéristiques d'un leurre pour suggestions avancées
struct LeurreCharacteristics {
    let hasLargeLip: Bool
    let isVertical: Bool
    let typeLeurre: TypeLeurre?
    
    init(hasLargeLip: Bool = false, isVertical: Bool = false, typeLeurre: TypeLeurre? = nil) {
        self.hasLargeLip = hasLargeLip
        self.isVertical = isVertical
        self.typeLeurre = typeLeurre
    }
}

// MARK: - Extensions Utiles

extension TypeDeNage {
    /// Retourne les mots-clés associés à ce type (pour debug/tests)
    var detectionKeywords: [String] {
        return TypeDeNageDetector.keywords.filter { $0.value == self }.map { $0.key }
    }
}
