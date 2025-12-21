//
//  SuggestionEngine.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  CŒUR DU MOTEUR DE SUGGESTION
//  Algorithme validé scientifiquement (sources CPS)
//  Scoring 40/30/30 : Technique / Couleur / Conditions
//
//  Created: 2024-12-05
//

import Foundation
import Combine

class SuggestionEngine: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isProcessing: Bool = false
    @Published var suggestions: [SuggestionResult] = []
    @Published var configurationSpread: ConfigurationSpread?
    @Published var errorMessage: String?
    @Published var progressMessage: String = ""
    
    // MARK: - Dependencies
    private let leureViewModel: LeureViewModel
    
    init(leureViewModel: LeureViewModel) {
        self.leureViewModel = leureViewModel
    }
    
    // MARK: - 🎯 FONCTION PRINCIPALE
    
    /// Génère les suggestions de leurres selon conditions
    func genererSuggestions(conditions: ConditionsPeche) {
        isProcessing = true
        errorMessage = nil
        progressMessage = "Validation des conditions..."
        
        // Validation
        let (valide, erreur) = conditions.estValide()
        guard valide else {
            errorMessage = erreur
            isProcessing = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.progressMessage = "Phase 1 : Filtrage technique..."
            }
            
            // PHASE 1 : Filtrage Technique (40%)
            let leuresCompatibles = self.filtrerLeuresCompatibles(
                conditions: conditions,
                tousLeurres: self.leureViewModel.leurres
            )
            
            guard !leuresCompatibles.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Aucun leurre compatible trouvé pour ces conditions.\n\nSuggestions :\n• Réduire la vitesse\n• Changer de zone\n• Vérifier la profondeur"
                    self.isProcessing = false
                    self.progressMessage = ""
                }
                return
            }
            
            DispatchQueue.main.async {
                self.progressMessage = "Phase 2-3 : Calcul des scores (\(leuresCompatibles.count) leurres)..."
            }
            
            // PHASE 2-3 : Scoring
            let resultats = leuresCompatibles.map { leurre in
                self.calculerScore(leurre: leurre, conditions: conditions)
            }
            
            // Tri par score décroissant
            let resultatsTriees = resultats
                .filter { $0.scoreTotal >= 50 }  // Seuil minimum
                .sorted { $0.scoreTotal > $1.scoreTotal }
            
            guard !resultatsTriees.isEmpty else {
                DispatchQueue.main.async {
                    self.errorMessage = "❌ Aucun leurre n'atteint le score minimum (50/100).\n\nEssayez de modifier les conditions."
                    self.isProcessing = false
                    self.progressMessage = ""
                }
                return
            }
            
            DispatchQueue.main.async {
                self.progressMessage = "Phase 4 : Génération du spread..."
            }
            
            // PHASE 4 : Attribution Spread
            let spreadConfig = self.genererSpread(
                suggestions: resultatsTriees,
                conditions: conditions
            )
            
            DispatchQueue.main.async {
                self.suggestions = resultatsTriees
                self.configurationSpread = spreadConfig
                self.isProcessing = false
                self.progressMessage = ""
                print("✅ \(resultatsTriees.count) suggestions générées")
            }
        }
    }
    
    // MARK: - 🔍 PHASE 1 : FILTRAGE TECHNIQUE (40%)
    
    private func filtrerLeuresCompatibles(
        conditions: ConditionsPeche,
        tousLeurres: [Leurre]
    ) -> [Leurre] {
        
        return tousLeurres.filter { leurre in
            
            // 1. RÈGLES D'ÉLIMINATION ABSOLUES
            
            // Poppers en profond
            if leurre.type == .popper && conditions.profondeurCible > 5 {
                return false
            }
            
            // Wahoo = haute vitesse obligatoire
            if conditions.especePrioritaire == .wahoo {
                if leurre.vitesseMaximale < 10 {
                    return false
                }
            }
            
            // Jigs métalliques = profond uniquement
            if leurre.type == .jigMetallique && conditions.profondeurCible < 10 {
                return false
            }
            
            // 2. COMPATIBILITÉ ZONE (critère principal)
            let zoneCompatible: Bool
            if conditions.zone == .lagon {
                // Accepter lagon ET lagonCotier
                zoneCompatible = leurre.categoriePeche.contains(.lagon) ||
                                leurre.categoriePeche.contains(.lagonCotier)
            } else if conditions.zone == .cotier {
                // Accepter cotier ET lagonCotier
                zoneCompatible = leurre.categoriePeche.contains(.cotier) ||
                                leurre.categoriePeche.contains(.lagonCotier)
            } else {
                zoneCompatible = leurre.categoriePeche.contains(conditions.zone)
            }
            
            if !zoneCompatible {
                return false
            }
            
            // 3. COMPATIBILITÉ PROFONDEUR (tolérance ±2m)
            let profCompatible = (conditions.profondeurCible >= leurre.profondeurMin - 2) &&
                                (conditions.profondeurCible <= leurre.profondeurMax + 2)
            
            if !profCompatible {
                return false
            }
            
            // 4. COMPATIBILITÉ VITESSE (tolérance ±1 nœud)
            let vitesseCompatible = (conditions.vitesseBateau >= leurre.vitesseMinimale - 1) &&
                                   (conditions.vitesseBateau <= leurre.vitesseMaximale + 1)
            
            if !vitesseCompatible {
                return false
            }
            
            // Leurre validé pour le scoring
            return true
        }
    }
    
    // MARK: - 🎨 PHASE 2-3 : CALCUL DU SCORE COMPLET
    
    private func calculerScore(
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> SuggestionResult {
        
        // Phase 1 : Technique (40 points)
        let scoreTechnique = calculerScoreTechnique(leurre: leurre, conditions: conditions)
        
        // Phase 2 : Couleur (30 points)
        let scoreCouleur = calculerScoreCouleur(leurre: leurre, conditions: conditions)
        
        // Phase 3 : Conditions (30 points)
        let scoreConditions = calculerScoreConditions(leurre: leurre, conditions: conditions)
        
        // Score total
        let scoreTotal = scoreTechnique.totalTechnique +
                        scoreCouleur.totalCouleur +
                        scoreConditions.totalConditions
        
        // Génération des justifications
        let justifications = genererJustifications(
            leurre: leurre,
            conditions: conditions,
            scoreTechnique: scoreTechnique,
            scoreCouleur: scoreCouleur,
            scoreConditions: scoreConditions
        )
        
        return SuggestionResult(
            leurre: leurre,
            scoreTechnique: scoreTechnique.totalTechnique,
            scoreCouleur: scoreCouleur.totalCouleur,
            scoreConditions: scoreConditions.totalConditions,
            scoreTotal: scoreTotal,
            positionSpread: nil,  // Sera attribué dans genererSpread()
            distanceSpread: nil,
            justificationTechnique: justifications.technique,
            justificationCouleur: justifications.couleur,
            justificationConditions: justifications.conditions,
            justificationPosition: "",  // Sera généré dans genererSpread()
            astucePro: justifications.astuce,
            detailsScoring: ScoringDetails(
                compatibiliteZone: scoreTechnique.compatibiliteZone,
                compatibiliteProfondeur: scoreTechnique.compatibiliteProfondeur,
                compatibiliteVitesse: scoreTechnique.compatibiliteVitesse,
                compatibiliteEspeces: scoreTechnique.compatibiliteEspeces,
                bonusLuminosite: scoreCouleur.bonusLuminosite,
                bonusTurbidite: scoreCouleur.bonusTurbidite,
                bonusContraste: scoreCouleur.bonusContraste,
                bonusMoment: scoreConditions.bonusMoment,
                bonusMer: scoreConditions.bonusMer,
                bonusMaree: scoreConditions.bonusMaree,
                bonusLune: scoreConditions.bonusLune,
                multiplicateurContextuel: scoreConditions.multiplicateurContextuel
            )
        )
    }
    
    // MARK: - Calcul Score Technique
    
    private func calculerScoreTechnique(
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> (compatibiliteZone: Double, compatibiliteProfondeur: Double, compatibiliteVitesse: Double, compatibiliteEspeces: Double, totalTechnique: Double) {
        
        var scoreZone: Double = 0
        var scoreProfondeur: Double = 0
        var scoreVitesse: Double = 0
        var scoreEspeces: Double = 0
        
        // 1. Zone (15 points max)
        if conditions.zone == .lagon {
            if leurre.categoriePeche.contains(.lagon) {
                scoreZone = 15
            } else if leurre.categoriePeche.contains(.lagonCotier) {
                scoreZone = 14
            } else if leurre.categoriePeche.contains(.passes) {
                scoreZone = 10  // Adjacent
            }
        } else if conditions.zone == .passes {
            if leurre.categoriePeche.contains(.passes) {
                scoreZone = 15
            } else if leurre.categoriePeche.contains(.lagon) || leurre.categoriePeche.contains(.hauturier) {
                scoreZone = 10  // Adjacent
            }
        } else if conditions.zone == .hauturier || conditions.zone == .large {
            if leurre.categoriePeche.contains(.hauturier) || leurre.categoriePeche.contains(.large) {
                scoreZone = 15
            } else if leurre.categoriePeche.contains(.passes) {
                scoreZone = 10  // Adjacent
            }
        } else if conditions.zone == .profond {
            if leurre.categoriePeche.contains(.profond) {
                scoreZone = 15
            } else if leurre.categoriePeche.contains(.hauturier) {
                scoreZone = 8
            }
        } else {
            // Autres zones
            if leurre.categoriePeche.contains(conditions.zone) {
                scoreZone = 15
            }
        }
        
        // 2. Profondeur (10 points max)
        if conditions.profondeurCible >= leurre.profondeurMin &&
           conditions.profondeurCible <= leurre.profondeurMax {
            scoreProfondeur = 10  // Plage exacte
        } else if conditions.profondeurCible >= leurre.profondeurMin - 2 &&
                  conditions.profondeurCible <= leurre.profondeurMax + 2 {
            scoreProfondeur = 5   // Proche (±2m)
        }
        
        // 3. Vitesse (10 points max)
        if conditions.vitesseBateau >= leurre.vitesseMinimale &&
           conditions.vitesseBateau <= leurre.vitesseMaximale {
            // Score progressif selon optimale
            if abs(conditions.vitesseBateau - leurre.vitesseOptimale) <= 1 {
                scoreVitesse = 10  // Vitesse optimale
            } else {
                scoreVitesse = 8   // Dans la plage
            }
        } else if conditions.vitesseBateau >= leurre.vitesseMinimale - 1 &&
                  conditions.vitesseBateau <= leurre.vitesseMaximale + 1 {
            scoreVitesse = 5       // Proche (±1 nœud)
        }
        
        // 4. Espèces (5 points max)
        if let especeCible = conditions.especePrioritaire {
            if leurre.especesCibles.contains(especeCible) {
                scoreEspeces = 5   // Espèce prioritaire
            } else {
                scoreEspeces = 1   // Pas spécifique mais compatible zone
            }
        } else {
            scoreEspeces = 3       // Pas d'espèce spécifiée
        }
        
        let total = scoreZone + scoreProfondeur + scoreVitesse + scoreEspeces
        
        return (scoreZone, scoreProfondeur, scoreVitesse, scoreEspeces, total)
    }
    
    // MARK: - Calcul Score Couleur
    
    private func calculerScoreCouleur(
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> (bonusLuminosite: Double, bonusTurbidite: Double, bonusContraste: Double, totalCouleur: Double) {
        
        var bonusLuminosite: Double = 0
        var bonusTurbidite: Double = 0
        var bonusContraste: Double = 0
        
        // Matrice Luminosité × Turbidité × Contraste
        
        // 1. Luminosité (10 points max)
        switch (conditions.luminosite, leurre.contraste) {
        case (.forte, .naturel):
            bonusLuminosite = 10  // Soleil fort = naturel optimal
        case (.forte, .flashy):
            bonusLuminosite = 6
        case (.forte, .sombre):
            bonusLuminosite = 3
        case (.forte, .contraste):
            bonusLuminosite = 7
            
        case (.diffuse, .contraste):
            bonusLuminosite = 10  // Nuageux = contraste optimal
        case (.diffuse, .flashy):
            bonusLuminosite = 9
        case (.diffuse, .naturel):
            bonusLuminosite = 6
        case (.diffuse, .sombre):
            bonusLuminosite = 5
            
        case (.faible, .sombre):
            bonusLuminosite = 10  // Aube/crépuscule = sombre optimal
        case (.faible, .contraste):
            bonusLuminosite = 9
        case (.faible, .flashy):
            bonusLuminosite = 6
        case (.faible, .naturel):
            bonusLuminosite = 4
        }
        
        // 2. Turbidité (10 points max)
        switch (conditions.turbiditeEau, leurre.contraste) {
        case (.claire, .naturel):
            bonusTurbidite = 10   // Eau claire = naturel optimal
        case (.claire, .contraste):
            bonusTurbidite = 7
        case (.claire, .flashy):
            bonusTurbidite = 5
        case (.claire, .sombre):
            bonusTurbidite = 4
            
        case (.legerementTrouble, .flashy):
            bonusTurbidite = 10   // Légèrement trouble = flashy optimal
        case (.legerementTrouble, .contraste):
            bonusTurbidite = 8
        case (.legerementTrouble, .naturel):
            bonusTurbidite = 6
        case (.legerementTrouble, .sombre):
            bonusTurbidite = 7
            
        case (.trouble, .sombre):
            bonusTurbidite = 10   // Trouble = sombre optimal
        case (.trouble, .contraste):
            bonusTurbidite = 9
        case (.trouble, .flashy):
            bonusTurbidite = 8
        case (.trouble, .naturel):
            bonusTurbidite = 3
            
        case (.tresTrouble, .flashy):
            bonusTurbidite = 10   // Très trouble = flashy (chartreuse) optimal
        case (.tresTrouble, .sombre):
            bonusTurbidite = 9
        case (.tresTrouble, .contraste):
            bonusTurbidite = 7
        case (.tresTrouble, .naturel):
            bonusTurbidite = 2
        }
        
        // 3. Bonus contraste spécifique (10 points max)
        // Chartreuse en eau trouble
        if conditions.turbiditeEau == .tresTrouble &&
           (leurre.couleurPrincipale == .chartreuse || leurre.couleurPrincipale == .jauneFluo) {
            bonusContraste = 10
        }
        // Rose fluo en mer agitée
        else if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            if leurre.couleurPrincipale == .roseFuchsia || leurre.couleurPrincipale == .roseFluo {
                bonusContraste = 10
            } else if leurre.contraste == .flashy {
                bonusContraste = 7
            } else {
                bonusContraste = 4
            }
        }
        // Argenté/bleu en eau claire
        else if conditions.turbiditeEau == .claire &&
                (leurre.couleurPrincipale == .argente || 
                 leurre.couleurPrincipale == .bleuArgente ||
                 leurre.couleurPrincipale == .sardine) {
            bonusContraste = 10
        }
        // Finition holographique
        else if leurre.finition == .holographique {
            bonusContraste = 8
        }
        // Finition mat en eau claire
        else if leurre.finition == .mat && conditions.turbiditeEau == .claire {
            bonusContraste = 7
        }
        else {
            bonusContraste = 5  // Score par défaut
        }
        
        let total = bonusLuminosite + bonusTurbidite + bonusContraste
        
        return (bonusLuminosite, bonusTurbidite, bonusContraste, total)
    }
    
    // MARK: - Calcul Score Conditions
    
    private func calculerScoreConditions(
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> (bonusMoment: Double, bonusMer: Double, bonusMaree: Double, bonusLune: Double, multiplicateurContextuel: Double, totalConditions: Double) {
        
        var bonusMoment: Double = 0
        var bonusMer: Double = 0
        var bonusMaree: Double = 0
        var bonusLune: Double = 0
        var multiplicateur: Double = 1.0
        
        // 1. Moment de la journée (10 points max)
        if leurre.conditionsOptimales.moments.contains(conditions.momentJournee) {
            switch conditions.momentJournee {
            case .aube:
                bonusMoment = 10  // PRIORITÉ MAXIMALE
            case .crepuscule:
                bonusMoment = 10  // PRIORITÉ MAXIMALE
            case .matinee:
                bonusMoment = 8
            case .apres_midi:
                bonusMoment = 6
            case .midi:
                bonusMoment = 4
            case .nuit:
                bonusMoment = 3
            }
        } else {
            bonusMoment = 2  // Moment non optimal
        }
        
        // 2. État de la mer (8 points max)
        if leurre.conditionsOptimales.etatMer.contains(conditions.etatMer) {
            switch conditions.etatMer {
            case .calme:
                bonusMer = 8   // Leurres discrets privilégiés
            case .peuAgitee:
                bonusMer = 7
            case .agitee:
                bonusMer = 8   // Leurres stables privilégiés
            case .formee:
                bonusMer = 7   // Lourds uniquement
            }
        } else {
            bonusMer = 3
        }
        
        // 3. Marée (6 points max)
        if leurre.conditionsOptimales.maree.contains(conditions.typeMaree) {
            switch conditions.typeMaree {
            case .montante:
                bonusMaree = 6   // Optimal général
            case .descendante:
                bonusMaree = 5
            case .etale:
                bonusMaree = 4
            }
        } else {
            bonusMaree = 2
        }
        
        // 4. Phase lunaire (6 points max)
        if leurre.conditionsOptimales.phasesLunaires.contains(conditions.phaseLunaire) {
            switch conditions.phaseLunaire {
            case .pleineLune:
                bonusLune = 6
                // Bonus métallique/holographique
                if leurre.finition == .holographique || leurre.finition == .metallique {
                    bonusLune += 2
                }
            case .nouvelleLune:
                bonusLune = 6
                // Bonus sombre
                if leurre.contraste == .sombre {
                    bonusLune += 2
                }
            case .premierQuartier, .dernierQuartier:
                bonusLune = 5
            }
        } else {
            bonusLune = 2
        }
        
        // 5. Multiplicateurs contextuels
        // Combo aube + marée montante + nouvelle lune
        if conditions.momentJournee == .aube &&
           conditions.typeMaree == .montante &&
           conditions.phaseLunaire == .nouvelleLune {
            multiplicateur = 1.3
        }
        // Combo crépuscule + mer calme + pleine lune
        else if conditions.momentJournee == .crepuscule &&
                conditions.etatMer == .calme &&
                conditions.phaseLunaire == .pleineLune {
            multiplicateur = 1.2
        }
        // Pénalité midi + mer agitée
        else if conditions.momentJournee == .midi &&
                (conditions.etatMer == .agitee || conditions.etatMer == .formee) {
            multiplicateur = 0.8
        }
        
        let scoreBase = bonusMoment + bonusMer + bonusMaree + bonusLune
        let total = scoreBase * multiplicateur
        
        return (bonusMoment, bonusMer, bonusMaree, bonusLune, multiplicateur, total)
    }
    
    // MARK: - Génération des justifications
    
    private func genererJustifications(
        leurre: Leurre,
        conditions: ConditionsPeche,
        scoreTechnique: (compatibiliteZone: Double, compatibiliteProfondeur: Double, compatibiliteVitesse: Double, compatibiliteEspeces: Double, totalTechnique: Double),
        scoreCouleur: (bonusLuminosite: Double, bonusTurbidite: Double, bonusContraste: Double, totalCouleur: Double),
        scoreConditions: (bonusMoment: Double, bonusMer: Double, bonusMaree: Double, bonusLune: Double, multiplicateurContextuel: Double, totalConditions: Double)
    ) -> (technique: String, couleur: String, conditions: String, astuce: String) {
        
        // JUSTIFICATION TECHNIQUE
        var justifTechnique = ""
        justifTechnique += "• Taille \(Int(leurre.longueur))cm adaptée au \(conditions.zone.displayName)\n"
        justifTechnique += "• Profondeur \(leurre.profondeurFormatee) pour \(Int(conditions.profondeurCible))m ciblé\n"
        justifTechnique += "• Vitesse \(leurre.vitesseFormatee) compatible avec \(Int(conditions.vitesseBateau)) nœuds"
        
        if let espece = conditions.especePrioritaire {
            if leurre.especesCibles.contains(espece) {
                justifTechnique += "\n• Cible spécifiquement les \(espece.displayName)"
            }
        }
        
        // JUSTIFICATION COULEUR
        var justifCouleur = ""
        justifCouleur += "• Contraste \(leurre.contraste.displayName.lowercased()) adapté à la luminosité \(conditions.luminosite.displayName.lowercased())\n"
        justifCouleur += "• Couleur \(leurre.couleurPrincipale.displayName) efficace en eau \(conditions.turbiditeEau.displayName.lowercased())"
        
        if let finition = leurre.finition {
            justifCouleur += "\n• Finition \(finition.displayName.lowercased()) optimise la visibilité"
        }
        
        // JUSTIFICATION CONDITIONS
        var justifConditions = ""
        if leurre.conditionsOptimales.moments.contains(conditions.momentJournee) {
            justifConditions += "• Moment \(conditions.momentJournee.displayName) : activité alimentaire favorable\n"
        }
        justifConditions += "• Mer \(conditions.etatMer.displayName.lowercased()) : leurre \(descriptionStabilite(leurre)) adapté\n"
        justifConditions += "• Marée \(conditions.typeMaree.displayName.lowercased()) : \(effetMaree(conditions.typeMaree))"
        
        // ASTUCE PRO
        let astuce = genererAstucePro(leurre: leurre, conditions: conditions)
        
        return (justifTechnique, justifCouleur, justifConditions, astuce)
    }
    
    private func descriptionStabilite(_ leurre: Leurre) -> String {
        if leurre.typeTete == .bullet || leurre.typeTete == .bavetteProfonde {
            return "stable"
        } else if leurre.typeTete == .popper {
            return "surface"
        } else {
            return "polyvalent"
        }
    }
    
    private func effetMaree(_ maree: TypeMaree) -> String {
        switch maree {
        case .montante: return "eau claire, poissons actifs"
        case .descendante: return "eau trouble, leurres contrastés"
        case .etale: return "condition neutre"
        }
    }
    
    private func genererAstucePro(leurre: Leurre, conditions: ConditionsPeche) -> String {
        // Aube en eau claire
        if conditions.momentJournee == .aube && conditions.turbiditeEau == .claire {
            if leurre.contraste == .naturel {
                return "À l'aube en eau claire, les carnassiers chassent par la vue. Les imitations naturelles sont le choix des professionnels."
            }
        }
        
        // Eau trouble
        if conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble {
            if leurre.contraste == .flashy {
                return "En eau trouble, les poissons chassent aux vibrations et au son. Les couleurs flashy se démarquent dans le chaos."
            }
        }
        
        // Mer agitée
        if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            return "En mer formée, privilégier les leurres lourds et stables. Les couleurs très visibles (rose, chartreuse) sont essentielles."
        }
        
        // Crépuscule
        if conditions.momentJournee == .crepuscule {
            return "Au crépuscule, les carnassiers chassent par silhouettes. Le contraste prime sur la couleur exacte."
        }
        
        // Wahoo
        if conditions.especePrioritaire == .wahoo {
            return "Le wahoo nécessite une vitesse élevée (12-16 nœuds) et des leurres avec bavettes profondes très robustes."
        }
        
        // Par défaut
        return "Respecter la profondeur et la vitesse optimale du leurre maximise les chances de réussite."
    }
    
    // MARK: - 📍 PHASE 4 : GÉNÉRATION DU SPREAD
    
    private func genererSpread(
        suggestions: [SuggestionResult],
        conditions: ConditionsPeche
    ) -> ConfigurationSpread {
        
        var suggestionsAvecPosition = suggestions
        let nbLignes = conditions.nombreLignes
        
        switch nbLignes {
        case 1:
            suggestionsAvecPosition = configurerUneLigne(suggestions)
        case 2:
            suggestionsAvecPosition = configurerDeuxLignes(suggestions)
        case 3:
            suggestionsAvecPosition = configurerTroisLignes(suggestions)
        case 4:
            suggestionsAvecPosition = configurerQuatreLignes(suggestions)
        case 5:
            suggestionsAvecPosition = configurerCinqLignes(suggestions)
        default:
            suggestionsAvecPosition = configurerUneLigne(suggestions)
        }
        
        return ConfigurationSpread(
            conditions: conditions,
            suggestions: suggestionsAvecPosition,
            dateGeneration: Date()
        )
    }
    
    // Configuration 1 ligne
    private func configurerUneLigne(_ suggestions: [SuggestionResult]) -> [SuggestionResult] {
        guard !suggestions.isEmpty else { return [] }
        
        var result = suggestions
        result[0].positionSpread = .libre
        result[0].distanceSpread = 25
        result[0].justificationPosition = "Position libre (20-25m). Meilleur leurre polyvalent pour ces conditions."
        
        return result
    }
    
    // Configuration 2 lignes
    private func configurerDeuxLignes(_ suggestions: [SuggestionResult]) -> [SuggestionResult] {
        guard suggestions.count >= 2 else { return configurerUneLigne(suggestions) }
        
        var result = suggestions
        let meilleur = suggestions[0]
        
        // Meilleur → Corner
        if meilleur.leurre.contraste == .naturel {
            result[0].positionSpread = .longCorner
            result[0].distanceSpread = 30
            result[0].justificationPosition = "Long Corner (30m). Naturel en zone calme du sillage."
        } else {
            result[0].positionSpread = .shortCorner
            result[0].distanceSpread = 15
            result[0].justificationPosition = "Short Corner (15m). Zone agressive près du bateau."
        }
        
        // Second → Rigger (contraste opposé)
        let contrasteOppose = trouverContrasteOppose(meilleur.leurre.contraste, dans: Array(suggestions[1...]))
        if let index = suggestions.firstIndex(where: { $0.id == contrasteOppose?.id }) {
            result[index].positionSpread = .riggerTribord
            result[index].distanceSpread = 55
            result[index].justificationPosition = "Rigger Tribord (55m). Contraste opposé pour couverture complète."
        }
        
        return result
    }
    
    // Configuration 3 lignes
    private func configurerTroisLignes(_ suggestions: [SuggestionResult]) -> [SuggestionResult] {
        guard suggestions.count >= 3 else { return configurerDeuxLignes(suggestions) }
        
        var result = configurerDeuxLignes(suggestions)
        
        // Shotgun → Discret loin
        let shotgun = trouverLeurreShotgun(dans: Array(suggestions[2...]))
        if let shotgun = shotgun, let index = suggestions.firstIndex(where: { $0.id == shotgun.id }) {
            result[index].positionSpread = .shotgun
            result[index].distanceSpread = 85
            result[index].justificationPosition = "Shotgun (85m). Position éloignée pour poissons méfiants."
        }
        
        return result
    }
    
    // Configuration 4 lignes
    private func configurerQuatreLignes(_ suggestions: [SuggestionResult]) -> [SuggestionResult] {
        guard suggestions.count >= 4 else { return configurerTroisLignes(suggestions) }
        
        var result = suggestions
        var utilisés: Set<UUID> = []
        
        // 1. Short Corner : Agressif/Flashy
        let shortLeurre = trouverPourShortCorner(dans: suggestions, exclure: utilisés)
        if let sl = shortLeurre, let idx = suggestions.firstIndex(where: { $0.id == sl.id }) {
            result[idx].positionSpread = .shortCorner
            result[idx].distanceSpread = 12
            result[idx].justificationPosition = "Short Corner (12m). Zone agressive, grosse bulle."
            utilisés.insert(sl.id)
        }
        
        // 2. Long Corner : Naturel
        let longLeurre = trouverPourLongCorner(dans: suggestions, exclure: utilisés)
        if let ll = longLeurre, let idx = suggestions.firstIndex(where: { $0.id == ll.id }) {
            result[idx].positionSpread = .longCorner
            result[idx].distanceSpread = 30
            result[idx].justificationPosition = "Long Corner (30m). Zone calme, naturel."
            utilisés.insert(ll.id)
        }
        
        // 3. Rigger Bâbord : Flashy
        let riggerB = trouverPourRigger(dans: suggestions, exclure: utilisés)
        if let rb = riggerB, let idx = suggestions.firstIndex(where: { $0.id == rb.id }) {
            result[idx].positionSpread = .riggerBabord
            result[idx].distanceSpread = 55
            result[idx].justificationPosition = "Rigger Bâbord (55m). Attracteur latéral flashy."
            utilisés.insert(rb.id)
        }
        
        // 4. Rigger Tribord : Flashy différent
        let riggerT = trouverPourRigger(dans: suggestions, exclure: utilisés, couleurDifferente: riggerB?.leurre.couleurPrincipale)
        if let rt = riggerT, let idx = suggestions.firstIndex(where: { $0.id == rt.id }) {
            result[idx].positionSpread = .riggerTribord
            result[idx].distanceSpread = 55
            result[idx].justificationPosition = "Rigger Tribord (55m). Attracteur latéral couleur différente."
            utilisés.insert(rt.id)
        }
        
        return result
    }
    
    // Configuration 5 lignes
    private func configurerCinqLignes(_ suggestions: [SuggestionResult]) -> [SuggestionResult] {
        guard suggestions.count >= 5 else { return configurerQuatreLignes(suggestions) }
        
        var result = configurerQuatreLignes(suggestions)
        
        // Ajouter Shotgun
        let utilisés = Set(result.compactMap { $0.positionSpread != nil ? $0.id : nil })
        let shotgun = trouverLeurreShotgun(dans: suggestions.filter { !utilisés.contains($0.id) })
        
        if let sg = shotgun, let idx = suggestions.firstIndex(where: { $0.id == sg.id }) {
            result[idx].positionSpread = .shotgun
            result[idx].distanceSpread = 85
            result[idx].justificationPosition = "Shotgun (85m). Très loin, cible marlins et mahi méfiants."
        }
        
        return result
    }
    
    // MARK: - Fonctions utilitaires spread
    
    private func trouverContrasteOppose(_ contraste: Contraste, dans suggestions: [SuggestionResult]) -> SuggestionResult? {
        switch contraste {
        case .naturel:
            return suggestions.first { $0.leurre.contraste == .flashy || $0.leurre.contraste == .sombre }
        case .flashy:
            return suggestions.first { $0.leurre.contraste == .naturel || $0.leurre.contraste == .sombre }
        case .sombre:
            return suggestions.first { $0.leurre.contraste == .flashy || $0.leurre.contraste == .naturel }
        case .contraste:
            return suggestions.first { $0.leurre.contraste == .naturel }
        }
    }
    
    private func trouverLeurreShotgun(dans suggestions: [SuggestionResult]) -> SuggestionResult? {
        // Chercher : Sombre ou Naturel, plutôt petit
        return suggestions.first { suggestion in
            (suggestion.leurre.contraste == .sombre || suggestion.leurre.contraste == .naturel) &&
            suggestion.leurre.longueur < 16
        } ?? suggestions.first
    }
    
    private func trouverPourShortCorner(dans suggestions: [SuggestionResult], exclure: Set<UUID>) -> SuggestionResult? {
        return suggestions.first { suggestion in
            !exclure.contains(suggestion.id) &&
            (suggestion.leurre.contraste == .flashy || suggestion.leurre.contraste == .contraste) &&
            (suggestion.leurre.typeTete == .plunger || suggestion.leurre.typeTete == .cupFace)
        } ?? suggestions.first { !exclure.contains($0.id) }
    }
    
    private func trouverPourLongCorner(dans suggestions: [SuggestionResult], exclure: Set<UUID>) -> SuggestionResult? {
        return suggestions.first { suggestion in
            !exclure.contains(suggestion.id) &&
            suggestion.leurre.contraste == .naturel &&
            (suggestion.leurre.typeTete == .bullet || suggestion.leurre.typeTete == .bavetteMoyenne)
        } ?? suggestions.first { !exclure.contains($0.id) }
    }
    
    private func trouverPourRigger(dans suggestions: [SuggestionResult], exclure: Set<UUID>, couleurDifferente: Couleur? = nil) -> SuggestionResult? {
        let couleursFlashy: [Couleur] = [.roseFuchsia, .rose, .roseFluo, .chartreuse, .orange, .jauneFluo]
        
        return suggestions.first { suggestion in
            !exclure.contains(suggestion.id) &&
            couleursFlashy.contains(suggestion.leurre.couleurPrincipale) &&
            (couleurDifferente == nil || suggestion.leurre.couleurPrincipale != couleurDifferente)
        } ?? suggestions.first { suggestion in
            !exclure.contains(suggestion.id) &&
            suggestion.leurre.contraste == .flashy
        } ?? suggestions.first { !exclure.contains($0.id) }
    }
}
