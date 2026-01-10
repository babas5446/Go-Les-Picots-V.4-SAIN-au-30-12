//
//  TechniqueDatabase.swift
//  Go Les Picots V.4
//
//  Module 4 - Sprint 3 : Base de données des techniques de pêche
//  6 fiches MONTAGES complètes (fiches 7-17 à venir)
//
//  Sources :
//  - Manuel CPS Techniques de pêche côtière 2023
//  - FICHES_PÉDAGOGIQUES.pdf
//  - Règles métiers Fast/Slow Jigging, Wobbling
//  - Preston 99 pêche profonde
//
//  Created by LANES Sebastien on 05/01/2026.
//

import Foundation

// MARK: - Enums

enum CategorieTechnique: String, Codable, CaseIterable {
    case montage = "Montages"
    case animation = "Animations"
    case strategie = "Stratégies"
    case equipement = "Équipement"
}

enum NiveauDifficulte: String, Codable {
    case debutant = "Débutant"
    case intermediaire = "Intermédiaire"
    case avance = "Avancé"
}

// MARK: - Structures

struct EtapeTechnique: Codable, Identifiable {
    let id: String
    let ordre: Int
    let titre: String
    let description: String
    let illustrationsEtapes: String?  // ✅ Nom de l'image dans Assets
    let conseil: String?
}

struct FicheTechnique: Codable, Identifiable {
    let id: String
    let titre: String
    let categorie: CategorieTechnique
    let niveauDifficulte: NiveauDifficulte
    let dureeApprentissage: String
    let description: String
    let materielNecessaire: [String]
    let illustrationPrincipale: String?
    let etapesDetaillees: [EtapeTechnique]
    let conseilsPro: [String]
    let erreursCourantes: [String]
    let videoURL: String?
    let photosIllustrations: [String]
    let especesConcernees: [String]
    
    // ❌ CETTE PROPRIÉTÉ EST SUPPRIMÉE
    // let illustrationsEtapes: [String]?
}

// MARK: - Base de données

class TechniqueDatabase {
    
    static let shared = TechniqueDatabase()
    
    // Tableau de toutes les fiches
    let toutesLesFiches: [FicheTechnique]
    
    // MARK: - Initializer
    
    private init() {
        // Initialisation du tableau avec les 26 fiches techniques complètes
        self.toutesLesFiches = [
            // ========== MONTAGES (Fiches 1-7) ==========
            // Fiche 1
            TechniqueDatabase.creerMontageTraineSimple(),
            // Fiche 2
            TechniqueDatabase.createSpreadProfessionnel(),
            // Fiche 3
            TechniqueDatabase.createPalangrotteFond(),
            // Fiche 4
            TechniqueDatabase.createDeepDropping(),
            // Fiche 5
            TechniqueDatabase.createPopperLancer(),
            // Fiche 6
            TechniqueDatabase.createStickbaitLancer(),
            // Fiche 7
            TechniqueDatabase.createDownriggerTraine(),
            
            // ========== ANIMATIONS (Fiches 8-14) ==========
            // Fiche 8
            TechniqueDatabase.createRecuperationLineaire(),
            // Fiche 9
            TechniqueDatabase.createTwitchingJerking(),
            // Fiche 10
            TechniqueDatabase.createStopAndGo(),
            // Fiche 11
            TechniqueDatabase.createWalkingTheDog(),
            // Fiche 12
            TechniqueDatabase.createSlowPitchJigging(),
            // Fiche 13
            TechniqueDatabase.createFastPitchJigging(),
            // Fiche 14
            TechniqueDatabase.createSlowVsFastJigging(),
            
            // ========== STRATÉGIES (Fiches 15-19) ==========
            // Fiche 15
            TechniqueDatabase.createZonesDePecheSpots(),
            // Fiche 16
            TechniqueDatabase.createAdaptationMeteoMaree(),
            // Fiche 17
            TechniqueDatabase.createLectureEauChasses(),
            // Fiche 18 ⭐ ENRICHIE (théorie solunaire)
            TechniqueDatabase.createTimingOptimal(),
            // Fiche 19
            TechniqueDatabase.createStrategiesMultiEspeces(),
            
            // ========== ÉQUIPEMENT (Fiches 20-26) ==========
            // Fiche 20
            TechniqueDatabase.createCannesMoulinets(),
            // Fiche 21
            TechniqueDatabase.createLignesTresses(),
            // Fiche 22
            TechniqueDatabase.createNoeudsEssentiels(),
            // Fiche 23
            TechniqueDatabase.createHameconsMontages(),
            // Fiche 24
            TechniqueDatabase.createEntretienStockage(),
            // Fiche 25 ⭐ ENRICHIE (réglementation NC complète)
            TechniqueDatabase.createSecuriteReglementation(),
            // Fiche 26 ⭐ ENRICHIE (anatomie leurres complète)
            TechniqueDatabase.createAnatomieStrategiqueLeurre()
        ]
    }
    
    // MARK: - Fonctions utilitaires
    
    func obtenirFichesParCategorie(_ categorie: CategorieTechnique) -> [FicheTechnique] {
        return toutesLesFiches.filter { $0.categorie == categorie }
    }
    
    func obtenirFichesParNiveau(_ niveau: NiveauDifficulte) -> [FicheTechnique] {
        return toutesLesFiches.filter { $0.niveauDifficulte == niveau }
    }
    
    func obtenirFicheParId(_ id: String) -> FicheTechnique? {
        return toutesLesFiches.first { $0.id == id }
    }
    
    func obtenirFichesParEspece(_ especeId: String) -> [FicheTechnique] {
        return toutesLesFiches.filter { $0.especesConcernees.contains(especeId) }
    }
    
    /// Recherche de fiches par mots-clés dans titre ou description
    func rechercherFiches(motsClefs: String) -> [FicheTechnique] {
        let termeRecherche = motsClefs.lowercased()
        return toutesLesFiches.filter { fiche in
            fiche.titre.lowercased().contains(termeRecherche) ||
            fiche.description.lowercased().contains(termeRecherche)
        }
    }
    
    /// Statistiques de la base de données
    var statistiques: (total: Int, parCategorie: [CategorieTechnique: Int]) {
        let total = toutesLesFiches.count
        var parCategorie: [CategorieTechnique: Int] = [:]
        
        for categorie in CategorieTechnique.allCases {
            parCategorie[categorie] = obtenirFichesParCategorie(categorie).count
        }
        
        return (total, parCategorie)
    }
    
    // MARK: - Accesseurs directs par catégorie
    
    // MONTAGES (1-7 et 26)
    var montageTraineSimple: FicheTechnique {
        return toutesLesFiches[0]
    }
    
    var montageSpreadComplet: FicheTechnique {
        return toutesLesFiches[1]
    }
    
    var montagePalangrotte: FicheTechnique {
        return toutesLesFiches[2]
    }
    
    var montagePecheProfonde: FicheTechnique {
        return toutesLesFiches[3]
    }
    
    var montagePopperLancer: FicheTechnique {
        return toutesLesFiches[4]
    }

    var montageStickbaitLancer: FicheTechnique {
        return toutesLesFiches[5]
    }

    var montageDownriggerTraine: FicheTechnique {
        return toutesLesFiches[6]
    }
    var montageAnatomieLeures: FicheTechnique {
        return toutesLesFiches[25]
    }
    
    // ANIMATIONS (8-14)
    var animationRecuperationLineaire: FicheTechnique {
        return toutesLesFiches[7]
    }
    
    var animationTwitchingJerking: FicheTechnique {
        return toutesLesFiches[8]
    }
    
    var animationStopAndGo: FicheTechnique {
        return toutesLesFiches[9]
    }
    
    var animationWalkingTheDog: FicheTechnique {
        return toutesLesFiches[10]
    }
    
    var animationSlowPitchJigging: FicheTechnique {
        return toutesLesFiches[11]
    }
    
    var animationFastPitchJigging: FicheTechnique {
        return toutesLesFiches[12]
    }
    
    var animationSlowVsFastJigging: FicheTechnique {
        return toutesLesFiches[13]
    }
    
    // STRATÉGIES (15-19)
    var strategieZonesPeche: FicheTechnique {
        return toutesLesFiches[14]
    }
    
    var strategieAdaptationMeteo: FicheTechnique {
        return toutesLesFiches[15]
    }
    
    var strategieLectureEau: FicheTechnique {
        return toutesLesFiches[16]
    }
    
    var strategieTimingOptimal: FicheTechnique {
        return toutesLesFiches[17]
    }
    
    var strategieMultiEspeces: FicheTechnique {
        return toutesLesFiches[18]
    }
    
    // ÉQUIPEMENT (20-26)
    var equipementCannesMoulinets: FicheTechnique {
        return toutesLesFiches[19]
    }
    
    var equipementLignesTresses: FicheTechnique {
        return toutesLesFiches[20]
    }
    
    var equipementNoeudsEssentiels: FicheTechnique {
        return toutesLesFiches[21]
    }
    
    var equipementHamecons: FicheTechnique {
        return toutesLesFiches[22]
    }
    
    var equipementEntretien: FicheTechnique {
        return toutesLesFiches[23]
    }
    
    var equipementSecurite: FicheTechnique {
        return toutesLesFiches[24]
    }
}

// MARK: - Extension pour debug et validation

extension TechniqueDatabase {
    
    /// Valide l'intégrité de la base de données
    func validerIntegrite() -> (valide: Bool, erreurs: [String]) {
        var erreurs: [String] = []
        
        // Vérifier nombre total
        if toutesLesFiches.count != 26 {
            erreurs.append("❌ Nombre de fiches incorrect: \(toutesLesFiches.count) au lieu de 26")
        }
        
        // Vérifier unicité des IDs
        let ids = toutesLesFiches.map { $0.id }
        let idsUniques = Set(ids)
        if ids.count != idsUniques.count {
            erreurs.append("❌ IDs en double détectés")
        }
        
        // Vérifier répartition par catégorie
        let stats = statistiques
        let attendu: [CategorieTechnique: Int] = [
            .montage: 7,
            .animation: 7,
            .strategie: 5,
            .equipement: 7
        ]
        
        for (categorie, nombre) in attendu {
            if stats.parCategorie[categorie] != nombre {
                erreurs.append("❌ Catégorie \(categorie.rawValue): \(stats.parCategorie[categorie] ?? 0) fiches au lieu de \(nombre)")
            }
        }
        
        return (erreurs.isEmpty, erreurs)
    }
    
    /// Affiche un rapport de la base de données
    func afficherRapport() {
        print("BASE DE DONNÉES TECHNIQUES DE PÊCHE")
        print("=====================================")
        print("Total fiches: \(toutesLesFiches.count)")
        print("")
        
        for categorie in CategorieTechnique.allCases {
            let fiches = obtenirFichesParCategorie(categorie)
            print("\(categorie.rawValue): \(fiches.count) fiches")
            for fiche in fiches {
                print("  [\(fiche.niveauDifficulte.rawValue)] \(fiche.titre)")
            }
            print("")
        }
        
        print("Validation:")
        let (valide, erreurs) = validerIntegrite()
        if valide {
            print("✅ Base de données intègre")
        } else {
            print("⚠️ Erreurs détectées:")
            for erreur in erreurs {
                print("  \(erreur)")
            }
        }
    }
}

// MARK: - Factory Methods (Création des fiches)

extension TechniqueDatabase {
    
