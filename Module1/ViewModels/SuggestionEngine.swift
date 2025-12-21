//
//  SuggestionEngine_ENHANCED.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  VERSION FINALE avec :
//  ✅ Tout le code validé du SuggestionEngine.swift original
//  ➕ Probabilités de prise (30-95%)
//  ➕ Justifications "niveau champion"
//  ➕ Analyse globale des conditions
//  ✅ Support complet Luminosité : forte, diffuse, faible, sombre, nuit
//  🔧 Corrections basées sur "la_meilleure_méthode_pour_choisir_un_leurre_de_traîne.pdf"
//
//  Created: 2024-12-08
//  Updated: 2024-12-12 - Corrections des erreurs de compilation
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
    @Published var shouldShowResults: Bool = false
    @Published var analyseGlobale: String = ""

    
    // MARK: - Dependencies
    private let leureViewModel: LeureViewModel
    var nombreLeurres: Int { leureViewModel.leurres.count }
    
    init(leureViewModel: LeureViewModel) {
        self.leureViewModel = leureViewModel
    }
    
    // MARK: - 📦 STRUCTURES DE RÉSULTATS

    struct SuggestionResult: Identifiable, Hashable {
        let id = UUID()
        let leurre: Leurre
        let scoreTechnique: Double
        let scoreCouleur: Double
        let scoreConditions: Double
        let scoreTotal: Double
        let probabilitePrise: Double
        
        var positionSpread: PositionSpread?
        var distanceSpread: Int?
        
        let justificationTechnique: String
        let justificationCouleur: String
        let justificationConditions: String
        var justificationPosition: String
        let astucePro: String
        
        let detailsScoring: ScoringDetails
        
        var niveauQualite: String {
            switch scoreTotal {
            case 90...100: return "Exceptionnel"
            case 80..<90: return "Excellent"
            case 70..<80: return "Très bon"
            case 60..<70: return "Bon"
            case 50..<60: return "Correct"
            default: return "Faible"
            }
        }
        
        // Hashable conformance
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        static func == (lhs: SuggestionResult, rhs: SuggestionResult) -> Bool {
            lhs.id == rhs.id
        }
    }

    struct ConfigurationSpread {
        let suggestions: [SuggestionResult]
        let nombreLignes: Int
        let distanceMoyenne: Double
        let analyseSpread: String
        let vitesseRecommandee: Double
        let vitessePlageMin: Double
        let vitessePlageMax: Double
        let justificationVitesse: String
        let ajustementsVitesse: [String]  // Facteurs contextuels d'ajustement
    }

    struct ScoringDetails {
        let compatibiliteZone: Double
        let compatibiliteProfondeur: Double
        let compatibiliteVitesse: Double
        let compatibiliteEspeces: Double
        
        let bonusLuminosite: Double
        let bonusTurbidite: Double
        let bonusContraste: Double
        
        let bonusMoment: Double
        let bonusMer: Double
        let bonusMaree: Double
        let bonusLune: Double
        let multiplicateurContextuel: Double
    }
    
    // MARK: - 🚤 CALCUL VITESSE RECOMMANDÉE
    
    /// Structure de recommandation de vitesse enrichie
    struct VitesseRecommandation {
        let vitesseRecommandee: Double
        let plageMin: Double
        let plageMax: Double
        let justification: String
        let ajustements: [String]
    }
    
    /// Calcule la vitesse de traîne recommandée avec plages élargies et ajustements contextuels
    static func calculerVitesseRecommandee(
        especePrioritaire: Espece?,
        profilBateau: ProfilBateau,
        zone: Zone,
        etatMer: EtatMer? = nil,
        turbidite: Turbidite? = nil,
        momentJournee: MomentJournee? = nil
    ) -> VitesseRecommandation {
        
        var vitesseBase: Double
        var plageMin: Double
        var plageMax: Double
        var justification: String
        var ajustements: [String] = []
        
        if let espece = especePrioritaire {
            // Mode ciblé : vitesse selon l'espèce (plages élargies)
            switch espece {
            case .wahoo:
                vitesseBase = 12.0
                plageMin = 10.0
                plageMax = 14.0
                justification = "Pélagique ultra-rapide chassant entre 10-14 kts. Vitesse élevée déclenche instinct prédateur et fait vibrer leurres profonds type bavettes haute vitesse."
                
            case .thonJaune, .thonObese:
                vitesseBase = 8.0
                plageMin = 6.5
                plageMax = 9.5
                justification = "Pélagiques actifs chassant à vitesse moyenne-élevée. 6.5-9.5 kts optimise nage des leurres tout en couvrant efficacement zone de chasse."
                
            case .marlin, .voilier:
                vitesseBase = 8.5
                plageMin = 7.0
                plageMax = 10.0
                justification = "Grands pélagiques préférant vitesse soutenue. 7-10 kts fait danser leurres surface et déclenche attaques spectaculaires."
                
            case .mahiMahi:
                vitesseBase = 8.5
                plageMin = 7.0
                plageMax = 10.0
                justification = "Chasseur visuel et curieux. 7-10 kts permet d'explorer zone tout en laissant temps d'investigation depuis profondeur."
                
            case .thazard, .thazardBatard:
                vitesseBase = 5.5
                plageMin = 4.0
                plageMax = 7.0
                justification = "Prédateurs surface chassant proies rapides. 4-7 kts idéal pour petits leurres bavettes et actions naturelles."
                
            case .bonite:
                vitesseBase = 6.5
                plageMin = 5.5
                plageMax = 8.0
                justification = "Chasseurs actifs en bancs. 5.5-8 kts maintient leurres surface et couvre efficacement zones de chasse."
                
            case .carangueGT, .carangue, .carangueBleue:
                vitesseBase = 6.0
                plageMin = 4.5
                plageMax = 7.5
                justification = "Prédateurs patrouillant structures. 4.5-7.5 kts permet passage près récifs sans accrochage tout en restant attractif."
                
            case .barracuda:
                vitesseBase = 6.0
                plageMin = 4.0
                plageMax = 8.0
                justification = "Chasseur embuscade à vitesse variable. 4-8 kts laisse temps repérage visuel et attaque foudroyante."
                
            case .loche, .lochePintade:
                vitesseBase = 4.5
                plageMin = 3.5
                plageMax = 6.0
                justification = "Espèces récif méfiantes. Vitesse lente 3.5-6 kts évite méfiance et permet présentation naturelle près structures."
                
            default:
                vitesseBase = 7.0
                plageMin = 5.5
                plageMax = 9.0
                justification = "Vitesse polyvalente offrant compromis couverture-attractivité pour espèces variées."
            }
            
        } else {
            // Mode "toutes espèces" : vitesse polyvalente selon la zone
            switch zone {
            case .lagon, .recif:
                vitesseBase = 5.5
                plageMin = 4.0
                plageMax = 7.0
                justification = "Zone côtière: vitesse modérée 4-7 kts optimise exploration structures tout en évitant accrochages. Compatible espèces résidentes."
                
            case .passe:
                vitesseBase = 6.0
                plageMin = 5.0
                plageMax = 8.0
                justification = "Passes: vitesse intermédiaire 5-8 kts pour intercepter pélagiques transitant entre lagon et large."
                
            case .large, .tombant:
                vitesseBase = 8.0
                plageMin = 6.0
                plageMax = 10.0
                justification = "Haute mer: vitesse polyvalente 6-10 kts compatible thons, wahoos, mahi-mahis. Optimise couverture zone tout en restant attractif."
                
            case .profond, .dcp:
                vitesseBase = 8.0
                plageMin = 6.0
                plageMax = 10.0
                justification = "Zone profonde/DCP: vitesse soutenue 6-10 kts cible gros pélagiques patrouillant structures flottantes et tombants."
            }
        }
        
        // AJUSTEMENTS CONTEXTUELS
        
        // Profil bateau
        if profilBateau == .clark429 {
            vitesseBase = max(3.0, vitesseBase - 0.5)
            plageMin = max(3.0, plageMin - 0.5)
            plageMax = max(4.0, plageMax - 0.5)
            ajustements.append("Clark 4.29m: -0.5 kt (stabilité bateau réduit)")
        }
        
        // État mer
        if let mer = etatMer {
            switch mer {
            case .agitee, .formee:
                vitesseBase = max(3.0, vitesseBase - 0.5)
                plageMin = max(3.0, plageMin - 0.5)
                ajustements.append("Mer agitée: -0.5 kt recommandé (maintien action leurres)")
            case .calme, .peuAgitee:
                break // Pas d'ajustement
            }
        }
        
        // Turbidité
        if let turb = turbidite {
            switch turb {
            case .trouble, .tresTrouble:
                vitesseBase = max(3.0, vitesseBase - 0.5)
                plageMax = max(4.0, plageMax - 0.5)
                ajustements.append("Eau trouble: -0.5 kt possible (visibilité réduite)")
            case .claire, .legerementTrouble:
                break // Pas d'ajustement
            }
        }
        
        // Moment journée (info, pas de modification chiffrée)
        if let moment = momentJournee {
            switch moment {
            case .aube, .crepuscule:
                ajustements.append("Aube/crépuscule: activité maximale, privilégier plage basse")
            case .midi:
                ajustements.append("Midi: ralentir si inactivité, explorer zones ombragées")
            default:
                break
            }
        }
        
        return VitesseRecommandation(
            vitesseRecommandee: vitesseBase,
            plageMin: plageMin,
            plageMax: plageMax,
            justification: justification,
            ajustements: ajustements
        )
    }
    
    /// Compatibilité rétroactive : retourne tuple simple
    static func calculerVitesseRecommandeeSimple(
        especePrioritaire: Espece?,
        profilBateau: ProfilBateau,
        zone: Zone
    ) -> (vitesseRecommandee: Double, plageMin: Double, plageMax: Double, justification: String) {
        let reco = calculerVitesseRecommandee(
            especePrioritaire: especePrioritaire,
            profilBateau: profilBateau,
            zone: zone
        )
        return (reco.vitesseRecommandee, reco.plageMin, reco.plageMax, reco.justification)
    }
    
    // MARK: - 🎣 GÉNÉRATION PRINCIPALE
    
    func genererSuggestions(conditions: ConditionsPeche) {
        isProcessing = true
        errorMessage = nil
        suggestions = []
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
            
            // Calcul vitesse recommandée enrichie
            let vitesseReco = SuggestionEngine.calculerVitesseRecommandee(
                especePrioritaire: conditions.especePrioritaire,
                profilBateau: conditions.profilBateau,
                zone: conditions.zone,
                etatMer: conditions.etatMer,
                turbidite: conditions.turbiditeEau,
                momentJournee: conditions.momentJournee
            )
            
            // PHASE 4 : Attribution Spread
            let spreadConfig = self.genererSpread(
                suggestions: resultatsTriees,
                conditions: conditions,
                vitesseReco: vitesseReco
            )
            
            // Génération analyse globale
            let analyse = self.genererAnalyseGlobale(
                conditions: conditions,
                suggestions: spreadConfig.suggestions
            )
            
            DispatchQueue.main.async {
                self.suggestions = spreadConfig.suggestions
                self.configurationSpread = spreadConfig
                self.analyseGlobale = analyse
                self.isProcessing = false
                self.progressMessage = ""
                self.shouldShowResults = true
                print("✅ \(spreadConfig.suggestions.count) suggestions générées")
            }
        }
    }
    
    // MARK: - 🔍 PHASE 1 : FILTRAGE TECHNIQUE (40%)
    
    private func filtrerLeuresCompatibles(
        conditions: ConditionsPeche,
        tousLeurres: [Leurre]
    ) -> [Leurre] {
        
        return tousLeurres.filter { leurre in
            
            // 0. ⚡️ RÈGLE ABSOLUE : SEULS LES LEURRES DE TRAÎNE POUR LE SPREAD
            // Un leurre est valide s'il est compatible avec la traîne
            guard leurre.estLeurreDeTraîne else {
                return false
            }
            
            // 1. RÈGLES D'ÉLIMINATION ABSOLUES
            
            // ⚠️ CORRECTION : Poppers et Jigs sont déjà exclus par `estLeurreDeTraîne`
            // Ces types sont uniquement pour lancer/jigging, jamais pour traîne
            
            // Wahoo = haute vitesse obligatoire
            if conditions.especePrioritaire == .wahoo {
                if let vitesseMax = leurre.vitesseTraineMax, vitesseMax < 10 {
                    return false
                }
            }
            
            // 2. COMPATIBILITÉ ZONE (critère principal)
            guard let zonesAdaptees = leurre.zonesAdaptees, !zonesAdaptees.isEmpty else {
                return false
            }
            
            let zoneCompatible: Bool
            if conditions.zone == .lagon {
                zoneCompatible = zonesAdaptees.contains(.lagon) ||
                                zonesAdaptees.contains(.recif)
            } else if conditions.zone == .recif {
                zoneCompatible = zonesAdaptees.contains(.recif) ||
                                zonesAdaptees.contains(.lagon)
            } else {
                zoneCompatible = zonesAdaptees.contains(conditions.zone)
            }
            
            if !zoneCompatible {
                return false
            }
            
            // 3. COMPATIBILITÉ PROFONDEUR D'EAU
            // ⚠️ CORRECTION : profondeurCible = profondeur d'eau (bathymétrie)
            // On élimine UNIQUEMENT les leurres qui toucheraient le fond
            // Tous les leurres dont profondeurNage < profondeurEau sont OK
            
            if let profMax = leurre.profondeurNageMax {
                // Éliminer si le leurre nage plus profond que l'eau disponible
                // Marge de sécurité : -2m (éviter d'accrocher le fond)
                if profMax > conditions.profondeurCible - 2 {
                    return false
                }
            }
            // Si pas de profondeurNageMax définie, on accepte le leurre
            
            // 4. COMPATIBILITÉ VITESSE (tolérance ±1 nœud)
            guard let vitesseMin = leurre.vitesseTraineMin,
                  let vitesseMax = leurre.vitesseTraineMax else {
                return false
            }
            
            var vitesseMaxAjustee = vitesseMax
            
            // Lagon/récif : accepter jusqu'à 7 nœuds
            if conditions.zone == .lagon || conditions.zone == .recif {
                vitesseMaxAjustee = max(vitesseMaxAjustee, 7.0)
            }
            
            // Thon jaune : accepter jusqu'à 12 nœuds
            if conditions.especePrioritaire == .thonJaune {
                vitesseMaxAjustee = max(vitesseMaxAjustee, 12.0)
            }
            
            let vitesseCompatible = (conditions.vitesseBateau >= vitesseMin - 1) &&
                                   (conditions.vitesseBateau <= vitesseMaxAjustee + 1)
            
            if !vitesseCompatible {
                return false
            }
            
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
        
        // Calcul de la probabilité de prise
        let probabilitePrise = calculerProbabilitePrise(
            scoreTotal: scoreTotal,
            leurre: leurre,
            conditions: conditions
        )
        
        // Génération des justifications ENRICHIES
        let justifications = genererJustificationsExpertes(
            leurre: leurre,
            conditions: conditions,
            scoreTechnique: scoreTechnique,
            scoreCouleur: scoreCouleur,
            scoreConditions: scoreConditions,
            probabilitePrise: probabilitePrise
        )
        
        return SuggestionResult(
            leurre: leurre,
            scoreTechnique: scoreTechnique.totalTechnique,
            scoreCouleur: scoreCouleur.totalCouleur,
            scoreConditions: scoreConditions.totalConditions,
            scoreTotal: scoreTotal,
            probabilitePrise: probabilitePrise,
            positionSpread: nil,
            distanceSpread: nil,
            justificationTechnique: justifications.technique,
            justificationCouleur: justifications.couleur,
            justificationConditions: justifications.conditions,
            justificationPosition: "",
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
    
    // MARK: - Calcul de Probabilité de Prise
    
    private func calculerProbabilitePrise(
        scoreTotal: Double,
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> Double {
        
        var probabilite = 60.0 + (scoreTotal - 50.0) * 0.7
        
        // Bonus espèce cible
        if let espece = conditions.especePrioritaire {
            if let especesCibles = leurre.especesCibles,
               especesCibles.contains(espece.displayName) {
                probabilite += 5.0
            }
        }
        
        // Bonus conditions idéales
        var facteursIdeaux = 0
        
        if let conditionsOpt = leurre.conditionsOptimales,
           let moments = conditionsOpt.moments,
           moments.contains(conditions.momentJournee) {
            facteursIdeaux += 1
            if conditions.momentJournee == .aube || conditions.momentJournee == .crepuscule {
                facteursIdeaux += 1
            }
        }
        
        if conditions.typeMaree == .montante {
            facteursIdeaux += 1
        }
        
        if let conditionsOpt = leurre.conditionsOptimales,
           let etatsM = conditionsOpt.etatMer,
           etatsM.contains(conditions.etatMer) {
            facteursIdeaux += 1
        }
        
        if estTurbiditeOptimale(leurre: leurre, turbidite: conditions.turbiditeEau) {
            facteursIdeaux += 1
        }
        
        if estLuminositeIdeale(leurre: leurre, luminosite: conditions.luminosite) {
            facteursIdeaux += 1
        }
        
        probabilite += Double(facteursIdeaux) * 2.0
        
        // Malus conditions défavorables
        if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            // ⚠️ CORRECTION : Les jigs ne sont pas dans le moteur de traîne
            // Seuls les leurres coulants restent efficaces en mer formée
            if leurre.typeLeurre != .poissonNageurCoulant {
                probabilite -= 5.0
            }
        }
        
        // Bonus marée descendante + eau trouble
        if conditions.typeMaree == .descendante && (conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble) {
            if let contraste = leurre.contraste {
                if contraste == .sombre || contraste == .flashy {
                    probabilite += 3.0
                }
            }
        }
        
        return min(max(probabilite, 30.0), 95.0)
    }
    
    // MARK: - Helpers conditions idéales
    
    private func estLuminositeIdeale(leurre: Leurre, luminosite: Luminosite) -> Bool {
        guard let contraste = leurre.contraste else { return false }
        
        switch luminosite {
        case .forte:
            return contraste == .naturel
        case .diffuse:
            return contraste == .contraste || contraste == .flashy
        case .faible:
            return contraste == .sombre || contraste == .contraste
        case .sombre:
            return contraste == .sombre
        case .nuit:
            return contraste == .sombre
        }
    }
    
    private func estTurbiditeOptimale(leurre: Leurre, turbidite: Turbidite) -> Bool {
        guard let contraste = leurre.contraste else { return false }
        
        switch turbidite {
        case .claire:
            return contraste == .naturel
        case .legerementTrouble:
            return contraste == .flashy || contraste == .contraste
        case .trouble, .tresTrouble:
            return contraste == .sombre || contraste == .flashy
        }
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
        if let zones = leurre.zonesAdaptees {
            if conditions.zone == .lagon {
                if zones.contains(.lagon) {
                    scoreZone = 15
                } else if zones.contains(.recif) {
                    scoreZone = 14
                } else if zones.contains(.passe) {
                    scoreZone = 10
                }
            } else if conditions.zone == .passe {
                if zones.contains(.passe) {
                    scoreZone = 15
                } else if zones.contains(.lagon) || zones.contains(.large) {
                    scoreZone = 10
                }
            } else if conditions.zone == .large {
                if zones.contains(.large) {
                    scoreZone = 15
                } else if zones.contains(.passe) {
                    scoreZone = 10
                }
            } else if conditions.zone == .profond {
                if zones.contains(.profond) {
                    scoreZone = 15
                } else if zones.contains(.large) {
                    scoreZone = 8
                }
            } else {
                if zones.contains(conditions.zone) {
                    scoreZone = 15
                }
            }
        }
        
        // 2. Profondeur (10 points max)
        // ⚠️ CORRECTION : Scoring basé sur l'adéquation profondeur nage vs espèce/zone
        // Plus le leurre nage dans la bonne couche d'eau, plus le score est élevé
        if let profMin = leurre.profondeurNageMin,
           let profMax = leurre.profondeurNageMax {
            
            // Déterminer la profondeur de nage idéale selon zone/espèce
            let profondeurIdéale: Double
            
            if let espece = conditions.especePrioritaire {
                // Profondeurs préférées par espèce
                switch espece {
                case .thazard, .thazardBatard, .bonite:
                    profondeurIdéale = 5.0  // Surface/sub-surface
                case .mahiMahi:
                    profondeurIdéale = 3.0  // ⚠️ CORRECTION : Remonte à la surface si attiré par couleurs vives
                case .barracuda:
                    profondeurIdéale = 6.0
                case .thonJaune, .carangueGT, .wahoo:
                    profondeurIdéale = 10.0  // Moyenne profondeur
                case .marlin, .voilier:
                    profondeurIdéale = 15.0  // Gros pélagiques
                default:
                    profondeurIdéale = 8.0  // Défaut
                }
            } else {
                // Profondeur selon zone
                switch conditions.zone {
                case .lagon, .recif:
                    profondeurIdéale = 5.0
                case .passe:
                    profondeurIdéale = 8.0
                case .large, .tombant:
                    profondeurIdéale = 10.0
                case .profond, .dcp:
                    profondeurIdéale = 15.0
                }
            }
            
            // Calculer le milieu de la plage de nage du leurre
            let profondeurMoyenneLeurre = (profMin + profMax) / 2.0
            let ecartAvecIdeale = abs(profondeurMoyenneLeurre - profondeurIdéale)
            
            // Attribution des points selon écart
            if ecartAvecIdeale <= 2 {
                scoreProfondeur = 10  // Parfait
            } else if ecartAvecIdeale <= 4 {
                scoreProfondeur = 8   // Très bien
            } else if ecartAvecIdeale <= 6 {
                scoreProfondeur = 6   // Bien
            } else if ecartAvecIdeale <= 10 {
                scoreProfondeur = 4   // Acceptable
            } else {
                scoreProfondeur = 2   // Limite
            }
        } else {
            // Pas de profondeur définie : score neutre
            scoreProfondeur = 5
        }
        
        // 3. Vitesse (10 points max)
        if let vitesseMin = leurre.vitesseTraineMin,
           let vitesseMax = leurre.vitesseTraineMax {
            let vitesseOptimale = (vitesseMin + vitesseMax) / 2.0
            
            if conditions.vitesseBateau >= vitesseMin &&
               conditions.vitesseBateau <= vitesseMax {
                if abs(conditions.vitesseBateau - vitesseOptimale) <= 1 {
                    scoreVitesse = 10
                } else {
                    scoreVitesse = 8
                }
            } else if conditions.vitesseBateau >= vitesseMin - 1 &&
                      conditions.vitesseBateau <= vitesseMax + 1 {
                scoreVitesse = 5
            }
        }
        
        // 4. Espèces (5 points max)
        if let especeCible = conditions.especePrioritaire {
            // Mode ciblé : privilégier les leurres spécifiques
            if let especesCibles = leurre.especesCibles,
               especesCibles.contains(especeCible.displayName) {
                scoreEspeces = 5
            } else {
                scoreEspeces = 1
            }
        } else {
            // ⚠️ MODE "TOUTES ESPÈCES" : Favoriser la polyvalence
            // Plus un leurre cible d'espèces différentes, plus il est intéressant
            if let especesCibles = leurre.especesCibles, !especesCibles.isEmpty {
                let nombreEspeces = especesCibles.count
                
                // Scoring progressif selon polyvalence
                switch nombreEspeces {
                case 5...: 
                    scoreEspeces = 5.0  // Très polyvalent (5+ espèces)
                case 4:
                    scoreEspeces = 4.5  // Polyvalent (4 espèces)
                case 3:
                    scoreEspeces = 4.0  // Bon (3 espèces)
                case 2:
                    scoreEspeces = 3.5  // Correct (2 espèces)
                case 1:
                    scoreEspeces = 2.5  // Spécialisé (1 espèce)
                default:
                    scoreEspeces = 3.0  // Neutre
                }
            } else {
                // Pas d'espèces définies : score neutre
                scoreEspeces = 3.0
            }
        }
        
        let total = scoreZone + scoreProfondeur + scoreVitesse + scoreEspeces
        
        return (scoreZone, scoreProfondeur, scoreVitesse, scoreEspeces, total)
    }
    
    // MARK: - Calcul Score Couleur (✅ CORRIGÉ avec .sombre et .nuit)
    
    private func calculerScoreCouleur(
        leurre: Leurre,
        conditions: ConditionsPeche
    ) -> (bonusLuminosite: Double, bonusTurbidite: Double, bonusContraste: Double, totalCouleur: Double) {
        
        var bonusLuminosite: Double = 0
        var bonusTurbidite: Double = 0
        var bonusContraste: Double = 0
        
        guard let contraste = leurre.contraste else {
            return (0, 0, 0, 0)
        }
        
        // 1. Luminosité (10 points max)
        switch (conditions.luminosite, contraste) {
        case (.forte, .naturel):
            bonusLuminosite = 10
        case (.forte, .flashy):
            bonusLuminosite = 6
        case (.forte, .sombre):
            bonusLuminosite = 3
        case (.forte, .contraste):
            bonusLuminosite = 7
            
        case (.diffuse, .contraste):
            bonusLuminosite = 10
        case (.diffuse, .flashy):
            bonusLuminosite = 9
        case (.diffuse, .naturel):
            bonusLuminosite = 6
        case (.diffuse, .sombre):
            bonusLuminosite = 5
            
        case (.faible, .sombre):
            bonusLuminosite = 10
        case (.faible, .contraste):
            bonusLuminosite = 9
        case (.faible, .flashy):
            bonusLuminosite = 6
        case (.faible, .naturel):
            bonusLuminosite = 4
            
        // ✅ NOUVEAU : LUMINOSITÉ SOMBRE
        case (.sombre, .sombre):
            bonusLuminosite = 10  // OPTIMAL
        case (.sombre, .contraste):
            bonusLuminosite = 8
        case (.sombre, .flashy):
            bonusLuminosite = 5
        case (.sombre, .naturel):
            bonusLuminosite = 3
            
        // ✅ NOUVEAU : LUMINOSITÉ NUIT
        case (.nuit, .sombre):
            bonusLuminosite = 10  // OPTIMAL
        case (.nuit, .contraste):
            bonusLuminosite = 9
        case (.nuit, .flashy):
            bonusLuminosite = 7
        case (.nuit, .naturel):
            bonusLuminosite = 4
        }
        
        // 2. Turbidité (10 points max)
        switch (conditions.turbiditeEau, contraste) {
        case (.claire, .naturel):
            bonusTurbidite = 10
        case (.claire, .contraste):
            bonusTurbidite = 7
        case (.claire, .flashy):
            bonusTurbidite = 5
        case (.claire, .sombre):
            bonusTurbidite = 4
            
        case (.legerementTrouble, .flashy):
            bonusTurbidite = 10
        case (.legerementTrouble, .contraste):
            bonusTurbidite = 8
        case (.legerementTrouble, .naturel):
            bonusTurbidite = 6
        case (.legerementTrouble, .sombre):
            bonusTurbidite = 7
            
        case (.trouble, .sombre):
            bonusTurbidite = 10
        case (.trouble, .contraste):
            bonusTurbidite = 9
        case (.trouble, .flashy):
            bonusTurbidite = 8
        case (.trouble, .naturel):
            bonusTurbidite = 3
            
        case (.tresTrouble, .flashy):
            bonusTurbidite = 10
        case (.tresTrouble, .sombre):
            bonusTurbidite = 9
        case (.tresTrouble, .contraste):
            bonusTurbidite = 7
        case (.tresTrouble, .naturel):
            bonusTurbidite = 2
        }
        
        // 3. Bonus contraste spécifique (10 points max)
        if conditions.turbiditeEau == .tresTrouble &&
           (leurre.couleurPrincipale == .chartreuse || leurre.couleurPrincipale == .jauneFluo) {
            bonusContraste = 10
        }
        else if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            if leurre.couleurPrincipale == .roseFuchsia || leurre.couleurPrincipale == .roseFluo {
                bonusContraste = 10
            } else if contraste == .flashy {
                bonusContraste = 7
            } else {
                bonusContraste = 4
            }
        }
        else if conditions.turbiditeEau == .claire &&
                (leurre.couleurPrincipale == .argente ||
                 leurre.couleurPrincipale == .bleuArgente ||
                 leurre.couleurPrincipale == .sardine) {
            bonusContraste = 10
        }
        else {
            bonusContraste = 5
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
        if let conditionsOpt = leurre.conditionsOptimales,
           let moments = conditionsOpt.moments,
           moments.contains(conditions.momentJournee) {
            switch conditions.momentJournee {
            case .aube:
                bonusMoment = 10
            case .crepuscule:
                bonusMoment = 10
            case .matinee:
                bonusMoment = 8
            case .apresMidi:
                bonusMoment = 6
            case .midi:
                bonusMoment = 4
            case .nuit:
                bonusMoment = 3
            }
        } else {
            bonusMoment = 2
        }
        
        // 2. État de la mer (8 points max)
        if let conditionsOpt = leurre.conditionsOptimales,
           let etatsM = conditionsOpt.etatMer,
           etatsM.contains(conditions.etatMer) {
            switch conditions.etatMer {
            case .calme:
                bonusMer = 8
            case .peuAgitee:
                bonusMer = 7
            case .agitee:
                bonusMer = 8
            case .formee:
                bonusMer = 7
            }
        } else {
            bonusMer = 3
        }
        
        // 3. Marée (6 points max)
        if let conditionsOpt = leurre.conditionsOptimales,
           let marees = conditionsOpt.maree,
           marees.contains(conditions.typeMaree) {
            switch conditions.typeMaree {
            case .montante:
                bonusMaree = 6
            case .descendante:
                bonusMaree = 5
            case .etale:
                bonusMaree = 4
            }
        } else {
            bonusMaree = 2
        }
        
        // Bonus marée descendante + eau trouble
        if conditions.typeMaree == .descendante &&
           (conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble) {
            if let contraste = leurre.contraste {
                if contraste == .sombre || contraste == .flashy {
                    bonusMaree += 2
                }
            }
        }
        
        // 4. Phase lunaire (6 points max)
        if let conditionsOpt = leurre.conditionsOptimales,
           let phases = conditionsOpt.phasesLunaires,
           phases.contains(conditions.phaseLunaire) {
            switch conditions.phaseLunaire {
            case .pleineLune:
                bonusLune = 6
            case .nouvelleLune:
                bonusLune = 6
            case .premierQuartier, .dernierQuartier:
                bonusLune = 5
            }
        } else {
            bonusLune = 2
        }
        
        // 5. Multiplicateurs contextuels
        if conditions.momentJournee == .aube &&
           conditions.typeMaree == .montante &&
           conditions.phaseLunaire == .nouvelleLune {
            multiplicateur = 1.3
        }
        else if conditions.momentJournee == .crepuscule &&
                conditions.etatMer == .calme &&
                conditions.phaseLunaire == .pleineLune {
            multiplicateur = 1.2
        }
        else if conditions.momentJournee == .midi &&
                (conditions.etatMer == .agitee || conditions.etatMer == .formee) {
            multiplicateur = 0.8
        }
        
        let scoreBase = bonusMoment + bonusMer + bonusMaree + bonusLune
        let total = scoreBase * multiplicateur
        
        return (bonusMoment, bonusMer, bonusMaree, bonusLune, multiplicateur, total)
    }
    
    // MARK: - Génération Justifications EXPERTES
    
    private func genererJustificationsExpertes(
        leurre: Leurre,
        conditions: ConditionsPeche,
        scoreTechnique: (compatibiliteZone: Double, compatibiliteProfondeur: Double, compatibiliteVitesse: Double, compatibiliteEspeces: Double, totalTechnique: Double),
        scoreCouleur: (bonusLuminosite: Double, bonusTurbidite: Double, bonusContraste: Double, totalCouleur: Double),
        scoreConditions: (bonusMoment: Double, bonusMer: Double, bonusMaree: Double, bonusLune: Double, multiplicateurContextuel: Double, totalConditions: Double),
        probabilitePrise: Double
    ) -> (technique: String, couleur: String, conditions: String, astuce: String) {
        
        // JUSTIFICATION TECHNIQUE
        var justifTechnique = "✅ Je recommande ce leurre car "
        justifTechnique += "sa taille de \(Int(leurre.longueur))cm est idéale pour le \(conditions.zone.displayName). "
        
        if let profMin = leurre.profondeurNageMin,
           let profMax = leurre.profondeurNageMax {
            justifTechnique += "Il nage entre \(Int(profMin))-\(Int(profMax))m, "
            
            // ⚠️ CORRECTION : Expliquer l'adéquation avec espèce/zone, pas avec profondeur d'eau
            if let espece = conditions.especePrioritaire {
                justifTechnique += "parfait pour cibler \(espece.displayName) dans cette couche d'eau. "
            } else {
                justifTechnique += "une profondeur adaptée à cette zone. "
            }
        }
        
        if let vitesseMin = leurre.vitesseTraineMin,
           let vitesseMax = leurre.vitesseTraineMax {
            justifTechnique += "Sa plage de vitesse (\(Int(vitesseMin))-\(Int(vitesseMax)) nœuds) "
            justifTechnique += "correspond à votre allure de \(Int(conditions.vitesseBateau)) nœuds."
        }
        
        // JUSTIFICATION COULEUR
        var justifCouleur = ""
        
        if let contraste = leurre.contraste {
            switch conditions.luminosite {
            case .forte:
                if contraste == .naturel {
                    justifCouleur = "🎨 Couleur OPTIMALE : En pleine lumière, les teintes naturelles imitent parfaitement les proies. "
                } else {
                    justifCouleur = "🎨 Avec une luminosité forte, ce leurre reste visible mais une teinte naturelle serait encore plus efficace. "
                }
                
            case .diffuse:
                if contraste == .contraste || contraste == .flashy {
                    justifCouleur = "🎨 Couleur IDÉALE : Luminosité diffuse = contraste maximum. Votre leurre sera parfaitement détectable. "
                } else {
                    justifCouleur = "🎨 Luminosité diffuse présente, mais un contraste plus marqué améliorerait la visibilité. "
                }
                
            case .faible:
                if contraste == .sombre || contraste == .contraste {
                    justifCouleur = "🎨 PARFAIT : Faible luminosité exige des silhouettes sombres marquées. Ce leurre crée l'ombre idéale. "
                } else {
                    justifCouleur = "🎨 Avec peu de lumière, privilégiez des contrastes plus sombres pour une meilleure silhouette. "
                }
                
            case .sombre:
                if contraste == .sombre {
                    justifCouleur = "🎨 CHAMPION : Conditions sombres = leurre sombre. La silhouette se découpe parfaitement contre le ciel. "
                } else {
                    justifCouleur = "🎨 En conditions sombres, un leurre plus sombre créerait une meilleure silhouette. "
                }
                
            case .nuit:
                if contraste == .sombre {
                    justifCouleur = "🎨 EXPERT : Pêche de nuit réussie avec des tons sombres qui créent une ombre visible pour les prédateurs. "
                } else {
                    justifCouleur = "🎨 La nuit, privilégiez toujours des leurres sombres pour maximiser la silhouette. "
                }
            }
        }
        
        // Turbidité
        if conditions.turbiditeEau == .tresTrouble {
            if leurre.couleurPrincipale == .chartreuse || leurre.couleurPrincipale == .jauneFluo {
                justifCouleur += "💡 Eau très trouble : votre jaune/chartreuse sera ultra-visible !"
            } else if let contraste = leurre.contraste, contraste == .flashy {
                justifCouleur += "⚡️ Flashy parfait pour percer la turbidité."
            }
        } else if conditions.turbiditeEau == .claire {
            if leurre.couleurPrincipale == .argente || leurre.couleurPrincipale == .bleuArgente {
                justifCouleur += "✨ Eau claire + argenté = imitation parfaite des bancs de poissons."
            }
        }
        
        // JUSTIFICATION CONDITIONS
        var justifConditions = ""
        
        if scoreConditions.multiplicateurContextuel > 1.0 {
            justifConditions = "🌟 CONDITIONS EXCEPTIONNELLES : "
            
            if conditions.momentJournee == .aube && conditions.typeMaree == .montante {
                justifConditions += "Aube + marée montante = combo gagnant ! Les poissons chassent activement. "
            } else if conditions.momentJournee == .crepuscule && conditions.etatMer == .calme {
                justifConditions += "Crépuscule calme = moment magique. Activité maximale des prédateurs. "
            }
            
            if conditions.phaseLunaire == .pleineLune || conditions.phaseLunaire == .nouvelleLune {
                justifConditions += "Phase lunaire idéale pour déclencher les attaques."
            }
        } else {
            // Conditions standards
            justifConditions = "📊 Conditions \(conditions.momentJournee.displayName.lowercased()) "
            justifConditions += "avec mer \(conditions.etatMer.displayName.lowercased()). "
            
            if conditions.typeMaree == .montante {
                justifConditions += "Marée montante favorable. "
            }
            
            if conditions.typeMaree == .descendante &&
               (conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble) {
                justifConditions += "Marée descendante + eau trouble = bonne configuration pour leurres contrastés."
            }
        }
        
        // ASTUCE PRO
        var astucePro = ""
        
        if probabilitePrise >= 80 {
            astucePro = "🏆 CONFIGURATION ELITE : "
            
            if leurre.typeLeurre == .poissonNageur {
                astucePro += "Variez la vitesse par petites secousses pour simuler un poisson blessé. "
            } else if leurre.typeLeurre == .cuiller {
                astucePro += "Les cuillers sont parfaites pour couvrir du terrain - maintenez cette vitesse. "
            } else if leurre.typeLeurre == .leurreAJupe {
                astucePro += "Les leurres à jupe créent des bulles et vibrations irrésistibles. Maintenez une vitesse constante. "
            }
            
            astucePro += "Changez de position toutes les 15min si pas de touche."
            
        } else if probabilitePrise >= 65 {
            astucePro = "💪 BON POTENTIEL : "
            
            if conditions.etatMer == .agitee || conditions.etatMer == .formee {
                astucePro += "Mer agitée = augmentez légèrement la vitesse et privilégiez les leurres lourds. "
            }
            
            if conditions.turbiditeEau == .tresTrouble {
                astucePro += "Eau trouble : ralentissez et passez près des structures. "
            }
            
            astucePro += "Testez différentes profondeurs si pas de résultat immédiat."
            
        } else {
            astucePro = "🎯 CONDITIONS MOYENNES : "
            astucePro += "Soyez patient et essayez plusieurs leurres de couleurs différentes. "
            
            if conditions.momentJournee == .midi {
                astucePro += "Midi = période calme, privilégiez les bordures et structures. "
            }
            
            astucePro += "Changez de zone si pas de résultat après 30min."
        }
        
        return (justifTechnique, justifCouleur, justifConditions, astucePro)
    }
    
    // MARK: - 🎣 PHASE 4 : GÉNÉRATION DU SPREAD
    
    // MARK: - Calcul dynamique des distances selon profil bateau et conditions
    
    /// Convertit waves en mètres (arrondi par excès)
    private func wavesVersMètres(_ waves: Double) -> Int {
        return Int(ceil(waves * 7.5))
    }
    
    /// Vérifie si le shotgun est autorisé selon profil et conditions
    private func shotgunAutorise(profil: ProfilBateau, vitesse: Double, profondeur: Double, zone: CategoriePeche) -> Bool {
        // Clark 4,29 m : conditions strictes
        if profil == .clark429 {
            return vitesse >= 6.5 && profondeur > 20 && (zone == .passe || zone == .large || zone == .profond || zone == .dcp)
        }
        
        // Classique : toujours autorisé si 5 lignes demandées
        return true
    }
    
    /// Calcule les distances dynamiques pour chaque position selon conditions
    private func calculerDistancesDynamiques(conditions: ConditionsPeche) -> [PositionSpread: Int] {
        let profil = conditions.profilBateau
        let vitesse = conditions.vitesseBateau
        let zone = conditions.zone
        let especePrioritaire = conditions.especePrioritaire
        
        // Presets de base par espèce (en waves)
        var distancesBase: [PositionSpread: Double]
        
        if let espece = especePrioritaire {
            switch espece {
            case .thazard:
                distancesBase = [
                    .shortCorner: 1.2,
                    .longCorner: 2.2,
                    .shortRigger: 2.8,
                    .longRigger: 3.2,
                    .shotgun: 4.5
                ]
            case .wahoo:
                distancesBase = [
                    .shortCorner: 1.5,
                    .longCorner: 2.8,
                    .shortRigger: 3.6,
                    .longRigger: 4.2,
                    .shotgun: 5.5
                ]
            case .carangueGT:
                distancesBase = [
                    .shortCorner: 1.0,
                    .longCorner: 2.0,
                    .shortRigger: 2.4,
                    .longRigger: 3.0,
                    .shotgun: 0  // non recommandé
                ]
            case .loche:
                distancesBase = [
                    .shortCorner: 0.9,
                    .longCorner: 1.7,
                    .shortRigger: 2.2,
                    .longRigger: 2.8,
                    .shotgun: 0  // non recommandé
                ]
            case .thonJaune:
                distancesBase = [
                    .shortCorner: 1.3,
                    .longCorner: 2.4,
                    .shortRigger: 3.2,
                    .longRigger: 3.8,
                    .shotgun: 5.5
                ]
            case .mahiMahi:
                distancesBase = [
                    .shortCorner: 1.0,
                    .longCorner: 2.0,
                    .shortRigger: 2.6,
                    .longRigger: 3.2,
                    .shotgun: 4.5
                ]
            case .bonite:
                distancesBase = [
                    .shortCorner: 1.1,
                    .longCorner: 2.1,
                    .shortRigger: 2.7,
                    .longRigger: 3.2,
                    .shotgun: 5.0
                ]
            default:
                // Mix (défaut)
                distancesBase = [
                    .shortCorner: 1.0,
                    .longCorner: 2.0,
                    .shortRigger: 2.8,
                    .longRigger: 3.5,
                    .shotgun: 5.0
                ]
            }
        } else {
            // Mix (défaut)
            distancesBase = [
                .shortCorner: 1.0,
                .longCorner: 2.0,
                .shortRigger: 2.8,
                .longRigger: 3.5,
                .shotgun: 5.0
            ]
        }
        
        // Coefficients d'ajustement selon vitesse (par nœud d'écart)
        let coefficientsVitesse: [PositionSpread: Double] = [
            .shortCorner: 0.20,
            .longCorner: 0.20,
            .shortRigger: 0.30,
            .longRigger: 0.30,
            .shotgun: 0.40
        ]
        
        // Ajustement selon vitesse
        let vitesseReference = profil.vitesseReference
        let ecartVitesse = vitesse - vitesseReference
        
        var distancesAjustees: [PositionSpread: Double] = [:]
        for (position, distanceBase) in distancesBase {
            let coeff = coefficientsVitesse[position] ?? 0
            distancesAjustees[position] = distanceBase + (ecartVitesse * coeff)
        }
        
        // Ajustements selon conditions
        
        // Mer formée : raccourcir toutes positions
        if conditions.etatMer == .formee || conditions.etatMer == .agitee {
            for position in distancesAjustees.keys {
                distancesAjustees[position]! -= 0.4
            }
        }
        
        // Eau très claire : allonger riggers
        if conditions.turbiditeEau == .claire {
            distancesAjustees[.shortRigger]? += 0.3
            distancesAjustees[.longRigger]? += 0.3
        }
        
        // Eau trouble : raccourcir toutes positions
        if conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble {
            for position in distancesAjustees.keys {
                distancesAjustees[position]! -= 0.3
            }
        }
        
        // Zone lagon : raccourcir
        if zone == .lagon {
            for position in distancesAjustees.keys {
                distancesAjustees[position]! -= 0.3
            }
        }
        
        // Garde-fous : bornes min/max selon profil
        let bornes: [PositionSpread: (min: Double, max: Double)]
        
        if profil == .clark429 {
            bornes = [
                .shortCorner: (0.8, 2.0),
                .longCorner: (1.5, 3.0),
                .shortRigger: (2.0, 4.0),
                .longRigger: (2.5, 4.5),
                .shotgun: (4.0, 5.0)
            ]
        } else {
            bornes = [
                .shortCorner: (1.0, 3.0),
                .longCorner: (2.0, 4.0),
                .shortRigger: (3.0, 6.0),
                .longRigger: (4.0, 7.0),
                .shotgun: (5.0, 9.0)
            ]
        }
        
        // Appliquer bornes
        for (position, (min, max)) in bornes {
            if let d = distancesAjustees[position] {
                distancesAjustees[position] = Swift.max(min, Swift.min(max, d))
            }
        }
        
        // Ordre strict : shortCorner < longCorner < shortRigger < longRigger < shotgun
        let ordre: [PositionSpread] = [.shortCorner, .longCorner, .shortRigger, .longRigger, .shotgun]
        for i in 1..<ordre.count {
            if let current = distancesAjustees[ordre[i]], let previous = distancesAjustees[ordre[i-1]] {
                if current <= previous {
                    distancesAjustees[ordre[i]] = previous + 0.5
                }
            }
        }
        
        // Shotgun jamais < Long Rigger + 0.7 wave
        if let shotgun = distancesAjustees[.shotgun], let longRigger = distancesAjustees[.longRigger] {
            if shotgun < longRigger + 0.7 {
                distancesAjustees[.shotgun] = longRigger + 0.7
            }
        }
        
        // Conversion en mètres
        var distancesMetres: [PositionSpread: Int] = [:]
        for (position, waves) in distancesAjustees {
            distancesMetres[position] = wavesVersMètres(waves)
        }
        
        // Position libre : moyenne des autres
        if !distancesMetres.isEmpty {
            let moyenne = distancesMetres.values.reduce(0, +) / distancesMetres.count
            distancesMetres[.libre] = moyenne
        }
        
        return distancesMetres
    }
    
    // MARK: - Diversification "Toutes Espèces"
    
    /// Réorganise les suggestions pour maximiser la diversité d'espèces en mode "toutes espèces"
    private func diversifierSpreadPourToutesEspeces(
        suggestions: [SuggestionResult],
        nombreLignes: Int
    ) -> [SuggestionResult] {
        
        var resultat: [SuggestionResult] = []
        var suggestionsRestantes = suggestions
        var especesDejaPresentes: Set<String> = []
        
        // Phase 1 : Sélectionner les leurres avec des espèces cibles différentes
        for _ in 0..<nombreLignes {
            guard !suggestionsRestantes.isEmpty else { break }
            
            // Chercher le meilleur leurre qui ajoute de nouvelles espèces
            var meilleurIndex = 0
            var meilleurScore = -1.0
            var meilleuresNouvellesEspeces = 0
            
            for (index, suggestion) in suggestionsRestantes.enumerated() {
                let especesCibles = Set(suggestion.leurre.especesCibles ?? [])
                let nouvellesEspeces = especesCibles.subtracting(especesDejaPresentes)
                
                // Critères de sélection :
                // 1. Priorité : ajouter de nouvelles espèces
                // 2. Secondaire : maintenir un bon score global
                let facteurDiversite = Double(nouvellesEspeces.count) * 15.0  // Bonus important
                let scoreAjuste = suggestion.scoreTotal + facteurDiversite
                
                if nouvellesEspeces.count > meilleuresNouvellesEspeces ||
                   (nouvellesEspeces.count == meilleuresNouvellesEspeces && scoreAjuste > meilleurScore) {
                    meilleurIndex = index
                    meilleurScore = scoreAjuste
                    meilleuresNouvellesEspeces = nouvellesEspeces.count
                }
            }
            
            // Ajouter le leurre sélectionné
            let suggestionSelectionnee = suggestionsRestantes.remove(at: meilleurIndex)
            resultat.append(suggestionSelectionnee)
            
            // Mettre à jour les espèces déjà couvertes
            if let especes = suggestionSelectionnee.leurre.especesCibles {
                especesDejaPresentes.formUnion(especes)
            }
        }
        
        // Phase 2 : Compléter avec les meilleurs scores restants si nécessaire
        while resultat.count < nombreLignes && !suggestionsRestantes.isEmpty {
            resultat.append(suggestionsRestantes.removeFirst())
        }
        
        return resultat
    }

    private func genererSpread(
        suggestions: [SuggestionResult],
        conditions: ConditionsPeche,
        vitesseReco: VitesseRecommandation? = nil
    ) -> ConfigurationSpread {
        
        let nombreLignes = min(conditions.nombreLignes, suggestions.count)
        var suggestionsAvecPosition: [SuggestionResult] = []
        
        // ⚠️ MODE "TOUTES ESPÈCES" : Optimiser la diversité du spread
        var suggestionsPourSpread = suggestions
        if conditions.especePrioritaire == nil && nombreLignes >= 3 {
            // Réorganiser pour maximiser la diversité d'espèces cibles
            suggestionsPourSpread = diversifierSpreadPourToutesEspeces(
                suggestions: suggestions,
                nombreLignes: nombreLignes
            )
        }
        
        // Positions disponibles selon nombre de lignes
        var positionsDisponibles: [PositionSpread] = {
            switch nombreLignes {
            case 1: return [.libre]
            case 2: return [.shortCorner, .shortRigger]
            case 3: return [.shortCorner, .longCorner, .shortRigger]
            case 4: return [.shortCorner, .longCorner, .shortRigger, .longRigger]
            default: return [.shortCorner, .longCorner, .shortRigger, .longRigger, .shotgun]
            }
        }()
        
        // Vérifier si shotgun autorisé pour profil Clark 4,29 m
        if conditions.profilBateau == .clark429 && positionsDisponibles.contains(.shotgun) {
            if !shotgunAutorise(
                profil: conditions.profilBateau,
                vitesse: conditions.vitesseBateau,
                profondeur: conditions.profondeurCible,
                zone: conditions.zone
            ) {
                // Retirer shotgun et limiter à 4 lignes
                positionsDisponibles.removeAll { $0 == .shotgun }
            }
        }
        
        // Calcul dynamique des distances
        let distancesDynamiques = calculerDistancesDynamiques(conditions: conditions)
        
        // Attribution des positions
        for (index, position) in positionsDisponibles.enumerated() {
            guard index < suggestionsPourSpread.count else { break }
            
            var suggestion = suggestionsPourSpread[index]
            suggestion.positionSpread = position
            suggestion.distanceSpread = distancesDynamiques[position] ?? 20
            
            // Justification position
            let distance = distancesDynamiques[position] ?? 20
            var justifPosition = ""
            
            switch position {
            case .libre:
                justifPosition = "Position LIBRE (\(distance)m) : "
                justifPosition += "Meilleur leurre en position flexible. "
                
            case .shortCorner:
                justifPosition = "Position SHORT CORNER (\(distance)m) : "
                justifPosition += "Agressif, naturel, dans les bulles du sillage. "
                
            case .longCorner:
                justifPosition = "Position LONG CORNER (\(distance)m) : "
                justifPosition += "Sombre, silhouette visible par en-dessous. "
                
            case .shortRigger:
                justifPosition = "Position SHORT RIGGER (\(distance)m) : "
                justifPosition += "Flashy, attracteur latéral sur tangon. "
                
            case .longRigger:
                justifPosition = "Position LONG RIGGER (\(distance)m) : "
                justifPosition += "Flashy, couleur différente sur tangon opposé. "
                
            case .shotgun:
                justifPosition = "Position SHOTGUN (\(distance)m) : "
                justifPosition += "Discret, fort contraste, très loin en position centrale. "
            }
            
            suggestion.justificationPosition = justifPosition
            suggestionsAvecPosition.append(suggestion)
        }
        
        // Analyse du spread
        let analyseSpread = genererAnalyseSpread(
            suggestions: suggestionsAvecPosition,
            conditions: conditions
        )
        
        // Calcul distance moyenne depuis les positions attribuées
        let distanceMoyenne: Double
        if !suggestionsAvecPosition.isEmpty {
            let totalDistances = suggestionsAvecPosition.compactMap { $0.distanceSpread }.reduce(0, +)
            distanceMoyenne = Double(totalDistances) / Double(suggestionsAvecPosition.count)
        } else {
            distanceMoyenne = 0
        }
        
        // Calcul de la vitesse recommandée enrichie
        let vitesseInfo = vitesseReco ?? SuggestionEngine.calculerVitesseRecommandee(
            especePrioritaire: conditions.especePrioritaire,
            profilBateau: conditions.profilBateau,
            zone: conditions.zone,
            etatMer: conditions.etatMer,
            turbidite: conditions.turbiditeEau,
            momentJournee: conditions.momentJournee
        )
        
        return ConfigurationSpread(
            suggestions: suggestionsAvecPosition,
            nombreLignes: nombreLignes,
            distanceMoyenne: distanceMoyenne,
            analyseSpread: analyseSpread,
            vitesseRecommandee: vitesseInfo.vitesseRecommandee,
            vitessePlageMin: vitesseInfo.plageMin,
            vitessePlageMax: vitesseInfo.plageMax,
            justificationVitesse: vitesseInfo.justification,
            ajustementsVitesse: vitesseInfo.ajustements
        )
    }
    private func genererAnalyseSpread(
            suggestions: [SuggestionResult],
            conditions: ConditionsPeche
        ) -> String {
            
            var analyse = "📐 ANALYSE DU SPREAD\n\n"
            
            // Diversité des couleurs
            let couleurs = Set(suggestions.compactMap { $0.leurre.couleurPrincipale })
            analyse += "🎨 Diversité couleurs : \(couleurs.count) teintes différentes\n"
            
            if couleurs.count == suggestions.count {
                analyse += "   ✅ Excellent ! Chaque leurre a une couleur unique.\n\n"
            } else {
                analyse += "   ⚠️ Certaines couleurs se répètent.\n\n"
            }
            
            // Diversité des tailles
            let tailles = suggestions.map { $0.leurre.longueur }
            let tailleMin = tailles.min() ?? 0
            let tailleMax = tailles.max() ?? 0
            
            analyse += "📏 Tailles : \(Int(tailleMin))-\(Int(tailleMax))cm\n"
            
            if tailleMax - tailleMin >= 5 {
                analyse += "   ✅ Bonne variation de tailles pour cibler différents poissons.\n\n"
            } else {
                analyse += "   ℹ️ Tailles similaires - cible homogène.\n\n"
            }
            
            // Profondeurs
            let profondeurs = suggestions.compactMap { $0.leurre.profondeurNageMax }
            if !profondeurs.isEmpty {
                let profMin = profondeurs.min() ?? 0
                let profMax = profondeurs.max() ?? 0
                
                analyse += "🌊 Profondeurs couvertes : \(Int(profMin))-\(Int(profMax))m\n"
                
                if profMax - profMin >= 3 {
                    analyse += "   ✅ Excellente couverture verticale.\n\n"
                } else {
                    analyse += "   ℹ️ Tous les leurres nagent à profondeur similaire.\n\n"
                }
            }
            
            // Recommandation finale
            analyse += "💡 CONSEIL PRO :\n"
            
            if suggestions.count >= 3 {
                analyse += "Configuration complète. Surveillez d'abord le leurre central, "
                analyse += "puis ajustez selon les touches."
            } else {
                analyse += "Avec \(suggestions.count) ligne(s), concentrez-vous sur les meilleures positions."
            }
            
            return analyse
        }
    
    // MARK: - 📊 ANALYSE GLOBALE DES CONDITIONS
    
    private func genererAnalyseGlobale(
        conditions: ConditionsPeche,
        suggestions: [SuggestionResult]
    ) -> String {
        
        var analyse = "🎣 ANALYSE GLOBALE DES CONDITIONS\n\n"
        
        // 1. Évaluation générale
        let scoresMoyens = suggestions.prefix(3).map { $0.scoreTotal }.reduce(0, +) / Double(min(3, suggestions.count))
        
        analyse += "📊 Qualité globale : "
        
        if scoresMoyens >= 80 {
            analyse += "EXCELLENTE ⭐️⭐️⭐️\n"
            analyse += "Conditions idéales pour une session productive !\n\n"
        } else if scoresMoyens >= 70 {
            analyse += "TRÈS BONNE ⭐️⭐️\n"
            analyse += "Bonnes conditions, résultats attendus.\n\n"
        } else if scoresMoyens >= 60 {
            analyse += "CORRECTE ⭐️\n"
            analyse += "Conditions acceptables, soyez patient.\n\n"
        } else {
            analyse += "MOYENNE\n"
            analyse += "Conditions moyennes, essayez plusieurs leurres.\n\n"
        }
        
        // 2. Points forts
        analyse += "✅ POINTS FORTS :\n"
        
        if conditions.momentJournee == .aube || conditions.momentJournee == .crepuscule {
            analyse += "• Moment optimal (aube/crépuscule) - activité maximale\n"
        }
        
        if conditions.typeMaree == .montante {
            analyse += "• Marée montante - poissons actifs\n"
        }
        
        if conditions.etatMer == .calme || conditions.etatMer == .peuAgitee {
            analyse += "• Mer calme - conditions confortables\n"
        }
        
        if conditions.phaseLunaire == .pleineLune || conditions.phaseLunaire == .nouvelleLune {
            analyse += "• Phase lunaire favorable\n"
        }
        
        analyse += "\n"
        
        // 3. Points d'attention
        let avertissements = conditions.avertissementsCoherence()
        if !avertissements.isEmpty {
            analyse += "⚠️ POINTS D'ATTENTION :\n"
            for avert in avertissements {
                analyse += "• \(avert)\n"
            }
            analyse += "\n"
        }
        
        // 4. Recommandations tactiques
        analyse += "🎯 TACTIQUES RECOMMANDÉES :\n"
        
        if conditions.zone == .lagon {
            analyse += "• Passez près des structures (coraux, herbiers)\n"
            analyse += "• Variez les vitesses (5-7 nœuds)\n"
        } else if conditions.zone == .large || conditions.zone == .profond {
            analyse += "• Cherchez les oiseaux et chasses\n"
            analyse += "• Maintenez une vitesse constante\n"
        }
        
        if conditions.turbiditeEau == .trouble || conditions.turbiditeEau == .tresTrouble {
            analyse += "• Eau trouble : ralentissez légèrement\n"
            analyse += "• Privilégiez les leurres contrastés/flashy\n"
        }
        
        if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            analyse += "• Mer formée : augmentez légèrement la vitesse\n"
            analyse += "• Utilisez des leurres plus lourds\n"
        }
        
        return analyse
    }
}
  
