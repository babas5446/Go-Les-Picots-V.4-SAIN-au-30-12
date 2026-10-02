//
//  SuggestionEngine.swift
//  Go les Picots - Module 2 : Suggestion IA
//
//  VERSION FINALE avec :
//  ✅ Tout le code validé du SuggestionEngine.swift original
//  ➕ Probabilités de prise (30-95%)
//  ➕ Justifications "niveau champion"
//  ➕ Analyse globale des conditions
//  ✅ Support complet Luminosité : forte, diffuse, faible, sombre, nuit
//
//  Created: 2024-12-08
//  Updated: 2024-12-12 - Corrections des erreurs de compilation
//  Updated: session 4 - Isolation MainActor de l'accès aux données SwiftData.
//                       Le scoring, les pondérations et les seuils sont inchangés.
//

import Foundation
import Combine

@MainActor
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
    let BoiteLeurresViewModel: BoiteLeurresViewModel
    var nombreLeurres: Int { BoiteLeurresViewModel.tousLesLeurres.count }

    nonisolated init(BoiteLeurresViewModel: BoiteLeurresViewModel) {
        self.BoiteLeurresViewModel = BoiteLeurresViewModel
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

    /// Structure de recommandation de vitesse enrichie
    struct VitesseRecommandation {
        let vitesseRecommandee: Double
        let plageMin: Double
        let plageMax: Double
        let justification: String
        let ajustements: [String]
    }

    // MARK: - 🚤 CALCUL VITESSE RECOMMANDÉE

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

        // Garde-fou : un second appui pendant un calcul en cours est ignoré.
        guard !isProcessing else {
            print("⚠️ Génération déjà en cours — appel ignoré")
            return
        }

        isProcessing = true
        errorMessage = nil
        suggestions = []
        progressMessage = "Validation des conditions..."

        // Validation
        let (valide, erreur) = conditions.estValide()
        guard valide else {
            errorMessage = erreur
            isProcessing = false
            progressMessage = ""
            return
        }

        // Tout le pipeline s'exécute sur la file principale : les propriétés
        // persistées de Leurre ne peuvent être lues que depuis le mainContext.
        // Les Task.yield() rendent la main à SwiftUI entre les phases pour que
        // l'overlay de progression reste visible.
        Task { @MainActor in

            await Task.yield()

            // Lagon, platier et pâtés, passes : moteur dédié (MoteurLagon.swift).
            if SuggestionEngine.moteurLagonApplicable(conditions) {
                self.progressMessage = "Moteur lagon : vitesse, étages et postes..."
                await Task.yield()
                self.executerMoteurLagon(conditions: conditions)
                return
            }

            self.progressMessage = "Phase 1 : Filtrage technique..."
            await Task.yield()

            // PHASE 1 : Filtrage Technique (40%)
            let leuresCompatibles = self.filtrerLeuresCompatibles(
                conditions: conditions,
                tousLeurres: self.BoiteLeurresViewModel.tousLesLeurres
            )

            guard !leuresCompatibles.isEmpty else {
                self.errorMessage = "❌ Aucun leurre compatible trouvé pour ces conditions.\n\nSuggestions :\n• Réduire la vitesse\n• Changer de zone\n• Vérifier la profondeur"
                self.isProcessing = false
                self.progressMessage = ""
                return
            }

            self.progressMessage = "Phase 2-3 : Calcul des scores (\(leuresCompatibles.count) leurres)..."
            await Task.yield()

            // PHASE 2-3 : Scoring
            let resultats = leuresCompatibles.map { leurre in
                self.calculerScore(leurre: leurre, conditions: conditions)
            }

            // Tri par score décroissant
            let resultatsTriees = resultats
                .filter { $0.scoreTotal >= 50 }  // Seuil minimum
                .sorted { $0.scoreTotal > $1.scoreTotal }

            guard !resultatsTriees.isEmpty else {
                self.errorMessage = "❌ Aucun leurre n'atteint le score minimum (50/100).\n\nEssayez de modifier les conditions."
                self.isProcessing = false
                self.progressMessage = ""
                return
            }

            self.progressMessage = "Phase 4 : Génération du spread..."
            await Task.yield()

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

            self.suggestions = resultatsTriees
            self.configurationSpread = spreadConfig
            self.analyseGlobale = analyse
            self.isProcessing = false
            self.progressMessage = ""
            self.shouldShowResults = true
            print("✅ \(resultatsTriees.count) suggestions générées (\(spreadConfig.suggestions.count) dans le spread)")
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
            guard leurre.estLeurreDeTraine else {
                return false
            }

            // 0.1 🔒 DOUBLE VÉRIFICATION : Exclure explicitement les leurres de lancer
            // Même si mal configurés dans la base de données
            let typesLancerInterdits: [TypeLeurre] = [
                .popper,
                .stickbait,
                .stickbaitFlottant,
                .stickbaitCoulant,
                .jigMetallique,
                .jigStickbait,
                .jigStickbaitCoulant,
                .jigVibrant,
                .madai,
                .inchiku
            ]
            if typesLancerInterdits.contains(leurre.typeLeurre) {
                return false
            }

            // 0.2 🔒 TRIPLE VÉRIFICATION : Exclure si technique principale = lancer
            if leurre.typePeche == .lancer {
                return false
            }

            // 1. RÈGLES D'ÉLIMINATION ABSOLUES

            // ⚠️ CORRECTION : Poppers et Jigs doivent être exclus même si mal configurés

            // Wahoo = haute vitesse obligatoire
            if conditions.especePrioritaire == .wahoo {
                if let vitesseMax = leurre.vitesseTraineMax, vitesseMax < 10 {
                    return false
                }
            }

            // 2. COMPATIBILITÉ ZONE (critère principal)
            // ✅ UTILISATION DES VALEURS FINALES (JSON > Notes > Déduction auto)
            let zonesAdaptees = leurre.zonesAdapteesFinales
            guard !zonesAdaptees.isEmpty else {
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
            // ⚠️ CORRECTION : profondeurZone = profondeur d'eau (bathymétrie)
            // On élimine UNIQUEMENT les leurres qui toucheraient le fond
            // Tous les leurres dont profondeurNage < profondeurEau sont OK

            if let profMax = leurre.profondeurNageMax {
                // Éliminer si le leurre nage plus profond que l'eau disponible
                // Marge de sécurité : -2m (éviter d'accrocher le fond)
                if profMax > conditions.profondeurZone - 2 {
                    return false
                }
            }
            // Si pas de profondeurNageMax définie, on accepte le leurre

            // 4. COMPATIBILITÉ VITESSE (tolérance ±1 nœud)
            // ✅ UTILISATION DES VALEURS FINALES (JSON > Déduction auto)
            let (vitesseMin, vitesseMax) = leurre.vitessesTraineFinales

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
            // ✅ UTILISATION DES VALEURS FINALES (Notes > JSON > Déduction auto)
            let especesCibles = leurre.especesCiblesFinales
            if especesCibles.contains(espece.displayName) {
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
        // ✅ UTILISATION DES VALEURS FINALES (JSON > Notes > Déduction auto)
        let zones = leurre.zonesAdapteesFinales
        if !zones.isEmpty {
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
        // ✅ NOUVEAU : Utilisation de la profondeur déduite depuis profondeurZone
        // Le moteur compare la profondeur de nage du leurre avec la profondeur déduite optimale
        if let profMin = leurre.profondeurNageMin,
           let profMax = leurre.profondeurNageMax {

            // ✅ Utiliser la profondeur de nage déduite depuis la zone
            let (profondeurNageMin, profondeurNageMax) = conditions.profondeurNageDeduite

            // Calculer le milieu de la plage de nage du leurre
            let profondeurMoyenneLeurre = (profMin + profMax) / 2.0

            // Calculer le milieu de la plage de nage optimale pour cette zone
            let profondeurIdéale = (profondeurNageMin + profondeurNageMax) / 2.0

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
        // ✅ UTILISATION DES VALEURS FINALES (JSON > Déduction auto)
        let (vitesseMin, vitesseMax) = leurre.vitessesTraineFinales
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

        // 4. Espèces (5 points max)
        if let especeCible = conditions.especePrioritaire {
            // Mode ciblé : privilégier les leurres spécifiques
            // ✅ UTILISATION DES VALEURS FINALES (Notes > JSON > Déduction auto)
            let especesCibles = leurre.especesCiblesFinales
            if especesCibles.contains(especeCible.displayName) {
                scoreEspeces = 5
            } else {
                scoreEspeces = 1
            }
        } else {
            // ⚠️ MODE "TOUTES ESPÈCES" : Favoriser la polyvalence
            // Plus un leurre cible d'espèces différentes, plus il est intéressant
            // ✅ UTILISATION DES VALEURS FINALES
            let especesCibles = leurre.especesCiblesFinales
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
                scoreEspeces = 3.0  // Neutre (liste vide, ne devrait pas arriver avec déduction auto)
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
        // ✅ AMÉLIORATION : Utiliser les composantes RGB réelles
        let rgb = leurre.composantesRGBPrincipale
        let estJauneVert = (rgb.g > 0.7 && rgb.r > 0.4 && rgb.b < 0.3) // Jaune/chartreuse
        let estRoseFlashy = (rgb.r > 0.8 && rgb.g < 0.5 && rgb.b > 0.4) // Rose flashy
        let estArgente = (abs(rgb.r - rgb.g) < 0.2 && abs(rgb.g - rgb.b) < 0.2 && rgb.r > 0.5) // Argenté/gris clair

        if conditions.turbiditeEau == .tresTrouble && estJauneVert {
            bonusContraste = 10
        }
        else if conditions.etatMer == .agitee || conditions.etatMer == .formee {
            if estRoseFlashy {
                bonusContraste = 10
            } else if contraste == .flashy {
                bonusContraste = 7
            } else {
                bonusContraste = 4
            }
        }
        else if conditions.turbiditeEau == .claire && estArgente {
            bonusContraste = 10
        }
        else {
            bonusContraste = 5
        }

        // 4. Bonus finition selon luminosité et turbidité (0-5 points)
        var bonusFinition: Double = 0
        if let finition = leurre.finition {
            // Scoring de base selon luminosité et profondeur
            bonusFinition = finition.bonusScoring(
                luminosite: conditions.luminosite,
                profondeurMax: leurre.profondeurNageMax
            )

            // Bonus supplémentaire selon turbidité
            switch (conditions.turbiditeEau, finition) {
            case (.claire, .holographique), (.claire, .chrome), (.claire, .miroir):
                bonusFinition += 1.5  // Excellent en eau claire
            case (.claire, .paillete):
                bonusFinition += 1.0

            case (.legerementTrouble, .perlee), (.legerementTrouble, .metallique):
                bonusFinition += 1.5  // Optimal en eau légèrement trouble

            case (.trouble, .mate):
                bonusFinition += 2.0  // Mat parfait en eau trouble
            case (.tresTrouble, .mate):
                bonusFinition += 2.5  // Mat exceptionnel en eau très trouble

            case (.trouble, .UV), (.tresTrouble, .UV):
                bonusFinition += 1.0  // UV perce la turbidité

            default:
                break  // Pas de bonus supplémentaire
            }

            // Bonus état de mer (finitions résistantes aux remous)
            if conditions.etatMer == .agitee || conditions.etatMer == .formee {
                switch finition {
                case .mate, .phosphorescent:
                    bonusFinition += 1.0  // Silhouettes sombres meilleures en mer formée
                case .holographique, .miroir, .chrome:
                    bonusFinition -= 0.5  // Reflets moins efficaces en mer agitée
                default:
                    break
                }
            }
        }

        let total = bonusLuminosite + bonusTurbidite + bonusContraste + bonusFinition

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

        // ✅ UTILISATION DES VALEURS FINALES (JSON > Déduction auto)
        let (vitesseMin, vitesseMax) = leurre.vitessesTraineFinales
        justifTechnique += "Sa plage de vitesse (\(Int(vitesseMin))-\(Int(vitesseMax)) nœuds) "
        justifTechnique += "correspond à votre allure de \(Int(conditions.vitesseBateau)) nœuds."

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

        // ✨ NOUVEAU : Justification finition
        if let finition = leurre.finition {
            justifCouleur += "\n\n✨ FINITION : "

            switch (conditions.luminosite, conditions.turbiditeEau, finition) {
            // Conditions excellentes pour finitions brillantes
            case (.forte, .claire, .holographique):
                justifCouleur += "Holographique PARFAIT en eau claire et forte lumière ! Les reflets arc-en-ciel seront irrésistibles."
            case (.forte, .claire, .chrome), (.forte, .claire, .miroir):
                justifCouleur += "Finition miroir IDÉALE ! Les éclats lumineux imitent parfaitement les écailles en plein soleil."
            case (.forte, .claire, .paillete):
                justifCouleur += "Paillettes ultra-visibles en eau claire - effet scintillant maximal !"

            // Conditions optimales pour finitions discrètes
            case (.faible, .trouble, .mate), (.sombre, .trouble, .mate), (.nuit, _, .mate):
                justifCouleur += "Finition mate EXCELLENTE ! Silhouette pure sans reflets parasites, parfait pour ces conditions."
            case (.sombre, _, .phosphorescent), (.nuit, _, .phosphorescent):
                justifCouleur += "Phosphorescent CHAMPION ! Luminosité propre visible même de loin dans l'obscurité."

            // Finitions polyvalentes
            case (_, _, .metallique), (_, _, .brillante):
                justifCouleur += "Finition polyvalente adaptée à ces conditions variées."

            // Finitions spécialisées
            case (_, .legerementTrouble, .perlee):
                justifCouleur += "Nacré parfait en eau légèrement trouble - reflets subtils mais efficaces."
            case (_, .trouble, .UV), (_, .tresTrouble, .UV):
                justifCouleur += "UV stratégique en eau trouble - réaction ultraviolette perce la turbidité !"

            // Situations sous-optimales
            case (.forte, _, .mate):
                justifCouleur += "Finition mate fonctionne mais brillant serait plus efficace en forte lumière."
            case (.faible, _, .holographique), (.sombre, _, .holographique):
                justifCouleur += "Holographique moins efficace en faible lumière - privilégiez pour sessions diurnes."
            case (.nuit, _, .holographique), (.nuit, _, .chrome), (.nuit, _, .miroir):
                justifCouleur += "Finition brillante peu adaptée la nuit - silhouette sombre recommandée."

            default:
                justifCouleur += "\(finition.displayName) - \(finition.conditionsIdeales)"
            }
        }

        // Turbidité
        // ✅ AMÉLIORATION : Utiliser les composantes RGB réelles pour les justifications
        let rgbPrincipale = leurre.composantesRGBPrincipale
        let nomCouleur = leurre.couleurPrincipaleAffichage.nom
        let estJauneVertJustif = (rgbPrincipale.g > 0.7 && rgbPrincipale.r > 0.4 && rgbPrincipale.b < 0.3)
        let estArgenteJustif = (abs(rgbPrincipale.r - rgbPrincipale.g) < 0.2 && abs(rgbPrincipale.g - rgbPrincipale.b) < 0.2 && rgbPrincipale.r > 0.5)

        if conditions.turbiditeEau == .tresTrouble {
            if estJauneVertJustif {
                justifCouleur += "\n\n💡 Eau très trouble : votre \(nomCouleur) sera ultra-visible !"
            } else if let contraste = leurre.contraste, contraste == .flashy {
                justifCouleur += "\n\n⚡️ Flashy parfait pour percer la turbidité."
            }
        } else if conditions.turbiditeEau == .claire {
            if estArgenteJustif {
                justifCouleur += "\n\n✨ Eau claire + \(nomCouleur) = imitation parfaite des bancs de poissons."
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
                // ✅ UTILISATION DES VALEURS FINALES
                let especesCibles = Set(suggestion.leurre.especesCiblesFinales)
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
            // ✅ UTILISATION DES VALEURS FINALES
            let especes = suggestionSelectionnee.leurre.especesCiblesFinales
            especesDejaPresentes.formUnion(especes)
        }

        // Phase 2 : Compléter avec les meilleurs scores restants si nécessaire
        while resultat.count < nombreLignes && !suggestionsRestantes.isEmpty {
            resultat.append(suggestionsRestantes.removeFirst())
        }

        return resultat
    }

    // MARK: - 🎯 Attribution Intelligente des Positions

    /// Évalue l'adéquation d'un leurre pour chaque position du spread
    /// EN TENANT COMPTE DU CONTEXTE (turbidité, luminosité)
    ///
    /// RÈGLES DÉFINITIVES :
    /// - Short Corner : Agressif OU Naturel imitatif (grande taille/couleur naturelle)
    /// - Long Corner : Discret OU Sombre (poissons méfiants à distance)
    /// - Riggers : FLASHY (couleurs vives/fluo, attracteurs latéraux)
    /// - Shotgun : DISCRET (poissons très méfiants, loin derrière)
    private func evaluerProfilPosition(
        leurre: Leurre,
        position: PositionSpread,
        conditions: ConditionsPeche
    ) -> Double {

        var score: Double = 0

        // ✅ Utiliser le PROFIL VISUEL (déduit de couleur + finition)
        let profil = leurre.profilVisuel
        let finition = leurre.finition
        let couleur = leurre.couleurPrincipale
        let taille = leurre.longueur

        // ✅ Calculer l'efficacité contextuelle du profil
        let efficaciteContexte = profil.efficaciteDansContexte(
            turbidite: conditions.turbiditeEau,
            luminosite: conditions.luminosite
        )

        switch position {

        // SHORT CORNER : Agressif OU Naturel imitatif (dans les bulles)
        case .shortCorner:
            // Priorité 1 : NATUREL avec finitions holographiques (imitation réaliste)
            if profil == .naturel {
                score += 10  // PARFAIT

                // Bonus finitions holographiques (reflets type écailles)
                if finition == .holographique || finition == .chrome || finition == .miroir {
                    score += 4  // Reflets imitent vrai poisson
                }

                // Bonus couleurs imitatives
                // ✅ AMÉLIORATION : Analyser RGB pour identifier couleurs imitatives
                let rgb = leurre.composantesRGBPrincipale
                let estArgente = (abs(rgb.r - rgb.g) < 0.2 && abs(rgb.g - rgb.b) < 0.2 && rgb.r > 0.5)
                let estVertDore = (rgb.g > 0.6 && rgb.r > 0.3 && rgb.b < 0.4)

                if estArgente {
                    score += 5  // Imitation fourrage parfaite
                } else if estVertDore {
                    score += 3  // Bon
                }
            }

            // Priorité 2 : Grande taille (agressif)
            if taille >= 15 {
                score += 5  // Leurre agressif grande taille
            }

            // Acceptable : Contraste
            if profil == .contraste {
                score += 6
            }

            // Moins adapté : Flashy ou Sombre
            if profil == .flashy {
                score += 3  // Trop voyant pour position proche
            }
            if profil == .sombre {
                score += 2  // Pas adapté
            }

        // LONG CORNER : DISCRET OU SOMBRE (poissons méfiants à distance)
        case .longCorner:
            // Priorité 1 : SOMBRE (silhouette pour poissons à distance)
            if profil == .sombre {
                score += 15  // CHAMPION

                // Bonus finition mate (silhouette pure)
                if finition == .mate {
                    score += 5
                }
                if finition == .phosphorescent {
                    score += 4
                }
            }

            // Priorité 2 : DISCRET (naturel sobre, pas de reflets agressifs)
            else if profil == .naturel {
                // Naturel discret acceptable si finition mate ou sans finition
                if finition == .mate || finition == nil {
                    score += 8  // Bon (discret)
                } else if finition == .perlee {
                    score += 6
                } else {
                    score += 4  // Moins bon (trop brillant)
                }
            }

            // Acceptable : Contraste
            else if profil == .contraste {
                score += 5
            }

            // Mauvais : Flashy
            else if profil == .flashy {
                score += 1  // Trop agressif pour poissons méfiants

                // Pénalité finitions brillantes
                if finition == .holographique || finition == .chrome || finition == .miroir {
                    score -= 2
                }
            }

            // Bonus couleurs sombres
            switch couleur {
            case .noir, .violet, .bleuFonce, .marron, .noirViolet:
                score += 6
            case .vert, .vertDore:
                score += 2
            case .chartreuse, .jauneFluo, .roseFuchsia, .roseFluo:
                score -= 3  // Trop flashy
            default:
                break
            }

        // RIGGERS : FLASHY (couleurs vives/fluo, attracteurs 0-2m)
        case .shortRigger, .longRigger:
            // Priorité ABSOLUE : FLASHY avec couleurs vives
            if profil == .flashy {
                score += 15  // PARFAIT

                // Bonus couleurs ultra-vives
                switch couleur {
                case .chartreuse, .jauneFluo:
                    score += 8  // Ultra-attracteur
                case .roseFuchsia, .roseFluo:
                    score += 8
                case .orange, .rouge:
                    score += 6
                case .rose, .jaune:
                    score += 5
                default:
                    score += 2
                }

                // ✅ BONUS CONTEXTUEL : Efficacité selon environnement
                score += efficaciteContexte * 0.5  // +0 à +5 pts
            }

            // Acceptable : Contraste
            else if profil == .contraste {
                score += 8
            }

            // Mauvais : Naturel ou Sombre
            else if profil == .naturel {
                score += 3  // Pas assez attractif
            }
            else if profil == .sombre {
                score += 2  // Pas du tout adapté
                score -= 3  // Pénalité
            }

            // Bonus finitions (toutes acceptées pour riggers)
            if let fin = finition {
                switch fin {
                case .holographique, .chrome, .miroir, .paillete:
                    score += 3  // Bon
                case .brillante, .metallique:
                    score += 2
                case .UV:
                    score += 2
                default:
                    break
                }
            }

        // SHOTGUN : DISCRET (poissons très méfiants, 70-100m)
        case .shotgun:
            // ✅ Priorité : DISCRET et efficace dans le contexte
            score += efficaciteContexte * 0.8  // 0-8 pts selon contexte

            // Profil naturel discret parfait
            if profil == .naturel {
                score += 8  // PARFAIT (discret)

                // Bonus finitions discrètes
                if finition == .mate || finition == nil {
                    score += 3
                } else if finition == .perlee {
                    score += 2
                }
            }

            // Contraste acceptable
            else if profil == .contraste {
                score += 6
            }

            // Sombre acceptable (discret)
            else if profil == .sombre {
                score += 5
            }

            // Flashy moins bon (trop agressif pour poissons méfiants)
            else if profil == .flashy {
                score += 3
            }

            // Couleurs discrètes
            switch couleur {
            case .argente, .bleuArgente, .sardine:
                score += 4  // Discret classique
            case .vertDore, .vert:
                score += 3
            case .noir, .violet:
                score += 2  // Sombre discret
            case .chartreuse, .jauneFluo, .roseFuchsia:
                score -= 2  // Trop voyant
            default:
                break
            }

        // LIBRE : Position flexible
        case .libre:
            score += 5
        }

        return score
    }

    /// Attribue intelligemment les positions selon les profils des leurres
    private func attribuerPositionsIntelligentes(
        suggestions: [SuggestionResult],
        positionsDisponibles: [PositionSpread],
        distancesDynamiques: [PositionSpread: Int],
        conditions: ConditionsPeche
    ) -> [SuggestionResult] {

        var resultat: [SuggestionResult] = []
        var suggestionsRestantes = suggestions
        var positionsRestantes = positionsDisponibles

        // Stratégie d'attribution par priorité des positions
        let ordrePriorite: [PositionSpread] = [
            .longCorner,    // Le plus difficile à remplir (besoin de leurres sombres)
            .shortRigger,   // Attracteur important
            .longRigger,    // Second attracteur
            .shortCorner,   // Naturel (plus facile)
            .shotgun,       // Polyvalent
            .libre          // Flexible
        ]

        // Attribution position par position selon priorité
        for positionPrioritaire in ordrePriorite {
            // Vérifier si cette position est demandée
            guard positionsRestantes.contains(positionPrioritaire) else { continue }
            guard !suggestionsRestantes.isEmpty else { break }

            // Cas spécial LONG RIGGER : éviter même couleur que SHORT RIGGER
            if positionPrioritaire == .longRigger {
                // Chercher si Short Rigger déjà attribué
                if let shortRiggerSuggestion = resultat.first(where: { $0.positionSpread == .shortRigger }) {
                    let couleurShortRigger = shortRiggerSuggestion.leurre.couleurPrincipale
                    let customShortRigger = shortRiggerSuggestion.leurre.couleurPrincipaleCustom

                    // Calculer scores en pénalisant les couleurs identiques
                    var meilleurIndex = 0
                    var meilleurScore = -1000.0

                    for (index, suggestion) in suggestionsRestantes.enumerated() {
                        var score = evaluerProfilPosition(
                            leurre: suggestion.leurre,
                            position: positionPrioritaire,
                            conditions: conditions  // ✅ Passer les conditions
                        )

                        // Bonus pour diversité du spread : privilégier le score global
                        score += suggestion.scoreTotal * 0.1

                        // ✅ AMÉLIORATION : Pénalité si même couleur (standard ou custom)
                        let memeCouleur: Bool
                        if let customCurrent = suggestion.leurre.couleurPrincipaleCustom,
                           let customShort = customShortRigger {
                            // Les deux sont custom : comparer par ID
                            memeCouleur = (customCurrent.id == customShort.id)
                        } else if customShortRigger == nil && suggestion.leurre.couleurPrincipaleCustom == nil {
                            // Les deux sont standards : comparer par enum
                            memeCouleur = (suggestion.leurre.couleurPrincipale == couleurShortRigger)
                        } else {
                            // L'une est custom, l'autre standard : couleurs différentes
                            memeCouleur = false
                        }

                        if memeCouleur {
                            score -= 10
                        }

                        if score > meilleurScore {
                            meilleurScore = score
                            meilleurIndex = index
                        }
                    }

                    // Attribuer
                    var suggestion = suggestionsRestantes.remove(at: meilleurIndex)
                    suggestion = attribuerPositionEtJustification(
                        suggestion: suggestion,
                        position: positionPrioritaire,
                        distance: distancesDynamiques[positionPrioritaire] ?? 20
                    )
                    resultat.append(suggestion)
                    positionsRestantes.removeAll { $0 == positionPrioritaire }

                    continue
                }
            }

            // Attribution standard : chercher le leurre le mieux adapté
            var meilleurIndex = 0
            var meilleurScore = -1000.0

            for (index, suggestion) in suggestionsRestantes.enumerated() {
                var score = evaluerProfilPosition(
                    leurre: suggestion.leurre,
                    position: positionPrioritaire,
                    conditions: conditions  // ✅ Passer les conditions
                )

                // Bonus pour le score global (on privilégie quand même les bons leurres)
                score += suggestion.scoreTotal * 0.1

                if score > meilleurScore {
                    meilleurScore = score
                    meilleurIndex = index
                }
            }

            // Attribuer la position au meilleur candidat
            var suggestion = suggestionsRestantes.remove(at: meilleurIndex)
            suggestion = attribuerPositionEtJustification(
                suggestion: suggestion,
                position: positionPrioritaire,
                distance: distancesDynamiques[positionPrioritaire] ?? 20
            )
            resultat.append(suggestion)
            positionsRestantes.removeAll { $0 == positionPrioritaire }
        }

        // Trier le résultat selon l'ordre des positions (pour affichage cohérent)
        let ordreAffichage: [PositionSpread] = [.shortCorner, .longCorner, .shortRigger, .longRigger, .shotgun, .libre]
        resultat.sort { suggestion1, suggestion2 in
            guard let pos1 = suggestion1.positionSpread,
                  let pos2 = suggestion2.positionSpread else {
                return false
            }
            let index1 = ordreAffichage.firstIndex(of: pos1) ?? 999
            let index2 = ordreAffichage.firstIndex(of: pos2) ?? 999
            return index1 < index2
        }

        return resultat
    }

    /// Attribue une position et génère la justification correspondante
    private func attribuerPositionEtJustification(
        suggestion: SuggestionResult,
        position: PositionSpread,
        distance: Int
    ) -> SuggestionResult {

        var suggestionModifiee = suggestion
        suggestionModifiee.positionSpread = position
        suggestionModifiee.distanceSpread = distance

        let leurre = suggestion.leurre
        var justifPosition = ""

        switch position {
        case .libre:
            justifPosition = "Position LIBRE (\(distance)m) : "
            justifPosition += "Meilleur leurre en position flexible. "

        case .shortCorner:
            justifPosition = "Position SHORT CORNER (\(distance)m) : "

            // ✅ Justification personnalisée selon profil du leurre
            let profil = leurre.profilVisuel
            if profil == .naturel {
                justifPosition += "Naturel parfait dans les bulles du sillage. "
                // ✅ AMÉLIORATION : Utiliser RGB réels
                let rgb = leurre.composantesRGBPrincipale
                let nomCouleur = leurre.couleurPrincipaleAffichage.nom
                let estArgente = (abs(rgb.r - rgb.g) < 0.2 && abs(rgb.g - rgb.b) < 0.2 && rgb.r > 0.5)
                if estArgente {
                    justifPosition += "Imitation poisson fourrage ultra-réaliste (\(nomCouleur)). "
                }
            } else if profil == .contraste {
                justifPosition += "Contraste visible dans la zone agitée proche. "
            } else if profil == .flashy {
                justifPosition += "Flashy attractif même dans les remous. "
            } else {
                justifPosition += "Position proche agressive dans le sillage. "
            }

        case .longCorner:
            justifPosition = "Position LONG CORNER (\(distance)m) : "

            // ✅ Justification selon profil (priorité leurres sombres)
            let profil = leurre.profilVisuel
            if profil == .sombre {
                justifPosition += "Silhouette SOMBRE visible par en-dessous - PARFAIT ! "
                if leurre.finition == .mate {
                    justifPosition += "Finition mate crée ombre pure idéale. "
                } else if leurre.finition == .phosphorescent {
                    justifPosition += "Phosphorescent crée contraste lumineux. "
                }
            } else if profil == .contraste {
                justifPosition += "Contraste marqué crée bonne silhouette. "
            } else {
                justifPosition += "Position éloignée, visible en approche oblique. "
                if profil == .flashy {
                    justifPosition += "Note : un leurre plus sombre serait encore mieux ici. "
                }
            }

        case .shortRigger:
            justifPosition = "Position SHORT RIGGER (\(distance)m) : "

            // ✅ Justification selon profil (priorité leurres flashy)
            let profil = leurre.profilVisuel
            if profil == .flashy {
                justifPosition += "FLASHY PARFAIT - Attracteur latéral maximum ! "

                if let finition = leurre.finition {
                    switch finition {
                    case .holographique:
                        justifPosition += "Holographique génère reflets irrésistibles. "
                    case .chrome, .miroir:
                        justifPosition += "Finition miroir crée éclats lumineux. "
                    case .paillete:
                        justifPosition += "Paillettes scintillent comme écailles. "
                    default:
                        break
                    }
                }

                // ✅ AMÉLIORATION : Utiliser RGB réels pour identifier les couleurs flashy
                let rgb = leurre.composantesRGBPrincipale
                let nomCouleur = leurre.couleurPrincipaleAffichage.nom
                let estJauneVert = (rgb.g > 0.7 && rgb.r > 0.4 && rgb.b < 0.3)
                let estRoseFlashy = (rgb.r > 0.8 && rgb.g < 0.5 && rgb.b > 0.4)

                if estJauneVert {
                    justifPosition += "\(nomCouleur) ultra-visible de loin. "
                } else if estRoseFlashy {
                    justifPosition += "\(nomCouleur) électrique attire l'œil. "
                }
            } else if profil == .contraste {
                justifPosition += "Contrasté efficace sur tangon latéral. "
            } else {
                justifPosition += "Attracteur latéral sur tangon. "
            }

        case .longRigger:
            justifPosition = "Position LONG RIGGER (\(distance)m) : "

            // ✅ Justification (même logique que Short Rigger + diversité)
            let profil = leurre.profilVisuel
            if profil == .flashy {
                justifPosition += "FLASHY sur tangon opposé - Diversité attracteurs ! "

                if let finition = leurre.finition {
                    switch finition {
                    case .holographique, .chrome, .miroir:
                        justifPosition += "Finition brillante complémentaire. "
                    case .paillete:
                        justifPosition += "Paillettes créent second point focal. "
                    default:
                        break
                    }
                }
            } else if profil == .contraste {
                justifPosition += "Contrasté sur second tangon. "
            } else {
                justifPosition += "Position tangon opposé pour couverture latérale. "
            }

        case .shotgun:
            justifPosition = "Position SHOTGUN (\(distance)m) : "
            justifPosition += "Position centrale lointaine - "

            let profil = leurre.profilVisuel
            if profil == .contraste {
                justifPosition += "Contraste fort efficace à distance. "
            } else if profil == .naturel {
                justifPosition += "Discret mais attractif, méfiance réduite. "
            } else if profil == .flashy {
                justifPosition += "Flashy visible même très loin. "
            } else {
                justifPosition += "Position arrière stratégique. "
            }
        }

        suggestionModifiee.justificationPosition = justifPosition

        return suggestionModifiee
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
                profondeur: conditions.profondeurZone,
                zone: conditions.zone
            ) {
                // Retirer shotgun et limiter à 4 lignes
                positionsDisponibles.removeAll { $0 == .shotgun }
            }
        }

        // Calcul dynamique des distances
        let distancesDynamiques = calculerDistancesDynamiques(conditions: conditions)

        // ✅ NOUVEAU : Attribution INTELLIGENTE des positions selon profil des leurres
        let suggestionsAvecPositionAttribuee = attribuerPositionsIntelligentes(
            suggestions: suggestionsPourSpread,
            positionsDisponibles: positionsDisponibles,
            distancesDynamiques: distancesDynamiques,
            conditions: conditions
        )

        suggestionsAvecPosition = suggestionsAvecPositionAttribuee

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
        // ✅ AMÉLIORATION : Compter les couleurs uniques (standard + custom)
        var couleursUniques = Set<String>()
        for suggestion in suggestions {
            if let custom = suggestion.leurre.couleurPrincipaleCustom {
                couleursUniques.insert("custom_\(custom.id.uuidString)")
            } else {
                couleursUniques.insert("standard_\(suggestion.leurre.couleurPrincipale.rawValue)")
            }
        }

        analyse += "🎨 Diversité couleurs : \(couleursUniques.count) teintes différentes\n"

        if couleursUniques.count == suggestions.count {
            analyse += "   ✅ Excellent ! Chaque leurre a une couleur unique.\n\n"
        } else {
            analyse += "   ⚠️ Certaines couleurs se répètent.\n\n"
        }

        // ✨ NOUVEAU : Diversité des finitions
        let finitions = suggestions.compactMap { $0.leurre.finition }
        if !finitions.isEmpty {
            let finitionsUniques = Set(finitions)
            analyse += "✨ Diversité finitions : \(finitionsUniques.count) types (\(finitions.count)/\(suggestions.count) leurres avec finition)\n"

            // Lister les finitions présentes
            let finitionsNoms = finitionsUniques.map { $0.displayName }.sorted()
            if !finitionsNoms.isEmpty {
                analyse += "   Types : \(finitionsNoms.joined(separator: ", "))\n"
            }

            // Évaluation selon conditions
            switch (conditions.luminosite, conditions.turbiditeEau) {
            case (.forte, .claire):
                let brillantes = finitions.filter {
                    $0 == .holographique || $0 == .chrome || $0 == .miroir || $0 == .paillete
                }.count
                if brillantes >= 2 {
                    analyse += "   ✅ Plusieurs finitions brillantes - parfait pour forte lumière !\n\n"
                } else {
                    analyse += "   💡 Ajoutez des finitions holographiques/chrome pour profiter de la lumière.\n\n"
                }

            case (.faible, _), (.sombre, _), (.nuit, _):
                let sombres = finitions.filter { $0 == .mate || $0 == .phosphorescent }.count
                if sombres >= 1 {
                    analyse += "   ✅ Finition mate/phosphorescente présente - adapté à la faible luminosité.\n\n"
                } else {
                    analyse += "   💡 Une finition mate améliorerait la silhouette en faible lumière.\n\n"
                }

            case (_, .trouble), (_, .tresTrouble):
                let adaptees = finitions.filter { $0 == .mate || $0 == .UV }.count
                if adaptees >= 1 {
                    analyse += "   ✅ Finition adaptée à l'eau trouble présente.\n\n"
                } else {
                    analyse += "   💡 UV ou mat seraient plus efficaces en eau trouble.\n\n"
                }

            default:
                analyse += "   ℹ️ Bon mélange de finitions.\n\n"
            }
        } else {
            analyse += "ℹ️ Aucune finition renseignée - pensez à compléter vos leurres.\n\n"
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

        // ✨ NOUVEAU : Recommandations finitions selon conditions
        analyse += "\n✨ FINITIONS RECOMMANDÉES :\n"

        switch (conditions.luminosite, conditions.turbiditeEau) {
        case (.forte, .claire):
            analyse += "• Holographique, Chrome, Miroir → Profitez de la lumière !\n"
            analyse += "• Pailleté → Effet scintillant maximal\n"

        case (.diffuse, .legerementTrouble):
            analyse += "• Perlé, Métallique → Reflets subtils efficaces\n"
            analyse += "• Brillante → Polyvalence assurée\n"

        case (.faible, _), (.sombre, _):
            analyse += "• Mat → Silhouette pure sans reflets parasites\n"
            analyse += "• Phosphorescent → Si pêche au crépuscule/nuit\n"

        case (.nuit, _):
            analyse += "• Phosphorescent → Luminosité propre visible de loin\n"
            analyse += "• Mat sombre → Silhouette découpée parfaite\n"

        case (_, .trouble), (_, .tresTrouble):
            analyse += "• UV → Réaction ultraviolette perce la turbidité\n"
            analyse += "• Mat → Contraste maximal\n"

        default:
            analyse += "• Métallique, Brillante → Polyvalents en conditions variées\n"
        }

        return analyse
    }
}