    // FICHE 1 : Montage traîne simple classique
    static func creerMontageTraineSimple() -> FicheTechnique {
        return FicheTechnique(
            id: "montage_traine_simple",
            titre: "Montage traîne simple classique",
            categorie: .montage,
            niveauDifficulte: .debutant,
            dureeApprentissage: "15-30 minutes",
            description: """
            Montage de base pour débuter la traîne hauturière. Simple, efficace et adapté à toutes les espèces pélagiques. \
            Ce montage direct permet de ressentir les touches immédiatement et facilite le combat avec le poisson.
            
            Utilisé depuis des décennies par les pêcheurs du Pacifique, ce montage reste la référence pour sa fiabilité \
            et sa polyvalence. Il convient parfaitement aux sorties en bateau léger (4-6 mètres) en lagon ou offshore.
            """,
            materielNecessaire: [
                "Ligne mère tressé PE 6-8 (ou nylon 50-60 lb) ou fil nylon de même résistance",
                "Émerillon baril robuste taille 4/0 ou 5/0",
                "Bas de ligne fluorocarbone 80-100 lb (2-3 mètres)",
                "Leurre traîne (poisson nageur, jupe, bullet)",
                "Pince à sertir + manchons (si utilisation câble acier pour wahoo)",
                "Ciseaux ou coupe-fil",
                "Briquet (pour cautériser les extrémités du tressé)"
            ],
            illustrationPrincipale: "LigneDeTraine_illustration",
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Préparation de la ligne mère",
                    description: "Déroulez environ 50-100 mètres de ligne mère du moulinet. Vérifiez l'absence d'abrasion ou de nœuds. Coupez 10-15 cm si l'extrémité est endommagée.",
                    illustrationsEtapes: "LignesMeres_illustration",
                    conseil: "Passez la ligne entre vos doigts pour détecter les imperfections au toucher"
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Fixation de l'émerillon à la ligne mère",
                    description: "Utilisez un nœud FG Knot (recommandé) ou Double Uni pour connecter la ligne mère à l'émerillon. Le FG Knot offre 95% de résistance et passe facilement dans les anneaux.",
                    illustrationsEtapes: "NoeudFG_illustration",
                    conseil: "Mouillez toujours le nœud à la salive avant de le serrer pour éviter l'échauffement et la perte de résistance"
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Choix et mesure du bas de ligne",
                    description: "Coupez 2 à 3 mètres de fluorocarbone selon l'espèce ciblée. Pour le wahoo, utilisez 3 mètres minimum. Pour le mahi-mahi ou thon, 2 mètres suffisent. Le fluorocarbone est quasi-invisible sous l'eau.",
                    illustrationsEtapes: "DifferentBasDeLignes_illustration",
                    conseil: "Adaptez la longueur : 3m pour espèces à dents tranchantes (wahoo), 2m pour opportunistes (mahi, thon)"
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Connexion bas de ligne à l'émerillon",
                    description: "Attachez le fluorocarbone à l'autre extrémité de l'émerillon avec un nœud Palomar (très résistant) ou un Double Uni. Serrez fermement après avoir mouillé le nœud.",
                    illustrationsEtapes: "NoeudPalomar_illustration",
                    conseil: "Testez la résistance en tirant fort : le nœud ne doit ni glisser ni se défaire"
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Fixation du leurre",
                    description: "Attachez le leurre au bout du fluorocarbone avec un nœud Rapala (pour les leurres à œillet) ou utilisez un snap pour changer facilement de leurre. Le snap doit être robuste (80-100 lb minimum).",
                    illustrationsEtapes: "NoeudRapala-illustration",
                    conseil: "Privilégiez le nœud direct pour plus de discrétion, le snap pour la polyvalence"
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Vérification de l'ensemble",
                    description: "Contrôlez tous les nœuds en tirant fermement. Vérifiez que l'émerillon tourne librement. Testez l'action du leurre en le trempant dans l'eau près du bateau.",
                    illustrationsEtapes: "AgrafesEtAttachesRapides_illustration",
                    conseil: "Un émerillon grippé provoque le vrillage de la ligne : remplacez-le immédiatement"
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Test de nage du leurre",
                    description: "Mettez le bateau à vitesse de traîne (5-8 nœuds selon leurre) et observez l'action. Le leurre doit nager droit, sans vriller ni sortir de l'eau.",
                    illustrationsEtapes: "NageLeurre",
                    conseil: "Si le leurre tire d'un côté, vérifiez l'alignement de l'œillet d'attache"
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Réglage de la longueur de sortie",
                    description: "Laissez sortir 20-40 mètres de ligne derrière le bateau selon les conditions. Zone lagon : 15-25m. Offshore : 30-50m. Utilisez la deuxième ou troisième vague comme repère.",
                    illustrationsEtapes: "SchemaVagues",
                    conseil: "Comptez les vagues derrière le bateau : 1 wave ≈ 7-8 mètres"
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Positionnement de la canne",
                    description: "Placez la canne dans le porte-canne avec le frein réglé au tiers de la résistance du bas de ligne (environ 30 lb pour un bas de ligne de 100 lb). Orientez le scion vers l'extérieur du bateau.",
                    illustrationsEtapes: "surfeur pas touriste",
                    conseil: "Le frein doit permettre au poisson de prendre du fil sans casser, mais freiner suffisamment pour fatiguer"
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Surveillance et ajustements",
                    description: "Vérifiez régulièrement l'action du leurre. Variez légèrement la vitesse et la trajectoire pour déclencher les attaques. Après chaque prise, inspectez le montage et remplacez les éléments endommagés.",
                    illustrationsEtapes: "VaguesEtVitesse",
                    conseil: "Changez le bas de ligne tous les 3-4 sorties même sans dommage visible : l'abrasion invisible affaiblit le fluorocarbone"
                )
            ],
            conseilsPro: [
                "Utilisez toujours un émerillon de qualité (Sampo, Spro) : un émerillon bon marché grippé ruine toute la session",
                "Pour le wahoo, ajoutez 50 cm de câble acier 90 lb entre le fluorocarbone et le leurre (dents tranchantes)",
                "En eau claire et poissons éduqués, allongez le bas de ligne à 4-5 mètres pour plus de discrétion",
                "Marquez votre ligne mère tous les 10 mètres avec un marqueur permanent : cela aide à reproduire les distances gagnantes",
                "Préparez 2-3 montages complets à l'avance : gain de temps en cas de casse ou d'emmêlement",
                "L’action est concentrée dans la zone entre la poupe et la fin du sillage (créé par le bateau et la turbulence des hélices) ou juste après, dans ce que l’on appelle la “zone de frappe” en jargon international. Et c’est précisément à l’intérieur de la zone de frappe que vous devriez laisser descendre vos appâts."
            ],
            erreursCourantes: [
                "Bas de ligne trop court (<1,5m) : le poisson voit le bateau et refuse le leurre, ou le wahoo coupe la ligne",
                "Émerillon trop petit ou de mauvaise qualité : provoque vrillage, affaiblissement de la ligne et casses fréquentes",
                "Nœuds mal serrés ou non mouillés : perte de 30-50% de résistance, casses au moment de la touche",
                "Fluorocarbone trop fin : économie mal placée, casses sur gros poissons ou structures",
                "Pas de vérification après chaque prise : un hameçon tordu ou un nœud abîmé compromet la sortie suivante",
                "Utilisation de fil nylon en bas de ligne : trop visible en eau claire, les poissons méfiants refusent"
            ],
            videoURL: nil,
            photosIllustrations: [
                "LigneDeTraine_illustration",
                "NoeudFG_illustration",
                "NoeudRapala_illustration",
                "Emerillons_illustration",
                "SchemaStrikeZone",
                "TableauRecapSpread5"
            ],
            especesConcernees: [
                "wahoo",
                    "thonJaune",
                    "bonite",
                    "mahiMahi",
                    "marlin",
                    "Espadon voilier",
                    "carangueGT",
                    "barracuda",
                    "thazard_raye",
                    "coureurArcEnCiel"
            ]
        )
    }
    
    // MARK: - FICHE 2: Spread Professionnel 4-5 Lignes
    
    static func createSpreadProfessionnel() -> FicheTechnique {
        return FicheTechnique(
            id: "montage_spread_complet",
            titre: "Spread Professionnel 4-5 Lignes",
            categorie: .montage,
            niveauDifficulte: .avance,
            dureeApprentissage: "45-60 minutes",
            description: """
            Le spread professionnel est une stratégie avancée utilisée en compétition qui exploite quatre à cinq lignes positionnées à différentes distances et hauteurs derrière le bateau. Cette technique maximise la couverture du sillage et l'attractivité globale du montage en présentant simultanément des leurres aux profils complémentaires.
            
            Chaque position du spread remplit un rôle stratégique précis : le Short Corner (10-15m) dans le bouillon immédiat attire les poissons agressifs, le Long Corner (20-30m) cible les individus plus prudents, le Rigger (40-60m) écarté latéralement par les tangons présente un leurre flashy visible de loin, et le Shotgun (70-100m) sur l'axe central vise les prédateurs les plus méfiants qui suivent à grande distance.
            
            La logique du spread repose sur la diversité : un leurre naturel, un sombre, un flashy et un contrasté garantissent qu'au moins l'un d'entre eux sera efficace quelles que soient les conditions de luminosité, de turbidité ou l'humeur des poissons. Cette approche professionnelle nécessite une installation soignée des tangons et une surveillance constante, mais offre les meilleurs rendements en pêche hauturière.
            
            En Nouvelle-Calédonie, cette technique excelle dans les zones de chasse des grands pélagiques autour des DCPs et le long des tombants externes du récif-barrière.
            """,
            materielNecessaire: [
                "Tangons (riggers) montés bâbord et tribord avec fixations solides",
                "Quatre ensembles complets de lignes de traîne (cannes/moulinets ou lignes fixes)",
                "Ligne-mère de 35 à 90 kg selon les espèces ciblées",
                "Émerillons haute résistance et agrafes robustes",
                "Assortiment de leurres variés : naturels, sombres, flashy, contrastés (8-20 cm)",
                "Bas de ligne en monofilament 45-140 kg ou câble métallique pour espèces à dents",
                "Agrafes de palangre pour changements rapides",
                "Étais et supports de tangons (sécurité critique)",
                "Baladeurs pour lignes fixes sur tangons (optionnel)",
                "Gants de manipulation pour lignes sous tension"
            ],
            illustrationPrincipale: "Spread5Vagues",
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Installation et sécurisation des tangons",
                    description: "Monter solidement les tangons sur bâbord et tribord du bateau, en veillant à ce qu'ils soient parfaitement équilibrés et inclinés à environ 45° vers l'extérieur. Installer les étais de sécurité qui supporteront la charge lorsqu'un gros poisson mordra à l'extrémité du tangon. Vérifier tous les points de fixation avant de commencer la pêche.",
                    illustrationsEtapes: "TangonCharnièreVerticale_illustration",
                    conseil: "Les tangons doivent supporter des charges importantes. Ne jamais négliger les étais de sécurité, car un gros thon ou un marlin peut exercer une traction de plusieurs dizaines de kilos à l'extrémité du tangon."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Préparation du Short Corner",
                    description: "Sélectionner un leurre agressif de grande taille (15-20 cm) dans une couleur naturelle comme bleu/blanc ou argenté. Ce leurre doit avoir une action marquée (tête plunger ou bavette agressive) pour créer un sillage visible dans le bouillon. Monter sur un bas de ligne robuste car cette position génère souvent des touches violentes.",
                    illustrationsEtapes: "ShortCorner",
                    conseil: "Le Short Corner est la première ligne que les poissons rencontrent. Choisissez un leurre imposant qui attire l'attention dans la turbulence du sillage immédiat."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Mise à l'eau du Short Corner à 10-15 mètres",
                    description: "Filer le leurre Short Corner à 10-15 mètres derrière le bateau, directement dans le bouillon blanc créé par les hélices. Vérifier que le leurre nage correctement et maintient une action stable malgré la turbulence. Ajuster la distance si nécessaire selon la taille du sillage du bateau.",
                    illustrationsEtapes: "StrikeZone_illustration",
                    conseil: "Dans le bouillon, le leurre doit rester visible par intermittence. Si le sillage est très important, vous pouvez reculer légèrement à 15-18m pour éviter que le leurre ne soit complètement noyé dans la mousse."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Préparation du Long Corner",
                    description: "Choisir un leurre plus discret et sombre (violet/noir ou couleurs naturelles foncées) avec une action stable (tête bullet). La taille peut être légèrement inférieure au Short Corner (12-18 cm). Ce leurre cible les poissons plus prudents qui restent à distance du bouillon principal.",
                    illustrationsEtapes: "LongCorner",
                    conseil: "Le contraste entre Short et Long Corner est essentiel. Si le Short est flashy et agressif, le Long doit être sobre et stable pour offrir une alternative aux poissons méfiants."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Mise à l'eau du Long Corner à 20-30 mètres",
                    description: "Filer le Long Corner à 20-30 mètres, dans la zone où le bouillon principal commence à se calmer mais reste légèrement troublé. Cette position intermédiaire est idéale pour les poissons qui suivent le bateau sans oser s'approcher du bouillon immédiat. Vérifier que la ligne ne croise pas celle du Short Corner.",
                    illustrationsEtapes: nil,
                    conseil: "Le Long Corner opère dans une zone critique où l'eau retrouve progressivement sa clarté. C'est souvent sur cette ligne que mordent les très gros spécimens prudents."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Préparation des leurres Rigger",
                    description: "Sélectionner des leurres très flashy dans des couleurs vives comme rose fluo, chartreuse ou orange. Ces leurres doivent être bien visibles de loin (16-20 cm) pour attirer l'attention latérale. Prévoir un leurre pour chaque tangon (bâbord et tribord).",
                    illustrationsEtapes: "RiggersTangons",
                    conseil: "Les Riggers sont vos 'phares' latéraux. Privilégiez les couleurs qui captent la lumière et créent des flashs visibles à grande distance, surtout par temps couvert ou en eau légèrement trouble."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Déploiement des Riggers via les tangons",
                    description: "Filer les leurres Rigger à 40-60 mètres derrière le bateau, puis écarter les lignes latéralement en utilisant les tangons. Les lignes doivent former un angle d'environ 45° par rapport à l'axe du bateau. Si vous utilisez des baladeurs, fixer les lignes aux extrémités des tangons. Ces lignes opèrent généralement entre 0 et 2 mètres de profondeur.",
                    illustrationsEtapes: "spread_4_lignes_vue_aerienne",
                    conseil: "L'écartement latéral est crucial : il permet de couvrir une largeur d'eau importante et d'éviter les emmêlements. Les tangons créent aussi un pattern visuel en V qui attire les poissons."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Préparation du Shotgun",
                    description: "Sélectionner le leurre le plus discret de votre boîte : couleurs sombres (noir/pourpre) ou imitation très réaliste de poisson volant. Taille moyenne (12-16 cm) avec une action subtile. Ce leurre cible les marlins, mahi-mahi et autres prédateurs qui suivent très loin derrière sans s'approcher.",
                    illustrationsEtapes: "ShotgunPoissonVolantNomad",
                    conseil: "Le Shotgun est votre 'ligne surprise'. Les poissons les plus méfiants ou les plus gros chasseurs (comme les marlins) préfèrent souvent observer de loin avant d'attaquer. Ce leurre leur offre une cible discrète dans une eau calme."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Mise à l'eau du Shotgun à 70-100 mètres",
                    description: "Filer le Shotgun très loin derrière le bateau (70-100 mètres) sur l'axe central, bien au-delà de la zone perturbée. Cette ligne opère dans une eau claire et non troublée. Marquer la distance à l'aide d'un marqueur sur la ligne ou compter les tours de moulinet pour assurer la répétabilité.",
                    illustrationsEtapes: nil,
                    conseil: "À cette distance, le leurre est quasiment invisible depuis le bateau. C'est normal. Les poissons qui chassent dans cette zone sont souvent les plus intéressants : gros mahi-mahi, marlins, ou thons obèses."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Ajustement de la vitesse et surveillance",
                    description: "Maintenir une vitesse de traîne adaptée aux leurres utilisés (généralement 5-8 nœuds). Surveiller constamment l'action de chaque leurre et ajuster les distances si nécessaire selon l'activité des poissons. Si une position génère plusieurs touches, envisager de dupliquer le type de leurre sur une autre position. Vérifier régulièrement que les lignes ne se croisent pas.",
                    illustrationsEtapes: "VaguesEtVitesse",
                    conseil: "Le spread professionnel demande une vigilance constante. Notez mentalement quelle position génère des touches pour ajuster votre stratégie : si le Rigger fonctionne bien, c'est que les poissons réagissent aux couleurs flashy, vous pouvez mettre du rose ou du chartreuse ailleurs."
                )
            ],
            conseilsPro: [
                "La logique du spread est de toujours exploiter les différentes couches visuelles du sillage : un leurre naturel pour l'eau claire, un sombre pour le contraste en silhouette, un flashy pour attirer de loin, et un contrasté pour les conditions difficiles.",
                "Cette répartition garantit qu'au moins un leurre sera efficace quelles que soient les conditions de luminosité, de turbidité de l'eau ou l'humeur des poissons.",
                "Espacer les lignes d'au moins 2 mètres verticalement lorsque vous utilisez plusieurs profondeurs pour éviter les emmêlements catastrophiques lors des touches multiples.",
                "Les tangons doivent être inclinés à environ 45° pour obtenir la meilleure couverture latérale sans compromettre la stabilité du bateau.",
                "Le Shotgun en eau non perturbée attire spécifiquement les prédateurs méfiants qui refusent de s'approcher du bouillon. C'est souvent sur cette ligne que mordent les marlins.",
                "Le Short Corner dans les remous est redoutable pour les carangues GT et les thons agressifs qui chassent activement. Ne sous-estimez jamais cette position.",
                "Adaptez les couleurs de vos leurres selon la luminosité et la turbidité : par temps couvert ou eau trouble, privilégiez les contrastes forts ; en plein soleil et eau claire, optez pour des couleurs naturelles."
            ],
            erreursCourantes: [
                "Ne pas sécuriser suffisamment les tangons avec des étais robustes. Un gros marlin peut littéralement arracher un tangon mal fixé.",
                "Utiliser des leurres trop similaires sur les différentes positions. La diversité est la clé du succès du spread : si tous vos leurres sont bleu/blanc, vous ne couvrez qu'une seule condition.",
                "Espacer insuffisamment les lignes entre elles. Un écart de moins de 2 mètres verticalement garantit presque les emmêlements dès qu'un poisson attaque.",
                "Adopter une vitesse inadaptée au type de leurres utilisés. Les leurres à tête pusher nécessitent 6-8 nœuds, tandis que les bavettes plongeantes préfèrent 5-7 nœuds.",
                "Négliger d'ajuster le montage selon l'activité observée des poissons. Si le Rigger flashy génère toutes les touches, c'est un signal clair pour modifier les autres positions.",
                "Traverser directement les bancs de poissons en chasse visible à la surface. Cela les effraie et les fait sonder en profondeur, hors de portée de vos leurres.",
                "Oublier de vérifier régulièrement que les algues ou débris ne s'accrochent pas aux leurres, particulièrement sur le Shotgun qui est difficile à inspecter visuellement."
            ],
            videoURL: nil,
            photosIllustrations: [
                "LigneDeTraine_illustration",
                "NoeudFG_illustration",
                "NoeudRapala_illustration",
                "Emerillons_illustration",
                "SchemaStrikeZone",
                "TableauRecapSpread5",
                "surfeur pas touriste",
                "spread_template_ok"
            ],
            especesConcernees: [
                "thonJaune",
                    "marlin",
                    "wahoo",
                    "mahiMahi",
                    "Espadon voilier",
                    "thon_obese",
                    "thonJaune"
            ]
        )
    }
    
    // MARK: - FICHE 3: Palangrotte Fond
    
    static func createPalangrotteFond() -> FicheTechnique {
        return FicheTechnique(
            id: "montage_palangrotte",
            titre: "Palangrotte Fond (Lagon/Profond)",
            categorie: .montage,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "30-45 minutes",
            description: """
            La palangrotte de fond est une technique de pêche statique ou dérivante qui utilise une longue ligne-mère équipée de multiples avançons espacés pour capturer les espèces démersales. Cette méthode polyvalente s'adapte aussi bien aux eaux lagonaires peu profondes (supérieures à 7 mètres) qu'aux zones côtières profondes.
            
            Le principe repose sur le déploiement d'une ligne-mère de plusieurs centaines de mètres portant 10 à 15 hameçons appâtés, espacés régulièrement de 10 à 20 mètres. La ligne est ancrée ou lestée aux deux extrémités et maintenue en surface par des flotteurs, créant une configuration verticale où chaque avançon se positionne juste au-dessus du fond, là où les poissons démersaux se nourrissent activement.
            
            Une caractéristique importante de la palangrotte est que les hameçons doivent être surélevés au-dessus du substrat, car la plupart des espèces démersales n'aiment pas s'emparer d'appâts reposant directement sur le sol. Cette surélévation est obtenue par l'utilisation de flotteurs intermédiaires résistants à la pression ou par une configuration verticale naturelle du montage.
            
            En Nouvelle-Calédonie, la palangrotte de fond est particulièrement efficace pour capturer le bec-de-cane dans le lagon Sud-Ouest et Nord, ainsi que les vivaneaux et empereurs sur les tombants externes. Les données de l'IRD montrent qu'elle capture des spécimens significativement plus gros que la ligne à main dans les mêmes zones.
            """,
            materielNecessaire: [
                "Ligne-mère en Kuralon de 8 mm ou monofilament 200-300 kg, longueur minimale 300 mètres",
                "Avançons en nylon monofilament 70-115 kg (résistance inférieure à la ligne-mère), longueur 3-6 mètres",
                "10 à 15 hameçons autoferrants Mustad 14/0-16/0 ou BKN taille 48",
                "Émerillons McMahon haute résistance taille 10/0-12/0 espacés de 15-20 mètres",
                "Agrafes de palangre avec émerillon (taille 12 cm) pour fixer les avançons",
                "Deux ou trois flotteurs de surface en plastique dur (diamètre 30 cm)",
                "Lests ou ancres pour les extrémités (2 à 5 kg selon profondeur et courant)",
                "Ligne de bouée en polypropylène 6-8 mm, longueur 5-10 mètres par extrémité",
                "Mât porte-pavillon en bambou ou fibre de verre (3 mètres) pour repérage",
                "Appâts : calmar (Loligo spp.), morceaux de bonite ou thon, salés pour durcissement"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Préparation de la ligne-mère avec émerillons",
                    description: "Dérouler 300 mètres de ligne-mère et fixer les émerillons McMahon à intervalles réguliers de 15 à 20 mètres. Utiliser des nœuds solides ou des manchons en aluminium pour sécuriser chaque émerillon. Confectionner des boucles de liaison aux deux extrémités de la ligne-mère pour fixer les ancres ou lests. Vérifier la solidité de chaque point d'attache.",
                    illustrationsEtapes: "palangrotte_schema",
                    conseil: "La régularité de l'espacement des émerillons est importante pour couvrir uniformément la zone de pêche. Un écart trop grand entre les hameçons réduit l'efficacité, tandis qu'un écart trop faible augmente les risques d'emmêlement."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Montage des avançons sur les émerillons",
                    description: "Découper des longueurs de monofilament de 3 à 6 mètres pour les avançons. Fixer une agrafe de palangre avec émerillon à une extrémité de chaque avançon à l'aide d'un manchon en aluminium ou d'un nœud solide. Attacher l'autre extrémité de l'avançon aux émerillons de la ligne-mère. La longueur des avançons doit être ajustée selon la profondeur : plus longs en eau profonde.",
                    illustrationsEtapes: nil,
                    conseil: "Les avançons doivent avoir une résistance inférieure d'au moins 50 kg à celle de la ligne-mère pour servir de 'fusible'. Ainsi, en cas d'accrochage, vous ne perdez qu'un avançon et son hameçon, pas toute la palangre."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Fixation des hameçons via agrafes",
                    description: "Fixer un hameçon autoferrant à chaque agrafe de palangre. Vérifier que les pointes sont bien acérées et que les hameçons sont exempts de rouille. Ranger les avançons équipés dans une caisse en bois ou les enrouler sur une bobine selon la méthode classique du Pacifique : chaque hameçon est passé à travers l'œil de sa propre agrafe et les agrafes sont accrochées sur un fil tendu dans la caisse.",
                    illustrationsEtapes: nil,
                    conseil: "Les hameçons autoferrants sont préférables car il est difficile de sentir les touches sur une palangre de fond. Le poisson se ferre lui-même lorsqu'il tire sur l'appât."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Appâtage systématique des hameçons",
                    description: "Appâter chaque hameçon généreusement avec du calmar (appât de prédilection pour le bec-de-cane et les vivaneaux) ou des morceaux de bonite/thon salés. L'appât doit complètement envelopper l'hameçon en laissant dépasser légèrement la pointe pour faciliter le ferrage automatique. Travailler méthodiquement pour appâter tous les hameçons avant la mise à l'eau.",
                    illustrationsEtapes: nil,
                    conseil: "Le calmar est l'appât universel pour la palangrotte de fond. Si vous utilisez de la bonite ou du thon, salez-les généreusement pour les durcir et éviter qu'ils ne se désagrègent trop rapidement dans l'eau."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Ancrage ou lestage de l'extrémité aval",
                    description: "Fixer un lest de 2 à 5 kg (selon la profondeur et l'intensité du courant) à la première extrémité de la ligne-mère. Ce lest peut être constitué de fers à béton soudés ensemble ou de plombs spécialement conçus. Si vous pêchez sur fond rocheux ou accidenté, utilisez une petite longueur de ligne fusible entre le lest et la ligne-mère pour pouvoir casser et récupérer la palangre en cas de coincement.",
                    illustrationsEtapes: nil,
                    conseil: "Sur les fonds rocheux ou irréguliers, les accrochages sont fréquents. Utilisez toujours une ligne fusible légère entre le lest et la ligne-mère pour pouvoir sacrifier uniquement le lest en cas de blocage."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Filage de la ligne-mère depuis le bateau",
                    description: "Commencer à filer la palangre lentement pendant que le bateau avance à vitesse réduite. Laisser descendre progressivement les avançons et leurs hameçons appâtés, en veillant à ce qu'ils ne s'emmêlent pas. Le filage commence toujours par le flotteur, suivi de la ligne de bouée, de l'ancre/lest, puis de la ligne-mère avec ses avançons. Maintenir le bateau en mouvement constant.",
                    illustrationsEtapes: nil,
                    conseil: "Le filage ne doit pas être effectué trop rapidement pour éviter les emmêlements. Une vitesse de 1-2 nœuds est idéale. Ayez un membre d'équipage qui surveille la descente des avançons pendant qu'un autre pilote le bateau."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Installation des flotteurs et mât porte-pavillon",
                    description: "Une fois toute la ligne-mère filée, attacher les flotteurs de surface à l'aide des lignes de bouée. Utiliser 2 ou 3 flotteurs de taille moyenne plutôt qu'un seul gros : cette configuration fonctionne comme un amortisseur de chocs lorsqu'un poisson se débat. Fixer le mât porte-pavillon sur le dernier flotteur pour faciliter le repérage visuel à distance. Le pavillon doit être bien visible.",
                    illustrationsEtapes: nil,
                    conseil: "Plusieurs petits flotteurs reliés par une ligne courte fonctionnent mieux qu'un seul gros flotteur. Lorsqu'un poisson est ferré, l'immersion du premier flotteur est un excellent indicateur visuel, et l'ensemble absorbe mieux les à-coups."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Ancrage ou lestage de l'extrémité amont",
                    description: "Terminer le montage en fixant le second lest ou ancre à l'extrémité opposée de la ligne-mère. Cette extrémité doit également être équipée d'une ligne de bouée remontant à la surface avec un flotteur et éventuellement un petit pavillon. S'assurer que la palangre repose bien sur le fond avec les avançons suspendus verticalement au-dessus du substrat.",
                    illustrationsEtapes: nil,
                    conseil: "Les deux extrémités doivent être identifiables en surface. En cas de dérive inattendue due à un courant fort, vous devez pouvoir localiser rapidement les deux bouts de votre palangre."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Dérive ou fixation pour la durée de pêche",
                    description: "Laisser la palangre en place pour une durée minimale d'une heure (optimum 1-2 heures dans le lagon). La palangre peut être laissée à la dérive libre si les courants sont faibles, ou fixée à une bouée de mouillage si vous souhaitez pêcher un spot précis. Si vous utilisez plusieurs palangres, les espacer suffisamment pour éviter qu'elles ne s'emmêlent. Noter l'heure de mise à l'eau et les conditions.",
                    illustrationsEtapes: nil,
                    conseil: "Une immersion d'une heure minimum est nécessaire pour que l'odeur des appâts se diffuse et attire les poissons. En revanche, au-delà de 3 heures, les appâts commencent à se dégrader et perdent leur attractivité, surtout par temps chaud."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Relevage méthodique depuis le flotteur",
                    description: "Pour relever la palangre, commencer toujours par le flotteur. Remonter lentement et régulièrement la ligne-mère en vérifiant chaque avançon. Noter l'état de chaque hameçon au relevage : appât en place, appât perdu, avançon perdu, ou poisson ferré. Cette information est précieuse pour analyser l'efficacité de la pêche. Décrocher les poissons capturés au fur et à mesure et les placer dans la glacière. Rincer et ranger méthodiquement la palangre.",
                    illustrationsEtapes: nil,
                    conseil: "Le relevage est le moment critique où se produisent la plupart des emmêlements. Travaillez lentement et méthodiquement. Si un poisson se débat encore sur un avançon, laissez-le se fatiguer quelques instants avant de le remonter à bord."
                )
            ],
            conseilsPro: [
                "Les études de l'IRD montrent que la palangrotte capture des poissons significativement plus gros que la ligne à main. Dans le lagon Nord de Nouvelle-Calédonie, le poids moyen des becs-de-cane à la palangre (2460 g) était presque le double de celui à la ligne à main (1450 g).",
                "La palangre ne peut être posée qu'à des profondeurs supérieures à 7 mètres dans le lagon pour éviter que les hameçons ne traînent sur le fond et ne s'accrochent dans les coraux peu profonds.",
                "Les poses de palangre doivent être effectuées à distance suffisante des récifs et structures coralliennes pour limiter les pertes de matériel par accrochage. En cas de doute, privilégiez les zones sableuses ou de petits fonds réguliers.",
                "Les hameçons doivent se tenir verticalement au-dessus du fond, car les espèces démersales n'aiment pas s'emparer d'appâts reposant directement sur le sol. C'est pourquoi certaines configurations utilisent des flotteurs résistants à la pression fixés à intervalles sur la ligne-mère.",
                "Une immersion d'une heure minimum est nécessaire pour obtenir de bons résultats. Les meilleurs rendements s'observent entre 1 et 2 heures d'immersion.",
                "Noter systématiquement l'état de chaque hameçon au relevage permet d'évaluer l'activité des poissons et d'optimiser les prochaines poses : si beaucoup d'appâts sont perdus, c'est qu'il y a de l'activité mais que les poissons ne se ferrent pas.",
                "L'utilisation de broumé (poisson haché dans un sac perforé fixé en haut du bas de ligne) peut significativement augmenter l'attractivité de la palangre en diffusant une traînée odorante."
            ],
            erreursCourantes: [
                "Poser la palangre trop près des récifs ou de structures coralliennes, ce qui entraîne des accrochages fréquents et des pertes importantes de matériel coûteux.",
                "Laisser les hameçons reposer directement sur le fond au lieu de les surélever. Les poissons démersaux sont réticents à mordre des appâts posés au sol.",
                "Pêcher à des profondeurs insuffisantes dans le lagon (moins de 7 mètres), où les risques d'accrochage sur les coraux sont maximaux.",
                "Utiliser des avançons de résistance égale ou supérieure à celle de la ligne-mère. En cas d'accrochage, c'est toute la palangre qui casse au lieu de sacrifier uniquement un avançon.",
                "Relever la palangre trop rapidement, ce qui provoque des emmêlements catastrophiques entre les avançons et risque de blesser les poissons encore en vie sur les hameçons.",
                "Négliger de saler les appâts de bonite ou de thon, qui deviennent rapidement mous et se détachent des hameçons en quelques minutes.",
                "Oublier de marquer clairement les deux extrémités de la palangre avec des flotteurs et pavillons visibles, ce qui rend la récupération difficile, voire impossible en cas de dérive."
            ],
            videoURL: nil,
            photosIllustrations: [
                "PalangreHorizontale_illustration",
                "PalangreVerticale_illustration",
                "PalangreTableau_illustration",
                "test_action_leurre.jpg"
            ],
            especesConcernees: [
                "becDeCane",
                "locheSaumonee",
                "carangueGT",
                "carangueBleue",
                "Vivaneaux (Pristipomoides spp., Etelis spp.)",
                "Empereurs (Lethrinus spp., Gymnocranius spp.)",
                "Loches (Epinephelus spp.)"
            ]
        )
    }
    
    // MARK: - FICHE 4: Deep Dropping 100-400m
    
    static func createDeepDropping() -> FicheTechnique {
        return FicheTechnique(
            id: "montage_peche_profonde",
            titre: "Deep Dropping 100-400m",
            categorie: .montage,
            niveauDifficulte: .avance,
            dureeApprentissage: "60-90 minutes",
            description: """
            Le deep dropping est une technique de pêche profonde spécialisée qui cible les espèces démersales de haute valeur commerciale vivant entre 100 et 400 mètres de profondeur. Cette pêche se pratique principalement sur les monts sous-marins et les tombants externes des récifs-barrières, dans des zones où l'océan atteint rapidement plusieurs centaines de mètres.
            
            La caractéristique principale du deep dropping est l'utilisation obligatoire d'hameçons autoferrants (à pointe rentrante). À ces profondeurs extrêmes, il est quasiment impossible pour le pêcheur de détecter les touches délicates des poissons. Les hameçons autoferrants permettent au poisson de se ferrer lui-même lorsqu'il tire sur l'appât, compensant ainsi l'insensibilité du pêcheur due à la longueur de ligne et à la pression de l'eau.
            
            L'avantage majeur des espèces capturées en pêche profonde est qu'elles ne sont jamais ciguatoxiques. Contrairement aux poissons de récif et de lagon qui peuvent accumuler la toxine de la gratte (ciguatera), les vivaneaux, empereurs et loches des grands fonds ont une alimentation différente qui les protège de cette contamination. Cette garantie sanitaire fait de ces espèces des cibles très valorisées sur les marchés locaux et à l'exportation.
            
            En Nouvelle-Calédonie, les travaux du programme Monts sous-marins et de ZoNéCo ont mis en évidence d'importantes ressources profondes dans la zone économique exclusive. Le deep dropping est devenu une alternative économique viable à la pêche récifale surexploitée.
            """,
            materielNecessaire: [
                "Ligne-mère d'au moins 500 mètres en monofilament, tresse ou Super-Toto de 100-300 kg",
                "Bas de ligne principal de 1,5 à 2,5 mètres avec 3-5 avançons de 30 cm",
                "Hameçons autoferrants (pointe rentrante) Mustad 5/0-9/0 ou équivalent BKN",
                "Lest très lourd de 0,5 à 2 kg pour descente rapide malgré le courant",
                "Moulinet robuste OBLIGATOIRE (remontée manuelle impossible à ces profondeurs)",
                "Échosondeur performant (essentiel pour localiser la profondeur précise)",
                "Sac à broumé (camoufle) optionnel, fixé au-dessus du bas de ligne",
                "Appâts : morceaux de bonite ou de thon, préalablement salés pour durcissement",
                "Gants de manipulation renforcés (protection contre les coupures)",
                "Ancre flottante pour maintenir la position du bateau au-dessus du spot"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Localisation précise avec échosondeur",
                    description: "Utiliser l'échosondeur pour identifier la profondeur exacte du fond et la nature de la pente. Rechercher les zones où le tombant est régulier et situé entre 100 et 400 mètres. Les monts sous-marins et les changements brusques de pente sont particulièrement productifs. Noter la profondeur précise et repérer d'éventuels poissons suspendus sur l'écran.",
                    illustrationsEtapes: "deep_dropping_schema",
                    conseil: "Un échosondeur de qualité est indispensable pour le deep dropping. Il vous permet non seulement de connaître la profondeur exacte, mais aussi de visualiser les structures sous-marines et parfois même les poissons eux-mêmes."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Mouillage ou ancre flottante",
                    description: "Le deep dropping se pratique généralement au mouillage ou avec une ancre flottante pour maintenir le bateau stationnaire au-dessus de la zone de pêche. Si la profondeur est accessible (moins de 150m), mouiller classiquement. Au-delà, utiliser une ancre flottante (drift anchor) qui maintient le bateau face au vent et réduit la dérive sans toucher le fond. Ajuster la position pour être exactement au-dessus du spot identifié.",
                    illustrationsEtapes: nil,
                    conseil: "Le maintien de la position est critique en deep dropping. Même une dérive lente peut rapidement vous éloigner d'un mont sous-marin productif ou faire traîner vos lignes sur des fonds rocheux où elles s'accrocheront."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Préparation du bas de ligne multi-hameçons",
                    description: "Monter un bas de ligne équipé de 3 à 5 hameçons autoferrants espacés le long d'avançons de 30 cm. La configuration classique place les hameçons les plus gros dans la partie supérieure (ils captureront les gros spécimens moins nombreux) et diminue progressivement la taille vers le bas (où les petits poissons sont plus abondants). Vérifier que tous les hameçons ont des pointes parfaitement acérées.",
                    illustrationsEtapes: nil,
                    conseil: "La disposition par taille décroissante des hameçons suit la distribution naturelle des poissons démersaux : les gros spécimens se tiennent plus haut dans la colonne d'eau, les petits près du fond."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Salage préalable des appâts",
                    description: "Couper la bonite ou le thon en morceaux de taille adaptée aux hameçons. Saler généreusement ces morceaux et les laisser reposer 30 minutes à plusieurs heures pour qu'ils durcissent. Ce durcissement est essentiel : les appâts non salés deviennent rapidement mous et se détachent pendant la descente ou au premier contact avec un poisson. Les appâts durcis résistent mieux et restent en place plus longtemps.",
                    illustrationsEtapes: nil,
                    conseil: "Le salage peut sembler une étape anodine, mais c'est la différence entre un appât qui tiendra 2 heures et un qui tombera en morceaux après 20 minutes. Soyez généreux avec le sel."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Appâtage généreux de tous les hameçons",
                    description: "Appâter chaque hameçon avec un morceau de bonite ou de thon salé suffisamment gros pour être attractif à grande distance. Les poissons profonds ont un excellent odorat qui compense la faible luminosité. L'appât doit complètement envelopper l'hameçon en laissant la pointe légèrement exposée pour faciliter le ferrage automatique. Travailler soigneusement car la remontée pour réappâter est longue et fastidieuse.",
                    illustrationsEtapes: nil,
                    conseil: "À ces profondeurs, vous ne pouvez pas réappâter fréquemment. Mettez des morceaux généreux qui tiendront longtemps. L'investissement dans des appâts de qualité et bien préparés se traduira directement par plus de poissons."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Fixation du lest à l'extrémité",
                    description: "Attacher solidement le lest de 0,5 à 2 kg à l'extrémité inférieure du bas de ligne. Le poids du lest doit être adapté à la profondeur et à l'intensité du courant : plus la profondeur est grande ou le courant fort, plus le lest doit être lourd pour assurer une descente verticale rapide. Sur fonds accidentés, utiliser une ligne fusible entre le lest et le bas de ligne.",
                    illustrationsEtapes: nil,
                    conseil: "Un lest trop léger fera dériver votre ligne avec le courant, l'éloignant de la verticale et rendant impossible la détection de la touche du fond. Privilégiez toujours un lest un peu trop lourd qu'un peu trop léger."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Descente contrôlée en comptant les tours",
                    description: "Commencer à descendre la ligne en comptant précisément les tours de moulinet. Cette méthode permet de connaître exactement la longueur de ligne filée et donc la profondeur atteinte. Descendre à vitesse constante, ni trop vite (risque d'emmêlement) ni trop lent (dérive excessive). Maintenir une légère tension sur la ligne pendant toute la descente pour sentir le moment où le lest touche le fond.",
                    illustrationsEtapes: nil,
                    conseil: "Notez la correspondance entre les tours de moulinet et la profondeur pour chaque ligne. Par exemple : '47 tours = 180 mètres'. Cette information sera précieuse pour reproduire rapidement la profondeur optimale."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Détection du fond et remontée de 1-2 mètres",
                    description: "Le moment où le lest touche le fond se manifeste par un relâchement soudain de la tension sur la ligne. Dès que vous sentez ce relâchement, remonter immédiatement de 1 à 2 mètres (2-4 tours de moulinet selon le rapport) pour surélever les hameçons au-dessus du substrat. Les poissons démersaux se nourrissent juste au-dessus du fond et n'aiment pas les appâts posés directement sur le sol.",
                    illustrationsEtapes: nil,
                    conseil: "Cette remontée de 1-2 mètres est critique. Si vos hameçons restent au sol, vous risquez l'accrochage sur les roches et surtout, les poissons ne mordront pas. Ils chassent dans la couche d'eau immédiatement au-dessus du fond."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Maintien de la tension constante",
                    description: "Une fois positionné, maintenir une tension constante sur la ligne pour détecter d'éventuelles touches. Si le bateau est soumis à la houle, il faudra parfois filer et virer de petites longueurs de ligne en synchronisation avec le mouvement vertical du bateau pour éviter que le lest ne rebondisse sur le fond (accrochage) ou que la ligne ne devienne trop molle (impossibilité de sentir les touches). C'est fatiguant mais nécessaire par mer agitée.",
                    illustrationsEtapes: nil,
                    conseil: "La gestion de la houle est l'aspect le plus technique du deep dropping. Dans l'idéal, choisissez des jours de mer calme. Si la houle est présente, concentrez-vous sur le maintien d'une tension constante en compensant activement les mouvements du bateau."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Ferrage automatique et remontée progressive",
                    description: "Avec des hameçons autoferrants, le ferrage est automatique : le poisson se ferre lui-même en tirant sur l'appât. Dès que vous sentez une résistance inhabituelle ou des à-coups caractéristiques, commencer la remontée lente et régulière. Ne remontez pas trop vite : les poissons profonds subissent un changement de pression important et une remontée trop rapide peut endommager leur vessie natatoire. Comptez environ 15-20 minutes pour remonter depuis 300 mètres.",
                    illustrationsEtapes: nil,
                    conseil: "La remontée lente est importante non seulement pour la survie du poisson (si vous pratiquez le relâcher), mais aussi parce qu'une remontée trop rapide risque de décrocher un poisson mal ferré. La patience est récompensée en deep dropping."
                )
            ],
            conseilsPro: [
                "Les vivaneaux rouges (Etelis coruscans et E. carbunculus) vivent généralement aux plus grandes profondeurs, vers 200-300 mètres, tandis que d'autres vivaneaux comme Pristipomoides spp. se capturent plutôt entre 150 et 250 mètres. Ajustez votre profondeur selon l'espèce ciblée.",
                "La disposition des hameçons par taille décroissante (gros en haut, petits vers le fond) suit la distribution naturelle des tailles : les gros spécimens sont plus rares et se tiennent plus haut, les petits sont plus nombreux près du fond.",
                "L'utilisation d'un sac à broumé (camoufle) fixé au point d'attache supérieur du bas de ligne améliore significativement les taux de capture en diffusant une traînée odorante qui attire les poissons de loin.",
                "Vérifiez systématiquement la profondeur chaque fois que vous remontez votre ligne. Les courants sous-marins peuvent déplacer le bateau ou faire dériver la ligne, vous éloignant progressivement du spot productif.",
                "Pour une espèce donnée, les spécimens les plus gros se trouvent dans la partie inférieure de la zone qu'elle occupe, tandis que les petits individus sont plus nombreux dans la partie supérieure. La meilleure profondeur se situe entre ces deux extrêmes.",
                "Le broumé (poissons hachés dans un sac perforé) peut transformer une session moyenne en une pêche exceptionnelle. L'odeur se diffuse lentement et attire les poissons démersaux qui ont un odorat très développé.",
                "Les espèces démersales profondes se nourrissent activement juste au-dessus du substrat, jamais directement sur le sol. C'est pourquoi il est impératif de surélever vos hameçons de 1-2 mètres après avoir touché le fond."
            ],
            erreursCourantes: [
                "Utiliser des hameçons standards au lieu d'hameçons autoferrants. À ces profondeurs, les touches sont imperceptibles et vous manquerez tous les poissons qui mordent délicatement.",
                "Disposer d'une ligne-mère trop courte (moins de 500 mètres). Même pour pêcher à 300m, il faut au moins 500m de ligne car la ligne ne descend jamais parfaitement verticalement à cause du courant.",
                "Utiliser un lest insuffisant pour la profondeur ou le courant. Un lest trop léger fera dériver votre ligne loin de la verticale et vous ne saurez plus vraiment à quelle profondeur vous pêchez.",
                "Négliger de compter et noter les tours de moulinet à la descente. Sans ce décompte, vous ne pouvez pas reproduire la profondeur optimale et perdez un temps précieux à tâtonner.",
                "Ne pas saler les appâts de bonite ou de thon. Ces appâts non traités deviennent mous et tombent des hameçons pendant la descente ou dès les premiers contacts avec les poissons.",
                "Laisser la ligne molle reposer sur le fond. Cela provoque des accrochages sur les roches et les coraux, et surtout, les poissons ne mordent pas les appâts posés au sol.",
                "Remonter trop rapidement après avoir ferré. Une remontée précipitée depuis 300 mètres peut décrocher un poisson mal ferré ou endommager sa vessie natatoire en cas de relâcher."
            ],
            videoURL: nil,
            photosIllustrations: [
                "montage_traine_complet_schema.jpg",
                "detail_noeud_FG.jpg",
                "emerillon_qualite_recommande.jpg",
                "test_action_leurre.jpg"
            ],
            especesConcernees: [
                "Vivaneaux rouges (Etelis coruscans, E. carbunculus)",
                "Vivaneau blanc (Pristipomoides filamentosus)",
                "Vivaneaux divers (P. flavipinnis, P. zonatus, P. multidens)",
                "Empereurs profonds (Gymnocranius spp.)",
                "Loches profondes (Epinephelus cometae et autres)",
                "Rouvet (Ruvettus pretiosus)",
                "Escolier serpent (Gempylidae)",
                "locheSaumonee"
            ]
        )
    }
    
    // MARK: - FICHE 5: Popper Lancer
    
    static func createPopperLancer() -> FicheTechnique {
        return FicheTechnique(
            id: "Montage_popper",
            titre: "Popper Lancer",
            categorie: .montage,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "45-60 minutes",
            description: """
            Le popping est une technique explosive de pêche de surface qui utilise des leurres à tête concave (cup face ou pusher) pour créer des éclaboussures spectaculaires et des bruits intenses imitant une proie blessée ou une chasse active. Cette approche visuelle et sonore provoque des attaques réflexes chez les prédateurs les plus agressifs.
            
            Le principe du popper repose sur sa forme spécifique : la tête concave ou tronquée capte l'eau lors des tractions brusques de la canne et la projette violemment en créant un 'pop' sonore caractéristique accompagné d'éclaboussures et de bulles. Cette perturbation en surface attire l'attention des prédateurs à grande distance et déclenche leur instinct de chasse, même lorsqu'ils ne sont pas en activité alimentaire.
            
            Le popping est particulièrement efficace à l'aube et au crépuscule, lorsque les prédateurs chassent activement en surface. Par mer agitée ou en présence de clapot, l'action bruyante et visible du popper perce le chaos ambiant et reste détectable par les poissons, contrairement aux leurres plus discrets qui se fondent dans le bruit de fond.
            
            En Nouvelle-Calédonie, cette technique excelle sur les carangues GT qui patrouillent les récifs-barrières et les passes, ainsi que sur les thons, thazards et barracudas qui chassent en surface autour des chasses d'oiseaux. L'attaque d'une GT de 20 kg sur un popper reste l'une des expériences les plus spectaculaires et mémorables de la pêche sportive.
            """,
            materielNecessaire: [
                "Canne lancer robuste 20-50 kg, action rapide, longueur 2,10-2,40 m",
                "Moulinet casting ou spinning haute capacité, ratio de récupération rapide",
                "Tresse multifilament 30-50 kg (PE 4-6) pour transmission directe des animations",
                "Bas de ligne en fluorocarbone 40-80 kg ou câble acier 40-60 cm pour espèces à dents",
                "Poppers de surface 10-19 cm à tête concave ou tronquée (cup face/pusher)",
                "Hameçons triples renforcés taille 2/0-5/0 montés sur anneaux brisés solides",
                "Pince à poisson robuste pour manipuler les prises sans danger",
                "Lunettes polarisées de qualité pour repérer les chasses et suivre le leurre",
                "Gants de lancer pour protéger les mains des frottements de la tresse",
                "Épuisette à large ouverture pour sécuriser les grosses carangues"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Repérage des chasses de surface",
                    description: "Observer attentivement la surface de l'eau pour détecter les signes d'activité prédatrice : oiseaux qui plongent, éclaboussures, 'bouillons' révélant des bancs de petits poissons poursuivis. Les carangues GT chassent souvent seules ou en petits groupes le long des tombants et des passes. Utiliser les lunettes polarisées pour voir sous la surface et repérer les poissons en approche.",
                    illustrationsEtapes: "popper_chasse_surface",
                    conseil: "Les oiseaux sont vos meilleurs alliés. Une concentration de sternes ou de fous plongeant activement signale presque toujours une chasse en cours. Approchez la zone discrètement et positionnez le bateau de façon à lancer vers la bordure de la chasse, jamais en son centre."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Positionnement stratégique du bateau",
                    description: "Positionner le bateau face au vent ou légèrement de trois-quarts pour faciliter les lancers et maintenir une dérive contrôlée vers la zone de chasse. Couper le moteur à bonne distance (30-50 mètres) pour ne pas effrayer les poissons. Si la zone est vaste, utiliser le moteur électrique ou la dérive naturelle pour rester dans la zone productive sans perturber les prédateurs.",
                    illustrationsEtapes: nil,
                    conseil: "Ne jamais foncer directement sur une chasse active avec le moteur thermique à plein régime. Les vibrations et le bruit dispersent immédiatement les poissons. Approchez doucement, coupez le moteur à distance, et laissez le bateau dériver naturellement vers la zone."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Sélection du popper adapté",
                    description: "Choisir un popper dont la taille et la couleur sont adaptées à l'espèce ciblée et aux conditions. Pour les GT, privilégier des poppers de 14-19 cm. Les couleurs vives (rose, chartreuse, orange) fonctionnent bien pour les mahi-mahi et par faible luminosité. Les couleurs sombres (noir/violet, bleu foncé) créent une silhouette marquée à l'aube et au crépuscule. Par eau claire et plein soleil, les couleurs naturelles (blanc/argenté) sont plus efficaces.",
                    illustrationsEtapes: nil,
                    conseil: "Ayez plusieurs poppers de tailles et couleurs différentes prêts sur le pont. Si un modèle ne fonctionne pas après 10-15 lancers, n'hésitez pas à changer. Parfois, un simple changement de couleur déclenche immédiatement les attaques."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Lancer au-delà de la zone de chasse",
                    description: "Effectuer un lancer puissant et précis qui dépose le popper 5 à 10 mètres au-delà de la zone où vous avez vu l'activité. L'objectif est de ramener le leurre à travers la zone de chasse plutôt que de le faire tomber directement dessus (ce qui effraierait les poissons). La distance de lancer est importante : plus vous êtes loin, moins vous perturbez les prédateurs.",
                    illustrationsEtapes: nil,
                    conseil: "Un bon lancer au popper nécessite un geste ample et progressif plutôt que violent. Laissez la canne charger pendant le geste arrière, puis accélérez progressivement vers l'avant. Le popper étant lourd et présentant une résistance au vent, la technique de lancer est différente de celle utilisée pour les leurres profilés."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Pause initiale de 2-3 secondes",
                    description: "Une fois le popper posé sur l'eau, laisser une pause de 2-3 secondes avant la première animation. Cette immobilité permet aux ondes de l'impact de se dissiper et donne aux prédateurs le temps de repérer le leurre. Les GT en particulier observent souvent le popper pendant plusieurs secondes avant de décider d'attaquer. Récupérer le mou de la ligne durant cette pause pour être prêt à animer.",
                    illustrationsEtapes: nil,
                    conseil: "Cette pause initiale est cruciale et souvent négligée par les débutants qui commencent à animer dès que le leurre touche l'eau. Patience : laissez le popper se stabiliser et créer ses premiers cercles à la surface. C'est durant cette phase que les GT remontent souvent sous le leurre."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Traction ample et brusque vers le bas",
                    description: "Effectuer une traction ample et brusque de la canne vers le bas (de la position 10h vers 8h environ), tout en récupérant simultanément le fil avec le moulinet. Ce geste combiné fait plonger la tête concave du popper dans l'eau et projette un jet d'eau vers l'avant, créant le 'pop' sonore caractéristique. L'amplitude de la traction détermine l'intensité du pop : plus la traction est ample, plus le pop est violent.",
                    illustrationsEtapes: "popper_action",
                    conseil: "Le mouvement doit être franc et décidé, pas hésitant. Imaginez que vous essayez de faire jaillir une grosse éclaboussure. La canne descend rapidement de 10h à 8h pendant que vous donnez un tour de moulinet rapide. C'est ce geste synchronisé qui crée l'effet optimal."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Création du pop sonore et des éclaboussures",
                    description: "Le résultat du geste précédent doit être un 'pop' audible accompagné d'éclaboussures visibles et d'une traînée de bulles. Si vous êtes proche, vous devez entendre distinctement le bruit. Ce son se propage bien dans l'eau et attire les prédateurs de loin. L'aspect visuel (éclaboussures, bulles) complète l'effet et simule un poisson affolé en surface.",
                    illustrationsEtapes: nil,
                    conseil: "Par temps calme, un pop trop violent peut parfois effrayer les poissons méfiants. Dans ce cas, modérez l'amplitude de vos tractions. À l'inverse, par mer agitée, n'hésitez pas à forcer le trait pour que votre popper se distingue du bruit ambiant."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Pause de 1-2 secondes",
                    description: "Après chaque pop, marquer une pause d'1 à 2 secondes en laissant le popper immobile à la surface. Durant cette pause, le leurre flotte et se stabilise, créant des ondulations qui s'éloignent en cercles concentriques. C'est souvent durant ces pauses que les poissons attaquent, soit parce qu'ils ont été attirés par le pop précédent, soit parce que l'immobilité soudaine déclenche leur instinct de prédation.",
                    illustrationsEtapes: nil,
                    conseil: "Les pauses sont aussi importantes que les pops. Beaucoup de pêcheurs débutants animent trop rapidement sans laisser aux poissons le temps de réagir. Si vous voyez une GT suivre votre popper sans attaquer, augmentez la durée des pauses - cela déclenche souvent l'attaque."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Répétition de la séquence pop-pause",
                    description: "Répéter la séquence 'traction-pop-pause' de façon rythmée sur toute la distance de récupération. Le rythme peut varier : régulier et méthodique pour une approche classique, ou irrégulier avec des pauses plus longues et des séries de pops rapides pour simuler un poisson paniqué. Observer la réaction des poissons : s'ils suivent sans attaquer, modifier le rythme.",
                    illustrationsEtapes: nil,
                    conseil: "L'animation du popper est une conversation avec les poissons. Si votre rythme régulier ne fonctionne pas, essayez de varier : 3 pops rapides, pause longue, 2 pops moyens, pause courte, 1 pop violent. Cette irrégularité imite un poisson réellement en détresse et déclenche souvent les GT indécises."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Accélération si poisson suit sans attaquer",
                    description: "Si vous voyez un poisson suivre le popper sans se décider à attaquer (cela arrive fréquemment avec les GT), accélérer légèrement le rythme d'animation en espaçant moins les pops et en réduisant les pauses. Cette accélération simule une proie qui tente de fuir et déclenche souvent l'attaque par réflexe de prédation. Alternativement, vous pouvez aussi ralentir complètement ou donner un pop extra-violent pour surprendre le poursuivant.",
                    illustrationsEtapes: nil,
                    conseil: "Quand une GT suit votre popper, c'est le moment le plus excitant et le plus stressant. Résistez à la tentation de ferrer prématurément dès que vous la voyez. Continuez l'animation normalement, voire accélérez légèrement. Le ferrage ne se fait qu'au moment où vous sentez le poids du poisson, pas quand vous le voyez."
                )
            ],
            conseilsPro: [
                "Les couleurs vives (rose fluo, chartreuse, orange) sont particulièrement efficaces sur les mahi-mahi et par conditions de faible luminosité (aube, crépuscule, temps couvert).",
                "Les couleurs sombres (noir/violet, bleu foncé) créent une silhouette très marquée à l'aube et au crépuscule. Elles sont redoutables sur les GT qui chassent tôt le matin.",
                "L'animation erratique et imprévisible est généralement plus efficace qu'un rythme régulier et métronome. Les poissons-proies en détresse ne nagent jamais de façon parfaitement régulière.",
                "Par mer agitée ou en présence de clapot, l'action bruyante et visible du popper reste détectable par les poissons, contrairement aux leurres discrets qui se fondent dans le bruit ambiant.",
                "L'attaque se produit souvent après plusieurs pops, rarement au premier. Les GT en particulier peuvent suivre un popper sur 20-30 mètres avant de se décider. Patience et persévérance sont essentielles.",
                "Le walking the dog (zigzag en surface) peut être incorporé entre les pops pour varier l'animation. Cela fonctionne particulièrement bien sur les thazards et wahoo.",
                "Pêchez les bordures des chasses, pas leur centre. Les poissons à la périphérie sont souvent les plus gros individus qui attendent que les petits épuisent les proies avant d'intervenir."
            ],
            erreursCourantes: [
                "Lancer directement dans le centre d'un banc en chasse. Cela effraie immédiatement tous les poissons qui se dispersent ou sondent en profondeur.",
                "Adopter une animation trop rapide et régulière sans laisser de pauses. Les poissons n'ont pas le temps de localiser et d'attaquer le leurre.",
                "Utiliser un popper trop petit pour les carangues GT. Un leurre de 10 cm n'attire pas l'attention d'une GT de 20 kg, alors qu'un modèle de 18 cm la fera attaquer violemment.",
                "Ferrer prématurément dès que vous voyez ou sentez le poisson toucher le leurre. Attendez de sentir le poids franc du poisson avant de ferrer fermement.",
                "Utiliser un bas de ligne trop faible. Une GT de bonne taille peut casser net un fluorocarbone de 30 kg. Privilégiez du 60-80 kg minimum.",
                "Pêcher au popper par mer d'huile parfaite avec une action ultra-aggressive. Dans ces conditions, un popper discret ou un stickbait est souvent plus efficace.",
                "Arrêter complètement l'animation lorsqu'un poisson suit le leurre sans attaquer. Au contraire, continuez ou accélérez légèrement pour déclencher l'attaque réflexe."
            ],
            videoURL: nil,
            photosIllustrations: [
                "montage_traine_complet_schema.jpg",
                "detail_noeud_FG.jpg",
                "emerillon_qualite_recommande.jpg",
                "test_action_leurre.jpg"
            ],
            especesConcernees: [
                "carangueGT",
                "thonsJaune",
                "thazard_raye",
                "barracuda",
                "mahiMahi",
                "Wahoo",
                "carangueGT",                  // Carangue GT (Giant Trevally)
                "carangueBleue",                // Carangue bleue / aile bleue
                "caranguePailletee",            // Carangue pailletée
                "carangueJoueBarree",
                "locheSaumonee"
            ]
        )
    }
    
    // MARK: - FICHE 6: Stickbait Lancer
    
    static func createStickbaitLancer() -> FicheTechnique {
        return FicheTechnique(
            id: "Montage_stickbait",
            titre: "Stickbait Lancer",
            categorie: .montage,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "45-60 minutes",
            description: """
            Le stickbait est un leurre profilé sans bavette qui imite un poisson-fourrage blessé ou fuyant par une animation en zigzag caractéristique appelée 'walking the dog' (la promenade du chien). Cette technique de surface ou sub-surface est particulièrement efficace sur les prédateurs rapides et agressifs qui chassent les bancs de petits poissons.
            
            Contrairement au popper qui crée du bruit et des éclaboussures, le stickbait mise sur l'imitation réaliste d'un poisson en détresse. L'animation en walking the dog consiste à faire osciller le leurre de gauche à droite en surface par de petites tractions sèches de la canne, créant une trajectoire sinueuse irrésistible pour les prédateurs. Cette nage en zigzag simule parfaitement un poisson désorienté ou blessé tentant de fuir.
            
            Les stickbaits existent en versions flottantes (surface), suspending (entre deux eaux) et coulantes (sinking) qui permettent de prospecter différentes couches d'eau. Les modèles coulants sont particulièrement efficaces sur les thazards méfiants qui suivent le leurre de surface sans oser attaquer : le fait de laisser couler le stickbait déclenche souvent l'attaque réflexe.
            
            En Nouvelle-Calédonie, cette technique excelle sur les thazards (rayé et bâtard) qui patrouillent le long des tombants et dans les passes, ainsi que sur les wahoos ultra-rapides qui chassent les poissons volants et aiguillettes. La récupération rapide combinée à l'animation erratique correspond parfaitement au profil de chasse de ces prédateurs véloces.
            """,
            materielNecessaire: [
                "Canne lancer 20-40 kg action rapide, longueur 2,10-2,40 m pour animation précise",
                "Moulinet haute vitesse de récupération (ratio 6:1 minimum) casting ou spinning",
                "Tresse multifilament 30-50 kg (PE 3-5) pour transmission directe",
                "Bas de ligne en câble acier torsadé 40-60 cm longueur (dents de thazards)",
                "Stickbaits 10-18 cm coulants, suspending ou flottants selon conditions",
                "Hameçons triples VMC ou Owner taille 1/0-4/0 ultra-affûtés",
                "Émerillons à roulement à billes pour éviter le vrillage",
                "Pinces coupantes pour le câble acier",
                "Épuisette à manche télescopique (thazards sautent hors de l'eau)",
                "Lunettes polarisantes pour suivre le leurre et détecter les suivis"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Localisation des zones de prédateurs actifs",
                    description: "Rechercher les secteurs où les thazards et wahoos sont actifs : bordures de tombants, entrées de passes, zones où les courants concentrent les poissons-fourrage. Observer les chasses en surface (éclaboussures, sauts), les oiseaux qui travaillent, ou utiliser l'échosondeur pour repérer les bancs de poissons-fourrage poursuivis. Les thazards chassent souvent à l'aube et en fin d'après-midi.",
                    illustrationsEtapes: "stickbait_zones",
                    conseil: "Les thazards rayés chassent volontiers en petits groupes le long des tombants à 20-40 mètres de profondeur. Lorsque vous en capturez un, insistez sur la zone car ses congénères sont généralement dans les parages et réagiront au même leurre."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Choix du stickbait adapté à la profondeur",
                    description: "Sélectionner un stickbait dont le comportement correspond à la profondeur de chasse observée. Stickbait flottant pour la stricte surface (0-50 cm), suspending pour la sub-surface (0,50-1,5 m), coulant pour descendre rapidement à 2-4 mètres. La taille (10-18 cm) et le poids (20-60g) dépendent de la taille des proies imitées et de la distance de lancer souhaitée.",
                    illustrationsEtapes: nil,
                    conseil: "Pour les wahoos très rapides, privilégiez les stickbaits coulants lourds (40-60g) qui permettent des lancers très longs et une récupération ultra-rapide. Pour les thazards plus méfiants, les modèles suspending de taille moyenne (12-14 cm, 25-35g) offrent le meilleur compromis."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Lancer loin au-delà de la zone cible",
                    description: "Effectuer un lancer long et précis qui projette le stickbait bien au-delà de la zone où vous avez repéré l'activité prédatrice. L'objectif est de ramener le leurre à travers la zone productive sur une longue distance, maximisant ainsi les chances de rencontre avec un prédateur. Les lancers longs permettent aussi d'éviter d'effrayer les poissons avec la présence du bateau.",
                    illustrationsEtapes: nil,
                    conseil: "La technique de lancer avec un stickbait lourd est différente de celle du popper. Le stickbait étant plus profilé, il fend mieux l'air. Utilisez toute la puissance de la canne avec un geste ample et fluide pour maximiser la distance. Des lancers de 60-70 mètres sont possibles avec un bon matériel."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Laisser couler si stickbait coulant",
                    description: "Si vous utilisez un stickbait coulant (sinking), laisser le leurre couler après l'impact en comptant mentalement les secondes : 3 secondes = environ 1 mètre, 6 secondes = 2 mètres, etc. Cette phase de coulée est cruciale pour atteindre la profondeur où les poissons chassent. Récupérer le mou de la ligne pendant la descente tout en maintenant un contact visuel ou tactile avec le leurre.",
                    illustrationsEtapes: nil,
                    conseil: "Expérimentez avec différents temps de coulée pour trouver la couche d'eau productive. Parfois, les thazards sont en surface, parfois à 3-4 mètres. Si vous ne touchez rien en surface, laissez couler 5-6 secondes sur les lancers suivants."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Twitchs courts et secs de la canne",
                    description: "Dès que le leurre est à la profondeur souhaitée (surface ou après coulée), commencer l'animation par de petites tractions sèches et rapides de la canne vers le bas. Chaque twitch doit être court (15-20 cm d'amplitude) et franc, suivi immédiatement d'un relâchement. C'est ce mouvement de va-et-vient rapide qui imprime au stickbait son action de zigzag caractéristique.",
                    illustrationsEtapes: "stickbait_walking_the_dog",
                    conseil: "Le geste est dans le poignet, pas dans tout le bras. Imaginez que vous secouez un thermomètre médical : petits coups secs et répétés. La canne doit être tenue en position basse (entre 8h et 9h) pour optimiser l'efficacité des twitchs."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Création de l'action zigzag en surface/sub-surface",
                    description: "L'enchaînement rapide des twitchs crée le walking the dog : le stickbait oscille alternativement à gauche puis à droite, dessinant une trajectoire sinueuse très attractive. Entre chaque twitch, le moulinet récupère le mou créé par le relâchement de la canne. La coordination canne-moulinet est essentielle : twitch-relâchement-tour de moulinet-twitch-relâchement-tour de moulinet, etc.",
                    illustrationsEtapes: nil,
                    conseil: "Au début, l'animation du stickbait peut sembler difficile à maîtriser. N'hésitez pas à vous entraîner dans une piscine ou près du bateau en eau calme pour voir l'action du leurre. Une fois le rythme acquis, cela devient instinctif."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Variation de vitesse et d'amplitude",
                    description: "Varier régulièrement la vitesse de récupération et l'amplitude des twitchs pour tester différentes animations. Séquence rapide (twitchs courts et fréquents) pour imiter un poisson paniqué, séquence lente (twitchs espacés) pour un poisson blessé. Alterner entre les deux rythmes au cours de la même récupération. Les prédateurs réagissent souvent aux changements de rythme.",
                    illustrationsEtapes: nil,
                    conseil: "Si vous voyez un thazard suivre sans attaquer, essayez d'abord d'accélérer brusquement (déclencheur réflexe). Si cela ne fonctionne pas, arrêtez complètement l'animation pendant 2-3 secondes puis reprenez doucement. Ce changement radical déclenche souvent l'attaque."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Pauses occasionnelles stratégiques",
                    description: "Intégrer des pauses de 2-4 secondes au cours de l'animation. Durant ces pauses, le stickbait flottant remonte lentement vers la surface, le suspending reste immobile entre deux eaux, et le coulant continue sa descente. Ces pauses créent un moment de vulnérabilité apparent qui déclenche souvent l'attaque d'un prédateur qui suivait sans oser se lancer. C'est le poisson qui décide.",
                    illustrationsEtapes: nil,
                    conseil: "Les pauses sont particulièrement efficaces après une série de twitchs rapides. L'immobilité soudaine du leurre après l'agitation crée un contraste fort qui attire l'attention et déclenche l'instinct de prédation. Ne sous-estimez jamais le pouvoir d'une bonne pause."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "Détection de la touche et attente",
                    description: "Lorsque vous sentez la touche (poids soudain, coup sec dans la canne), résister à l'envie de ferrer immédiatement. Attendre 1 seconde tout en continuant légèrement la récupération pour laisser au poisson le temps de bien engamer le leurre. Les thazards et wahoos ont des mâchoires très dures et des attaques ultra-rapides : un ferrage prématuré résulte souvent en un leurre arraché de la gueule du poisson.",
                    illustrationsEtapes: nil,
                    conseil: "Comptez mentalement 'un Mississippi' dès que vous sentez la touche, puis ferrez franchement. Cette seconde d'attente semble une éternité mais fait toute la différence entre un poisson bien ferré et un raté. Les thazards sont connus pour leurs attaques éclair suivies de sauts spectaculaires."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Ferrage puissant et combat",
                    description: "Après la seconde d'attente, ferrer fort et franchement en relevant la canne d'un coup sec vers le haut. Les thazards et wahoos ont des mâchoires ossifiées très dures qui nécessitent un ferrage appuyé pour que les hameçons pénètrent bien. Une fois ferré, maintenir une tension constante car ces poissons sont connus pour leurs sauts spectaculaires et leurs rushs explosifs qui peuvent décrocher un hameçon mal implanté.",
                    illustrationsEtapes: nil,
                    conseil: "Après le ferrage, baissez immédiatement la canne et combattez le poisson canne basse pour limiter l'effet de levier qui pourrait faire sauter l'hameçon. Les thazards effectuent souvent 2-3 sauts impressionnants : tendez légèrement la ligne pendant les sauts pour éviter qu'elle ne se prenne dans les nageoires ou la gueule."
                )
            ],
            conseilsPro: [
                "Les couleurs argentées avec dos bleu ou vert imitant les aiguillettes et sardines sont ultra-efficaces en eau claire et par temps ensoleillé sur les thazards et wahoos.",
                "Les couleurs flashy (chartreuse, rose, or) fonctionnent remarquablement bien en eau légèrement trouble, à l'aube, au crépuscule, ou par temps couvert.",
                "Le walking the dog classique s'exécute par une série de petits twitchs rapides : twitch-pause-twitch-pause. Le rythme doit être vif mais pas précipité.",
                "Les stickbaits coulants (sinking) sont redoutables sur les thazards méfiants qui suivent un leurre de surface sans oser attaquer. Laisser couler 5-6 secondes après quelques twitchs de surface déclenche souvent l'attaque pendant la descente.",
                "La récupération rapide combinée à l'animation erratique correspond au profil de chasse du wahoo qui poursuit les poissons volants à des vitesses folles. N'hésitez pas à récupérer vraiment vite.",
                "Le bas de ligne en câble acier est absolument obligatoire pour les thazards et wahoos. Leurs dents sont comme des rasoirs et couperont net n'importe quel monofilament ou fluorocarbone, aussi résistant soit-il.",
                "L'animation irrégulière est la clé : alternez twitchs rapides, twitchs lents, pauses courtes, pauses longues, accélérations brutales. Les poissons réagissent à l'imprévisibilité."
            ],
            erreursCourantes: [
                "Utiliser un bas de ligne en monofilament ou fluorocarbone au lieu de câble acier. Résultat garanti : le thazard coupe net la ligne avec ses dents tranchantes comme des lames de rasoir.",
                "Adopter une animation trop régulière et mécanique. Les stickbaits sont faits pour imiter des poissons en détresse, pas des métronomes. L'irrégularité est essentielle.",
                "Ferrer immédiatement dès la première touche sans attendre que le poisson engame. Résultat : beaucoup de ratés frustrants avec le leurre arraché de la gueule du poisson.",
                "Utiliser un stickbait trop léger qui limite la distance de lancer. Avec les prédateurs rapides comme les wahoos, il faut pouvoir lancer loin pour couvrir beaucoup d'eau.",
                "Négliger de varier la profondeur de récupération. Si rien ne mord en surface, laissez couler davantage : les thazards chassent souvent entre 2 et 5 mètres de profondeur.",
                "Abandonner trop rapidement un spot après quelques lancers infructueux. Les thazards se déplacent en groupes : si vous en ratez un, ses congénères vont souvent mordre dans les minutes qui suivent.",
                "Négliger l'affûtage des hameçons. Les mâchoires des thazards et wahoos sont très dures : des hameçons émoussés ne pénétreront pas suffisamment et le poisson se décrochera au premier saut."
            ],
            videoURL: nil,
            photosIllustrations: [
                "montage_traine_complet_schema.jpg",
                "detail_noeud_FG.jpg",
                "emerillon_qualite_recommande.jpg",
                "test_action_leurre.jpg"
            ],
            especesConcernees: [
                "carangueGT",
                "carangueBleue",
                "thonJaune",
                "bonite",
                "wahoo",
                "barracuda",
                "locheSaumonee",
                "thazard-raye"
            ]
        )
    }
    
    // MARK: - FICHE 7: Downrigger Traîne Profonde
    
    static func createDownriggerTraine() -> FicheTechnique {
        return FicheTechnique(
            id: "montage_downrigger",
            titre: "Downrigger Traîne Profonde",
            categorie: .montage,
            niveauDifficulte: .avance,
            dureeApprentissage: "60-90 minutes",
            description: """
            Le downrigger (parfois appelé boulet de canon) est un système sophistiqué de traîne profonde qui utilise un poids très lourd tracté par un câble dédié pour amener les leurres à une profondeur exacte et contrôlée. Cette technique permet d'atteindre des profondeurs inaccessibles aux méthodes classiques tout en conservant la possibilité de combattre le poisson directement, sans le poids du plomb.
            
            Le principe du downrigger repose sur une ingénieuse pince déclencheuse : la ligne de pêche est fixée au câble du downrigger via cette pince réglable qui libère automatiquement la ligne lorsqu'un poisson mord. Ainsi, le pêcheur descend son leurre à la profondeur souhaitée grâce au downrigger, mais dès qu'un poisson attaque, la ligne se détache et le combat se déroule normalement, sans être entravé par le poids du plomb.
            
            Cette technique excelle pour cibler la thermocline, cette couche d'eau où se concentrent les poissons pélagiques en raison des conditions optimales de température et d'oxygénation. L'échosondeur est indispensable pour localiser précisément cette zone productive qui peut varier de 15 à 60 mètres selon les saisons et les conditions océanographiques.
            
            En Nouvelle-Calédonie, le downrigger est particulièrement efficace pour la pêche au-dessus des DCPs et le long des tombants externes où les grands thons, wahoos et mahi-mahi chassent en profondeur. La maîtrise de cette technique demande un investissement en équipement et un apprentissage méthodique, mais offre un accès unique aux prédateurs qui évoluent bien en-dessous de la surface.
            """,
            materielNecessaire: [
                "Downrigger en plomb avec ailette anti-vrille (poids 4-8 kg selon profondeur)",
                "Câble ou ligne de downrigger sur moulinet dédié avec compteur de profondeur",
                "Pinces déclencheuses réglables (2-3 unités pour pêche multi-lignes)",
                "Canne de traîne classique avec moulinet robuste 30-50 lb",
                "Ligne-mère monofilament ou tresse 35-90 kg selon espèces",
                "Leurres adaptés traîne profonde (bavettes, cuillères, leurres à jupe)",
                "Échosondeur performant avec fonction thermocline (indispensable)",
                "Gants de manipulation renforcés (câbles sous tension)",
                "Compteur de profondeur digital (si moulinet non équipé)",
                "Tangons optionnels pour pêche multi-downriggers"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "step1",
                    ordre: 1,
                    titre: "Repérage de la profondeur cible à l'échosondeur",
                    description: "Utiliser l'échosondeur pour identifier la profondeur optimale de pêche. Rechercher la thermocline (changement brusque de température visible comme une bande sombre sur l'écran) où se concentrent naturellement les pélagiques. Repérer également les structures sous-marines (monts, tombants) et les éventuels poissons suspendus. Noter précisément la profondeur cible : c'est cette information qui guidera le réglage du downrigger.",
                    illustrationsEtapes: "downrigger_echosondeur",
                    conseil: "La thermocline est votre meilleure alliée en pêche au downrigger. En Nouvelle-Calédonie, elle se situe généralement entre 25 et 50 mètres selon la saison. C'est à cette profondeur que s'accumulent les nutriments et que se concentrent les poissons-fourrage, suivis de près par les prédateurs."
                ),
                EtapeTechnique(
                    id: "step2",
                    ordre: 2,
                    titre: "Mise à l'eau du leurre à 20-25 mètres",
                    description: "Avant de mettre en place le downrigger, filer d'abord le leurre de traîne à 20-25 mètres derrière le bateau. Vérifier que le leurre nage correctement à cette distance et que l'action est satisfaisante. Cette longueur de ligne entre le leurre et la pince déclencheuse permet un arc suffisant pour absorber les chocs et donne une action naturelle au leurre malgré la contrainte du downrigger.",
                    illustrationsEtapes: nil,
                    conseil: "Ne filez pas le leurre trop loin derrière le bateau avant de fixer la pince. 20-25 mètres est la distance optimale : suffisante pour que le leurre ne soit pas perturbé par le sillage du bateau, mais pas excessive pour faciliter la manipulation lors de la mise en place du système."
                ),
                EtapeTechnique(
                    id: "step3",
                    ordre: 3,
                    titre: "Passage de la ligne dans la pince déclencheuse",
                    description: "Saisir la ligne-mère de pêche et la faire passer dans la pince déclencheuse qui est reliée au câble du downrigger. Ajuster la tension de la pince selon le poids du leurre et la résistance de la ligne : trop serrée, elle ne libérera pas lors d'une touche ; trop lâche, elle se déclenchera intempestivement avec les vibrations de la traîne. Refermer soigneusement la pince sur la ligne.",
                    illustrationsEtapes: "downrigger_pince",
                    conseil: "Le réglage de la pince est un art subtil. Commencez avec une tension moyenne puis ajustez selon les résultats. La pince doit se déclencher au premier rush du poisson, mais pas avec les vibrations normales du leurre. Testez en tirant doucement sur la ligne : elle doit se libérer avec une traction franche mais pas au moindre à-coup."
                ),
                EtapeTechnique(
                    id: "step4",
                    ordre: 4,
                    titre: "Descente contrôlée du downrigger",
                    description: "Commencer à descendre lentement le downrigger en filant le câble tout en surveillant simultanément la ligne-mère de pêche. Maintenir une tension constante sur la ligne de traîne pour éviter qu'elle ne se détende complètement et que tout le fil de la bobine ne se dévide dans l'eau. La descente doit être progressive et régulière, à raison d'environ 30-50 cm par seconde. Observer le compteur de profondeur du downrigger.",
                    illustrationsEtapes: nil,
                    conseil: "La coordination entre la descente du downrigger et la gestion de la ligne de pêche demande un peu de pratique. Idéalement, ayez un équipier qui gère la ligne de pêche pendant que vous manipulez le câble du downrigger. Seul, c'est faisable mais requiert de l'attention."
                ),
                EtapeTechnique(
                    id: "step5",
                    ordre: 5,
                    titre: "Espacement si multi-downriggers",
                    description: "Si vous utilisez plusieurs downriggers simultanément (configuration avancée), espacer les pinces déclencheuses d'au moins 2 mètres verticalement sur le câble. Cette séparation verticale évite les emmêlements catastrophiques si deux poissons mordent simultanément. Utiliser des tangons pour écarter latéralement les différents downriggers et créer une couverture élargie de la colonne d'eau.",
                    illustrationsEtapes: "downrigger_setup",
                    conseil: "La pêche multi-downriggers est complexe mais productive. Configuration classique : un downrigger à tribord à 25m, un autre à bâbord à 30m, éventuellement un central à 35m. Cela couvre trois profondeurs différentes et maximise vos chances de trouver les poissons actifs."
                ),
                EtapeTechnique(
                    id: "step6",
                    ordre: 6,
                    titre: "Tension du câble et armement du frein",
                    description: "Une fois le downrigger à la profondeur souhaitée, vérifier que le câble est bien tendu et que le downrigger ne touche pas le fond (sauf si c'est l'objectif dans certaines configurations spéciales). Mettre ensuite le frein du moulinet de pêche en position 'Strike' (tension de combat) et récupérer tout le mou de la ligne-mère. La ligne doit former un arc léger entre la canne et la pince déclencheuse.",
                    illustrationsEtapes: nil,
                    conseil: "Le câble du downrigger doit toujours être tendu mais pas exagérément. Une tension excessive fatigue inutilement l'équipement et augmente les risques de rupture. Une fois en place, la ligne de pêche forme naturellement un arc gracieux jusqu'à la pince - c'est cet arc qui absorbera le choc lors du déclenchement."
                ),
                EtapeTechnique(
                    id: "step7",
                    ordre: 7,
                    titre: "Ajustement de la vitesse de traîne",
                    description: "Régler la vitesse du bateau pour une traîne modérée, généralement inférieure à 5 nœuds. Les dispositifs plongeurs comme les downriggers sont sensibles à la vitesse : au-delà de 5-6 nœuds, le downrigger risque de remonter significativement sous l'effet de la résistance hydraulique, faussant la profondeur de pêche. Vérifier régulièrement l'échosondeur pour confirmer que vous restez à la bonne profondeur.",
                    illustrationsEtapes: nil,
                    conseil: "La vitesse optimale pour le downrigger se situe entre 3 et 5 nœuds. C'est plus lent que la traîne de surface classique (6-8 nœuds) mais c'est à ces vitesses que les leurres profonds travaillent le mieux et que le downrigger maintient sa profondeur stable."
                ),
                EtapeTechnique(
                    id: "step8",
                    ordre: 8,
                    titre: "Surveillance et localisation optimale",
                    description: "Traîner idéalement au-dessus des DCPs, des tombants ou dans les zones où l'échosondeur révèle des concentrations de poissons. La thermocline est votre cible prioritaire. Effectuer des passages méthodiques en zigzag ou en cercles concentriques autour des structures productives. Observer constamment les cannes : une touche se manifeste par une courbure soudaine suivie d'un relâchement lorsque la pince libère la ligne.",
                    illustrationsEtapes: nil,
                    conseil: "Les DCPs sont des spots privilégiés pour le downrigger car les poissons y évoluent souvent en profondeur. Effectuez des passages à 50-100 mètres du DCP plutôt que trop près : les poissons se tiennent dans un rayon de plusieurs centaines de mètres autour de ces structures."
                ),
                EtapeTechnique(
                    id: "step9",
                    ordre: 9,
                    titre: "PRIORITÉ : Remonter le downrigger d'abord",
                    description: "Dès qu'une touche se produit et que la pince libère la ligne, REMONTER IMMÉDIATEMENT LE DOWNRIGGER avant de combattre le poisson. Cette étape est CRITIQUE et NON NÉGOCIABLE. Si vous commencez à combattre le poisson sans avoir remonté le downrigger, le poisson fera des cercles autour du câble du downrigger, emmêlera la ligne, et vous perdrez à la fois le poisson et potentiellement tout votre matériel.",
                    illustrationsEtapes: nil,
                    conseil: "C'est l'erreur numéro un des débutants au downrigger : ils sont tellement excités par la touche qu'ils oublient de remonter le downrigger et commencent directement à combattre. Répétez-vous mentalement : 'Touche = remonter downrigger, ensuite seulement combattre'. Faites-en un réflexe."
                ),
                EtapeTechnique(
                    id: "step10",
                    ordre: 10,
                    titre: "Combat du poisson après remontée",
                    description: "Une fois le downrigger remonté et sécurisé (accroché au bateau ou posé sur le pont), combattre normalement le poisson. Le combat s'effectue sans le poids du downrigger puisque la ligne a été libérée par la pince déclencheuse. Le poisson ne sent que la résistance de la canne et du frein. Combattez méthodiquement, en alternant pompages et récupérations, jusqu'à l'épuisement du poisson.",
                    illustrationsEtapes: nil,
                    conseil: "L'avantage majeur du downrigger est qu'il permet de pêcher profond tout en conservant un combat 'propre', sans le poids d'un gros plomb. Le poisson se bat normalement et vous pouvez pleinement apprécier sa puissance. C'est sportif et beaucoup plus gratifiant qu'un combat entravé par un lest de 2 kg."
                )
            ],
            conseilsPro: [
                "Espacer les lignes d'au moins 2 mètres verticalement si vous utilisez plusieurs downriggers. Cette séparation est cruciale pour éviter les emmêlements désastreux lors de touches multiples simultanées.",
                "La thermocline est votre zone cible prioritaire. C'est là que se concentrent naturellement les prédateurs en raison des conditions optimales de température, d'oxygénation et de nourriture disponible.",
                "La vitesse est critique en pêche au downrigger : au-delà de 5 nœuds, l'efficacité diminue drastiquement car le downrigger remonte sous l'effet de la résistance hydraulique. Restez entre 3 et 5 nœuds maximum.",
                "Les DCPs et les tombants sont des zones idéales pour le downrigger. Les poissons y chassent souvent en profondeur, précisément là où votre downrigger positionne les leurres.",
                "Ajustez la tension de la pince déclencheuse selon le poids du leurre et les conditions. Une pince bien réglée se déclenche au premier rush du poisson mais pas avec les vibrations normales de la traîne.",
                "Vérifiez et testez le fonctionnement de la pince déclencheuse avant chaque sortie. Une pince grippée, rouillée ou mal réglée peut ruiner une session de pêche en ne se déclenchant pas lors d'une touche.",
                "L'ailette à l'arrière du downrigger est essentielle pour éviter qu'il ne vrille et ne tourne sur lui-même, ce qui vrille le câble et peut provoquer des ruptures ou des emmêlements."
            ],
            erreursCourantes: [
                "Erreur CRITIQUE : remonter le poisson AVANT d'avoir remonté le downrigger. Résultat garanti : emmêlement catastrophique de la ligne autour du câble du downrigger et perte du poisson et potentiellement du matériel. Remontez TOUJOURS le downrigger en premier.",
                "Adopter une vitesse de traîne excessive (supérieure à 5 nœuds). Le downrigger remonte significativement sous l'effet de la pression hydraulique et vous ne pêchez plus à la profondeur souhaitée.",
                "Négliger de maintenir une tension suffisante sur la ligne de pêche pendant la descente du downrigger. Résultat : tout le fil de la bobine se dévide dans l'eau en créant un nid d'oiseau impossible à démêler.",
                "Oublier d'utiliser l'échosondeur pour localiser la thermocline et les structures. Pêcher 'à l'aveugle' au downrigger est un gaspillage de temps : vous devez savoir précisément où sont les poissons.",
                "Espacer insuffisamment les pinces déclencheuses en configuration multi-downriggers (moins de 2 mètres). Les emmêlements sont alors inévitables dès qu'un poisson mord.",
                "Oublier les gants lors de la manipulation du câble du downrigger sous tension. Les câbles d'acier peuvent provoquer des coupures sérieuses aux mains nues.",
                "Négliger l'entretien des pinces déclencheuses. Des pinces grippées, rouillées ou encrassées de sel ne fonctionneront pas correctement et vous feront rater des poissons."
            ],
            videoURL: nil,
            photosIllustrations: [
                "montage_traine_complet_schema.jpg",
                "detail_noeud_FG.jpg",
                "emerillon_qualite_recommande.jpg",
                "test_action_leurre.jpg"
            ],
            especesConcernees: [
                "thonJaune",
                "wahoo",
                "mahiMahi",
                "thon_obese",
                "marlin",                       // Marlin (Bleu/Noir)
                "Espadon voilier"
            ]
        )
    }
    
    // MARK: - FICHE 8: Récupération Linéaire Constante
    
    static func createRecuperationLineaire() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_recuperation_lineaire",
            titre: "Récupération Linéaire Constante",
            categorie: .animation,
            niveauDifficulte: .debutant,
            dureeApprentissage: "5-10 minutes",
            description: """
            La récupération linéaire constante est l'animation la plus simple et la plus naturelle de toutes les techniques de pêche aux leurres. Elle consiste à ramener le leurre à vitesse régulière sans variation, laissant le leurre produire sa propre action sous l'effet de la récupération. Cette présentation mimétique imite un poisson-fourrage se déplaçant tranquillement à une profondeur constante.
            
            Cette technique repose sur la capacité naturelle du leurre à travailler : la queue des shads s'anime toute seule, les bavettes des poissons nageurs créent un wobbling régulier, et les jupes de traîne ondulent naturellement dans le sillage. Le pêcheur se contente de maintenir une vitesse de récupération adaptée, sans imprimer de mouvements supplémentaires avec la canne.
            
            La récupération linéaire est particulièrement efficace lorsque les poissons sont en activité alimentaire et chassent activement. Elle permet de couvrir rapidement de larges zones de pêche, augmentant ainsi les chances de rencontrer un prédateur. Beaucoup de pêcheurs ont d'ailleurs capturé leurs plus beaux poissons sur les derniers mètres de récupération, en ramenant simplement le leurre de façon continue pour relancer.
            
            En Nouvelle-Calédonie, cette animation excelle en traîne lente dans le lagon (4-8 nœuds) pour les carangues et thons, et en traîne rapide offshore (10+ nœuds) pour les wahoos. Au lancer, elle fonctionne admirablement sur les chasses actives où les prédateurs montent facilement dans la colonne d'eau pour poursuivre une proie en déplacement.
            """,
            materielNecessaire: [
                "Cannes traîne ou casting adaptées à la technique (lente ou rapide)",
                "Moulinets avec récupération régulière (pas de gros à-coups)",
                "Ligne-mère tressée ou nylon selon technique",
                "Leurres adaptés : shads, swimbaits, poissons nageurs, jupes de traîne",
                "Bas de ligne fluorocarbone ou câble métallique selon espèces",
                "Indicateur de vitesse (GPS ou compteur de nœuds) pour traîne",
                "Émerillons de qualité pour éviter le vrillage",
                "Têtes plombées de poids adaptés pour atteindre la profondeur souhaitée"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "lineaire_step1",
                    ordre: 1,
                    titre: "Choix du leurre adapté à la vitesse",
                    description: "Sélectionner un leurre dont l'action naturelle correspond à la vitesse de récupération souhaitée. Les shads et swimbaits fonctionnent bien à toutes les vitesses grâce à leur queue mobile. Les poissons nageurs à bavette nécessitent une vitesse minimale pour plonger correctement (4-8 nœuds). Les leurres à jupe (traîne) excellent à vitesse rapide (6-12 nœuds). Vérifier que le leurre nage correctement en le testant près du bateau.",
                    illustrationsEtapes: "leurres_action_naturelle",
                    conseil: "Chaque leurre a une plage de vitesses optimale. Les shads fonctionnent de 2 à 10 nœuds, les bavettes plongeantes de 4 à 8 nœuds, les jupes de traîne de 6 à 16 nœuds. Respectez ces vitesses pour une nage naturelle."
                ),
                EtapeTechnique(
                    id: "lineaire_step2",
                    ordre: 2,
                    titre: "Lancer au-delà de la zone cible (casting)",
                    description: "Si vous pêchez au lancer, projeter le leurre au-delà de la zone où vous pensez que les poissons se trouvent. Cela permet de commencer la récupération avant d'atteindre la zone productive, donnant au leurre le temps de se stabiliser et d'atteindre la profondeur souhaitée. Laisser le leurre couler jusqu'à la profondeur désirée en comptant les secondes après l'impact.",
                    illustrationsEtapes: nil,
                    conseil: "Pour les eaux peu profondes (lagon), comptez 1 seconde par 50 cm de profondeur. Pour cibler 2 mètres, laissez couler 4 secondes avant de commencer la récupération."
                ),
                EtapeTechnique(
                    id: "lineaire_step3",
                    ordre: 3,
                    titre: "Positionner la canne correctement",
                    description: "Maintenir le scion de la canne entre 8h et 10h (légèrement relevé) pour garder un bon contrôle de la ligne et pouvoir ferrer efficacement. Cette position permet de sentir les touches tout en gardant suffisamment de fil hors de l'eau pour éviter qu'il ne frotte sur le bateau ou les obstacles. En traîne, placer la canne dans le porte-canne avec un angle d'environ 45° vers l'extérieur.",
                    illustrationsEtapes: nil,
                    conseil: "Une canne trop basse (proche de l'horizontale) réduit votre capacité à ferrer rapidement. Une canne trop haute fatigue inutilement le bras. Trouvez le compromis entre confort et efficacité."
                ),
                EtapeTechnique(
                    id: "lineaire_step4",
                    ordre: 4,
                    titre: "Démarrer la récupération à vitesse constante",
                    description: "Commencer à récupérer la ligne à une vitesse régulière et constante. En casting, utilisez le moulinet sans imprimer de mouvements avec la canne. En traîne, maintenez une vitesse de bateau stable selon l'espèce ciblée : 4-8 nœuds pour le lagon, 6-10 nœuds pour les thons offshore, 12-16 nœuds pour les wahoos. La régularité est la clé de cette animation.",
                    illustrationsEtapes: "recuperation_lineaire_constante",
                    conseil: "Concentrez-vous sur la régularité plutôt que sur la vitesse absolue. Un moulinet avec un bon ratio de récupération (5:1 à 6:1) facilite le maintien d'une vitesse constante sans fatigue."
                ),
                EtapeTechnique(
                    id: "lineaire_step5",
                    ordre: 5,
                    titre: "Maintenir la profondeur de pêche",
                    description: "Ajuster la vitesse de récupération pour maintenir le leurre à la profondeur souhaitée. Plus vous récupérez vite, plus le leurre remonte vers la surface (sauf pour les leurres plongeants à bavette qui descendent avec la vitesse). Pour pêcher près du fond, récupérez lentement et laissez occasionnellement le leurre recontacter le substrat pour vérifier que vous êtes toujours à bonne profondeur.",
                    illustrationsEtapes: nil,
                    conseil: "En lagon peu profond, une récupération trop rapide fera sortir votre leurre de la zone de chasse. Ralentissez si vous sentez que le leurre effleure fréquemment la surface. Accélérez s'il accroche régulièrement le fond."
                ),
                EtapeTechnique(
                    id: "lineaire_step6",
                    ordre: 6,
                    titre: "Couvrir systématiquement la zone",
                    description: "Balayer méthodiquement toute la zone de pêche en effectuant des lancers en éventail (casting) ou des passages parallèles (traîne). La récupération linéaire permet de prospecter rapidement de grandes étendues d'eau. Changer légèrement l'angle de lancer à chaque passe pour couvrir l'ensemble du secteur. En traîne, effectuer des passages espacés de 50 à 100 mètres.",
                    illustrationsEtapes: nil,
                    conseil: "La force de la récupération linéaire est la couverture d'eau. Ne restez pas fixé sur un seul axe : variez les angles pour maximiser vos chances de croiser un banc de poissons en déplacement."
                ),
                EtapeTechnique(
                    id: "lineaire_step7",
                    ordre: 7,
                    titre: "Observer l'action du leurre",
                    description: "Vérifier régulièrement que le leurre nage correctement en l'observant près du bateau (traîne) ou en le testant sur les premiers mètres (casting). Un leurre qui vrille, qui sort de l'eau ou qui ne vibre pas correctement ne déclenchera pas d'attaques. Ajuster la vitesse ou changer de leurre si l'action n'est pas satisfaisante. Un bon leurre doit avoir une nage stable et régulière.",
                    illustrationsEtapes: nil,
                    conseil: "Profitez des premiers mètres de chaque récupération pour vérifier l'action du leurre. Si quelque chose ne va pas (vrillage, nage erratique), corrigez immédiatement plutôt que de gaspiller tout le lancer."
                ),
                EtapeTechnique(
                    id: "lineaire_step8",
                    ordre: 8,
                    titre: "Varier subtilement la vitesse (optionnel)",
                    description: "Bien que l'animation soit fondamentalement linéaire, vous pouvez introduire de légères variations de vitesse pour déclencher des attaques hésitantes. Accélérer légèrement pendant 2-3 secondes puis revenir à la vitesse normale peut simuler une proie qui détecte un danger et tente de fuir. Ces micro-variations subtiles maintiennent l'intérêt des prédateurs sans briser la linéarité de base.",
                    illustrationsEtapes: nil,
                    conseil: "Ces variations doivent rester très discrètes. L'objectif n'est pas de faire du stop-and-go, mais simplement d'ajouter un peu d'imprévisibilité à une nage globalement constante. Pensez à un poisson qui accélère brièvement puis reprend sa vitesse de croisière."
                ),
                EtapeTechnique(
                    id: "lineaire_step9",
                    ordre: 9,
                    titre: "Détecter et attendre les touches",
                    description: "Rester concentré pendant toute la récupération car les touches peuvent survenir à tout moment. En linéaire, les touches sont souvent franches et violentes, surtout si les poissons sont actifs. Sentir un poids soudain, un coup sec dans la canne ou voir la ligne partir latéralement. Attendre 1 seconde avant de ferrer pour laisser au poisson le temps d'engamer complètement le leurre.",
                    illustrationsEtapes: nil,
                    conseil: "Beaucoup d'attaques se produisent dans les derniers mètres de récupération, lorsque le leurre approche du bateau ou du bord. Ne relâchez jamais votre attention et continuez l'animation jusqu'au bout."
                ),
                EtapeTechnique(
                    id: "lineaire_step10",
                    ordre: 10,
                    titre: "Ferrage et adaptation",
                    description: "Ferrer franchement dès que vous sentez le poids du poisson. Si vous ratez plusieurs touches, c'est peut-être que votre vitesse n'est pas adaptée : les poissons suivent mais n'arrivent pas à engamer. Ralentissez légèrement. Si au contraire vous n'avez aucune touche, essayez d'accélérer pour provoquer des attaques réflexes ou changez de profondeur. La récupération linéaire est une base qu'il faut ajuster selon l'humeur des poissons.",
                    illustrationsEtapes: nil,
                    conseil: "Notez mentalement à quelle vitesse et à quelle profondeur se sont produites les touches. Si vous capturez un poisson à une récupération lente près du fond, reproduisez exactement cette configuration sur les lancers suivants."
                )
            ],
            conseilsPro: [
                "La récupération linéaire est la présentation la plus mimétique qui existe : elle imite un poisson-fourrage se déplaçant naturellement à vitesse et profondeur constantes.",
                "Cette animation couvre rapidement de grandes zones d'eau, ce qui en fait une technique de prospection idéale pour localiser les poissons avant d'affiner avec des animations plus complexes.",
                "En traîne lente lagon (4-8 nœuds), privilégiez les leurres à bavette plongeante et les petits shads qui maintiennent une profondeur constante sans remonter en surface.",
                "En traîne rapide offshore (10-16 nœuds), les leurres à jupe et les têtes bullet sont parfaits car ils restent stables à haute vitesse et créent une traînée de bulles attractive.",
                "La vitesse de récupération doit être adaptée à l'espèce : lente (2-4 nœuds) pour les espèces démersales calmes, moyenne (5-8 nœuds) pour les carangues et thons actifs, rapide (10-16 nœuds) pour les wahoos ultra-véloces.",
                "Beaucoup de pêcheurs capturent leurs plus beaux poissons sur les derniers mètres de récupération linéaire rapide, lorsqu'ils ramènent le leurre pour relancer. Ne négligez jamais cette phase.",
                "Par eau froide ou poissons peu actifs, ralentissez considérablement la récupération. Par eau chaude et poissons en chasse, accélérez franchement pour déclencher des attaques réflexes."
            ],
            erreursCourantes: [
                "Récupérer de façon irrégulière en imprimant involontairement des à-coups avec la canne ou le moulinet. La constance est la clé de cette animation.",
                "Adopter une vitesse inadaptée au type de leurre : trop rapide pour les shads souples qui vrillent, trop lente pour les bavettes plongeantes qui ne descendent pas.",
                "Négliger de vérifier régulièrement la profondeur de nage du leurre. En linéaire, le leurre doit évoluer dans la bonne couche d'eau pendant toute la récupération.",
                "Abandonner la technique trop rapidement si les premières passes sont infructueuses. La récupération linéaire demande de couvrir beaucoup d'eau pour rencontrer des poissons actifs.",
                "Ferrer trop rapidement dès la première sensation de touche. Attendez de sentir vraiment le poids du poisson avant de ferrer, surtout avec les leurres souples.",
                "Utiliser un leurre trop léger qui ne descend pas assez rapidement à la profondeur voulue. Le temps que le leurre atteigne la bonne couche d'eau, la moitié de la récupération est déjà passée.",
                "Relâcher l'attention sur les derniers mètres de récupération. C'est précisément à ce moment que beaucoup d'attaques se produisent, notamment de la part des gros spécimens."
            ],
            videoURL: nil,
            photosIllustrations: [
                "recuperation_lineaire_schema",
                "vitesses_par_espece",
                "positions_canne_lineaire"
            ],
            especesConcernees: [
                "carangueGT",
                "carangueBleue",
                "thonJaune",
                "bonite",
                "mahiMahi",
                "wahoo",
                "barracuda",
                "becunes",
                "Vivaneaux (lent près du fond)",
                "Empereurs (lent près du fond)"
            ]
        )
    }
    
    // MARK: - FICHE 9: Twitching / Jerking
    
    static func createTwitchingJerking() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_twitching_jerking",
            titre: "Twitching / Jerking (Animation Saccadée)",
            categorie: .animation,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "20-30 minutes",
            description: """
            Le twitching (petits coups secs) et le jerking (coups amples) sont des techniques d'animation erratiques qui imitent un poisson blessé, désorienté ou en fuite paniquée. Ces mouvements saccadés déclenchent l'instinct de prédation des carnassiers en leur présentant une proie vulnérable facile à capturer.
            
            Le principe repose sur des tractions brusques et irrégulières de la canne qui font dévier le leurre de sa trajectoire, créant une nage désordonnée et imprévisible. Entre chaque traction, une courte pause permet au leurre de se stabiliser avant le prochain coup de canne. Cette alternance mouvement-pause est la signature de cette animation.
            
            Cette technique excelle avec les stickbaits, jerkbaits et certains poppers qui n'ont pas d'action propre et dépendent entièrement de l'animation du pêcheur. L'irrégularité est la clé du succès : aucun poisson blessé ne nage de façon mécanique et régulière. Plus l'animation est chaotique et imprévisible, plus elle est efficace.
            
            En Nouvelle-Calédonie, le twitching/jerking est redoutable sur les thazards méfiants qui refusent les leurres en linéaire, sur les wahoos ultra-rapides qui réagissent aux changements brusques de direction, et sur les carangues GT qui ne peuvent résister à l'image d'une proie vulnérable zigzaguant en surface.
            """,
            materielNecessaire: [
                "Canne casting ou spinning action rapide 15-40 kg",
                "Moulinet haute vitesse ratio 6:1 minimum pour récupérer le mou",
                "Tresse multifilament 20-40 kg pour transmission directe",
                "Bas de ligne fluorocarbone 30-60 kg ou câble acier (wahoo/thazards)",
                "Stickbaits, jerkbaits, soft jerkminnows 8-18 cm",
                "Émerillons à roulement pour éviter le vrillage",
                "Gants de lancer pour protéger les mains",
                "Lunettes polarisées pour suivre le leurre"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "twitch_step1",
                    ordre: 1,
                    titre: "Choix du leurre à animer",
                    description: "Sélectionner un leurre sans action propre qui dépend de l'animation : stickbait, jerkbait ou soft jerkminnow. Ces leurres ont un profil profilé sans bavette et nécessitent les coups de canne pour nager. Vérifier que le leurre est bien équipé d'hameçons triples affûtés car les attaques sont souvent violentes.",
                    illustrationsEtapes: nil,
                    conseil: "Les stickbaits coulants (sinking) permettent d'explorer plusieurs couches d'eau en variant le temps de descente entre les twitchs. Les flottants restent en surface."
                ),
                EtapeTechnique(
                    id: "twitch_step2",
                    ordre: 2,
                    titre: "Lancer et laisser stabiliser",
                    description: "Effectuer un lancer précis vers la zone cible. Laisser le leurre se poser et se stabiliser 2-3 secondes avant de commencer l'animation. Cette pause initiale permet au leurre de créer des ondes qui attirent l'attention des prédateurs. Pour les leurres coulants, compter les secondes de chute pour atteindre la profondeur désirée.",
                    illustrationsEtapes: nil,
                    conseil: "Ne commencez jamais l'animation immédiatement après l'impact. La pause initiale est importante et génère souvent des attaques de poissons qui ont repéré le splash de l'atterrissage."
                ),
                EtapeTechnique(
                    id: "twitch_step3",
                    ordre: 3,
                    titre: "Positionner la canne basse",
                    description: "Tenir la canne en position basse (scion entre 8h et 9h) pour optimiser l'efficacité des twitchs. Cette position permet des tractions plus efficaces et une meilleure transmission de l'énergie au leurre. Récupérer le mou de ligne laissé par la pause initiale avant de commencer.",
                    illustrationsEtapes: "twitch_position_canne",
                    conseil: "Une canne trop haute réduit l'amplitude des twitchs et fatigue le bras. La position basse est fondamentale pour un twitching efficace et durable."
                ),
                EtapeTechnique(
                    id: "twitch_step4",
                    ordre: 4,
                    titre: "Premier twitch court et sec",
                    description: "Donner un premier coup de scion court (15-30 cm) et sec vers le bas. Le geste doit être franc et rapide, comme si vous vouliez arracher le leurre de l'eau. Ce twitch fait dévier le leurre latéralement ou le fait plonger brusquement selon le type de leurre. Observer le comportement du leurre pour ajuster.",
                    illustrationsEtapes: nil,
                    conseil: "Le twitch est dans le poignet, pas dans tout le bras. Imaginez que vous donnez un coup sec sur un clou avec un marteau : petit mouvement, grande efficacité."
                ),
                EtapeTechnique(
                    id: "twitch_step5",
                    ordre: 5,
                    titre: "Pause et récupération du mou",
                    description: "Immédiatement après le twitch, faire une pause d'1-2 secondes en récupérant rapidement le mou créé par le relâchement de la canne. Cette récupération doit être rapide pour maintenir le contact avec le leurre. Pendant la pause, le leurre se stabilise et c'est souvent à ce moment que les poissons attaquent.",
                    illustrationsEtapes: nil,
                    conseil: "La pause est aussi importante que le twitch lui-même. C'est le moment de vulnérabilité apparente qui déclenche l'attaque. Soyez prêt à ferrer pendant la pause."
                ),
                EtapeTechnique(
                    id: "twitch_step6",
                    ordre: 6,
                    titre: "Enchaîner les twitchs de façon irrégulière",
                    description: "Répéter la séquence twitch-pause-récupération de façon totalement irrégulière. Alternez 2-3 twitchs rapides rapprochés, puis un twitch isolé, puis une pause plus longue de 3-4 secondes, puis à nouveau 2 twitchs. L'imprévisibilité est la clé : aucun pattern régulier ne doit émerger.",
                    illustrationsEtapes: "twitch_sequences",
                    conseil: "Pensez à un poisson réellement blessé : ses mouvements sont chaotiques, pas métronomiques. Variez amplitude, rythme et durée des pauses constamment."
                ),
                EtapeTechnique(
                    id: "twitch_step7",
                    ordre: 7,
                    titre: "Jerking ample pour changement radical",
                    description: "De temps en temps, remplacer les petits twitchs par un jerking ample : traction franche de 60-100 cm qui fait bondir le leurre violemment. Cette variation radicale surprend les poissons qui suivaient sans oser attaquer. Le jerking simule une proie qui détecte un danger et tente de fuir désespérément.",
                    illustrationsEtapes: nil,
                    conseil: "Le jerking est particulièrement efficace après 10-15 secondes de twitching régulier. Ce changement brutal de comportement déclenche souvent les attaques réflexes des prédateurs hésitants."
                ),
                EtapeTechnique(
                    id: "twitch_step8",
                    ordre: 8,
                    titre: "Varier la profondeur (coulants)",
                    description: "Avec les stickbaits coulants, varier la profondeur en laissant couler plus ou moins longtemps entre les séquences de twitchs. Trois twitchs rapides suivis d'une pause de 5 secondes pendant laquelle le leurre coule peuvent déclencher des attaques pendant la descente. Couvrir ainsi toute la colonne d'eau.",
                    illustrationsEtapes: nil,
                    conseil: "Les thazards et wahoos chassent souvent entre 2 et 8 mètres sous la surface. Ne restez pas fixé en surface : explorez les couches profondes avec des temps de chute variables."
                ),
                EtapeTechnique(
                    id: "twitch_step9",
                    ordre: 9,
                    titre: "Observer les suivis et ajuster",
                    description: "Surveiller attentivement le leurre et l'eau environnante pour détecter les poissons qui suivent sans attaquer. Si vous voyez une forme sombre suivre le leurre, ne changez rien brutalement : continuez l'animation en accélérant très légèrement le rythme ou en introduisant un jerking ample pour déclencher l'attaque.",
                    illustrationsEtapes: nil,
                    conseil: "Les lunettes polarisées sont essentielles pour repérer les suivis. Un wahoo ou un thazard peut suivre sur 10-20 mètres avant de se décider. La patience et la persévérance paient."
                ),
                EtapeTechnique(
                    id: "twitch_step10",
                    ordre: 10,
                    titre: "Ferrage retardé et combat",
                    description: "Attendre de sentir franchement le poids du poisson avant de ferrer. Les attaques sur twitching sont souvent explosives mais les poissons peuvent rater le leurre dans leur précipitation. Compter mentalement 'un Mississippi' puis ferrer fermement. Les thazards et wahoos ont des mâchoires très dures nécessitant un ferrage appuyé.",
                    illustrationsEtapes: nil,
                    conseil: "Le ferrage prématuré est l'erreur numéro un en twitching. Vous verrez l'attaque ou sentirez le coup, mais attendez vraiment de sentir le poids tirant sur la ligne avant de ferrer."
                )
            ],
            conseilsPro: [
                "L'irrégularité est la clé absolue du succès en twitching/jerking. Aucun poisson blessé ne nage de façon mécanique : variez constamment amplitude, rythme et durée des pauses.",
                "Les attaques se produisent majoritairement pendant les pauses, lorsque le leurre se stabilise après un twitch. C'est le moment de vulnérabilité apparente qui déclenche l'instinct de prédation.",
                "Par mer calme et eau claire, privilégiez le twitching subtil avec de petits coups de scion. Par mer agitée ou eau trouble, forcez sur le jerking ample pour que le leurre reste visible.",
                "Les stickbaits coulants sont plus polyvalents que les flottants car ils permettent d'explorer toute la colonne d'eau en variant les temps de chute entre les animations.",
                "Le câble acier est absolument obligatoire pour les thazards et wahoos. Leurs dents de rasoir couperont net n'importe quel fluorocarbone en une fraction de seconde.",
                "Si un poisson suit sans attaquer, essayez d'abord d'accélérer le rythme (réflexe de poursuite). Si cela échoue, faites l'inverse : arrêtez complètement 3-4 secondes puis reprenez doucement.",
                "La technique est physiquement exigeante sur de longues sessions. Alternez avec des animations plus reposantes comme le linéaire pour économiser votre énergie."
            ],
            erreursCourantes: [
                "Adopter un rythme régulier et mécanique de type métronome. Les poissons détectent cette artificialité et refusent le leurre.",
                "Twitch trop faible ou hésitant qui ne fait pas vraiment dévier le leurre de sa trajectoire. Le geste doit être franc et décidé.",
                "Ne pas récupérer suffisamment le mou entre les twitchs, créant une bannière molle qui empêche de détecter les touches et de ferrer efficacement.",
                "Maintenir la canne trop haute pendant l'animation. La position basse (8-9h) est essentielle pour l'efficacité du mouvement et éviter la fatigue.",
                "Ferrer immédiatement dès la première sensation de touche. Les wahoos et thazards ratent souvent le leurre au premier rush : attendez de sentir le poids.",
                "Abandonner trop rapidement la technique après quelques lancers infructueux. Le twitching demande de l'investissement mais les résultats sont spectaculaires.",
                "Utiliser un bas de ligne en fluorocarbone au lieu de câble acier pour les espèces à dents. Résultat garanti : coupure nette et perte du leurre et du poisson."
            ],
            videoURL: nil,
            photosIllustrations: [
                "twitch_technique_schema",
                "sequences_irreguliere",
                "position_canne_twitch"
            ],
            
            especesConcernees: [
                "carangueGT",
                "carangueBleue",
                "wahoo",
                "barracuda",
                "becunes",
                "thazard_raye",
                "bonite",
                "mahiMahi"
            ]
        )
    }
    
    // MARK: - FICHE 10: Stop and Go
    
    static func createStopAndGo() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_stop_and_go",
            titre: "Stop and Go (Alternance Récupération-Pause)",
            categorie: .animation,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "15-20 minutes",
            description: """
            Le stop and go est une technique d'animation qui alterne des phases de récupération active (go) avec des arrêts complets (stop). Cette alternance simule une proie qui se déplace puis s'arrête brusquement, créant des moments de vulnérabilité apparente qui déclenchent l'attaque des prédateurs.
            
            Le principe repose sur le contraste entre mouvement et immobilité. Pendant la phase 'go', le leurre nage activement et attire l'attention. Pendant la phase 'stop', le leurre se stabilise, flotte, coule ou plane selon son type, offrant une fenêtre d'attaque idéale. La pêche au leurre et ses animations permet de simuler un poisson blessé et généralement un poisson blessé adopte une nage aléatoire avec des pauses régulières. La majorité des touches se produisent précisément pendant ou juste après l'arrêt.
            
            L’animation d’un leurre en Stop & Go procure chez le carnassier le sentiment d’une proie facile puis d’une proie qui va lui échapper lors du redémarrage d’où souvent une attaque brutale et superbe sur un leurre de surface.
            
            Maintenant le Stop & Go n’aura pas le même résultat suivant le type de leurre. On retrouve sur le marché des leurres de différentes densités, flottant, suspending ou encore coulant ce qui vous donne différent effet avec l’animation d’un leurre Stop & Go, les voici :
                - Stop & Go Floating : Avec un leurre de type flottant, idéal sur certaines zones encombrées ou lorsque le poisson stationne dans la couche supérieur. Le leurre à bavette coule à la moindre traction et remonte des que celle-ci s’arrête !
            
                - Stop & Go Suspending : Avec un leurre de type suspending. Un leurre parfaitement équilibré permettant de stagner à la même profondeur, le « stop » permet d’insister sur le poste et de laisser le leurre à la vue du carnassier, le « go » permet de, susciter le besoin au carnassier et l’énervement pour lancer l’attaque.
            
                - Stop & Go Sinking : Avec un leurre de type sinking. Superbe pour prospecter un trou ou une fosse, de plus le leurre descend généralement en papillonnant envoyant des flashs avec ses flans. Une fois la pause réalisée le leurre peux continuer à descendre ou remonter suivant la traction fourni par le pêcheur et suivant la profondeur donné par le constructeur du leurre.
            
            Cette animation est particulièrement efficace sur les poissons peu actifs ou méfiants qui hésitent à attaquer un leurre en mouvement constant. L'arrêt brise leur hésitation en leur présentant une cible stationnaire facile. Le stop and go fonctionne avec tous les types de leurres : souples, durs, jigs, en surface ou en profondeur.
            
            En Nouvelle-Calédonie, le stop and go excelle en jigging vertical sur les tombants pour les vivaneaux et loches, en traîne lente dans le lagon pour les carangues méfiantes, et au casting sur les chasses de surface pour déclencher les GT et barracudas indécis. La technique s'adapte à pratiquement toutes les situations.
            """,
            materielNecessaire: [
                "Canne adaptée à la technique (verticale, casting ou traîne)",
                "Moulinet avec bon frein progressif",
                "Tresse_illustration",
                "Leurres polyvalents : shads, jigs, poissons nageurs, stickbaits",
                "Bas de ligne adapté aux espèces ciblées",
                "Montre ou compteur pour chronométrer les pauses (optionnel)",
                "Têtes plombées de poids variable pour jigging"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "stopgo_step1",
                    ordre: 1,
                    titre: "Choix du leurre et technique",
                    description: "Sélectionner le leurre selon la technique utilisée. Pour le jigging vertical : jigs métalliques. Pour le casting : shads, stickbaits ou poissons nageurs. Pour la traîne : leurres à jupe ou bavettes. Tous les leurres peuvent être animés en stop and go, l'important est d'adapter le rythme à la situation.",
                    illustrationsEtapes: "StopAndGo3Schemas_illustration",
                    conseil: "Les leurres suspending (qui restent entre deux eaux) sont parfaits pour le stop and go car ils maintiennent leur profondeur pendant les pauses, restant dans la zone de chasse."
                ),
                EtapeTechnique(
                    id: "stopgo_step2",
                    ordre: 2,
                    titre: "Phase GO - Récupération active",
                    description: "Effectuer 3 à 5 tractions amples avec la canne (jigging vertical) ou 3 à 5 tours de moulinet rapides (casting/traîne). Cette phase doit être dynamique et visible pour attirer l'attention des prédateurs. Le leurre monte, nage ou vibre activement selon le type. Cette phase dure généralement 2 à 4 secondes.",
                    illustrationsEtapes: "stopgo_phase_go",
                    conseil: "La phase GO doit être suffisamment longue pour attirer l'attention mais pas trop pour ne pas fatiguer le poisson. 3-5 tractions est le ratio optimal testé en compétition."
                ),
                EtapeTechnique(
                    id: "stopgo_step3",
                    ordre: 3,
                    titre: "Phase STOP - Arrêt complet",
                    description: "Stopper complètement toute récupération. Ne touchez ni à la canne ni au moulinet. Laissez le leurre faire ce qu'il veut naturellement : flotter (flottant), couler lentement (coulant) ou rester en suspension (suspending). Cette phase d'immobilité dure 3 à 5 secondes. Restez extrêmement concentré car 70% des touches arrivent maintenant.",
                    illustrationsEtapes: nil,
                    conseil: "Pendant le STOP, gardez une tension légère sur la ligne pour détecter les touches. Beaucoup d'attaques sont très discrètes : un simple poids qui apparaît sur la ligne."
                ),
                EtapeTechnique(
                    id: "stopgo_step4",
                    ordre: 4,
                    titre: "Compter mentalement la pause",
                    description: "Pendant le STOP, compter mentalement 'un-deux-trois-quatre-cinq' à vitesse normale (environ 5 secondes). Ce décompte mental aide à maintenir des pauses régulières et évite de les écourter par impatience. Observer attentivement la ligne ou le scion pendant tout le décompte pour détecter les touches.",
                    illustrationsEtapes: nil,
                    conseil: "Les débutants ont tendance à écourter les pauses par impatience. Forcez-vous à compter jusqu'à 5. Si vous n'avez pas de touches après 10-15 séquences, essayez des pauses plus longues (7-10 secondes)."
                ),
                EtapeTechnique(
                    id: "stopgo_step5",
                    ordre: 5,
                    titre: "Reprise de la phase GO",
                    description: "Après les 5 secondes de pause, reprendre la phase GO avec les mêmes 3-5 tractions ou tours de moulinet. Le contraste entre l'immobilité et la reprise soudaine du mouvement est crucial. Cette transition brutale peut elle aussi déclencher des attaques réflexes de poissons qui hésitaient.",
                    illustrationsEtapes: nil,
                    conseil: "Variez occasionnellement l'intensité de la reprise : parfois douce et progressive, parfois brutale et explosive. Cette imprévisibilité maintient l'intérêt des prédateurs."
                ),
                EtapeTechnique(
                    id: "stopgo_step6",
                    ordre: 6,
                    titre: "Répéter le cycle complet",
                    description: "Enchaîner les cycles GO (3-5 actions) - STOP (5 secondes) de façon continue sur toute la récupération ou la descente/remontée en jigging. En jigging vertical, effectuer 5-10 cycles pour couvrir la colonne d'eau du fond vers la surface. En casting, continuer jusqu'au bateau. En traîne, maintenir le pattern pendant plusieurs minutes.",
                    illustrationsEtapes: "stopgo_cycles",
                    conseil: "La régularité du pattern GO-STOP est importante pour établir un rythme prévisible que les poissons peuvent anticiper. Mais n'hésitez pas à casser ce rythme occasionnellement."
                ),
                EtapeTechnique(
                    id: "stopgo_step7",
                    ordre: 7,
                    titre: "Varier la durée des pauses",
                    description: "Si après 10-15 cycles vous n'avez pas de touches, expérimenter avec des pauses plus courtes (2-3 secondes) ou plus longues (7-10 secondes). Les poissons très actifs préfèrent les pauses courtes. Les poissons peu actifs ou méfiants réagissent mieux aux pauses longues qui leur donnent le temps de cibler.",
                    illustrationsEtapes: nil,
                    conseil: "Par eau froide ou pression de pêche élevée, allongez systématiquement les pauses à 7-10 secondes. Les poissons sont plus prudents et ont besoin de plus de temps pour se décider."
                ),
                EtapeTechnique(
                    id: "stopgo_step8",
                    ordre: 8,
                    titre: "Adaptation à la profondeur (jigging)",
                    description: "En jigging vertical profond (>100m), augmenter l'amplitude des tractions et la durée des pauses. En profondeur, les mouvements doivent être plus amples pour être perceptibles et les pauses plus longues car les poissons ont plus de distance à parcourir pour atteindre le leurre.",
                    illustrationsEtapes: nil,
                    conseil: "Règle empirique : doublez la durée des pauses tous les 50 mètres de profondeur. À 150m, une pause de 10 secondes est appropriée."
                ),
                EtapeTechnique(
                    id: "stopgo_step9",
                    ordre: 9,
                    titre: "Détection des touches pendant le STOP",
                    description: "Les touches pendant le STOP sont souvent très discrètes : un simple poids qui apparaît sur la ligne, une tension qui se relâche légèrement (le poisson remonte avec le leurre dans la gueule), ou le scion qui se redresse. Ne ferrez pas immédiatement : attendez de sentir vraiment le poids tirer avant de ferrer.",
                    illustrationsEtapes: nil,
                    conseil: "En jigging profond, une touche pendant le STOP se manifeste souvent par une simple absence de contact avec le fond quand vous reprenez. Le poisson a pris le jig pendant la descente."
                ),
                EtapeTechnique(
                    id: "stopgo_step10",
                    ordre: 10,
                    titre: "Ferrage et ajustements",
                    description: "Ferrer franchement dès que vous sentez le poids du poisson tirer. Si vous ratez plusieurs touches, c'est probablement que vos pauses sont trop courtes et les poissons n'ont pas le temps d'engamer. Rallongez à 7-10 secondes. Si au contraire aucune touche, raccourcissez à 2-3 secondes pour des poissons plus actifs.",
                    illustrationsEtapes: "nil",
                    conseil: "Notez mentalement le moment exact de la touche : début, milieu ou fin du STOP ? Cela vous indique si les poissons sont rapides (début) ou prudents (fin). Ajustez la durée en conséquence."
                )
            ],
            conseilsPro: [
                "70% des touches en stop and go se produisent pendant ou immédiatement après la pause. La phase STOP est le moment critique de l'animation.",
                "Les pauses de 5 secondes sont un excellent point de départ universel. Ajustez ensuite selon l'activité des poissons : 2-3s si actifs, 7-10s si méfiants.",
                "Le stop and go est THE technique pour les poissons peu actifs, calés sur le fond ou sous forte pression de pêche. Quand le linéaire ne fonctionne pas, essayez le stop and go.",
                "En jigging vertical, le moment où le jig touche le fond après une pause est critique. Beaucoup de vivaneaux et loches attaquent précisément à ce moment.",
                "Combinez stop and go avec d'autres techniques : 5 cycles de stop-go puis 10 secondes de linéaire puis reprise du stop-go. Cette variation maintient l'intérêt.",
                "Les leurres suspending (Suspending) sont parfaits car ils restent dans la zone de chasse pendant les pauses. Les coulants et flottants fonctionnent aussi mais changent de profondeur.",
                "Par eau très froide (<18°C), les pauses peuvent être rallongées jusqu'à 15-20 secondes. Les poissons sont léthargiques et ont besoin de temps pour réagir."
            ],
            erreursCourantes: [
                "Écourter les pauses par impatience. Forcez-vous à compter mentalement jusqu'à 5 minimum, même si cela vous semble une éternité.",
                "Ne pas maintenir une légère tension sur la ligne pendant le STOP. Sans tension, vous ne pouvez pas détecter les touches discrètes.",
                "Adopter un pattern trop mécanique et régulier. Cassez occasionnellement le rythme avec une pause extra-longue ou deux phases GO consécutives sans STOP.",
                "Ferrer trop rapidement dès la première sensation pendant le STOP. Laissez au poisson le temps d'engamer : attendez de sentir le poids tirer.",
                "Ne pas adapter la durée des pauses aux conditions. Ce qui fonctionne un jour (5s) peut être inefficace le lendemain (besoin de 10s).",
                "Abandonner la technique après seulement 5-10 cycles. Le stop and go demande de la persévérance : faites au moins 20-30 cycles avant de changer de technique.",
                "Négliger la phase GO en la faisant trop molle. La phase GO doit être dynamique pour créer le contraste avec le STOP."
            ],
            videoURL: nil,
            photosIllustrations: [
                "StopAndGoFloattingSchema_illustration",
                "StopAndGoSinkingSchema_illustration",
                "StopAndGoSuspendingSchema_illustration"
            ],
            especesConcernees: [
                "Vivaneaux (toutes espèces)",
                "locheSaumonee",
                "carangueGT",
                "carangueBleue",
                "barracuda",
                "becunes",
                "wahoo",
                "thonJaune",
                "thon_obese",
                "becDeCane",
                "thazard-raye",
            ]
        )
    }
    
    // MARK: - FICHE 11: Walking the Dog
    
    static func createWalkingTheDog() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_walking_the_dog",
            titre: "Walking the Dog (Zigzag Surface)",
            categorie: .animation,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "30-45 minutes",
            description: """
            Le walking the dog est une animation de surface spectaculaire qui fait zigzaguer le leurre de gauche à droite en créant une trajectoire sinueuse hypnotisante. Cette technique, réservée aux stickbaits de surface sans bavette, imite parfaitement un poisson blessé ou désorienté tentant de maintenir son équilibre.
            
            Le principe repose sur une série de petits coups de scion rapides et rythmés qui font osciller le leurre alternativement à gauche puis à droite. Chaque twitch imprime une impulsion latérale au leurre qui change de direction. L'enchaînement rapide des twitchs crée un zigzag fluide et régulier, d'où le nom 'walking the dog' - la promenade du chien qui va de droite à gauche en reniflant.
            
            Cette animation est visuellement très attractive et fonctionne particulièrement bien sur les prédateurs de surface qui chassent activement. Le mouvement erratique combiné aux remous et flashs créés par le leurre déclenche des attaques réflexes explosives. C'est l'une des animations les plus excitantes de la pêche aux leurres car les attaques sont visibles et spectaculaires.
            
            En Nouvelle-Calédonie, le walking the dog est redoutable sur les carangues GT en maraude sur les récifs, sur les thazards chassant en meute en surface, et sur les barracudas embusqués qui ne peuvent résister à l'image d'un poisson vulnérable zigzaguant au-dessus d'eux.
            """,
            materielNecessaire: [
                "Canne casting ou spinning 15-40 kg action rapide",
                "Moulinet haute vitesse ratio 6:1+ pour récupérer le mou rapidement",
                "Tresse 20-40 kg pour transmission directe sans élasticité",
                "Bas de ligne fluorocarbone 30-60 kg (15-25 kg pour barracudas méfiants)",
                "Stickbaits de surface 10-15 cm (flottants uniquement)",
                "Lunettes polarisées indispensables pour suivre le leurre",
                "Casquette pour réduire l'éblouissement",
                "Gants fins pour protéger les mains"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "wtd_step1",
                    ordre: 1,
                    titre: "Sélection du stickbait adapté",
                    description: "Choisir un stickbait de surface FLOTTANT sans bavette. Les modèles entre 10 et 15 cm sont polyvalents. Vérifier que le leurre est bien équipé d'hameçons triples acérés et d'anneaux brisés solides. Les stickbaits de qualité ont un équilibrage parfait qui facilite le walking.",
                    illustrationsEtapes: nil,
                    conseil: "Les débutants réussiront mieux avec des stickbaits légers (15-20g) qui répondent facilement. Les modèles lourds (30-40g) permettent des lancers plus longs mais demandent plus de technique."
                ),
                EtapeTechnique(
                    id: "wtd_step2",
                    ordre: 2,
                    titre: "Lancer et pause initiale",
                    description: "Effectuer un lancer précis vers la zone cible. Laisser le leurre se poser et rester immobile 3-5 secondes. Cette pause initiale permet aux ondes de l'impact de se dissiper et donne aux prédateurs le temps de repérer le leurre. Récupérer le mou de ligne pendant cette pause.",
                    illustrationsEtapes: nil,
                    conseil: "Les GT remontent souvent sous le leurre pendant cette pause initiale. Avec des lunettes polarisées par temps clair, vous pouvez parfois voir l'ombre du poisson arriver."
                ),
                EtapeTechnique(
                    id: "wtd_step3",
                    ordre: 3,
                    titre: "Position canne basse fondamentale",
                    description: "Tenir la canne en position très basse, scion entre 8h et 9h, presque horizontal au ras de l'eau. Cette position est absolument critique pour le walking the dog. Plus la canne est basse, plus les twitchs seront efficaces et moins vous vous fatiguerez. Pointer le scion vers le leurre.",
                    illustrationsEtapes: "wtd_position_canne",
                    conseil: "C'est l'erreur numéro un des débutants : tenir la canne trop haute. Forcez-vous à baisser au maximum. Votre poignet doit être au niveau de votre taille, pas de votre épaule."
                ),
                EtapeTechnique(
                    id: "wtd_step4",
                    ordre: 4,
                    titre: "Premier twitch du poignet",
                    description: "Donner le premier twitch : petit coup de poignet sec vers le bas (10-15 cm d'amplitude). Le geste est uniquement dans le poignet, comme si vous tapiez sur un clou. Le leurre doit faire un pas de côté sur l'eau (généralement vers la gauche pour un droitier). Observer la réaction du leurre.",
                    illustrationsEtapes: nil,
                    conseil: "Le geste ne doit mobiliser que le poignet, absolument pas le bras. Imaginez que votre bras est immobilisé dans un plâtre : seul le poignet bouge."
                ),
                EtapeTechnique(
                    id: "wtd_step5",
                    ordre: 5,
                    titre: "Récupération du mou instantanée",
                    description: "Immédiatement après le twitch, récupérer le mou créé par le relâchement avec un demi-tour de moulinet rapide. Cette récupération doit être quasi-simultanée au twitch. Maintenir une tension légère constante sur la ligne pour être prêt au twitch suivant.",
                    illustrationsEtapes: nil,
                    conseil: "La coordination twitch-récupération est la clé du walking the dog. Au début, décomposez : twitch... récupération. Puis progressivement, faites-les en même temps."
                ),
                EtapeTechnique(
                    id: "wtd_step6",
                    ordre: 6,
                    titre: "Enchaîner les twitchs rythmés",
                    description: "Répéter immédiatement le deuxième twitch : même geste sec du poignet. Le leurre doit maintenant partir dans l'autre direction (vers la droite). Continuer l'enchaînement : twitch-récup-twitch-récup-twitch-récup de façon rythmée et continue. Le leurre zigzague ainsi de gauche à droite.",
                    illustrationsEtapes: "wtd_zigzag_action",
                    conseil: "Le rythme doit être soutenu : environ 2-3 twitchs par seconde. Trop lent et le leurre ne zigzague pas fluide ment, trop rapide et vous perdez le contrôle."
                ),
                EtapeTechnique(
                    id: "wtd_step7",
                    ordre: 7,
                    titre: "Maintenir le rythme constant",
                    description: "Une fois le rythme établi, le maintenir sur 10-15 twitchs sans interruption. Le leurre doit dessiner une belle trajectoire sinueuse continue sur 5-10 mètres. La régularité du rythme est importante pour créer une nage fluide et naturelle qui hypnotise les prédateurs.",
                    illustrationsEtapes: nil,
                    conseil: "Concentrez-vous sur la fluidité : twitch-récup-twitch-récup-twitch-récup en continu comme une machine bien huilée. Au début c'est difficile, mais après 20-30 lancers, cela devient instinctif."
                ),
                EtapeTechnique(
                    id: "wtd_step8",
                    ordre: 8,
                    titre: "Pauses stratégiques occasionnelles",
                    description: "Après 10-15 twitchs, stopper complètement 2-3 secondes en laissant le leurre immobile à la surface. Cette pause brise le rythme et déclenche souvent les GT ou barracudas qui suivaient sans oser attaquer. Reprendre ensuite le walking normal ou accélérer le rythme.",
                    illustrationsEtapes: nil,
                    conseil: "La pause est particulièrement efficace si vous voyez ou suspectez un poisson en train de suivre le leurre. L'arrêt brutal simule une proie épuisée qui devient une cible facile."
                ),
                EtapeTechnique(
                    id: "wtd_step9",
                    ordre: 9,
                    titre: "Variations de rythme et d'amplitude",
                    description: "Varier occasionnellement le rythme : 5 twitchs rapides puis 3 twitchs lents puis reprise rapide. Varier aussi l'amplitude : petits twitchs serrés (zigzag étroit) puis grands twitchs amples (zigzag large). Ces variations maintiennent l'intérêt des prédateurs et déclenchent les hésitants.",
                    illustrationsEtapes: nil,
                    conseil: "Par mer calme et poissons méfiants, privilégiez le walking lent et serré. Par mer agitée ou poissons actifs, walking rapide et ample pour créer plus de turbulences visibles."
                ),
                EtapeTechnique(
                    id: "wtd_step10",
                    ordre: 10,
                    titre: "Attendre l'attaque et ferrage retardé",
                    description: "Quand vous voyez ou sentez l'attaque, ne ferrez surtout pas immédiatement. Comptez mentalement 'un Mississippi' en continuant à pointer la canne vers le leurre, puis ferrez franchement vers le haut. Les attaques de surface sont spectaculaires mais les poissons ratent souvent : donnez-leur le temps d'engamer.",
                    illustrationsEtapes: nil,
                    conseil: "Le ferrage prématuré est la cause numéro un des ratés en surface. Voir une GT de 15 kg exploser sur votre leurre est si excitant qu'on ferre par réflexe. Résistez : comptez jusqu'à 1, PUIS ferrez."
                )
            ],
            conseilsPro: [
                "La position canne basse (8-9h) est absolument critique. C'est ce qui différencie un débutant d'un expert en walking the dog. Forcez-vous à tenir bas même si c'est inconfortable au début.",
                "Le walking the dog se maîtrise par la pratique. Entraînez-vous dans une piscine ou près du bateau pour voir l'action et perfectionner la coordination twitch-récupération sans la pression de la pêche.",
                "Les lunettes polarisées sont indispensables non seulement pour suivre le leurre mais surtout pour voir les poissons approcher par en-dessous. Cette anticipation visuelle aide à contrôler son excitation au moment de l'attaque.",
                "Par eau agitée ou vent fort, augmentez l'amplitude des twitchs et le volume du leurre (modèles 13-15 cm) pour que l'animation reste visible dans le chaos de surface.",
                "Le walking the dog fonctionne mieux à l'aube, au crépuscule et de nuit quand les prédateurs chassent activement en surface. En plein soleil, la technique perd de son efficacité.",
                "Si un poisson suit sans attaquer, accélérez brusquement le rythme de walking pendant 5-6 twitchs comme si la proie détectait le danger. Ce changement déclenche souvent l'attaque réflexe.",
                "Les stickbaits avec une finition holographique ou des côtés argentés créent des flashs lumineux pendant le walking qui attirent les prédateurs de très loin, surtout en eau claire."
            ],
            erreursCourantes: [
                "Tenir la canne trop haute. C'est l'erreur majeure qui rend le walking inefficace et fatigant. La canne doit être quasiment horizontale, scion à 8-9h maximum.",
                "Utiliser le bras entier au lieu du poignet seul. Le walking the dog est un mouvement de poignet, pas d'épaule. Garder le bras immobile et travailler uniquement avec le poignet.",
                "Ne pas récupérer assez rapidement le mou entre les twitchs. Sans récupération rapide, la bannière devient molle et le leurre ne réagit plus aux twitchs suivants.",
                "Adopter un rythme trop lent. Le walking the dog nécessite un rythme soutenu (2-3 twitchs/seconde) pour créer un zigzag fluide. Trop lent et le leurre fait des mouvements saccadés peu naturels.",
                "Ferrer immédiatement à l'attaque visible. C'est humain mais catastrophique : 80% des ferrages prématurés arrachent le leurre de la gueule du poisson. Compter 'un Mississippi' est vital.",
                "Utiliser des stickbaits coulants au lieu de flottants. Les coulants sont pour le twitching subsurface, pas pour le walking the dog qui est strictement une technique de surface.",
                "Abandonner après quelques lancers infructueux. Le walking the dog demande de couvrir beaucoup d'eau et de tomber sur des poissons actifs. Persévérance et patience sont essentielles."
            ],
            videoURL: nil,
            photosIllustrations: [
                "wtd_position_canne_correcte",
                "wtd_trajectoire_zigzag",
                "wtd_sequence_twitchs"
            ],
            
            especesConcernees: [
                "locheSaumonee",
                "carangueGT",
                "carangueBleue",
                "barracuda",
                "becunes",
                "wahoo",
                "thonJaune",
                "thon_obese",
                "becDeCane",
                "thazard-raye",
            ]
        )
    }
    
    
    // MARK: - FICHE 12: Slow Pitch Jigging
    
    static func createSlowPitchJigging() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_slow_pitch_jigging",
            titre: "Slow Pitch Jigging (Dandine Lente)",
            categorie: .animation,
            niveauDifficulte: .avance,
            dureeApprentissage: "1-2 heures pratique",
            description: """
            Le slow pitch jigging est une technique verticale japonaise ultra-fine qui privilégie la descente papillonnante contrôlée du leurre plutôt que sa remontée. Cette approche repose sur des tirées courtes (10-50 cm) suivies de relâchements complets qui provoquent une chute désaxée et imprévisible du jig, imitant une crevette ou un poisson blessé. 70% des touches se produisent pendant la phase descendante.
            
            Le principe hydrodynamique est simple mais puissant : lors de la levée courte de la canne, le jig se met à plat. Lors du relâchement, la ligne semi-détendue permet au jig de papillonner, décrocher latéralement et exposer alternativement ses flancs en changeant d'axe. Cette action désordonnée simule une proie vulnérable mourante que les prédateurs embusqués ne peuvent résister.
            
            Les jigs de slow pitch ont un corps plat ou asymétrique avec un centre de gravité décentré qui amplifie le papillonnement. Contrairement au fast jigging qui cible les poissons actifs en chasse, le slow pitch excelle sur les poissons calés sur le fond, méfiants, peu actifs ou sous forte pression de pêche. C'est une pêche de précision, de lecture et de tempo.
            
            En Nouvelle-Calédonie, le slow pitch jigging est redoutable sur les tombants lagunaires (20-100m) pour les vivaneaux et pagres, autour des DCP (50-150m) pour les thons jaunes et dentis, et en offshore profond (150-300m) pour les vivaneaux profonds et loches pintade. La technique s'adapte parfaitement aux conditions calédoniennes avec eau translucide et poissons éduqués.
            """,
            materielNecessaire: [
                "Canne slow pitch parabolique fine PE 1-3 (50-200g selon profondeur)",
                "Moulinet 5000-14000 à ratio lent 5:1 pour contrôle précis",
                "Tresse multifilament PE 1-2.5 multicolore pour visualiser la verticalité",
                "Jigs plats/asymétriques 30-400g selon profondeur (corps large, CG décentré)",
                "Assist hooks simples en tête (parfois en queue) montés sur kevlar",
                "Fluorocarbone 20-40 kg pour leader court (1-2m)",
                "Émerillons à roulement pour éviter vrillage",
                "Échosondeur pour localiser structures et poissons suspendus",
                "Ancre flottante ou moteur électrique pour dérive lente contrôlée",
                "Gants fins pour sentir les touches discrètes"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "slow_step1",
                    ordre: 1,
                    titre: "Localisation et positionnement bateau",
                    description: "Utiliser l'échosondeur pour repérer les tombants récifaux, monts sous-marins ou poissons suspendus. Positionner le bateau au-dessus de la structure et couper le moteur thermique. Utiliser une ancre flottante ou le moteur électrique pour maintenir une dérive très lente (< 1 nœud). La verticalité de la ligne est absolument critique en slow pitch.",
                    illustrationsEtapes: "slow_jigging_verticalite",
                    conseil: "En Nouvelle-Calédonie, les tombants du lagon sud (Prony, Goro) de 20-100m sont parfaits pour débuter. Ciblez les zones de 40-80m où se concentrent vivaneaux rubis et pagres."
                ),
                EtapeTechnique(
                    id: "slow_step2",
                    ordre: 2,
                    titre: "Sélection du jig adapté à la profondeur",
                    description: "Choisir le poids selon la profondeur et le courant. Règle empirique : doubler le grammage par rapport à la profondeur (80g pour 40m). Lagune 20-100m : jigs 40-150g. DCP 50-150m : jigs 100-250g. Offshore 150-300m : jigs 250-400g. Privilégier les jigs plats avec finition glow ou holographique.",
                    illustrationsEtapes: "slow_jigs_selection",
                    conseil: "Les jigs en forme de feuille de saule (leaf shape) papillonnent mieux que les modèles droits. Par eau trouble ou profonde, les finitions glow UV sont redoutables."
                ),
                EtapeTechnique(
                    id: "slow_step3",
                    ordre: 3,
                    titre: "Descente contrôlée jusqu'au fond",
                    description: "Ouvrir le pick-up et laisser descendre le jig verticalement jusqu'au fond. Observer la bannière pour maintenir la verticalité : si elle dérive, le bateau se déplace trop vite. Compter mentalement les secondes de descente (utile pour revenir à la même profondeur). Sentir le 'toc' du contact fond via la tresse.",
                    illustrationsEtapes: nil,
                    conseil: "En profondeur moyenne (50-100m), la descente dure 30-60 secondes. Ne soyez pas impatient : certains vivaneaux attaquent déjà pendant cette phase. Gardez le frein serré."
                ),
                EtapeTechnique(
                    id: "slow_step4",
                    ordre: 4,
                    titre: "Première levée courte de la canne",
                    description: "Une fois le jig au fond, lever doucement la canne de 30 à 60 cm (10-20 cm en peu profond, 50 cm en profondeur). Le mouvement est lent et contrôlé, la canne doit plier au tiers supérieur. Cette levée met le jig à plat et le prépare pour le papillonnement. Ne pas tirer brutalement.",
                    illustrationsEtapes: "slow_pitch_levee",
                    conseil: "Imaginez que vous soulevez délicatement un objet fragile du fond. Le geste est précis, pas violent. La canne fait le travail, pas votre bras."
                ),
                EtapeTechnique(
                    id: "slow_step5",
                    ordre: 5,
                    titre: "Relâchement et descente papillonnante (CRITIQUE)",
                    description: "Après la levée, redescendre immédiatement la canne à sa position initiale en accompagnant le mouvement. Relâcher complètement la tension (ligne semi-détendue) pour permettre au jig de papillonner librement pendant 2-4 secondes. NE PAS bloquer la ligne. Observer attentivement la bannière car 70% des touches arrivent MAINTENANT.",
                    illustrationsEtapes: "slow_papillonnement",
                    conseil: "C'est LE moment critique. Votre ligne doit avoir un léger mou visible. Si elle reste tendue, vous bridez le papillonnement et tuez l'efficacité. Lâchez vraiment !"
                ),
                EtapeTechnique(
                    id: "slow_step6",
                    ordre: 6,
                    titre: "Pitch lent au moulinet",
                    description: "Pendant ou après le relâchement, effectuer 1/8 à 1/2 tour de moulinet (selon profondeur). Peu profond 20-50m : 1/8 tour. Moyen 50-150m : 1/4-1/2 tour. Profond 150-300m : 1/2-1 tour. Ce pitch minimal récupère le mou et prépare la prochaine levée. La récupération doit être fluide et lente.",
                    illustrationsEtapes: nil,
                    conseil: "Le ratio de moulinet lent (5:1) est crucial ici. Il empêche la récupération trop rapide qui casserait le rythme lent caractéristique du slow pitch."
                ),
                EtapeTechnique(
                    id: "slow_step7",
                    ordre: 7,
                    titre: "Pause d'observation (optionnel)",
                    description: "Après 3-5 cycles levée-descente identiques, marquer une pause complète de 5-10 secondes sans toucher ni canne ni moulinet. Laisser le jig totalement immobile dans la colonne d'eau. Cette pause brise le rythme et déclenche les poissons qui suivaient sans oser attaquer. Observer la bannière pour détecter les touches.",
                    illustrationsEtapes: nil,
                    conseil: "Les pauses longues (10s) sont particulièrement efficaces par eau froide ou pression de pêche élevée. Les poissons méfiants ont besoin de temps pour se décider."
                ),
                EtapeTechnique(
                    id: "slow_step8",
                    ordre: 8,
                    titre: "Répétition et couverture colonne d'eau",
                    description: "Répéter les cycles levée-relâchement-pitch de façon monotone et régulière. Effectuer 10-20 cycles pour remonter du fond vers la mi-eau (environ 10-30m de remontée totale). Le désordre vient du jig lui-même, pas du pêcheur qui doit rester régulier. Couvrir méthodiquement toute la colonne d'eau productive.",
                    illustrationsEtapes: "slow_coverage_eau",
                    conseil: "En slow pitch, la patience et la régularité priment sur la variation. Contrairement au fast jigging, maintenez un rythme monotone : c'est le jig qui fait le travail."
                ),
                EtapeTechnique(
                    id: "slow_step9",
                    ordre: 9,
                    titre: "Détection des touches discrètes",
                    description: "Les touches en slow pitch sont souvent très subtiles : un simple poids qui apparaît, une tension qui se relâche (le poisson remonte avec le jig), ou la bannière qui cesse de plonger. Surveiller constamment la ligne. En profondeur, une touche se manifeste parfois par l'absence de contact fond quand vous relâchez. Ne ferrez pas immédiatement.",
                    illustrationsEtapes: nil,
                    conseil: "Avec une tresse multicolore, vous pouvez voir la ligne 'sauter' de couleur quand un poisson prend et modifie la profondeur. Soyez attentif à ces micro-signaux."
                ),
                EtapeTechnique(
                    id: "slow_step10",
                    ordre: 10,
                    titre: "Ferrage et combat vertical",
                    description: "Quand vous détectez une touche, tendre fermement la ligne en levant progressivement la canne pour sentir le poids. Une fois le poids confirmé, ferrer franchement vers le haut. En profondeur, le ferrage doit être ample car il y a beaucoup de fil à tendre. Combattre en pompant : canne haute pour soulever, canne basse pour récupérer.",
                    illustrationsEtapes: nil,
                    conseil: "Les vivaneaux et loches ont des gueules osseuses dures. Le ferrage doit être appuyé. Ne vous contentez pas d'un petit coup de poignet : ferrez avec conviction."
                )
            ],
            conseilsPro: [
                "Le slow pitch jigging est une pêche de confiance dans le leurre, pas dans la force du pêcheur. Si vous sentez trop votre jig, vous pêchez trop vite. Ralentissez.",
                "70% des touches se produisent pendant la descente papillonnante. Cette phase est votre moment critique : relâchez vraiment la tension pour laisser le jig travailler.",
                "La verticalité est absolue. Dès que votre bannière commence à dériver de plus de 30°, remontez et repositionnez le bateau. La pêche en biais tue l'efficacité du slow pitch.",
                "Les jigs plats en forme de feuille (leaf) papillonnent mieux que les modèles droits. Investissez dans des jigs de qualité avec un vrai travail de descente erratique.",
                "Par eau translucide lagunaire calédonienne, les poissons voient très bien et sont méfiants. Le slow pitch avec ses mouvements lents et naturels est parfait pour ces conditions difficiles.",
                "Testez vos jigs en bassin ou à quai pour visualiser leur action de descente. Vous devez voir le papillonnement, les changements d'axe et les flashs des flancs.",
                "Changez de spot si après 20-30 cycles vous n'avez aucune touche. Le slow pitch n'est pas une technique de prospection rapide : il faut être sur le poisson."
            ],
            erreursCourantes: [
                "Aller trop vite. C'est l'erreur numéro un. Le slow pitch est lent par définition. Si vous vous ennuyez, c'est bon signe : vous avez trouvé le bon rythme.",
                "Garder la ligne tendue pendant la descente. Sans relâchement, le jig descend droit comme un ascenseur sans papillonner. Vous devez voir du mou dans la bannière.",
                "Utiliser des jigs trop légers qui ne descendent pas assez vite ou trop lourds qui descendent comme des pierres sans action. Le bon poids = profondeur × 2 en grammes.",
                "Pêcher en dérive rapide (> 1 nœud). À cette vitesse, impossible de maintenir la verticalité. Utilisez une ancre flottante ou le moteur électrique pour ralentir.",
                "Faire des animations trop amples (> 1 mètre de levée). Le slow pitch est minimaliste : petites levées de 30-50 cm maximum. L'amplitude vient de la profondeur, pas de vos gestes.",
                "Vouloir sentir le jig en permanence. En slow pitch, vous ne devez pas toujours sentir le jig. Le contact intermittent avec des phases de mou est normal et recherché.",
                "Utiliser un moulinet à ratio rapide (6:1+). Cela vous pousse à récupérer trop vite. Un ratio lent 5:1 ou moins force le rythme correct."
            ],
            videoURL: nil,
            photosIllustrations: [
                "slow_jigging_cycle_complet",
                "jigs_plats_asymetriques",
                "papillonnement_action",
                "profondeurs_poids_NC"
            ],
            especesConcernees: [
                "Vivaneaux (rubis, flamme, chien, job)",
                "Pagres",
                "locheSaumonee",
                "carangueGT",
                "carangueBleue",
                "barracuda",
                "becunes",
                "wahoo",
                "thonJaune",
                "thon_obese",
                "becDeCane",
                "thazard-raye",
                "Dentis",
                "Empereurs"
            ]
        )
    }
    
    // MARK: - FICHE 13: Fast Pitch Jigging
    
    static func createFastPitchJigging() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_fast_pitch_jigging",
            titre: "Fast Pitch Jigging (Dandine Rapide)",
            categorie: .animation,
            niveauDifficulte: .avance,
            dureeApprentissage: "1-2 heures pratique",
            description: """
            Le fast pitch jigging (ou speed jigging) est une technique verticale énergique qui privilégie les remontées explosives rapides pour imiter un poisson paniqué fuyant vers la surface. Cette approche agressive utilise des tirées hautes (80-250 cm) combinées à un moulinage constant et rapide (6-12 tours) pour créer un mouvement darting erratique en montée qui déclenche des attaques réflexes par poursuite.
            
            Le principe hydrodynamique est opposé au slow pitch : l'attaque se déclenche pendant la remontée rapide, pas la descente. Le jig doit filer droit ou en léger S vers la surface en vibrant fortement et en produisant un signal hydrodynamique intense. Les poissons réagissent par réflexe de poursuite pour intercepter cette proie qui semble leur échapper.
            
            Les jigs de fast pitch ont un corps compact et dense avec un profil allongé ou fuselé et un centre de gravité bas ou central. Ils descendent rapidement et remontent de façon rectiligne en flashant. Contrairement au slow pitch qui cible les poissons calés, le fast jigging excelle sur les poissons actifs en chasse, dans des zones de courant établi et de bonne oxygénation.
            
            En Nouvelle-Calédonie, le fast pitch jigging est redoutable dans les passes lagunaires (30-100m) sur les carangues GT et barracudas en chasse active, autour des DCP (100-250m) sur les wahoos et thazards en pleine eau, et en offshore profond (250-400m+) sur les thons obèses et sérioles. La technique couvre rapidement toute la colonne d'eau pour localiser les poissons actifs.
            """,
            materielNecessaire: [
                "Canne fast/extra fast PE 3-6 (150-600g) à blank rigide",
                "Moulinet 10000-30000 à ratio rapide 5.5:1+ et très puissant",
                "Tresse PE 4-8 pour transmettre les tirées sans élasticité",
                "Jigs compacts/fuselés 80-800g selon profondeur (stick jigs, tapered)",
                "Assist hooks triples renforcés en tête montés sur kevlar épais",
                "Câble acier 40-60 cm pour wahoo/thazard obligatoire",
                "Fluorocarbone 40-80 kg pour leader court si pas de dents",
                "Gants renforcés pour protéger des frottements",
                "Harnais de combat pour offshore profond (> 200m)",
                "Échosondeur haute définition pour repérer chasses"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fast_step1",
                    ordre: 1,
                    titre: "Repérage des poissons actifs",
                    description: "Utiliser l'échosondeur pour localiser les chasses sous-surface, les poissons suspendus en pleine eau ou les bancs actifs autour des DCP. Le fast jigging cible les poissons en mouvement et en activité alimentaire. Observer aussi les oiseaux qui plongent (indicateur de chasse de thons). Positionner le bateau au-dessus de l'activité.",
                    illustrationsEtapes: nil,
                    conseil: "Les meilleures heures pour le fast jigging en Nouvelle-Calédonie : milieu de matinée (9h-11h) et milieu d'après-midi (14h-16h) quand les thons et wahoos sont actifs autour des DCP."
                ),
                EtapeTechnique(
                    id: "fast_step2",
                    ordre: 2,
                    titre: "Sélection du jig selon profondeur",
                    description: "Choisir un jig compact adapté. Lagune/passes 30-100m : jigs 80-200g. DCP 100-250m : jigs 200-400g. Offshore 250-400m+ : jigs 400-800g tapered. Les jigs de fast pitch sont plus lourds que ceux de slow pitch car ils doivent descendre très vite et rester verticaux pendant les remontées rapides.",
                    illustrationsEtapes: "fast_jigs_compact",
                    conseil: "Les jigs en forme de cigare (cigar shape) ou effilés (tapered) sont optimaux pour le fast jigging. Ils vibrent intensément en remontée et créent un flash attractif."
                ),
                EtapeTechnique(
                    id: "fast_step3",
                    ordre: 3,
                    titre: "Descente rapide verticale",
                    description: "Ouvrir le pick-up et laisser filer le jig en chute libre verticale. La descente est rapide (jig lourd) et a peu d'intérêt halieutique sauf exceptions. L'objectif est de remettre rapidement le jig en zone de pêche. Compter mentalement les secondes pour retrouver la même profondeur. Sentir le contact fond ou atteindre la profondeur des poissons repérés au sondeur.",
                    illustrationsEtapes: nil,
                    conseil: "En fast jigging offshore (250m+), la descente peut durer 1-2 minutes. Restez patient : l'action commence à la remontée. Utilisez ce temps pour préparer mentalement votre séquence explosive."
                ),
                EtapeTechnique(
                    id: "fast_step4",
                    ordre: 4,
                    titre: "Première tirée explosive haute",
                    description: "Contact fond confirmé ou profondeur atteinte, effectuer immédiatement la première tirée : lever la canne de 80-120 cm (peu profond) à 180-250 cm (profond) de façon franche et rapide. L'angle de la canne passe de 60° à 90°. Cette traction énergique fait jaillir le jig vers le haut en créant un flash et des vibrations intenses.",
                    illustrationsEtapes: "fast_tiree_explosive",
                    conseil: "La tirée doit être franche mais contrôlée, pas brutale au point de faire sauter le jig hors de l'eau. Imaginez que vous soulevez un poids de 10 kg d'un coup sec."
                ),
                EtapeTechnique(
                    id: "fast_step5",
                    ordre: 5,
                    titre: "Moulinage rapide constant",
                    description: "Simultanément à la tirée, mouliner très rapidement : 6-8 tours (peu profond) à 10-12 tours (profond). Le moulinage doit être constant et soutenu pendant toute la levée de canne. Cette combinaison tirée+moulinage fait monter le jig de 1-2 mètres en créant une action darting erratique. Le jig doit 'flasher' en filant vers le haut.",
                    illustrationsEtapes: nil,
                    conseil: "Le ratio rapide du moulinet (5.5:1 minimum, idéalement 6:1+) est critique. Un ratio lent ne permettrait pas de récupérer assez vite pour suivre la tirée."
                ),
                EtapeTechnique(
                    id: "fast_step6",
                    ordre: 6,
                    titre: "Descente contrôlée tension maintenue",
                    description: "Après la tirée, redescendre rapidement la canne à sa position initiale (60°) en ralentissant le moulinage mais sans l'arrêter complètement. Relâcher environ 50% de la tension (frein serré) pour laisser le jig redescendre tout en maintenant le contact. Cette descente dure 1-2 secondes. Être prêt car des touches peuvent survenir ici aussi.",
                    illustrationsEtapes: nil,
                    conseil: "Contrairement au slow pitch, ne relâchez jamais complètement la tension en fast jigging. Vous devez toujours sentir le jig pour être prêt à la tirée suivante immédiate."
                ),
                EtapeTechnique(
                    id: "fast_step7",
                    ordre: 7,
                    titre: "Enchaînement immédiat sans pause",
                    description: "Dès que la canne est revenue à 60°, enchaîner immédiatement la deuxième tirée explosive sans marquer de pause. Répéter le cycle : tirée haute + moulinage rapide, descente contrôlée, tirée haute + moulinage rapide, descente contrôlée. Le rythme est soutenu et continu : 2-5 secondes par cycle complet.",
                    illustrationsEtapes: "fast_cycles_continus",
                    conseil: "Le fast jigging est physiquement épuisant. C'est normal. Si vous n'êtes pas essoufflé après 5-10 cycles, c'est que vous n'allez pas assez vite. Donnez tout pendant 15-20 minutes."
                ),
                EtapeTechnique(
                    id: "fast_step8",
                    ordre: 8,
                    titre: "Variation après 5-10 cycles",
                    description: "Après 5-10 cycles identiques (remontée de 10-20m), marquer occasionnellement une pause de 3 secondes pour observer si des poissons suivent. Cette micro-pause brise le rythme monotone et peut déclencher les hésitants. Puis reprendre immédiatement le fast jigging normal ou accélérer encore plus.",
                    illustrationsEtapes: nil,
                    conseil: "Les pauses en fast jigging doivent rester courtes (3-5s maximum). Des pauses longues feraient basculer dans le slow pitch qui cible un autre profil de poissons."
                ),
                EtapeTechnique(
                    id: "fast_step9",
                    ordre: 9,
                    titre: "Remontée complète colonne d'eau",
                    description: "Continuer les cycles explosifs jusqu'à remonter le jig du fond à la mi-eau ou surface selon activité (remontée totale de 30-100m). Couvrir rapidement toute la colonne d'eau pour intercepter les bancs de thons ou wahoos qui se déplacent verticalement. Si aucune touche, remonter complètement puis relâcher pour redescendre au fond.",
                    illustrationsEtapes: nil,
                    conseil: "En présence de wahoos autour d'un DCP, concentrez le fast jigging sur les 10-50 premiers mètres sous la surface. C'est leur zone de chasse préférentielle."
                ),
                EtapeTechnique(
                    id: "fast_step10",
                    ordre: 10,
                    titre: "Ferrage et combat puissant",
                    description: "Les touches en fast jigging sont généralement violentes et franches : vous sentez un choc brutal dans la canne. Ferrer immédiatement et fermement. Le combat est énergique avec des rushs puissants. Pomper en cycles courts : canne haute pour soulever, canne basse pour récupérer rapidement. Le frein doit être bien réglé (60-70% de la résistance).",
                    illustrationsEtapes: nil,
                    conseil: "Les wahoos et thazards pris en fast jigging font des rushs explosifs de 30-50 mètres. Soyez prêt à laisser filer le frein. Après le premier rush, pompez énergiquement : ce sont des sprinters, pas des marathoniens."
                )
            ],
            conseilsPro: [
                "Le fast jigging ne convainc pas, il provoque. S'il n'y a pas de réaction rapide dans les 5-10 premières minutes, ce n'est probablement pas la bonne technique pour le moment. Basculez en slow pitch.",
                "Les attaques se produisent majoritairement pendant la montée explosive, rarement en descente. La remontée est votre moment critique : maintenez l'intensité jusqu'au bout.",
                "Sessions courtes (15-20 min par spot) car la technique est épuisante. Si pas de touches après 20 minutes d'effort maximal, changez de spot ou de technique.",
                "Le fast jigging excelle dans les passes lagunaires avec courant établi (coefficient > 80). Le courant oxygène l'eau et active les prédateurs qui deviennent réceptifs à cette animation agressive.",
                "Autour des DCP, le fast jigging est optimal entre 10h-11h et 14h-16h quand les bancs de thons et wahoos sont en chasse active. Évitez l'aube et le crépuscule où les poissons sont plus calés.",
                "Les jigs avec finition argentée ou holographique créent des flashs lumineux intenses pendant les remontées rapides, visibles de très loin et irrésistibles pour les thons obèses.",
                "Alternez fast jigging et slow pitch selon les refus. Si le fast ne fonctionne pas, tentez quelques cycles de slow pour voir quelle humeur domine."
            ],
            erreursCourantes: [
                "Aller trop lentement ou avec trop de pauses. Le fast jigging est rapide par définition : rythme soutenu sans interruption pendant au moins 10 cycles consécutifs.",
                "Tirer avec les bras au lieu d'utiliser le poids du corps. Engagez le dos et les jambes : redressez-vous entièrement à chaque tirée en pivotant légèrement.",
                "Utiliser des jigs trop légers qui ne descendent pas assez vite ou remontent en déséquilibre. Le poids du jig doit être adapté à la profondeur et au courant.",
                "Relâcher complètement la tension en descente. En fast pitch, vous devez maintenir une tension partielle constante pour enchaîner les cycles rapidement.",
                "Persister 45-60 minutes sans succès. Le fast jigging est une pêche de fenêtre d'opportunité : 15-20 minutes max par spot puis changement ou switch technique.",
                "Utiliser un bas de ligne en fluorocarbone pour les wahoos et thazards. Résultat garanti : coupure nette. Le câble acier 40-60 cm est absolument obligatoire.",
                "Négliger de surveiller la ligne pendant les descentes. Même si 90% des touches sont en montée, les 10% restantes se produisent en descente : restez vigilant."
            ],
            videoURL: nil,
            photosIllustrations: [
                "fast_jigging_remontee_explosive",
                "jigs_compacts_tapered",
                "tirees_amplitude_profondeur",
                "zones_NC_fast_jigging"
            ],
            especesConcernees: [
                "locheSaumonee",
                "carangueGT",
                "carangueBleue",
                "barracuda",
                "becunes",
                "wahoo",
                "thonJaune",
                "thon_obese",
                "becDeCane",
                "thazard-raye",
                "bonite",
                "Sérioles",
                "mahiMahi"
            ]
        )
    }
    
    // MARK: - FICHE 14: Comparaison Slow vs Fast Jigging
    
    static func createSlowVsFastJigging() -> FicheTechnique {
        return FicheTechnique(
            id: "animation_slow_vs_fast_jigging",
            titre: "Slow vs Fast Jigging : Guide de Choix",
            categorie: .animation,
            niveauDifficulte: .avance,
            dureeApprentissage: "Lecture 10 min",
            description: """
            Le choix entre slow pitch jigging et fast pitch jigging n'est pas une question de préférence personnelle mais d'adaptation aux conditions de pêche et au comportement des poissons. Ces deux techniques verticales opposées ciblent des profils de prédateurs différents et répondent à des situations distinctes. Comprendre quand utiliser l'une ou l'autre multiplie considérablement vos chances de succès.
            
            Le slow pitch jigging excelle lorsque les poissons sont peu actifs, calés sur le fond, méfiants ou sous forte pression de pêche. Son animation lente avec descente papillonnante laisse le temps aux prédateurs de cibler et attaquer. Le fast pitch jigging domine quand les poissons sont en chasse active, dans des zones oxygénées avec courant, et réagissent aux stimuli agressifs. Sa remontée explosive déclenche l'instinct de poursuite.
            
            La lecture halieutique est la clé : observer les conditions (courant, luminosité, activité visible), tester rapidement les deux approches, et ajuster en temps réel selon les résultats. Un pêcheur compétent bascule entre slow et fast au cours d'une même sortie en fonction de l'évolution de l'activité des poissons.
            
            En Nouvelle-Calédonie, la combinaison slow + fast jigging est redoutablement efficace. Commencer en fast pour localiser rapidement l'activité et déclencher les poissons agressifs, puis basculer en slow pour finesse si les refus s'accumulent ou si l'activité baisse. Cette approche hybride adaptative optimise le temps de pêche.
            """,
            materielNecessaire: [
                "Matériel slow pitch : canne souple PE 1-3, moulinet ratio lent, jigs plats",
                "Matériel fast pitch : canne rigide PE 3-6, moulinet ratio rapide, jigs compacts",
                "Ou setup hybride : canne medium PE 2-4, moulinet 6000-8000, jigs polyvalents",
                "Carnet de pêche pour noter conditions et technique efficace",
                "Échosondeur pour évaluer activité des poissons",
                "Assortiment de jigs 40-400g couvrant les deux styles"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "compare_step1",
                    ordre: 1,
                    titre: "Tableau comparatif des différences",
                    description: "VITESSE : Slow = lente (2-6s/cycle) / Fast = rapide (2-5s/cycle) || MOMENT CLÉ : Slow = descente / Fast = remontée || EFFORT PHYSIQUE : Slow = modéré / Fast = intense || POISSON CIBLÉ : Slow = calé, méfiant / Fast = actif, chasseur || TAUX DE TOUCHES : Slow = régulier / Fast = plus faible mais poissons trophées || SÉLECTIVITÉ : Slow = large spectre / Fast = forte sélection.",
                    illustrationsEtapes: "slow_fast_comparison_table",
                    conseil: "Mémorisez ce tableau. En situation de pêche, référez-vous mentalement à ces critères pour décider rapidement quelle technique employer."
                ),
                EtapeTechnique(
                    id: "compare_step2",
                    ordre: 2,
                    titre: "Quand choisir le SLOW pitch jigging",
                    description: "Conditions favorables : poissons calés sur le fond, peu de chasse visible, eau très claire (lagon), pression de pêche élevée, dérive lente (< 1 nœud), luminosité forte, eau froide (< 20°C). Espèces réceptives : vivaneaux, loches, mérous, pagres, carangues posées, empereurs. Période : matin très tôt (6h-8h) et soir (17h-19h).",
                    illustrationsEtapes: nil,
                    conseil: "Si vous voyez des poissons au sondeur mais ils ne réagissent à rien, c'est LE signal pour passer en slow pitch. Les poissons sont là mais pas agressifs : séduisez-les plutôt que de les provoquer."
                ),
                EtapeTechnique(
                    id: "compare_step3",
                    ordre: 3,
                    titre: "Quand choisir le FAST pitch jigging",
                    description: "Conditions favorables : chasses visibles sous la surface, oiseaux qui plongent, courant établi (coef > 80), bonne oxygénation, dérive modérée, luminosité moyenne, eau tempérée (22-26°C). Espèces réceptives : thons, wahoos, carangues GT, thazards, bonites, sérioles. Période : milieu de matinée (9h-11h) et milieu d'après-midi (14h-16h).",
                    illustrationsEtapes: nil,
                    conseil: "Autour des DCP calédoniens, commencez toujours par le fast jigging pour localiser rapidement les bancs actifs. Si vous n'avez rien après 20 minutes, basculez en slow."
                ),
                EtapeTechnique(
                    id: "compare_step4",
                    ordre: 4,
                    titre: "Stratégie de bascule en temps réel",
                    description: "Règle de décision rapide : CHASSE VISIBLE → Fast immédiat. TOUCHES VIOLENTES → Continuer Fast. SUIVIS SANS ATTAQUE → Basculer en Slow. AUCUNE RÉACTION → Changer de technique ou de spot. Observer et ajuster toutes les 15-20 minutes maximum. Ne persistez jamais plus de 30 minutes avec une technique qui ne produit rien.",
                    illustrationsEtapes: "decision_tree_slow_fast",
                    conseil: "La règle des 15 minutes : testez une technique pendant 15 minutes max. Si zéro contact, switch. Le temps de pêche est précieux, ne le gaspillez pas dans l'entêtement."
                ),
                EtapeTechnique(
                    id: "compare_step5",
                    ordre: 5,
                    titre: "Lecture halieutique : interpréter les signaux",
                    description: "SIGNAL : Poissons visibles au sondeur mais aucune touche → SLOW. SIGNAL : Échos dispersés en pleine eau, oiseaux actifs → FAST. SIGNAL : Touches discrètes, poissons timides → SLOW. SIGNAL : Attaques ratées, rushs courts → FAST (déclenche l'agressivité). SIGNAL : Coefficient de marée > 90, courant fort → FAST. SIGNAL : Coefficient < 60, eau calme → SLOW.",
                    illustrationsEtapes: nil,
                    conseil: "Développez votre sens de l'observation. Les meilleurs jiggeurs lisent l'eau, le sondeur, le comportement des oiseaux et ajustent leur technique en conséquence avant même de mouiller la ligne."
                ),
                EtapeTechnique(
                    id: "compare_step6",
                    ordre: 6,
                    titre: "Approche hybride optimale en NC",
                    description: "Stratégie recommandée pour Nouvelle-Calédonie : 1) Arrivée sur spot → Fast jigging 15 min pour localiser activité. 2) Si touches → Continuer Fast jusqu'à baisse d'activité. 3) Baisse activité → Basculer Slow pour finesse. 4) Si aucune touche Fast après 15 min → Tester Slow 15 min. 5) Si rien des deux → Changer de spot.",
                    illustrationsEtapes: "nc_hybrid_strategy",
                    conseil: "Cette approche hybride Fast d'abord puis Slow couvre 90% des situations calédoniennes. Vous prospectez rapidement en Fast, puis affinez en Slow si besoin."
                ),
                EtapeTechnique(
                    id: "compare_step7",
                    ordre: 7,
                    titre: "Adaptation selon profondeur NC",
                    description: "LAGUNE 20-100m : Slow prioritaire (vivaneaux, pagres méfiants). PASSES 30-100m : Fast si courant fort (GT actives). DCP 50-150m : Fast milieu journée, Slow aube/crépuscule. OFFSHORE 150-300m+ : Fast pour localiser puis Slow pour cibler. Règle : Plus c'est profond et calme, plus le Slow est efficace. Plus c'est moyen et agité, plus le Fast domine.",
                    illustrationsEtapes: "profondeur_technique_NC",
                    conseil: "Les tombants du lagon sud (Prony, Goro) de 40-80m sont parfaits pour le Slow. Les passes nord avec courant (Dumbéa, Boulari) excellentes pour le Fast."
                ),
                EtapeTechnique(
                    id: "compare_step8",
                    ordre: 8,
                    titre: "Gestion de l'énergie du pêcheur",
                    description: "Le Fast jigging est physiquement épuisant : 15-20 minutes de Fast = fatigue intense. Le Slow jigging est reposant : on peut pêcher 2-3 heures en Slow sans épuisement. Stratégie énergétique : alterner 15 min Fast + 30 min Slow pour gérer l'endurance sur une sortie de 4-6 heures. Rester en Slow si vous êtes seul à pêcher ou par forte chaleur.",
                    illustrationsEtapes: nil,
                    conseil: "Si vous partez pour une longue session (journée complète), ne faites pas que du Fast : vous serez épuisé en 2 heures. Mixez intelligemment pour tenir toute la journée."
                ),
                EtapeTechnique(
                    id: "compare_step9",
                    ordre: 9,
                    titre: "Cas pratiques de décision",
                    description: "CAS 1 : DCP, midi, oiseaux qui plongent, échos dispersés → FAST. CAS 2 : Tombant lagon, aube, eau claire, poissons collés au fond → SLOW. CAS 3 : Passe, marée montante coef 95, courant 2 nœuds → FAST. CAS 4 : Après 1h de pêche, poissons qui suivent sans mordre → SLOW. CAS 5 : Offshore profond 250m, recherche exploratoire → FAST puis SLOW.",
                    illustrationsEtapes: "cas_pratiques_decision",
                    conseil: "Entraînez-vous à prendre ces décisions rapidement. Avec l'expérience, vous saurez instinctivement quelle technique employer dès votre arrivée sur le spot."
                ),
                EtapeTechnique(
                    id: "compare_step10",
                    ordre: 10,
                    titre: "Carnet de pêche et optimisation",
                    description: "Noter systématiquement : date, heure, spot, profondeur, coefficient de marée, technique employée (Slow/Fast), résultat (touches/captures), observations. Après 10-20 sorties, des patterns émergent : telle passe fonctionne en Fast aux grandes marées, tel tombant excelle en Slow le matin, etc. Capitaliser sur ces données pour optimiser les sorties futures.",
                    illustrationsEtapes: nil,
                    conseil: "Un carnet de pêche détaillé est l'outil le plus précieux du jiggeur expérimenté. Vos propres données terrain valent mieux que n'importe quel article : elles reflètent VOS spots et VOS conditions."
                )
            ],
            conseilsPro: [
                "Règle d'or : le jigging qui fonctionne est celui adapté à l'humeur des poissons du moment, pas celui que vous préférez pêcher. Soyez flexible.",
                "En Nouvelle-Calédonie, la transparence exceptionnelle de l'eau lagunaire favorise le Slow pitch car les poissons voient de très loin et sont méfiants. Le Fast fonctionne mieux en offshore ou passes turbides.",
                "Ne mélangez jamais les deux styles simultanément : choisissez l'un OU l'autre pour une séquence donnée. Faire du 'slow-fast' hybride confus ne marche sur rien.",
                "Les coefficients de marée sont un excellent prédicteur : coef > 85 favorise le Fast (courant = poissons actifs), coef < 70 favorise le Slow (calme = poissons posés).",
                "Autour des DCP, la règle des heures : 6h-9h = Slow, 9h-16h = Fast, 16h-19h = Slow. L'activité des thons suit un cycle prévisible que vous pouvez exploiter.",
                "Si vous avez un doute entre Slow et Fast, testez d'abord le Fast pendant 10 minutes. C'est plus rapide pour confirmer/infirmer la présence de poissons actifs.",
                "Les meilleurs résultats viennent souvent de l'alternance : Fast pour localiser et déclencher les agressifs, puis Slow pour nettoyer les méfiants qui restent."
            ],
            erreursCourantes: [
                "S'entêter sur une technique parce qu'on y croit ou qu'on la maîtrise mieux. Les poissons se moquent de vos préférences : adaptez-vous à EUX.",
                "Ne jamais tester l'autre technique par dogmatisme ('je ne fais que du Fast'). Cette rigidité vous fait rater 50% des opportunités.",
                "Basculer trop rapidement d'une technique à l'autre sans leur laisser le temps de prouver leur efficacité. Donnez 15-20 minutes minimum à chaque approche.",
                "Ignorer les signaux de l'environnement (oiseaux, courant, échos sondeur) et choisir une technique au hasard. La lecture halieutique doit guider votre choix.",
                "Pêcher en Fast quand les conditions crient 'Slow' (eau calme, poissons calés, pas de courant). Résultat garanti : épuisement et bredouille.",
                "Ne pas noter ses observations et reproduire les mêmes erreurs de sortie en sortie. Un carnet de pêche transforme l'expérience en connaissance exploitable.",
                "Utiliser le mauvais matériel pour la technique choisie : canne souple pour le Fast (pas assez de puissance) ou canne rigide pour le Slow (pas assez de finesse)."
            ],
            videoURL: nil,
            photosIllustrations: [
                "tableau_comparatif_complet",
                "arbre_decision_technique",
                "zones_NC_par_technique",
                "calendrier_horaire_optimal"
            ],
            especesConcernees: [
                "SLOW : Vivaneaux, loches, mérous, pagres, empereurs, dentis",
                "FAST : Thons, wahoos, carangues GT, thazards, bonites, sérioles",
                "POLYVALENTES : Carangues (Slow si calées, Fast si actives)"
            ]
        )
    }
    
    // MARK: - FICHE 15: Zones de pêche et sélection des spots
    
    static func createZonesDePecheSpots() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_15_zones_peche",
            titre: "Zones de pêche et sélection des spots",
            categorie: .strategie,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "2-3 sorties",
            description: """
            Identifier et exploiter les zones productives en fonction des espèces recherchées, profondeur, relief sous-marin et indices de surface.
            
            La lecture de l'environnement marin (carte, sondeur, observation surface) permet de localiser les zones de concentration de poissons et d'optimiser le temps de pêche.
            """,
            materielNecessaire: [
                "Sondeur/échosondeur",
                "GPS cartographique",
                "Jumelles",
                "Thermomètre de surface (optionnel)",
                "Cartes marines Nouvelle-Calédonie"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche15_step1",
                    ordre: 1,
                    titre: "Lecture de la carte marine",
                    description: "Identifier les structures sous-marines prometteuses : hauts-fonds, tombants, canyons, récifs, passes. Les zones de changement de profondeur concentrent les poissons.",
                    illustrationsEtapes: "carte_bathymetrique",
                    conseil: "Les tombants 100-300m sont particulièrement productifs pour les grands pélagiques en Nouvelle-Calédonie"
                ),
                EtapeTechnique(
                    id: "fiche15_step2",
                    ordre: 2,
                    titre: "Utilisation du sondeur",
                    description: "Détecter le relief précis, localiser les bancs de poissons-appâts (petites marques suspendues), identifier les gros spécimens (échos importants près du fond). Analyser température et thermoclines.",
                    illustrationsEtapes: "lecture_sondeur",
                    conseil: "Un échosondeur de qualité permet de visualiser les structures sous-marines et parfois même les poissons eux-mêmes"
                ),
                
                EtapeTechnique(
                    id: "fiche15_step3",
                    ordre: 3,
                    titre: "Observation de la surface",
                    description: "Repérer les oiseaux en chasse (frégates, fous, sternes), détecter les cassures de couleur d'eau, observer les nappes d'huile (trace de poissons), identifier les courants de bord et lignes de convergence.",
                    illustrationsEtapes: "observation_surface",
                    conseil: "Oiseaux en chasse = signal fort de présence thons/bonites. Frégates = thons jaunes ; fous masqués = bonites/petits thons"
                ),
                EtapeTechnique(
                    id: "fiche15_step4",
                    ordre: 4,
                    titre: "Mémorisation et marquage waypoints",
                    description: "Enregistrer au GPS les spots productifs avec date, conditions, espèces capturées. Constituer progressivement une base de données personnelle des zones à potentiel.",
                    illustrationsEtapes: "waypoints_gps",
                    conseil: "Noter systématiquement les conditions lors des captures réussies : heure, profondeur, température eau, météo, marée, phase lunaire"
                ),
                EtapeTechnique(
                    id: "fiche15_step5",
                    ordre: 5,
                    titre: "Adaptation profondeur selon espèces",
                    description: "Ajuster la zone de prospection : surface-20m (thons, bonites, coryphènes), 50-150m (thazards, carangues), 100-300m (marlins, voiliers), 150-400m (vivaneaux profonds).",
                    illustrationsEtapes: "profondeurs_especes",
                    conseil: "Les passes entre lagon et océan sont des zones de passage obligé très productives"
                )
            ],
            conseilsPro: [
                "Les tombants 100-300m sont particulièrement productifs pour les grands pélagiques en Nouvelle-Calédonie",
                "Oiseaux en chasse = signal fort de présence thons/bonites. Frégates = thons jaunes ; fous masqués = bonites/petits thons",
                "Courants de bord (rencontre courant/récif) concentrent les appâts et donc les prédateurs",
                "Noter systématiquement les conditions lors des captures réussies : heure, profondeur, température eau, météo, marée, phase lunaire",
                "Explorer méthodiquement de nouvelles zones plutôt que pêcher toujours aux mêmes endroits",
                "Les passes entre lagon et océan sont des zones de passage obligé très productives",
                "Changements brusques de profondeur (5-10m sur 50m horizontal) = zones de chasse privilégiées"
            ],
            erreursCourantes: [
                "Négliger la lecture du sondeur en traîne continue (manquer des structures intéressantes)",
                "Pêcher toujours aux mêmes endroits sans explorer de nouvelles zones",
                "Ignorer les indices de surface (oiseaux, sauts de poissons, cassures d'eau)",
                "Ne pas noter les conditions des captures réussies (impossible de reproduire)",
                "Prospecter trop vite sans laisser le temps d'analyser le sondeur",
                "Pêcher en surface alors que les poissons sont en profondeur (ou inverse)",
                "Sous-estimer l'importance des courants dans la localisation des poissons"
            ],
            videoURL: nil,
            photosIllustrations: [
                "zones_productives_nc",
                "lecture_sondeur_pelagiques",
                "oiseaux_chasse_thons",
                "tombant_100_300m",
                "waypoints_gps_spots"
            ],
            especesConcernees: [
                "Toutes espèces hauturières",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "bonite",
                "becDeCane",
                "locheSaumonee",
                "thonJaune",
                "thon_Obese",
                "Espadon voilier",
                "thazard-raye",
                "Vivaneaux profonds"
            ]
        )
    }
    
    // MARK: - FICHE 16: Adaptation aux condition météo et marées
    
    static func createAdaptationMeteoMaree() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_16_adaptation_meteo_maree",
            titre: "Adaptation aux conditions météo et marée",
            categorie: .strategie,
            niveauDifficulte: .avance,
            dureeApprentissage: "Toute une saison",
            description: """
                Optimiser sa stratégie de pêche selon vent, houle, marée, coefficient, phases lunaires et conditions océanographiques.
                
                Les conditions météo-marines influencent fortement le comportement des poissons. Adapter sa technique et ses zones de pêche selon ces paramètres améliore considérablement les résultats.
                """,
            materielNecessaire: [
                "Application météo marine (Météo France NC, Windy)",
                "Almanach des marées Nouvelle-Calédonie",
                "Anémomètre (optionnel)",
                "Baromètre",
                "Thermomètre eau de surface"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche16_step1",
                    ordre: 1,
                    titre: "Vérification prévisions complètes",
                    description: "Consulter vent (force et direction), houle (hauteur et période), marée (horaires et coefficient), pression atmosphérique, température. Anticiper évolution sur la journée.",
                    illustrationsEtapes: "consultation_meteo",
                    conseil: "Évaluer objectivement les risques. Vent >20 nœuds prévu : report. Houle >2m : expérience requise. Pression chutant rapidement : mauvais signe"
                ),
                EtapeTechnique(
                    id: "fiche16_step2",
                    ordre: 2,
                    titre: "Adaptation zone selon conditions",
                    description: "Vent d'est : côte ouest protégée. Vent d'ouest : côte est abritée. Houle sud : zones nord. Privilégier les abris naturels (baies, caps, îlots) par mauvais temps.",
                    illustrationsEtapes: "choix_zone_meteo",
                    conseil: "Ne jamais foncer directement sur une chasse active avec le moteur thermique à plein régime. Approchez doucement, coupez le moteur à distance"
                ),
                EtapeTechnique(
                    id: "fiche16_step3",
                    ordre: 3,
                    titre: "Choix leurres selon état mer et luminosité",
                    description: "Mer calme : leurres surface (poppers, stickbaits). Mer formée : plongeurs profonds. Eau claire : couleurs naturelles. Eau turbide : couleurs vives/flashy. Ciel couvert : couleurs contrastées.",
                    illustrationsEtapes: "leurres_conditions",
                    conseil: "Mer calme = privilégier leurres surface et animations rapides. Mer formée = plongeurs et traîne plus lente"
                ),
                EtapeTechnique(
                    id: "fiche16_step4",
                    ordre: 4,
                    titre: "Ajustement vitesse et profondeur",
                    description: "Adapter vitesse traîne selon conditions : ralentir par mer formée, accélérer par mer calme. Varier profondeur selon température et luminosité (plus profond si soleil intense).",
                    illustrationsEtapes: "ajustement_technique",
                    conseil: "Coefficient de marée >80 : forts courants, pêche plus technique mais souvent très productive"
                ),
                EtapeTechnique(
                    id: "fiche16_step5",
                    ordre: 5,
                    titre: "Décision sortie/report selon sécurité",
                    description: "Évaluer objectivement les risques. Vent >20 nœuds prévu : report. Houle >2m : expérience requise. Pression chutant rapidement : mauvais signe. Sécurité prioritaire absolue.",
                    illustrationsEtapes: "decision_sortie",
                    conseil: "Changement de conditions météo = moment clé : poissons s'alimentent activement avant/après le changement"
                )
            ],
            conseilsPro: [
                "Marées montantes souvent plus productives que descendantes (poissons suivent le flux d'eau riche en oxygène et appâts)",
                "Vent d'est modéré (10-15 nœuds) favorable en Nouvelle-Calédonie : favorise les chasses de surface",
                "Néoménie (nouvelle lune) et pleine lune = périodes particulièrement favorables pour grands pélagiques (activité accrue)",
                "Mer calme = privilégier leurres surface et animations rapides. Mer formée = plongeurs et traîne plus lente",
                "Coefficient de marée >80 : forts courants, pêche plus technique mais souvent très productive",
                "Pression stable ou montante = conditions favorables. Pression chutant = poissons moins actifs",
                "Eau turbide après pluies : rapprocher de la côte, les pélagiques suivent l'eau claire",
                "Changement de conditions météo = moment clé : poissons s'alimentent activement avant/après le changement"
            ],
            erreursCourantes: [
                "Sortir par conditions dangereuses (vent >20 nœuds, houle >2m si inexpérimenté)",
                "Ignorer le coefficient de marée et ses effets sur les courants",
                "Ne pas adapter les leurres à la turbidité de l'eau",
                "Pêcher toujours au même endroit quelles que soient les conditions",
                "Négliger la pression atmosphérique (influence majeure sur activité poissons)",
                "Sous-estimer l'impact de la phase lunaire sur l'activité",
                "Persister par conditions défavorables au lieu de reporter"
            ],
            videoURL: nil,
            photosIllustrations: [
                "meteo_favorable_peche",
                "adaptation_zone_vent",
                "leurres_selon_conditions",
                "phases_lunaires_peche",
                "coefficients_marees_nc"
            ],
            especesConcernees: [
                "Toutes espèces, influence variable",
                "Thons (très sensibles pression atmosphérique)",
                "Marlins (actifs nouvelle/pleine lune)",
                "Coryphènes (préfèrent mer formée modérée)",
                "Bonites (actives marée montante)",
                "Wahoos (peu sensibles conditions)",
                "Vivaneaux (actifs coefficient élevé)",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "bonite",
                "thazard_raye",
                "barracuda"
            ]
        )
    }
    
    // MARK: - FICHE 17: Lecture de l'eau et détection des chasses
    
    static func createLectureEauChasses() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_17_lecture_eau_chasses",
            titre: "Lecture de l'eau et détection des chasses",
            categorie: .strategie,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "1 saison",
            description: """
                Reconnaître et exploiter les chasses de poissons, détecter la présence de prédateurs par observation attentive de l'environnement marin.
                
                Les chasses sont des moments privilégiés où les poissons pélagiques rabattent les appâts en surface. Les identifier et les exploiter correctement multiplie les chances de captures.
                """,
            materielNecessaire: [
                "Jumelles polarisantes",
                "Lunettes polarisantes",
                "Leurres casting (poppers 80-120g, stickbaits 100-150g)",
                "Canne casting dédiée (20-40 lbs)",
                "Moulinet casting forte récupération"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche17_step1",
                    ordre: 1,
                    titre: "Observation constante horizon 360°",
                    description: "Balayer régulièrement tout l'horizon aux jumelles. Alterner observation lointaine (2-5 km) et proche (200-500m). Porter attention particulière aux zones de cassure et convergence.",
                    illustrationsEtapes: "observation_horizon",
                    conseil: "Les oiseaux sont vos meilleurs alliés. Une concentration de sternes ou de fous plongeant activement signale presque toujours une chasse en cours"
                ),
                EtapeTechnique(
                    id: "fiche17_step2",
                    ordre: 2,
                    titre: "Identification oiseaux en activité",
                    description: "Repérer frégates planant puis plongeant (thons jaunes), fous masqués en piqué (bonites/petits thons), sternes en vol stationnaire (petits pélagiques). Concentration d'oiseaux = chasse probable.",
                    illustrationsEtapes: "oiseaux_chasse",
                    conseil: "Frégates en vol plané circulaire = thons jaunes en profondeur. Frégates en piqué = thons en chasse surface"
                ),
                EtapeTechnique(
                    id: "fiche17_step3",
                    ordre: 3,
                    titre: "Détection sauts et bouillonnements",
                    description: "Identifier sauts de thons (jaillissement vertical), bonds de coryphènes (sortie tête), remous et bouillonnements de surface (attaque en masse). Évaluer taille et direction déplacement chasse.",
                    illustrationsEtapes: "detection_chasse",
                    conseil: "Fous masqués en groupe compact piquant = bonites ou petits thons. Sternes en vol stationnaire bas = petits pélagiques donc prédateurs à proximité"
                ),
                EtapeTechnique(
                    id: "fiche17_step4",
                    ordre: 4,
                    titre: "Approche chasse tactique",
                    description: "Approcher discrètement par l'arrière du vent, ralentir à 100-150m, couper moteur si possible. Ne JAMAIS passer au milieu (dispersion). Positionner bateau en bordure chasse, côté sous le vent.",
                    illustrationsEtapes: "approche_chasse",
                    conseil: "Ne jamais passer au milieu d'une chasse avec le moteur : dispersion garantie. Approche discrète par la périphérie"
                ),
                EtapeTechnique(
                    id: "fiche17_step5",
                    ordre: 5,
                    titre: "Exploitation casting ou traîne bordure",
                    description: "Lancer casting en bordure chasse (jamais au centre). Ou passage traîne lente en périphérie. Animation rapide, récupération immédiate si touche. Varier vitesse/direction si chasse se déplace.",
                    illustrationsEtapes: "exploitation_chasse",
                    conseil: "Chasse qui s'arrête brutalement : prédateurs ont plongé, attendre 5-10 min à proximité, souvent reprise"
                )
            ],
            conseilsPro: [
                "Chasses plus fréquentes tôt le matin (6h-9h) et fin d'après-midi (16h-18h) en Nouvelle-Calédonie",
                "Ne jamais passer au milieu d'une chasse avec le moteur : dispersion garantie. Approche discrète par la périphérie",
                "Varier vitesse et direction si chasse se déplace : suivre sans coller",
                "Frégates en vol plané circulaire = thons jaunes en profondeur. Frégates en piqué = thons en chasse surface",
                "Fous masqués en groupe compact piquant = bonites ou petits thons",
                "Sternes en vol stationnaire bas = petits pélagiques (athérines, sardines) donc prédateurs à proximité",
                "Chasse qui s'arrête brutalement : prédateurs ont plongé, attendre 5-10 min à proximité, souvent reprise",
                "Débris végétaux flottants (algues, branches) attirent coryphènes et thons : toujours inspecter"
            ],
            erreursCourantes: [
                "Foncer directement sur la chasse avec le moteur à pleine vitesse (dispersion immédiate)",
                "Lancer au centre de la chasse (les prédateurs fuient vers la périphérie)",
                "Abandonner trop vite après un passage (attendre, observer, la chasse peut reprendre)",
                "Négliger les petites chasses discrètes (souvent très productives)",
                "Ignorer les oiseaux qui ne plongent pas encore (surveiller, la chasse va démarrer)",
                "Approcher vent debout (moteur, bruit, odeur alertent les poissons)",
                "Rester collé à une chasse qui s'éloigne rapidement (harcèlement improductif)"
            ],
            videoURL: nil,
            photosIllustrations: [
                "chasse_thons_surface",
                "oiseaux_frigates_chasse",
                "approche_tactique_chasse",
                "casting_bordure_chasse",
                "bouillonnement_surface"
            ],
            especesConcernees: [
                "thonJaune",
                "bonite",
                "mahiMahi",
                "carangueGT",
                "wahoo",
                "thazard_raye"
            ]
        )
    }
    
    
    // MARK: - FICHE 18: Gestion du temps de pêche (timing optimal)
    
    static func createTimingOptimal() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_18_timing_optimal",
            titre: "Gestion du temps de pêche (timing optimal)",
            categorie: .strategie,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "Quelques sorties",
            description: """
                Identifier et exploiter les plages horaires et périodes les plus productives selon espèces cibles, conditions météo-marines, et cycles solunaires.
                
                L'activité des poissons suit des cycles biologiques (circadiens, lunaires, solunaires). Comprendre et exploiter ces cycles permet d'optimiser le temps passé en mer et maximiser les captures.
                """,
            materielNecessaire: [
                "Montre/smartphone",
                "Carnet de bord",
                "Table solunaire (app marées pêche recommandée)",
                "Almanach lunaire",
                "Thermomètre eau (optionnel)"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche18_step1",
                    ordre: 1,
                    titre: "Consultation table solunaire quotidienne",
                    description: "Vérifier les périodes majeures (2h, transit lunaire) et mineures (1h, lever/coucher lune) du jour. Planifier sortie pour couvrir au moins une période majeure. Application mareespeche.com recommandée.",
                    illustrationsEtapes: "table_solunaire",
                    conseil: "4 périodes par jour lunaire (24h50) : 2 périodes majeures de 2h + 2 périodes mineures de 1h. Superposition période solunaire + lever/coucher soleil = activité MAXIMALE"
                ),
                EtapeTechnique(
                    id: "fiche18_step2",
                    ordre: 2,
                    titre: "Sortie pré-levée soleil",
                    description: "Être sur zone 30-45 minutes avant le lever du soleil. Période crépusculaire matin = moment privilégié, souvent coïncide avec période solunaire mineure (lever lune) = effet cumulatif.",
                    illustrationsEtapes: "pre_levee_soleil",
                    conseil: "6h-9h = période la plus productive en Nouvelle-Calédonie toute l'année (coïncide souvent période solunaire + lever soleil)"
                ),
                EtapeTechnique(
                    id: "fiche18_step3",
                    ordre: 3,
                    titre: "Exploitation période dorée matin",
                    description: "Intensifier effort de pêche pendant les 2 heures suivant le lever du soleil (6h-9h en NC). Pic d'activité maximum si coïncidence avec période solunaire majeure (marqué vert sur app).",
                    illustrationsEtapes: "periode_doree_matin",
                    conseil: "Les périodes solunaires majeures (2h) correspondent au transit lunaire (lune au-dessus) et transit opposé (lune sous nos pieds) = pics d'activité maximum"
                ),
                EtapeTechnique(
                    id: "fiche18_step4",
                    ordre: 4,
                    titre: "Pause chaleur ou profondeur",
                    description: "Milieu de journée (10h-15h) : activité réduite en surface. Options : pause ravitaillement, ou pêche espèces profondes (vivaneaux, loches), ou prospection nouvelles zones à vitesse réduite.",
                    illustrationsEtapes: "strategie_milieu_journee",
                    conseil: "Milieu journée : si chaleur intense, cibler vivaneaux profonds (150-400m) plutôt que pélagiques surface"
                ),
                EtapeTechnique(
                    id: "fiche18_step5",
                    ordre: 5,
                    titre: "Reprise activité fin après-midi",
                    description: "Second pic d'activité 16h-18h, souvent période solunaire mineure (coucher lune). Poissons s'alimentent activement avant la nuit. Surveiller déclenchement des chasses.",
                    illustrationsEtapes: "fin_apres_midi",
                    conseil: "16h-18h = second pic d'activité quotidien, période solunaire mineure fréquente (lever ou coucher lune)"
                ),
                EtapeTechnique(
                    id: "fiche18_step6",
                    ordre: 6,
                    titre: "Pêche crépusculaire",
                    description: "Poursuivre jusqu'à nuit tombante si conditions le permettent. Moment privilégié pour gros spécimens (marlins, gros thons) qui chassent au crépuscule. Sécurité navigation prioritaire.",
                    illustrationsEtapes: "crepuscule",
                    conseil: "Les périodes mineures (1h) correspondent au lever et coucher de la lune = activité accrue mais moindre que les majeures"
                )
            ],
            conseilsPro: [
                "PÉRIODES SOLUNAIRES MAJEURES (2h) : transit lunaire (lune au-dessus) et transit opposé (lune sous nos pieds) = pics d'activité maximum poissons. 4 périodes par jour lunaire (24h50)",
                "PÉRIODES MINEURES (1h) : lever et coucher de la lune = activité accrue mais moindre que majeures",
                "SUPERPOSITION période solunaire + lever/coucher soleil = activité MAXIMALE (marquée en vert sur applications spécialisées)",
                "6h-9h = période la plus productive en Nouvelle-Calédonie toute l'année (coïncide souvent période solunaire + lever soleil)",
                "16h-18h = second pic d'activité quotidien (période solunaire mineure fréquente)",
                "Phases lunaires influencent : pleine lune et nouvelle lune (néoménie) = périodes particulièrement favorables grands pélagiques",
                "Milieu journée : si chaleur intense, cibler vivaneaux profonds (150-400m) plutôt que pélagiques surface",
                "DISTINCTION IMPORTANTE : Périodes solunaires ≠ marées. Les deux sont liées à la lune mais diffèrent dans le temps. Consulter LES DEUX pour planification optimale",
                "Ne pas confondre marée haute/basse et périodes solunaires : erreur fréquente des débutants"
            ],
            erreursCourantes: [
                "Arriver sur zone trop tard (9h passées) : période dorée manquée",
                "Rentrer trop tôt (15h-16h) : manquer second pic d'activité fin après-midi",
                "Négliger les heures crépusculaires (aube et coucher) : moments privilégiés gros poissons",
                "Ignorer les tables solunaires et pêcher uniquement selon les marées (confusion fréquente)",
                "Croire que marée haute = meilleure période : non, ce sont les périodes solunaires qui déterminent l'activité",
                "Ne pas consulter les périodes solunaires quotidiennes (application gratuite mareespeche.com)",
                "Abandonner la pêche en milieu de journée sans essayer les espèces profondes",
                "Pêcher aux mêmes horaires toute l'année sans s'adapter aux variations saisonnières"
            ],
            videoURL: nil,
            photosIllustrations: [
                "table_solunaire_exemple_nc",
                "lever_soleil_peche",
                "graphique_activite_journaliere",
                "app_marees_peche",
                "periodes_optimales_nc"
            ],
            especesConcernees: [
                "Toutes espèces, rythmes circadiens et solunaires variables",
                "Thons (très sensibles cycles solunaires)",
                "Marlins (actifs périodes majeures, crépuscule)",
                "Bonites (pics matin et fin après-midi)",
                "Coryphènes (actives toute journée si conditions)",
                "Wahoos (préfèrent aube et crépuscule)",
                "Vivaneaux (actifs milieu journée en profondeur)",
                "Carangues (suivent cycles solunaires)",
                "thonJaune",
                "thon_obese",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "bonite",
                "barracuda"
            ]
        )
    }
    
    // MARK: - FICHE 19: Stratégie multi espèces
    
    static func createStrategiesMultiEspeces() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_19_strategies_multi_especes",
            titre: "Stratégies multi-espèces",
            categorie: .strategie,
            niveauDifficulte: .avance,
            dureeApprentissage: "1-2 saisons",
            description: """
                Optimiser les prises en ciblant plusieurs espèces simultanément grâce à une sélection stratégique de leurres, profondeurs et zones de pêche.
                
                Plutôt que de spécialiser sur une espèce, la stratégie multi-espèces maximise les opportunités et s'adapte à l'activité du moment. Approche particulièrement efficace en Nouvelle-Calédonie où la diversité est exceptionnelle.
                """,
            materielNecessaire: [
                "4-6 cannes configurations différentes",
                "Variété de leurres (surface, mi-eau, profond)",
                "Downriggers ou plombs plongeurs",
                "Sondeur performant",
                "Thermomètre multi-profondeur (optionnel)"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche19_step1",
                    ordre: 1,
                    titre: "Constitution spread varié équilibré",
                    description: "Répartir leurres sur différentes profondeurs : 2 en surface (0-2m), 2 mi-eau (5-15m), 2 profonds (20-50m). Couvrir ainsi toute la colonne d'eau et maximiser les opportunités toutes espèces.",
                    illustrationsEtapes: "spread_multi_profondeur",
                    conseil: "Spread classique Nouvelle-Calédonie efficace : 2 surface (poppers/stickbaits), 2 plongeurs 5-10m, 2 downrigger 30-50m"
                ),
                EtapeTechnique(
                    id: "fiche19_step2",
                    ordre: 2,
                    titre: "Sélection leurres polyvalents",
                    description: "Privilégier tailles 15-20cm et formes généralistes qui attirent large spectre d'espèces. Alterner couleurs naturelles (bleu/blanc, vert/jaune) et flashy (rose/violet, orange). Éviter leurres trop spécialisés.",
                    illustrationsEtapes: "leurres_polyvalents",
                    conseil: "Leurres 15-20cm = taille optimale captant large spectre : thons moyens à marlins, coryphènes, wahoos, carangues"
                ),
                EtapeTechnique(
                    id: "fiche19_step3",
                    ordre: 3,
                    titre: "Prospection zones overlap",
                    description: "Cibler zones 100-200m de profondeur : chevauchement habitats de nombreuses espèces (thons, marlins, coryphènes, wahoos, carangues). Zones de convergence courants particulièrement productives.",
                    illustrationsEtapes: "zones_overlap",
                    conseil: "Tombants 150-250m = zone multi-espèces optimale en NC : concentration maximale de diversité"
                ),
                EtapeTechnique(
                    id: "fiche19_step4",
                    ordre: 4,
                    titre: "Adaptation vitesse compromis",
                    description: "Vitesse traîne 6-8 nœuds = compromis efficace : assez rapide pour thons/wahoos, assez lente pour marlins/coryphènes. Ajuster selon espèces dominantes du moment observées au sondeur.",
                    illustrationsEtapes: "vitesse_compromis",
                    conseil: "Alterner couleurs vives (rose, orange, chartreuse) et naturelles (bleu/blanc, vert/jaune) dans le spread"
                ),
                EtapeTechnique(
                    id: "fiche19_step5",
                    ordre: 5,
                    titre: "Rotation leurres selon résultats",
                    description: "Analyser quels leurres/profondeurs produisent. Ajuster progressivement : doubler leurres productifs, retirer ou remplacer ceux ignorés. Adaptation dynamique selon activité observée.",
                    illustrationsEtapes: "rotation_leurres",
                    conseil: "Observer thermoclines au sondeur : souvent concentrations multi-espèces à ces profondeurs (changement température)"
                )
            ],
            conseilsPro: [
                "Spread classique Nouvelle-Calédonie efficace : 2 surface (poppers/stickbaits), 2 plongeurs 5-10m, 2 downrigger 30-50m",
                "Leurres 15-20cm = taille optimale captant large spectre : thons moyens à marlins, coryphènes, wahoos, carangues",
                "Tombants 150-250m = zone multi-espèces optimale en NC : concentration maximale de diversité",
                "Alterner couleurs vives (rose, orange, chartreuse) et naturelles (bleu/blanc, vert/jaune) dans le spread",
                "Observer thermoclines au sondeur : souvent concentrations multi-espèces à ces profondeurs (changement température)",
                "Période solunaire majeure = moment où stratégie multi-espèces est la plus efficace (toutes espèces actives)",
                "Ne pas hésiter à mixer techniques : traîne + casting opportuniste si chasse détectée",
                "Débris flottants (algues, bois, FAD naturels) = hotspots multi-espèces : toujours prospecter"
            ],
            erreursCourantes: [
                "Spread trop spécialisé une espèce : perte d'opportunités autres espèces actives",
                "Négliger la profondeur intermédiaire 10-30m : zone très productive souvent ignorée",
                "Vitesse inadaptée : trop rapide = perte espèces lentes (marlins, coryphènes), trop lente = désintérêt rapides (thons, wahoos)",
                "Ne pas varier les leurres alors qu'une profondeur/couleur ne produit rien",
                "Abandonner une zone productive après une capture au lieu d'insister (souvent plusieurs espèces présentes)",
                "Utiliser uniquement des leurres chers : les leurres simples bien présentés sont souvent aussi efficaces",
                "Ignorer les petites touches : parfois coryphènes ou carangues qui testent le leurre"
            ],
            videoURL: nil,
            photosIllustrations: [
                "spread_multi_especes",
                "leurres_polyvalents_nc",
                "zones_overlap_bathymetrie",
                "captures_variees",
                "configuration_cannes_diversifiees"
            ],
            especesConcernees: [
                "thonJaune",
                "mahiMahi",
                "wahoo",
                "bonite",
                "marlin",
                "Espadon voilier",
                "carangueGT",
                "thazard_raye"
            ]
        )
    }
    
    
    // MARK: - FICHE 20: Cannes et moulinets selon technique
    
    static func createCannesMoulinets() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_20_cannes_moulinets",
            titre: "Cannes et moulinets selon technique",
            categorie: .equipement,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "Progressif",
            description: """
                Sélectionner et utiliser le matériel adapté à chaque technique (traîne lourde, traîne légère, casting, jigging) et aux espèces visées.
                
                Le choix du matériel conditionne le confort, l'efficacité et les chances de réussite. Un ensemble bien équilibré et adapté fait toute la différence lors du combat.
                """,
            materielNecessaire: [
                "Cannes 20-50 lbs (traîne légère/casting)",
                "Cannes 50-80 lbs (traîne lourde marlins)",
                "Moulinets spinning 4000-8000",
                "Moulinets conventionnels 30-50-80 lbs",
                "Harnais de combat (optionnel marlins)"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche20_step1",
                    ordre: 1,
                    titre: "Définition technique et espèces cibles",
                    description: "Identifier précisément la technique pratiquée (traîne lourde marlins, traîne légère thons/coryphènes, casting chasses, jigging profond) et les espèces visées (taille moyenne attendue).",
                    illustrationsEtapes: "techniques_peche",
                    conseil: "Traîne thon/marlin Nouvelle-Calédonie : cannes 50-80 lbs, moulinets conventionnels 50-80, essentiels pour gros spécimens"
                ),
                EtapeTechnique(
                    id: "fiche20_step2",
                    ordre: 2,
                    titre: "Choix puissance canne adaptée",
                    description: "Sélectionner selon résistance ligne utilisée : 20-30 lbs (traîne légère), 30-50 lbs (traîne moyenne thons), 50-80 lbs (traîne lourde marlins), 150-300g (jigging profond). Action parabolique préférable.",
                    illustrationsEtapes: "puissances_cannes",
                    conseil: "Traîne légère coryphène/bonite : 20-30 lbs, moulinets spinning 6000-8000, plus sportif et ludique"
                ),
                EtapeTechnique(
                    id: "fiche20_step3",
                    ordre: 3,
                    titre: "Sélection moulinet adapté",
                    description: "Dimensionner selon ligne : spinning 4000-6000 (traîne légère), 6000-8000 (casting), conventionnel 30-50 lbs (traîne moyenne), 50-80 lbs (traîne lourde). Frein progressif et puissant indispensable.",
                    illustrationsEtapes: "moulinets_types",
                    conseil: "Jigging profond (vivaneaux 150-400m) : cannes spécifiques 150-300g, moulinets forte récupération (ratio élevé)"
                ),
                EtapeTechnique(
                    id: "fiche20_step4",
                    ordre: 4,
                    titre: "Équilibrage ensemble canne/moulinet",
                    description: "Vérifier équilibre en main : point d'équilibre doit se situer légèrement devant le porte-moulinet. Ensemble déséquilibré = fatigue rapide. Tester flexion sous charge progressive.",
                    illustrationsEtapes: "equilibrage",
                    conseil: "Casting chasses : cannes 20-40 lbs, moulinets spinning ou casting 5000-6000, ratio récupération rapide"
                ),
                EtapeTechnique(
                    id: "fiche20_step5",
                    ordre: 5,
                    titre: "Test terrain et ajustements",
                    description: "Valider sur le terrain : confort préhension, réactivité ferrage, puissance au combat, résistance frein. Ajuster réglages (frein, drag, poignée). Roder progressivement le matériel.",
                    illustrationsEtapes: "test_terrain",
                    conseil: "Harnais de combat recommandé pour marlins >100kg : économie forces, combat prolongé possible"
                )
            ],
            conseilsPro: [
                "Traîne thon/marlin Nouvelle-Calédonie : cannes 50-80 lbs, moulinets conventionnels 50-80, essentiels pour gros spécimens",
                "Traîne légère coryphène/bonite : 20-30 lbs, moulinets spinning 6000-8000, plus sportif et ludique",
                "Jigging profond (vivaneaux 150-400m) : cannes spécifiques 150-300g, moulinets forte récupération (ratio élevé)",
                "Casting chasses : cannes 20-40 lbs, moulinets spinning ou casting 5000-6000, ratio récupération rapide",
                "Privilégier moulinets à freins puissants et progressifs : critères essentiels pour wahoos, thazards, marlins",
                "Marque Shimano, Daiwa, Penn reconnues fiables en milieu marin : investissement durable",
                "Harnais de combat recommandé pour marlins >100kg : économie forces, combat prolongé possible",
                "Anneaux SIC ou Fuji préférables : résistance abrasion tresse supérieure"
            ],
            erreursCourantes: [
                "Sous-estimer puissance nécessaire pour espèces locales : casse matériel assurée sur gros marlin",
                "Moulinets bas de gamme : défaillance frein au moment critique (perte gros poisson frustrant)",
                "Mauvais ratio récupération pour technique pratiquée : jigging avec ratio lent = épuisant",
                "Négliger équilibrage canne/moulinet : fatigue excessive bras",
                "Acheter matériel inadapté eau salée : corrosion rapide",
                "Cannes trop rigides : casse ligne au ferrage, inconfort au combat",
                "Économiser sur le moulinet (élément crucial) pour acheter canne chère : erreur de priorité"
            ],
            videoURL: nil,
            photosIllustrations: [
                "cannes_moulinets_techniques",
                "ensemble_traine_lourde",
                "ensemble_casting",
                "ensemble_jigging",
                "equilibrage_canne_moulinet"
            ],
            especesConcernees: [
                "Toutes espèces, adaptation matériel spécifique",
                "Marlins (50-80 lbs minimum)",
                "Thons (30-50 lbs recommandé)",
                "Wahoos (30-50 lbs, frein puissant)",
                "Coryphènes (20-30 lbs suffisant)",
                "Vivaneaux profonds (jigging spécifique)",
                "Carangues (30-50 lbs combat violent)",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "locheSaumonee",
                "becDeCane"
            ]
        )
    }
    
    // MARK: - FICHE 21: Lignes, tresses et bas de ligne
    
    static func createLignesTresses() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_21_lignes_tresses_bas_ligne",
            titre: "Lignes, tresses et bas de ligne",
            categorie: .equipement,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "Quelques sessions",
            description: """
                Choisir diamètres, matériaux et résistances adaptés. Constituer des bas de ligne performants selon espèces et techniques.
                
                La ligne est l'élément de connexion entre le pêcheur et le poisson. Un montage inadapté ou mal réalisé compromet toute la chaîne et conduit à la perte du poisson.
                """,
            materielNecessaire: [
                "Tresse 30-80 lbs (corps de ligne)",
                "Fluorocarbone 60-200 lbs (bas de ligne)",
                "Émerillons baril haute résistance (taille adaptée)",
                "Agrafes quick-change (optionnel)",
                "Ciseaux coupe-fil",
                "Briquet (sceller extrémités)"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche21_step1",
                    ordre: 1,
                    titre: "Sélection tresse corps de ligne",
                    description: "Choisir résistance selon technique et espèces : 30 lbs (traîne légère), 50 lbs (polyvalent NC), 80 lbs (traîne lourde marlins). Privilégier tresses 4 ou 8 brins (plus lisses, plus résistantes).",
                    illustrationsEtapes: "tresses_types",
                    conseil: "Tresse 50 lbs = standard polyvalent Nouvelle-Calédonie : compromis résistance/discrétion/casting"
                ),
                EtapeTechnique(
                    id: "fiche21_step2",
                    ordre: 2,
                    titre: "Choix fluorocarbone bas de ligne",
                    description: "Dimensionner selon espèces : 60-80 lbs (thons, coryphènes), 100-130 lbs (wahoos, gros thons), 150-200 lbs (marlins). Fluorocarbone = discrétion + résistance abrasion (dents, rostres, écailles).",
                    illustrationsEtapes: "fluorocarbone",
                    conseil: "Bas de ligne fluorocarbone 80-100 lbs = optimal : discrétion en eau claire + résistance suffisante thons/wahoos"
                ),
                EtapeTechnique(
                    id: "fiche21_step3",
                    ordre: 3,
                    titre: "Dimensionnement longueur bas de ligne",
                    description: "Longueur standard : 2-3 mètres minimum. Sécurité contre dents/rostres + permet manipulations décrochage sans risque coupure tresse. Marlins : 3-4m recommandés (sauts, frottements prolongés).",
                    illustrationsEtapes: "longueur_bas_ligne",
                    conseil: "Longueur 2m MINIMUM impérative : sécurité contre dents thazards/wahoos et rostres marlins"
                ),
                EtapeTechnique(
                    id: "fiche21_step4",
                    ordre: 4,
                    titre: "Connexions backing/tresse/bas de ligne",
                    description: "Réaliser nœuds de qualité : FG knot (tresse-fluorocarbone = 95-100% résistance), Palomar ou Uni (fluorocarbone-émerillon). Toujours humidifier avant serrage. Tester par traction progressive.",
                    illustrationsEtapes: "noeuds_connexion",
                    conseil: "Changer bas de ligne systématiquement tous les 3-4 sorties : abrasion invisible fragilise progressivement"
                ),
                EtapeTechnique(
                    id: "fiche21_step5",
                    ordre: 5,
                    titre: "Vérification usure et remplacement",
                    description: "Contrôler régulièrement : abrasion fluorocarbone (passer entre doigts), état tresse (effilochage), nœuds (glissement). Remplacer bas de ligne tous les 3-4 sorties, tresse chaque saison minimum.",
                    illustrationsEtapes: "verification_usure",
                    conseil: "Tresse multi-couleurs (changement tous les 10m) : permet estimer profondeur leurre en traîne"
                )
            ],
            conseilsPro: [
                "Tresse 50 lbs = standard polyvalent Nouvelle-Calédonie : compromis résistance/discrétion/casting",
                "Bas de ligne fluorocarbone 80-100 lbs = optimal : discrétion en eau claire + résistance suffisante thons/wahoos",
                "Longueur 2m MINIMUM impérative : sécurité contre dents thazards/wahoos et rostres marlins",
                "Changer bas de ligne systématiquement tous les 3-4 sorties : abrasion invisible fragilise progressivement",
                "Tresse multi-couleurs (changement tous les 10m) : permet estimer profondeur leurre en traîne",
                "Backing monofilament entre moulinet et tresse : amortisseur + économie tresse + meilleur remplissage tambour",
                "Éviter agrafes sur bas de ligne marlins : point faible, préférer connexion directe nœud loop",
                "Tresses japonaises (Varivas, YGK) réputées qualité supérieure mais coût élevé"
            ],
            erreursCourantes: [
                "Tresse trop fine pour espèces locales : casse assurée sur gros spécimens (marlins, gros thons)",
                "Bas de ligne nylon standard au lieu de fluorocarbone : trop visible, casse facilement",
                "Longueur bas de ligne <2m : risque coupure tresse par dents/rostre",
                "Négliger contrôle abrasion après chaque capture : fragilisation invisible",
                "Nœuds mal réalisés (serrage à sec) : point de rupture garanti",
                "Garder même bas de ligne toute saison : usure UV + micro-abrasions = rupture imprévue",
                "Tresse trop ancienne (>2 saisons) : perte résistance et élasticité"
            ],
            videoURL: nil,
            photosIllustrations: [
                "tresses_fluorocarbone",
                "montage_bas_ligne",
                "fg_knot_etapes",
                "verification_abrasion",
                "exemples_montages_especes"
            ],
            especesConcernees: [
                "Toutes espèces hauturières NC",
                "Wahoos (bas de ligne renforcé 130+ lbs)",
                "Thazards (fluorocarbone résistant dents)",
                "Marlins (bas de ligne long 3-4m, 150-200 lbs)",
                "Thons (80-100 lbs standard)",
                "Coryphènes (60-80 lbs suffisant)",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "barracuda",
                "becunes"
            ]
        )
    }
    
    
    // MARK: - FICHE 22: Nœuds essentiels pour la pêche hauturière
    
    static func createNoeudsEssentiels() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_22_noeuds_essentiels",
            titre: "Nœuds essentiels pêche hauturière",
            categorie: .equipement,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "Pratique régulière",
            description: """
                Maîtriser les nœuds fiables et rapides pour connexions tresse/fluorocarbone, bas de ligne/émerillon, bas de ligne/leurre.
                
                Un nœud mal réalisé est le point faible de toute la chaîne : 90% des pertes de gros poissons sont dues à une défaillance du nœud. La maîtrise des nœuds essentiels est donc fondamentale.
                """,
            materielNecessaire: [
                "Chutes tresse et fluorocarbone (entraînement)",
                "Récipient eau ou salive (humidification)",
                "Pince coupe-fil précise",
                "Briquet (sceller extrémités)",
                "Support fixe (porte, poignée) pour entraînement"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche22_step1",
                    ordre: 1,
                    titre: "Maîtrise du FG Knot (tresse-fluorocarbone)",
                    description: "Nœud de référence connexion tresse-fluorocarbone. Résistance 95-100% si parfaitement exécuté. Technique : tresse enroulée autour fluorocarbone tendu, minimum 15 tours, blocage final. S'entraîner jusqu'à automatisme.",
                    illustrationsEtapes: "fg_knot_tutorial",
                    conseil: "FG Knot = nœud de référence tresse-fluorocarbone : 95-100% résistance si parfaitement réalisé, compact, passe anneaux"
                ),
                EtapeTechnique(
                    id: "fiche22_step2",
                    ordre: 2,
                    titre: "Palomar (fluorocarbone-émerillon/agrafe)",
                    description: "Nœud simple et ultra-résistant (95-100%). Idéal émerillons et agrafes. Technique : boucle dans œillet, nœud simple avec boucle double, passer émerillon dans boucle, serrer. Toujours humidifier.",
                    illustrationsEtapes: "palomar_tutorial",
                    conseil: "TOUJOURS humidifier nœuds avant serrage final : chaleur friction fragilise considérablement (30-50% perte résistance)"
                ),
                EtapeTechnique(
                    id: "fiche22_step3",
                    ordre: 3,
                    titre: "Loop Knot (bas de ligne-leurre)",
                    description: "Nœud boucle laissant liberté mouvement au leurre (meilleure nage). Recommandé poppers, stickbaits, minnows. Technique : boucle non-serrante, 5-6 tours autour brin, repasser dans boucles. Humidifier impérativement.",
                    illustrationsEtapes: "loop_knot_tutorial",
                    conseil: "Doubler nombre de tours sur fluorocarbone gros diamètre (>100 lbs) : rigidité nécessite plus de tours pour serrage optimal"
                ),
                EtapeTechnique(
                    id: "fiche22_step4",
                    ordre: 4,
                    titre: "Entraînement répété jusqu'à automatisme",
                    description: "Pratiquer à terre, confortablement installé, sans stress. Répéter chaque nœud 10-20 fois jusqu'à réalisation fluide. S'entraîner les yeux fermés (simulation conditions difficiles en mer). Chronomètrer progression.",
                    illustrationsEtapes: "entrainement_noeuds",
                    conseil: "S'entraîner régulièrement à terre : en mer, stress et conditions difficiles compliquent réalisation"
                ),
                EtapeTechnique(
                    id: "fiche22_step5",
                    ordre: 5,
                    titre: "Test résistance systématique",
                    description: "Tester CHAQUE nœud par traction progressive forte avant utilisation. Nœud correct ne glisse pas et casse au niveau du fil, pas au nœud. Si glissement ou casse au nœud : refaire.",
                    illustrationsEtapes: "test_resistance",
                    conseil: "Couper excédent fils 2-3mm, JAMAIS à ras : risque glissement sous tension. Sceller extrémités au briquet (tresse) sans brûler nœud"
                )
            ],
            conseilsPro: [
                "FG Knot = nœud de référence tresse-fluorocarbone : 95-100% résistance si parfaitement réalisé, compact, passe anneaux",
                "TOUJOURS humidifier nœuds avant serrage final : chaleur friction fragilise considérablement (30-50% perte résistance)",
                "Doubler nombre de tours sur fluorocarbone gros diamètre (>100 lbs) : rigidité nécessite plus de tours pour serrage optimal",
                "Couper excédent fils 2-3mm, JAMAIS à ras : risque glissement sous tension. Sceller extrémités au briquet (tresse) sans brûler nœud",
                "Alternative FG Knot : Slim Beauty (plus simple, 90% résistance) ou PR Bobbin Knot (100% mais nécessite outil)",
                "Uni Knot double face = alternative Palomar, légèrement plus complexe mais équivalent résistance",
                "Loop Knot : ajuster taille boucle selon leurre, boucle trop grande = enchevêtrements",
                "S'entraîner régulièrement à terre : en mer, stress et conditions difficiles compliquent réalisation"
            ],
            erreursCourantes: [
                "Serrage à sec : friction = chaleur = fragilisation (30-50% résistance perdue), TOUJOURS humidifier abondamment",
                "Nœuds complexes mal maîtrisés : mieux vaut nœud simple bien fait que nœud élaboré approximatif",
                "Ne pas tester résistance avant utilisation : nœud défectueux découvert lors du combat = trop tard",
                "Couper fils à ras : risque glissement sous forte tension",
                "Trop peu de tours (FG Knot) : glissement garanti sous charge",
                "Serrage trop brutal : échauffement excessif = fragilisation même si humidifié",
                "Négliger entraînement régulier : dextérité se perd rapidement"
            ],
            videoURL: nil,
            photosIllustrations: [
                "fg_knot_etapes_detaillees",
                "palomar_etapes",
                "loop_knot_etapes",
                "test_resistance_noeud",
                "erreurs_courantes_noeuds"
            ],
            especesConcernees: [
                "Toutes espèces, nœuds universels",
                "Marlins (nœuds résistance maximale)",
                "Wahoos (FG Knot critique, dents tranchantes)",
                "Thons (Palomar émerillons)",
                "Coryphènes (Loop Knot leurres)",
                "Tous poissons à rostre (bas de ligne long + nœuds parfaits)",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "bonite",
                "thazard_raye",
                "Espadon voilier"
            ]
        )
    }
    
    // MARK: - FICHE 23: Hameçons et montage terminal
    
    static func createHameconsMontages() -> FicheTechnique {
        return FicheTechnique(
            id: "fiche_23_hamecons_montages",
            titre: "Hameçons et montages terminal",
            categorie: .equipement,
            niveauDifficulte: .intermediaire,
            dureeApprentissage: "Progressif",
            description: """
                Sélectionner types, tailles et montages d'hameçons adaptés aux leurres, techniques et espèces ciblées.
                
                L'hameçon est le point de contact final avec le poisson. Sa qualité, son affûtage et son adaptation déterminent le taux de réussite au ferrage et la tenue durant le combat.
                """,
            materielNecessaire: [
                "Hameçons simples (tailles 1/0 à 10/0)",
                "Hameçons doubles (tailles 2/0 à 6/0)",
                "Hameçons triples renforcés (tailles 2/0 à 6/0)",
                "Hameçons spéciaux GT/marlin (10/0 à 14/0)",
                "Anneaux brisés haute résistance",
                "Pinces hameçons",
                "Pierre à affûter diamant"
            ],
            illustrationPrincipale: nil,
            etapesDetaillees: [
                EtapeTechnique(
                    id: "fiche23_step1",
                    ordre: 1,
                    titre: "Identification type hameçon selon leurre",
                    description: "Adapter selon leurre : triples pour minnows/crankbaits (standard), simples ou doubles pour poppers/stickbaits (meilleurs sauts), assistés pour jigs (accroche ventre), cercle pour appâts naturels.",
                    illustrationsEtapes: "types_hamecons",
                    conseil: "Hameçons simples = meilleur taux décrochage pour no-kill : un seul point pénétration, poisson se décroche plus facilement (relâche saine)"
                ),
                EtapeTechnique(
                    id: "fiche23_step2",
                    ordre: 2,
                    titre: "Sélection taille proportionnelle",
                    description: "Dimensionner selon leurre et espèce, la taille minimale de l’hameçon est déterminée par la taille de la tête de l’appât : 2/0-4/0 (leurres 10-15cm, coryphènes, bonites), 4/0-6/0 (leurres 15-20cm, thons, wahoos), 8/0-12/0 (leurres >20cm, marlins). Ouverture adaptée bouche poisson.",
                    illustrationsEtapes: "tailles_hamecons",
                    conseil: "Taille standard 2/0-4/0 pour leurres 15-20cm NC = polyvalent : thons moyens, coryphènes, wahoos, carangues"
                ),
                EtapeTechnique(
                    id: "fiche23_step3",
                    ordre: 3,
                    titre: "Vérification piquant et résistance",
                    description: "Tester systématiquement affûtage : pointe doit s'accrocher dans ongle sans pression. Vérifier résistance ferrure (pas de déformation à la pince). Contrôler soudures anneaux/hampes.",
                    illustrationsEtapes: "verification_hamecons",
                    conseil: "Affûter régulièrement pierre diamant : pointe émoussée = ferrage raté, même bonne tirée. Test ongle fiable"
                ),
                EtapeTechnique(
                    id: "fiche23_step4",
                    ordre: 4,
                    titre: "Montage sécurisé anneaux brisés",
                    description: "Utiliser UNIQUEMENT anneaux brisés qualité (acier inox soudé). Jamais anneaux simples torsadés (ouverture sous tension). Taille anneau adaptée : suffisant pour liberté mouvement, pas excessif.",
                    illustrationsEtapes: "montage_anneaux",
                    conseil: "Marques Owner, Gamakatsu, Mustad réputées qualité : acier résistant, piquant durable, soudures fiables"
                ),
                EtapeTechnique(
                    id: "fiche23_step5",
                    ordre: 5,
                    titre: "Contrôle corrosion et affûtage",
                    description: "Inspecter après chaque sortie : corrosion (remplacer), émoussement (affûter pierre diamant), déformation (remplacer). Stocker hameçons à sec. Affûter régulièrement (tous les 2-3 poissons capturés).",
                    illustrationsEtapes: "entretien_hamecons",
                    conseil: "Remplacer hameçons AVANT rouille visible : corrosion fragilise structure (cassure sous tension)"
                )
            ],
            conseilsPro: [
                "Hameçons simples = meilleur taux décrochage pour no-kill : un seul point pénétration, poisson se décroche plus facilement (relâche saine)",
                "Triples renforcés OBLIGATOIRES pour thons/marlins : forces combat énormes, triples standard se déforment (ouverture) = décrochage",
                "Taille standard 2/0-4/0 pour leurres 15-20cm NC = polyvalent : thons moyens, coryphènes, wahoos, carangues",
                " Concept fondamental : La taille minimale de l’hameçon est déterminée par la taille de la tête de l’appât. L’ouverture de l’hameçon doit être capable d’accueillir la tête de l’appât, que ce soit une tête en résine, une tête souple ou une tête métallique.Au moins la moitié de l’ouverture de l’hameçon soit libre de l’action d’ombre que la tête exerce pendant la traîne, et donc d’avoir au moins la moitié de la largeur de l’hameçon capable de pénétrer profondément dans la mâchoire du poisson, garantissant ainsi une prise plus solide.",
                "Affûter régulièrement pierre diamant : pointe émoussée = ferrage raté, même bonne tirée. Test ongle fiable",
                "Marques Owner, Gamakatsu, Mustad réputées qualité : acier résistant, piquant durable, soudures fiables",
                "Cercle hooks (hameçons circulaires) pour appâts naturels : auto-ferrage coin bouche, moins de mortalité relâche",
                "Couleur hameçon : nickel (discret), noir (discret eau claire), rouge (imite sang, attractif)",
                "Remplacer hameçons AVANT rouille visible : corrosion fragilise structure (cassure sous tension)"
            ],
            erreursCourantes: [
                "Hameçons bas de gamme : déformation au combat (ouverture), perte gros poissons frustration maximale",
                "Taille inadaptée : trop gros = refus poisson (méfiance) ; trop petit = décrochage facile",
                "Négliger corrosion eau salée : fragilisation invisible puis cassure brutale au combat",
                "Ne jamais affûter : efficacité pénétration diminue rapidement (contact écailles, dents, structures)",
                "Anneaux brisés de mauvaise qualité : ouverture sous tension = perte leurre + poisson",
                "Garder hameçons rouillés : risque infection poisson (si relâche) + fragilité",
                "Trop d'hameçons sur même leurre : enchevêtrements, nage dégradée"
            ],
            videoURL: nil,
            photosIllustrations: [
                "types_hamecons_peche",
                "tailles_comparaison",
                "affutage_hamecon",
                "montage_hamecons_leurres",
                "hamecons_renforces_traine"
            ],
            especesConcernees: [
                "Toutes espèces, adaptation spécifique",
                "Marlins (triples renforcés 8/0-12/0)",
                "Thons (triples renforcés 4/0-8/0)",
                "Wahoos (simples ou triples 4/0-6/0)",
                "Coryphènes (simples ou doubles 2/0-4/0)",
                "GT carangues (simples extra-forts 6/0-10/0)",
                "Vivaneaux (cercle hooks 4/0-8/0)",
                "thonJaune",
                "marlin",
                "wahoo",
                "mahiMahi",
                "carangueGT",
                "becDeCane",
                "locheSaumonee"
            ]
        )
    }
    
    // MARK: - FICHE 24: Entretien et stockage du matériel
    
        static func createEntretienStockage() -> FicheTechnique {
            return FicheTechnique(
                id: "fiche_24_entretien_stockage",
                titre: "Entretien et stockage du matériel",
                categorie: .equipement,
                niveauDifficulte: .debutant,
                dureeApprentissage: "Routine à établir",
                description: """
                Procédures de rinçage, nettoyage, graissage et stockage pour préserver performances et durabilité du matériel de pêche.
                
                L'eau salée est le premier ennemi du matériel. Un entretien rigoureux après chaque sortie prolonge la durée de vie et garantit le bon fonctionnement au moment critique.
                """,
                materielNecessaire: [
                    "Eau douce (tuyau arrosage ou bassine)",
                    "Graisse moulinets (spécifique pêche)",
                    "Huile anti-corrosion (WD-40 ou CRC)",
                    "Chiffons microfibres",
                    "Brosses douces (nylon)",
                    "Tournevis précision (démontage moulinets)"
                ],
                illustrationPrincipale: nil,
                etapesDetaillees: [
                    EtapeTechnique(
                        id: "fiche24_step1",
                        ordre: 1,
                        titre: "Rinçage eau douce immédiat",
                        description: "IMMÉDIATEMENT après sortie, rincer abondamment cannes, moulinets (extérieur), leurres à l'eau douce. Insister sur mécanismes moulinets (manivelle, frein, guide-fil). Éliminer tout résidu sel. Durée 5-10 minutes minimum.",
                        illustrationsEtapes: "rincage_materiel",
                        conseil: "Ne JAMAIS ranger matériel humide/salé : corrosion garantie en 24-48h, dommages irréversibles sur mécanismes moulinets"
                    ),
                    EtapeTechnique(
                        id: "fiche24_step2",
                        ordre: 2,
                        titre: "Séchage complet avant rangement",
                        description: "Laisser sécher COMPLÈTEMENT à l'ombre (pas plein soleil). Essuyer cannes/moulinets avec chiffon microfibre. Actionner manivelle moulinet à vide pour évacuer eau mécanismes. Séchage complet = prévention corrosion.",
                        illustrationsEtapes: "sechage_materiel",
                        conseil: "Débrayer frein moulinet pendant stockage : préserve ressort, évite déformation permanente (frein inefficace ensuite)"
                    ),
                    EtapeTechnique(
                        id: "fiche24_step3",
                        ordre: 3,
                        titre: "Graissage moulinets périodique",
                        description: "Tous les 3 mois (ou 10 sorties) : graissage préventif. Déposer quelques gouttes huile sur roulements, manivelle, guide-fil. Tous les 6-12 mois : démontage complet, nettoyage, re-graissage engrenages. Selon notice fabricant.",
                        illustrationsEtapes: "graissage_moulinet",
                        conseil: "Vérifier lignes UV/abrasion régulièrement : passer entre doigts, rugosité = usure = remplacement proche"
                    ),
                    EtapeTechnique(
                        id: "fiche24_step4",
                        ordre: 4,
                        titre: "Contrôle anneaux cannes régulier",
                        description: "Vérifier anneaux cannes après chaque grosse prise : fissures (céramique), usure (rainure tresse), fixation (colle). Passer coton-tige dans anneaux : accrochage = fissure = remplacement urgent (casse ligne).",
                        illustrationsEtapes: "controle_anneaux",
                        conseil: "Démonter/nettoyer moulinets annuellement : entretien complet par professionnel ou selon notice fabricant (vidéos YouTube utiles)"
                    ),
                    EtapeTechnique(
                        id: "fiche24_step5",
                        ordre: 5,
                        titre: "Stockage optimal zone sèche",
                        description: "Stocker cannes verticales ou horizontales sur supports. Zone sèche, aérée, à l'abri UV. Débrayer frein moulinets (préserve ressort, évite déformation). Lignes détendues. Leurres séparés (éviter enchevêtrements).",
                        illustrationsEtapes: "stockage_materiel",
                        conseil: "Stocker cannes suspendues verticalement si possible : évite déformation, protège anneaux"
                    )
                ],
                conseilsPro: [
                    "Ne JAMAIS ranger matériel humide/salé : corrosion garantie en 24-48h, dommages irréversibles sur mécanismes moulinets",
                    "Débrayer frein moulinet pendant stockage : préserve ressort, évite déformation permanente (frein inefficace ensuite)",
                    "Vérifier lignes UV/abrasion régulièrement : passer entre doigts, rugosité = usure = remplacement proche",
                    "Démonter/nettoyer moulinets annuellement : entretien complet par professionnel ou selon notice fabricant (vidéos YouTube utiles)",
                    "Stocker cannes suspendues verticalement si possible : évite déformation, protège anneaux",
                    "Vaporiser WD-40 ou CRC sur mécanismes moulinets après rinçage/séchage : protection anti-corrosion supplémentaire",
                    "Remplacer joints moulinets préventivement (tous les 2 ans) : évite infiltrations eau = dommages coûteux",
                    "Ranger leurres séparément par type dans boîtes compartimentées : évite enchevêtrements hameçons, prolonge durée vie"
                ],
                erreursCourantes: [
                    "Négliger rinçage eau douce : sel = ennemi n°1 = corrosion rapide = matériel hors service en une saison",
                    "Sur-graisser moulinets : excès attire poussière/sable = abrasion accélérée engrenages (pire que sous-graissage)",
                    "Stockage plein soleil : UV dégradent nylon/fluorocarbone + dessèchent joints + décolorent leurres",
                    "Stockage environnement humide : moisissures, corrosion accélérée même si rincé",
                    "Oublier débrayage frein : déformation ressort = frein inefficace = casse ligne au combat suivant",
                    "Attendre corrosion visible pour agir : trop tard, dommages déjà importants",
                    "Ranger leurres emmêlés dans vrac : hameçons enchevêtrés = temps perdu + risque blessure"
                ],
                videoURL: nil,
                photosIllustrations: [
                    "rincage_eau_douce",
                    "sechage_materiel_ombre",
                    "graissage_moulinet_etapes",
                    "controle_anneaux_canne",
                    "stockage_optimal_cannes"
                ],
                especesConcernees: [
                    "Non applicable (maintenance préventive)",
                    "Bénéfice toutes techniques",
                    "Protection investissement matériel",
                    "Fiabilité au moment critique",
                    "Durabilité long terme"
                ]
            )
        }
    
    
    // MARK: - FICHE 25: Sécurité et réglementation
    
        static func createSecuriteReglementation() -> FicheTechnique {
            return FicheTechnique(
                id: "fiche_25_securite_reglementation_nc",
                titre: "Sécurité et réglementation Nouvelle-Calédonie",
                categorie: .equipement,
                niveauDifficulte: .debutant,
                dureeApprentissage: "Lecture réglementation",
                description: """
                Équipements de sécurité obligatoires, règles de sécurité en mer, réglementation pêche plaisance NC : tailles minimales, quotas, Aires Marines Protégées, espèces protégées.
                
                La sécurité est prioritaire. La réglementation protège les ressources pour les générations futures. Le respect de ces règles est une obligation légale et éthique.
                """,
                materielNecessaire: [
                    "Gilets sauvetage (1 par personne minimum)",
                    "VHF marine (canal 16 surveillance)",
                    "Fusées de détresse (3 minimum)",
                    "Trousse premiers secours complète",
                    "Miroir de signalisation",
                    "Ancre + cordage adapté profondeur",
                    "Écope + pompe de cale",
                    "Réserve carburant suffisante + 30%",
                    "Réglementation pêche NC à jour"
                ],
                illustrationPrincipale: nil,
                etapesDetaillees: [
                    EtapeTechnique(
                        id: "fiche25_step1",
                        ordre: 1,
                        titre: "Vérification équipements sécurité",
                        description: "Avant CHAQUE sortie : contrôler présence et état gilets (nombre suffisant, gonflage OK), VHF fonctionnelle (batteries), fusées non périmées, trousse secours complète, ancre opérationnelle. Liste check obligatoire.",
                        illustrationsEtapes: "equipements_securite",
                        conseil: "VHF canal 16 EN SURVEILLANCE PERMANENTE : appel détresse COSS (tél 16 ou VHF 16), réponse immédiate = survie"
                    ),
                    EtapeTechnique(
                        id: "fiche25_step2",
                        ordre: 2,
                        titre: "Consultation météo et zones AMP",
                        description: "Vérifier prévisions météo complètes (vent, houle, orages). Consulter carte Aires Marines Protégées (AMP) : localiser réserves intégrales (accès interdit), réserves naturelles (pêche interdite), AGDR. Planifier trajet conformément.",
                        illustrationsEtapes: "consultation_meteo_amp",
                        conseil: "Cartographie Aires Marines Protégées à jour : application smartphone ou cartes papier. Zones évoluent, vérifier annuellement"
                    ),
                    EtapeTechnique(
                        id: "fiche25_step3",
                        ordre: 3,
                        titre: "Respect tailles minimales réglementaires",
                        description: "Mesurer CHAQUE capture : thons 40cm fourche, picots rayés 20cm total, langoustes tête 7,5cm, bénitiers 20cm (2 max), trocas 9-12cm, huîtres 6cm, crabes 14cm. Relâcher immédiatement si sous-taille. Amende 2,684M F.",
                        illustrationsEtapes: "tailles_minimales_nc",
                        conseil: "Tailles minimales NC PRINCIPALES : thons 40cm FL, vivaneaux 25-35cm selon espèce, picot rayé 20cm, langoustes 7,5cm tête"
                    ),
                    EtapeTechnique(
                        id: "fiche25_step4",
                        ordre: 4,
                        titre: "Application stricte quotas pêche",
                        description: "Quota MAXIMUM : 40 kg par bateau/pêcheur/jour (poissons + coquillages + crustacés), SAUF pélagiques hauturiers (15 individus max wahoo/mahi/bonite/thon/marlin). Bénitiers 2 max. Huîtres 10 douzaines. Respecter scrupuleusement.",
                        illustrationsEtapes: "quotas_peche_nc",
                        conseil: "Quota général : 40 kg max par bateau/pêcheur/jour (poissons + coquillages + crustacés), SAUF pélagiques"
                    ),
                    EtapeTechnique(
                        id: "fiche25_step5",
                        ordre: 5,
                        titre: "Déclaration sorties et respect fermetures",
                        description: "Sorties >10 milles : informer personne contact (retour prévu). Respecter périodes fermeture : picots (1 sept-31 janv), crabes palétuviers (1 déc-31 janv), certaines passes. Espèces protégées : AUCUNE capture (tortues, dugongs, requins...).",
                        illustrationsEtapes: "periodes_fermeture_nc",
                        conseil: "Réserves intégrales NC : Yves Merlet (Grand Lagon Sud), N'Digoro (La Foa) = ACCÈS TOTALEMENT INTERDIT (amende 3,579M F)"
                    )
                ],
                conseilsPro: [
                    "VHF canal 16 EN SURVEILLANCE PERMANENTE : appel détresse COSS (tél 16 ou VHF 16), réponse immédiate = survie",
                    "Cartographie Aires Marines Protégées à jour : application smartphone ou cartes papier. Zones évoluent, vérifier annuellement",
                    "Tailles minimales NC PRINCIPALES : thons 40cm FL, vivaneaux 25-35cm selon espèce, picot rayé 20cm, langoustes 7,5cm tête",
                    "Ciguatera PRUDENCE : gros carnivores lagon >2kg (carangues, loches, vivaneaux côtiers) = risque élevé. Privilégier hauturier ou petits spécimens",
                    "Réserves intégrales NC : Yves Merlet (Grand Lagon Sud), N'Digoro (La Foa) = ACCÈS TOTALEMENT INTERDIT (amende 3,579M F)",
                    "Marquage obligatoire crustacés (sauf crabes) : couper bout queue langoustes/popinées/cigales (distinction pêche plaisance/pro)",
                    "Contacts urgence : COSS 16 (VHF/tél), Gardes Nature 54 13 02, Gendarmerie Maritime 29 40 36, Météo 36 67 36",
                    "Rejet déchets/restes poissons <500m côte/îlots = INTERDIT (requins) : amende 90 000 F, danger baigneurs"
                ],
                erreursCourantes: [
                    "Négliger météo avant sortie : prise risque inacceptable (vent >20 nœuds = danger, report obligatoire)",
                    "Ignorer tailles minimales : prélèvement juvéniles = appauvrissement stocks = sanctions lourdes (délit 2,684M F + confiscation)",
                    "Pêcher zones protégées par ignorance : AMP étendues NC, se renseigner AVANT. Amende 3,579M F + confiscation matériel",
                    "Dépasser quotas 40 kg : délit pénal sévèrement sanctionné (2,684M F + confiscation + casier judiciaire possible)",
                    "Capturer/déranger espèces protégées : tortues, dugongs, requins (TOUTES espèces), cétacés = délit 1,780M F + 6 mois prison",
                    "Absence équipements sécurité : gilets, VHF, fusées = immobilisation bateau + amendes",
                    "Vider poissons près îlots/côte : conditionnement dangereux requins = infraction + danger public"
                ],
                videoURL: nil,
                photosIllustrations: [
                    "equipements_securite_obligatoires",
                    "carte_amp_nouvelle_caledonie",
                    "tailles_minimales_principales_especes",
                    "especes_protegees_nc",
                    "contacts_urgence_nc",
                    "periodes_fermeture_saisonnieres"
                ],
                especesConcernees: [
                    "Toutes espèces : réglementation spécifique par espèce",
                    "PROTÉGÉES : tortues, dugongs, requins (toutes espèces), cétacés, napoléon, perroquet bosse, tricots rayés",
                    "QUOTAS : 40 kg max général (sauf pélagiques), bénitiers 2, huîtres 10 douzaines",
                    "FERMETURES : picots (sept-janv), crabes palétuviers (déc-janv)",
                    "TAILLES : thons 40cm, picots 20cm, langoustes 7,5cm tête, bénitiers 20cm, trocas 9-12cm",
                    "thonJaune",
                    "marlin",
                    "wahoo",
                    "mahiMahi",
                    "carangueGT",
                    "becDeCane",
                    "locheSaumonee",
                    "barracuda"
                ]
            )
        }
    
    // MARK: - FICHE 26: Anatomie stratégique d'un leurre de traîne
    
        static func createAnatomieStrategiqueLeurre() -> FicheTechnique {
            return FicheTechnique(
                id: "fiche_26_anatomie_strategique_leurres",
                titre: "Anatomie stratégique des leurres (Guide complet)",
                categorie: .montage,
                niveauDifficulte: .avance,
                dureeApprentissage: "Une saison d'observation",
                description: """
                Guide exhaustif sur l'anatomie des leurres de traîne : têtes (Bullet, Plunger, Pusher, Jet), jupes, bavettes, dimensions, vitesses optimales, profondeurs de nage et stratégie couleurs/contraste selon conditions environnementales.
                
                La sélection stratégique suit une hiérarchie décisionnelle scientifique : ZONE (lagon/large) → PROFONDEUR → VITESSE → TAILLE/ACTION → COULEUR/CONTRASTE. Chaque composant émet des signaux spécifiques (visuels, sonores, vibratoires) déclenchant l'attaque. Le succès n'est pas hasardeux mais résulte d'une analyse méthodique des variables : luminosité, turbidité, état mer, espèces cibles, vitesse bateau.
                """,
                materielNecessaire: [
                    "LEURRES À JUPE : têtes Bullet/Plunger/Pusher/Jet (5-7'' lagon, 8-12'' large)",
                    "LEURRES À BAVETTE : plongeants 10-15cm (lagon 2-4m), 14-20cm (large 6-12m)",
                    "ASSORTIMENT COULEURS : naturel (bleu/argent), contraste (bleu/blanc), sombre (noir/violet), flashy (rose/chartreuse)",
                    "JUPES DE RECHANGE : caoutchouc, plumes, tissu",
                    "HAMEÇONS : simples ou doubles, tailles 2/0-10/0 selon leurre",
                    "FIL DENTAIRE ou ficelle résistante (fixation jupes)",
                    "ANNEAUX BRISÉS haute résistance",
                    "CARNET OBSERVATIONS : noter résultats par condition (essentiel apprentissage)"
                ],
                illustrationPrincipale: nil,
                etapesDetaillees: [
                    EtapeTechnique(
                        id: "fiche26_step1",
                        ordre: 1,
                        titre: "Anatomie complète leurre à jupe",
                        description: "COMPOSANTS : (1) TÊTE RIGIDE (métal/plastique/bois) : détermine stabilité, production bulles, vitesse optimale. Formes : Bullet (ogive conique stabilité max), Plunger/Pusher (tronquée concave agressive), Jet (perforée traînée bulles).(2) JUPE SOUPLE (caoutchouc/plumes/tissu) : ondule imitant proie blessée, dissimule hameçons. Longueur : 5-7'' lagon (10-16cm), 8-12'' large (15-25cm). (3) HAMEÇONS : montage 1-2, premier caché jupe, second près extrémité. MONTAGE : fixer hameçons bas de ligne (manchons sertis), glisser jupe, attacher tête fil dentaire/ficelle. FABRICATION MAISON : lests plomb, tubes métal, corps stylo pour têtes. Plumes poulet, bandes tissu pour jupes.",
                        illustrationsEtapes: "anatomie_leurre_jupe_detaillee",
                        conseil: "DIMENSIONNEMENT CRITIQUE : Lagon = imitation fusiliers/sardines 10-16cm. Large = imitation bonites/maquereaux 15-25cm. Jupe endommagée = remplacement IMMÉDIAT, attractivité chute 70%"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step2",
                        ordre: 2,
                        titre: "Types de têtes et actions spécifiques",
                        description: "BULLET (OGIVE/CONIQUE) : Stabilité maximale, nage discrète droite, bulle modérée. Vitesse haute 10-16 nœuds. Mer calme ou traîne rapide. Wahoo (12-16 nœuds), thons jaune. Performent mieux forte luminosité (sillage peu visible). PLUNGER/PUSHER (TRONQUÉE/CONCAVE = CUP FACE) : Agressive, turbulence max, bulles abondantes, POP sonore surface (respiration). Poissons actifs, mer formée. Excellente mahi-mahi. Compense faible visibilité par bruit. Cycle respiration optimal : 4,5-5,5 secondes (leurres très actifs). JET (PERFORÉE/SIFFLEUSE) : Traînée bulles longue visible (il fume), simule proie fuite, attire de loin. Recherche vastes zones. Marlin, thon. Signature visuelle maximale. CHOIX SELON MER : Mer agitée = têtes Bullet (stables). Mer calme = têtes Pusher (agressives). Eau trouble = Cup face (bulles/bruit compensent).",
                        illustrationsEtapes: "tetes_actions_comparaison",
                        conseil: "ACTION = signature vibratoire leurre. Réglage correct : rythme capture air + plongée régulier, cycle 4,5-5,5 sec pour actifs. Test terrain obligatoire avant pêche : observer comportement surface vitesse cible"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step3",
                        ordre: 3,
                        titre: "Bavettes : géométrie, angle, profondeur",
                        description: "PRINCIPE : Bavette inclinée crée résistance hydrodynamique → force leurre vers bas + wobbling latéral (oscillation attractive). PROFONDEUR dépend : taille bavette, angle inclinaison, ligne utilisée, vitesse traîne. LAGON (10-15cm bavettes) : Profondeur nage 2-4m réelle. Medium à deep. Supportent 4-6 nœuds sans décrocher. Espèces : thazards, carangues, barracudas, petits thons. Coloris : bleu/argent (sardine), chartreuse/blanc (eau teintée), rose/blanc (aube). Exemples : Halco Sorcerer 125, Rapala X-Rap Magnum 140. LARGE (14-20cm bavettes) : Profondeur nage 6-12m. Modèles HIGH SPEED TROLLING nécessaires si >8 nœuds. Wahoo, thon profond. Coloris : sardine, bonite, maquereau. Exemples : Manns Magnum Stretch 30+, Rapala Countdown Magnum 180 (plonge 2-6m). VITESSE CRITIQUE : <5 nœuds généralement. Trop rapide = leurre remonte surface (perd profondeur). WOBBLING : action serrée rapide préférable. Cliquetis/billes internes aident détection ligne latérale faible visibilité.",
                        illustrationsEtapes: "bavettes_profondeurs_angles",
                        conseil: "RÈGLE : Plus bavette longue/inclinée, plus plonge profond. Vitesse excessive annule plongée. Modèles spéciaux haute vitesse existent (rare, coûteux). Tester profondeur réelle : repères profondimètre ou observation sondeur"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step4",
                        ordre: 4,
                        titre: "Stratégie couleur selon luminosité",
                        description: "RÈGLE GÉNÉRALE : Plus eau claire + lumineuse → couleur naturelle (mimétisme finesse). Plus eau sombre/sale → contraste élevé (visibilité maximale). SOLEIL FORT / CIEL DÉGAGÉ / EAU CLAIRE : Couleurs NATURELLES, transparentes, métalliques : bleu/argent, vert/doré, sardine, maquereau, reflets holographiques légers. Poissons voient très bien, finesse et reflets subtils préférables. Têtes discrètes (Bullet). Contraste naturel bas. NUAGEUX / LUMIÈRE DIFFUSE / TEMPS VOILÉ : Couleurs CONTRASTÉES : bleu/blanc, rose/blanc, violet/blanc, vert/chartreuse. Augmenter légèrement contraste + vibration. Têtes Cup face modérées. Mylar (flash) devient atout. AUBE / CRÉPUSCULE / TEMPS NOIR / FAIBLE LUMIÈRE : Couleurs SOMBRES et CONTRASTÉES : noir/violet, noir/rouge, noir/bleu, orange. Carnassiers chassent par SILHOUETTE (ombre contre luminosité résiduelle). Contraste > couleur pure. Têtes Cup face fortes. PRINCIPE : Carnivores chassent souvent PAR SILHOUETTE dans colonne eau, surtout faible lumière. Contraste détermine visibilité.",
                        illustrationsEtapes: "couleurs_luminosite_science",
                        conseil: "ERREUR FRÉQUENTE : leurre trop fluo eau limpide = fait décrocher poissons méfiants. ASTUCE PRO : construire sillage traîne couleurs COMPLÉMENTAIRES (Naturel + Sombre + Flashy) = couvre toutes options visuelles simultanément"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step5",
                        ordre: 5,
                        titre: "Stratégie couleur selon turbidité",
                        description: "EAU TRÈS CLAIRE (lagon intérieur) : Couleurs DISCRÈTES, naturelles, transparentes : bleu clair, vert pâle, argenté transparent, reflets subtils. Poissons TRÈS méfiants, éviter flashy excessif. Petits leurres, têtes peu bruyantes (Bullet, semi-bullet). Flash mylar subtil uniquement. EAU LÉGÈREMENT TURBIDE (passes, marée, vent modéré) : Couleurs VIVES et FLASHY : chartreuse, rose, violet, orange. Mylar (flash) devient ATOUT (compense turbidité). Contraste modéré à élevé. Têtes Pusher efficaces. EAU TRÈS TROUBLE (pluie forte, marée sortante lagon, eau chargée sédiments) : Couleurs TRÈS CONTRASTÉES : noir, violet foncé, rouge, chartreuse fluo. Têtes BRUYANTES obligatoires : Cup face profond (bulles + pop sonore compensent manque visibilité totale). Bavettes avec cliquetis internes. PRINCIPE : Turbidité réduit visibilité → compenser par contraste + bruit + vibration. Plus eau sale, plus signaux forts nécessaires (visuels + sonores).",
                        illustrationsEtapes: "couleurs_turbidite_strategie",
                        conseil: "ADAPTATION DYNAMIQUE essentielle : eau change durant journée (marée, pluie, vent). Observer résultats, changer si nécessaire. Eau sale = ne pas hésiter couleurs extrêmes (noir total, chartreuse fluo)"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step6",
                        ordre: 6,
                        titre: "Matrice décision complète : zone et vitesse",
                        description: "HIÉRARCHIE DÉCISIONNELLE : Zone → Profondeur → Vitesse → Taille/Action → Couleur/Contraste. LAGON/CÔTIERS (4-7 nœuds) : Espèces : thazards, carangues, barracudas, petits thons. Profondeur : 1-5m. Taille : 10-16cm (imitation fusiliers/sardines). Leurres : bavettes 10-15cm (medium à deep 2-4m, supportent 4-6 nœuds), jupes 5-7'' (têtes Bullet ou petit Pusher peu agressif). Couleurs : naturel (bleu/argent), chartreuse/blanc (eau teintée), rose/blanc (aube/couvert). LARGE/HORS RÉCIF STANDARD (6-8 nœuds) : Espèces : mahi-mahi, thons jaunes. Profondeur : 0-15m. Taille : 15-25cm (imitation bonites/maquereaux). Leurres : bavettes 14-20cm (plongent 6-12m), jupes 8-12'' (têtes Plunger/Pusher gros remous surface). Couleurs : bleu/blanc, vert/doré/lumo (mahi-mahi), violet/noir (faible lumière). HAUTE VITESSE WAHOO (12-16 nœuds) : Leurres : têtes Bullet lourdes (stabilité maximale haute vitesse), bavettes high speed trolling spéciales. Jupes grandes 10-12''. Bas de ligne lourds. Couleurs : violet/noir, sardine, bonite. Profondeur : 0-12m. Technique : prospection vastes zones, passes autour DCPs sans traverser banc.",
                        illustrationsEtapes: "matrice_decision_complete",
                        conseil: "TRANSITION CLAIRE : Lagon = finesse + imitation (leurres discrets, couleurs naturelles). Large = visibilité + provocation (leurres grands, têtes agressives, contrastes élevés) pour environnement vaste et compétitif"
                    ),
                    EtapeTechnique(
                        id: "fiche26_step7",
                        ordre: 7,
                        titre: "Arsenal de base recommandé",
                        description: "ARSENAL LAGON MINIMUM (débuter) : (1) Bavette 12-15cm couleur naturelle (bleu/argent sardine), (2) Bavette 12-15cm couleur fluo (chartreuse/blanc ou rose/blanc), (3) Petite jupe 5-7'' tête Bullet (bleu/blanc ou vert/doré). Permet couvrir 80% situations. ARSENAL LARGE MINIMUM (débuter) : (1) Jupe 8-10'' tête Pusher bleu/blanc (universel), (2) Jupe 8-10'' tête Pusher vert/doré/lumo (mahi-mahi), (3) Juke 8-10'' tête Bullet violet/noir (faible lumière/gros poissons), (4) Bavette haute vitesse 16-20cm sardine/bonite (wahoo profond). PROGRESSION : Constituer collection progressive observations terrain. Noter systématiquement : conditions (luminosité, turbidité, mer), leurre utilisé, résultat. Ajuster arsenal selon zones pêchées fréquemment. MARQUES RÉFÉRENCE : Halco, Rapala (bavettes), fabrication artisanale locale (jupes), Manns (bavettes haute vitesse). INVESTISSEMENT : Qualité > quantité. Mieux 5 leurres excellents parfaitement maîtrisés que 30 médiocres jamais testés.",
                        illustrationsEtapes: "arsenal_base_recommande",
                        conseil: "SCIENCE DE L'OBSERVATION : succès pêche traîne n'est PAS hasard. Démarche méthodique, analyse environnement, chaque variable compte (couleur eau, phase lune, turbidité, luminosité). Sélection leurre = conclusion analyse stratégique"
                    )
                ],
                conseilsPro: [
                    "Fabrication maison leurres à jupe : lests plomb, tubes métal, corps stylo pour têtes + plumes poulet, bandes tissu pour jupes. Économique et efficace",
                    "Cycle respiration optimal leurres très actifs : 4,5-5,5 secondes (capture air + plongée). Réglage critique pour efficacité maximale",
                    "Haute vitesse (10-16 nœuds) : UNIQUEMENT têtes ogives/siffleuses (Bullet/Tube) pour nage stable. Autres têtes décrochent, perdent action",
                    "Eau trouble/agitée : têtes Cup face profondes OBLIGATOIRES (bulles + pop sonore compensent faible visibilité). Ne pas espérer résultats têtes discrètes",
                    "Bavettes : vitesse <5 nœuds généralement. Modèles high speed (>8 nœuds) rares et chers. Trop rapide = leurre remonte surface = perte profondeur cible",
                    "Wobbling bavettes : action serrée rapide préférable. Cliquetis/billes internes aident détection ligne latérale (vibrations) en faible visibilité",
                    "Règle couleurs UNIVERSELLE : Eau claire/lumineuse → naturel/mimétisme. Eau sombre/sale → contraste élevé/visibilité. Exception : méfiance poissons eau très claire (éviter fluo excessif)",
                    "Sillage traîne couleurs complémentaires : déployer simultanément Naturel + Sombre + Flashy = exploite toutes options visuelles = maximise probabilité attaque",
                    "Carnassiers chassent PAR SILHOUETTE dans colonne eau, surtout faible lumière. Contraste > couleur absolue. Aube/crépuscule : noir/rouge, noir/violet excellents",
                    "Adaptation dynamique essentielle : eau change durant journée (marée, pluie, vent, soleil). Observer résultats réels, ajuster rapidement si improductif",
                    "Arsenal minimum efficace : Lagon = 3 leurres (2 bavettes + 1 jupe). Large = 4 leurres (3 jupes + 1 bavette haute vitesse). Qualité > quantité",
                    "Science de l'observation : succès = analyse méthodique, pas hasard. Noter systématiquement conditions/leurres/résultats. Construire base données personnelle",
                    "Transition lagon/large claire : Lagon = finesse 10-16cm + naturel + discret + 4-6 nœuds. Large = visibilité 15-25cm + contraste + agressif + 6-16 nœuds",
                    "Ne JAMAIS utiliser tête Pusher agressive par mer calme eau claire : rend poissons méfiants. Inversement, ne JAMAIS utiliser tête Bullet discrète eau trouble mer formée : invisible",
                    "Marques référence fiables : Halco Sorcerer, Rapala X-Rap Magnum, Manns Magnum Stretch. Mais artisanat local souvent aussi efficace si bien conçu"
                ],
                erreursCourantes: [
                    "Ne pas remplacer jupe endommagée : attractivité chute 70%, ondulation incorrecte, hameçons exposés = refus poissons",
                    "Utiliser tête Pusher agressive par mer calme eau claire : turbulence excessive rend poissons méfiants, fuient",
                    "Utiliser tête Bullet discrète eau très trouble mer formée : totalement invisible, aucun signal, improductif garanti",
                    "Traîner bavettes trop rapidement (>5-6 nœuds pour standards) : annule plongée, leurre remonte surface, perd profondeur cible, improductif",
                    "Leurre trop fluo (chartreuse, rose vif) en eau limpide soleil fort : effet inverse, fait décrocher poissons méfiants au lieu d'attirer",
                    "Ignorer conditions luminosité et turbidité dans choix couleur : erreur fondamentale, rend leurre invisible ou repoussant",
                    "Ne pas varier types têtes selon conditions mer et activité poissons : rigidité stratégique, perd opportunités",
                    "Négliger importance contraste conditions faible visibilité : carnassiers chassent par silhouette, contraste primordial aube/crépuscule/eau trouble",
                    "Arsenal pléthorique mal maîtrisé : 30 leurres jamais testés < 5 leurres excellents parfaitement connus et réglés",
                    "Ne pas noter observations terrain : impossible progresser, reproduire succès, comprendre échecs. Carnet observations OBLIGATOIRE",
                    "Croire qu'un seul leurre miracle universel existe : illusion. Adaptation conditions TOUJOURS nécessaire. Polyvalence = clé",
                    "Négliger réglage cycle respiration leurres actifs : mauvais réglage = action incorrecte = inefficace même bon leurre/bonne couleur",
                    "Traîner uniquement surface (jupes) ou uniquement profondeur (bavettes) : ne couvre pas colonne eau. Varier profondeurs dans spread obligatoire"
                ],
                videoURL: nil,
                photosIllustrations: [
                    "anatomie_leurre_jupe_composants",
                    "tetes_bullet_plunger_pusher_jet_comparaison",
                    "bavettes_angles_profondeurs_schema",
                    "tableau_couleurs_luminosite_detaille",
                    "tableau_couleurs_turbidite_detaille",
                    "matrice_decision_zone_vitesse_complete",
                    "sillage_traine_couleurs_complementaires",
                    "arsenal_base_lagon_large",
                    "cycle_respiration_leurre_actif",
                    "exemples_reels_captures_par_leurre"
                ],
                especesConcernees: [
                    "LAGON : Thazards (bavettes 10-15cm), Carangues (bavettes naturelles), Barracudas (bavettes vives), Petits thons (jupes 5-7'' Bullet)",
                    "LARGE STANDARD : Thons jaunes (jukes 8-10'' Bullet/Tube), Mahi-mahi (jupes 8-12'' Pusher vert/doré/lumo)",
                    "HAUTE VITESSE : Wahoo (jupes 10-12'' Bullet lourd 12-16 nœuds, bavettes high speed)",
                    "MARLINS : Jupes grandes 10-12'' têtes Jet (traînée bulles), têtes Pusher (mer formée)",
                    "VOILIERS : Jupes 8-10'' têtes variées selon activité",
                    "THAZARD-BÂTARD : Bavettes 15-18cm couleurs vives, leurres rigides rapides",
                    "COUREUR ARC-EN-CIEL : Bavettes moyennes profondeur variable",
                    "BEC-DE-CANE : Rarement traîne (plutôt jigging profond), mais bavettes profondes possibles",
                    "thonJaune",
                    "mahiMahi",
                    "marlin",
                    "wahoo",
                    "thazard_raye",
                    "carangueGT",
                    "bonite",
                    "becDeCane",
                    "Espadon voilier"
                ]
            )
        }
    }
