//
//  EspecesDatabase.swift
//  Go les Picots - Module 2
//
//  Base de connaissances des espèces de Nouvelle-Calédonie
//  Focus sur les espèces pêchables à la traîne (Phase 2 Module 2)
//
//  Sources :
//  - CPS "Techniques de pêche côtière" 2023
//  - Guide Moore & Colas - Identification poissons côtiers
//  - Document "Consignes pour moteur stratégique de suggestion"
//
//  Created: 2024-12-11
//

import Foundation

// MARK: - Structure EspeceInfo pour le moteur de suggestion

/// Informations complètes sur une espèce pour le moteur de suggestion
struct EspeceInfo: Codable, Hashable, Identifiable {
    var id: String { identifiant }
    
    let identifiant: String              // Ex: "thonJaune"
    let nomCommun: String                // Ex: "Thon jaune"
    let nomScientifique: String          // Ex: "Thunnus albacares"
    let famille: String                  // Ex: "Scombridae"
    
    // Où la trouver
    let zones: [Zone]
    let profondeurMin: Double            // mètres
    let profondeurMax: Double            // mètres
    
    // Comment la pêcher
    let typesPecheCompatibles: [TypePeche]
    
    // Spécifique TRAINE (renseigné si pêchable en traîne)
    let traineInfo: TraineInfo?
    
    // Comportement
    let comportement: String?
    let momentsFavorables: [MomentJournee]?
    
    /// Indique si cette espèce est pêchable à la traîne
    var estPechableEnTraine: Bool {
        typesPecheCompatibles.contains(.traine)
    }
}

/// Informations spécifiques à la pêche à la traîne pour une espèce
struct TraineInfo: Codable, Hashable {
    let vitesseMin: Double               // nœuds
    let vitesseMax: Double               // nœuds
    let vitesseOptimale: Double          // nœuds
    let profondeurNageOptimale: String   // Ex: "0-15m", "surface"
    let tailleLeurreMin: Double          // cm
    let tailleLeurreMax: Double          // cm
    let typesLeurresRecommandes: [String] // Ex: ["bavette", "jupe", "stickbait"]
    let couleursRecommandees: [String]   // Ex: ["bleu/blanc", "naturel"]
    let positionsSpreadRecommandees: [PositionSpread]?
    let notes: String?
}

// MARK: - Base de données des espèces

/// Base de connaissances des espèces - Singleton
class EspecesDatabase {
    
    static let shared = EspecesDatabase()
    
    private init() {}
    
    // ═══════════════════════════════════════════════════════════════════════════
    // ESPÈCES PÊCHABLES À LA TRAÎNE (Focus Phase 2 Module 2)
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Toutes les espèces avec leurs informations complètes
    lazy var especesTraine: [EspeceInfo] = [
        
        // ─────────────────────────────────────────────────────────────────────
        // THONS
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "thonJaune",
            nomCommun: "Thon jaune (Albacore)",
            nomScientifique: "Thunnus albacares",
            famille: "Scombridae",
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 100,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "0-50m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["jupe", "bavette plongeante"],
                couleursRecommandees: ["bleu/blanc", "vert/doré", "rose"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shortRigger],
                notes: "Chasse en banc, très rapide. DCP très efficaces."
            ),
            comportement: "Chasse en banc à la surface, attaque rapide",
            momentsFavorables: [.aube, .matinee, .crepuscule]
        ),
        
        EspeceInfo(
            identifiant: "thonObese",
            nomCommun: "Thon obèse",
            nomScientifique: "Thunnus obesus",
            famille: "Scombridae",
            zones: [.large, .dcp],
            profondeurMin: 50,
            profondeurMax: 300,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 9.0,
                vitesseOptimale: 7.0,
                profondeurNageOptimale: "50-150m",
                tailleLeurreMin: 18.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["bavette profonde", "jupe lourde"],
                couleursRecommandees: ["naturel", "bleu foncé", "violet"],
                positionsSpreadRecommandees: [.longCorner, .shotgun],
                notes: "Espèce profonde, nécessite leurres plongeants ou downrigger."
            ),
            comportement: "Évolue en profondeur, remonte à l'aube/crépuscule",
            momentsFavorables: [.aube, .crepuscule]
        ),
        
        EspeceInfo(
            identifiant: "bonite",
            nomCommun: "Bonite (Listao)",
            nomScientifique: "Katsuwonus pelamis",
            famille: "Scombridae",
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 30,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 5.0,
                vitesseMax: 9.0,
                vitesseOptimale: 7.0,
                profondeurNageOptimale: "surface-20m",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["jupe petite", "bavette", "plume"],
                couleursRecommandees: ["bleu/blanc", "rose/blanc", "naturel"],
                positionsSpreadRecommandees: [.shortRigger, .longRigger],
                notes: "Très présente aux DCP. Excellente pour débuter."
            ),
            comportement: "Chasse en surface en grands bancs",
            momentsFavorables: [.matinee, .apresMidi]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // WAHOO
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "wahoo",
            nomCommun: "Wahoo (Thazard-bâtard)",
            nomScientifique: "Acanthocybium solandri",
            famille: "Scombridae",
            zones: [.large, .passe, .dcp],
            profondeurMin: 0,
            profondeurMax: 40,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 10.0,
                vitesseMax: 16.0,
                vitesseOptimale: 12.0,
                profondeurNageOptimale: "5-20m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 22.0,
                typesLeurresRecommandes: ["bavette haute vitesse", "jupe bullet"],
                couleursRecommandees: ["rose", "bleu/blanc", "noir/violet", "naturel"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "VITESSE ÉLEVÉE OBLIGATOIRE. Dents acérées = câble métallique."
            ),
            comportement: "Chasseur ultra-rapide, attaque éclair",
            momentsFavorables: [.midi, .apresMidi]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // MAHI-MAHI
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "mahiMahi",
            nomCommun: "Mahi-mahi (Coryphène)",
            nomScientifique: "Coryphaena hippurus",
            famille: "Coryphaenidae",
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 50,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "surface-30m",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 20.0,
                typesLeurresRecommandes: ["jupe pusher", "bavette", "flying fish"],
                couleursRecommandees: ["vert/doré", "bleu/blanc", "chartreuse", "rose"],
                positionsSpreadRecommandees: [.shortRigger, .longRigger, .shotgun],
                notes: "Suit les objets flottants. DCP et débris très efficaces."
            ),
            comportement: "Suit les objets flottants, attaque en surface",
            momentsFavorables: [.matinee, .apresMidi]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // MARLINS ET VOILIERS
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "marlin",
            nomCommun: "Marlin",
            nomScientifique: "Makaira spp.",
            famille: "Istiophoridae",
            zones: [.large],
            profondeurMin: 0,
            profondeurMax: 100,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 7.0,
                vitesseMax: 12.0,
                vitesseOptimale: 9.0,
                profondeurNageOptimale: "surface-50m",
                tailleLeurreMin: 20.0,
                tailleLeurreMax: 35.0,
                typesLeurresRecommandes: ["jupe large 10-12\"", "flying fish"],
                couleursRecommandees: ["noir/pourpre", "rose/blanc", "bleu/blanc"],
                positionsSpreadRecommandees: [.shotgun, .longRigger],
                notes: "Poisson suiveur. Position shotgun idéale. Gros matériel."
            ),
            comportement: "Chasse visuelle, suit les leurres avant d'attaquer",
            momentsFavorables: [.aube, .crepuscule]
        ),
        
        EspeceInfo(
            identifiant: "voilier",
            nomCommun: "Voilier (Espadon voilier)",
            nomScientifique: "Istiophorus platypterus",
            famille: "Istiophoridae",
            zones: [.large, .passe],
            profondeurMin: 0,
            profondeurMax: 50,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 5.0,
                vitesseMax: 9.0,
                vitesseOptimale: 7.0,
                profondeurNageOptimale: "surface-30m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["jupe", "bavette", "appât naturel"],
                couleursRecommandees: ["bleu/blanc", "rose", "naturel"],
                positionsSpreadRecommandees: [.longRigger, .shotgun],
                notes: "Plus fréquent que le marlin. Vitesse modérée."
            ),
            comportement: "Chasse en surface et mi-eau",
            momentsFavorables: [.aube, .matinee, .crepuscule]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // THAZARDS
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "thazard",
            nomCommun: "Thazard rayé (commun)",
            nomScientifique: "Scomberomorus commerson",
            famille: "Scombridae",
            zones: [.lagon, .passe, .recif],
            profondeurMin: 0,
            profondeurMax: 15,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 7.0,
                vitesseOptimale: 5.0,
                profondeurNageOptimale: "surface-10m",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 16.0,
                typesLeurresRecommandes: ["bavette 10-15cm", "jupe petite"],
                couleursRecommandees: ["naturel", "bleu/argenté", "chartreuse"],
                positionsSpreadRecommandees: [.longCorner, .shortRigger],
                notes: "Espèce côtière. Vitesse modérée. Câble recommandé."
            ),
            comportement: "Chasse en surface, attaque rapide",
            momentsFavorables: [.aube, .matinee]
        ),
        
        EspeceInfo(
            identifiant: "thazardBatard",
            nomCommun: "Thazard bâtard (du large)",
            nomScientifique: "Acanthocybium solandri",
            famille: "Scombridae",
            zones: [.large, .passe],
            profondeurMin: 0,
            profondeurMax: 30,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 8.0,
                vitesseMax: 14.0,
                vitesseOptimale: 10.0,
                profondeurNageOptimale: "5-20m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 22.0,
                typesLeurresRecommandes: ["bavette rapide", "jupe bullet"],
                couleursRecommandees: ["rose", "bleu/blanc", "naturel"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "Similaire au Wahoo. Vitesse élevée. Câble obligatoire."
            ),
            comportement: "Très rapide, attaque violente",
            momentsFavorables: [.midi, .apresMidi]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // CARANGUES
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "carangueGT",
            nomCommun: "Carangue GT (Giant Trevally)",
            nomScientifique: "Caranx ignobilis",
            famille: "Carangidae",
            zones: [.passe, .recif, .lagon, .large],
            profondeurMin: 0,
            profondeurMax: 20,
            typesPecheCompatibles: [.traine, .lancer, .jig],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "surface-15m",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["popper", "stickbait", "bavette", "jupe"],
                couleursRecommandees: ["naturel", "blanc/rouge", "chartreuse"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "Embuscade, attaque violente. Casting souvent préféré."
            ),
            comportement: "Embuscade près des structures, attaque violente",
            momentsFavorables: [.aube, .crepuscule]
        ),
        
        EspeceInfo(
            identifiant: "carangueBleue",
            nomCommun: "Carangue bleue",
            nomScientifique: "Caranx melampygus",
            famille: "Carangidae",
            zones: [.lagon, .recif, .passe],
            profondeurMin: 0,
            profondeurMax: 15,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 7.0,
                vitesseOptimale: 5.0,
                profondeurNageOptimale: "surface-10m",
                tailleLeurreMin: 8.0,
                tailleLeurreMax: 15.0,
                typesLeurresRecommandes: ["bavette petite", "jupe 5-7\""],
                couleursRecommandees: ["bleu/argenté", "naturel", "vert"],
                positionsSpreadRecommandees: [.longCorner, .shortRigger],
                notes: "Espèce lagonaire. Petits leurres efficaces."
            ),
            comportement: "Chasse active dans le lagon",
            momentsFavorables: [.matinee, .apresMidi]
        ),
        
        EspeceInfo(
            identifiant: "carangue",
            nomCommun: "Carangue (diverses)",
            nomScientifique: "Caranx spp.",
            famille: "Carangidae",
            zones: [.lagon, .recif, .passe],
            profondeurMin: 0,
            profondeurMax: 20,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 7.0,
                vitesseOptimale: 5.0,
                profondeurNageOptimale: "surface-15m",
                tailleLeurreMin: 8.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["bavette", "jupe", "stickbait"],
                couleursRecommandees: ["naturel", "bleu/argenté", "chartreuse"],
                positionsSpreadRecommandees: [.longCorner, .shortRigger],
                notes: "Groupe diversifié. Adapter taille selon espèce ciblée."
            ),
            comportement: "Variable selon espèce",
            momentsFavorables: [.aube, .matinee, .crepuscule]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // BARRACUDAS / BÉCUNES
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "barracuda",
            nomCommun: "Barracuda",
            nomScientifique: "Sphyraena barracuda",
            famille: "Sphyraenidae",
            zones: [.lagon, .passe, .recif],
            profondeurMin: 0,
            profondeurMax: 15,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "surface-10m",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["bavette longue", "jupe argentée"],
                couleursRecommandees: ["argenté", "naturel", "bleu/blanc"],
                positionsSpreadRecommandees: [.longCorner, .shortRigger],
                notes: "Embuscade. Leurres allongés argentés. CÂBLE OBLIGATOIRE."
            ),
            comportement: "Embuscade, attaque éclair",
            momentsFavorables: [.matinee, .apresMidi]
        ),
        
        EspeceInfo(
            identifiant: "becune",
            nomCommun: "Bécune",
            nomScientifique: "Sphyraena spp.",
            famille: "Sphyraenidae",
            zones: [.lagon, .recif],
            profondeurMin: 0,
            profondeurMax: 10,
            typesPecheCompatibles: [.traine, .lancer],
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 6.0,
                vitesseOptimale: 5.0,
                profondeurNageOptimale: "surface-5m",
                tailleLeurreMin: 8.0,
                tailleLeurreMax: 14.0,
                typesLeurresRecommandes: ["bavette petite", "jupe 5-6\""],
                couleursRecommandees: ["argenté", "naturel"],
                positionsSpreadRecommandees: [.longCorner],
                notes: "Plus petite que le barracuda. Lagon uniquement."
            ),
            comportement: "Chasse à l'affût dans le lagon",
            momentsFavorables: [.matinee]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // LOCHES (traîne possible mais jig/montage préféré)
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "loche",
            nomCommun: "Loche",
            nomScientifique: "Epinephelus spp.",
            famille: "Serranidae",
            zones: [.recif, .tombant, .dcp],
            profondeurMin: 10,
            profondeurMax: 200,
            typesPecheCompatibles: [.jig, .montage, .traine],
            traineInfo: TraineInfo(
                vitesseMin: 3.0,
                vitesseMax: 5.0,
                vitesseOptimale: 4.0,
                profondeurNageOptimale: "fond-20m",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 16.0,
                typesLeurresRecommandes: ["bavette plongeante", "jig lourd"],
                couleursRecommandees: ["naturel", "brun", "orange"],
                positionsSpreadRecommandees: [.longCorner],
                notes: "Traîne lente près du fond. Jig/montage plus efficace."
            ),
            comportement: "Embuscade près du fond et des structures",
            momentsFavorables: [.matinee, .apresMidi]
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // COUREUR ARC-EN-CIEL
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            identifiant: "coureurArcEnCiel",
            nomCommun: "Coureur arc-en-ciel",
            nomScientifique: "Elagatis bipinnulata",
            famille: "Carangidae",
            zones: [.large, .passe, .dcp],
            profondeurMin: 0,
            profondeurMax: 50,
            typesPecheCompatibles: [.traine],
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "surface-30m",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["jupe", "bavette"],
                couleursRecommandees: ["bleu/blanc", "vert/doré", "naturel"],
                positionsSpreadRecommandees: [.shortRigger, .longRigger],
                notes: "Souvent aux DCP avec les thons."
            ),
            comportement: "Nage en banc autour des structures flottantes",
            momentsFavorables: [.matinee, .apresMidi]
        )
    ]
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MÉTHODES DE RECHERCHE
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Retourne les espèces pêchables à la traîne dans une zone donnée
    func especesTrainePourZone(_ zone: Zone) -> [EspeceInfo] {
        especesTraine.filter { espece in
            espece.zones.contains(zone) && espece.estPechableEnTraine
        }
    }
    
    /// Retourne les espèces compatibles avec une vitesse de traîne donnée
    func especesPourVitesse(_ vitesse: Double) -> [EspeceInfo] {
        especesTraine.filter { espece in
            guard let traineInfo = espece.traineInfo else { return false }
            return vitesse >= traineInfo.vitesseMin && vitesse <= traineInfo.vitesseMax
        }
    }
    
    /// Retourne les espèces pour une zone ET une vitesse données
    func especesPourZoneEtVitesse(zone: Zone, vitesse: Double) -> [EspeceInfo] {
        especesTraine.filter { espece in
            guard espece.zones.contains(zone),
                  espece.estPechableEnTraine,
                  let traineInfo = espece.traineInfo else { return false }
            return vitesse >= traineInfo.vitesseMin && vitesse <= traineInfo.vitesseMax
        }
    }
    
    /// Retourne une espèce par son identifiant
    func espece(identifiant: String) -> EspeceInfo? {
        especesTraine.first { $0.identifiant == identifiant }
    }
    
    /// Retourne toutes les espèces d'une zone (tous types de pêche)
    func toutesEspecesPourZone(_ zone: Zone) -> [EspeceInfo] {
        especesTraine.filter { $0.zones.contains(zone) }
    }
    
    // ═══════════════════════════════════════════════════════════════════════════
    // MAPPING Zone → Espèces (format String pour compatibilité)
    // ═══════════════════════════════════════════════════════════════════════════
    
    /// Mapping classique Zone → [String] pour compatibilité avec le code existant
    var especesParZone: [Zone: [String]] {
        [
            .lagon: [
                "Carangue ignobilis (GT)",
                "Carangue bleue",
                "Bécune",
                "Barracuda",
                "Thazard rayé",
                "Vivaneau queue noire",
                "Loche croissant",
                "Bec-de-cane"
            ],
            .recif: [
                "Carangue GT",
                "Loche pintade",
                "Loche aréolée",
                "Bec de canne",
                "Vivaneau chien rouge",
                "Empereur",
                "Mérou",
                "Barracuda"
            ],
            .passe: [
                "Thazard commun",
                "Thon jaune",
                "Wahoo",
                "Carangue GT",
                "Bonite",
                "Barracuda",
                "Mahi-mahi",
                "Voilier"
            ],
            .tombant: [
                "Loche pintade (100-280m)",
                "Bec de canne",
                "Vivaneau rubis (200-300m)",
                "Vivaneau la flamme (200-300m)",
                "Vivaneau blanc (150-250m)",
                "Mérou",
                "Thon jaune",
                "Wahoo"
            ],
            .large: [
                "Thon jaune",
                "Thon obèse",
                "Marlin",
                "Espadon voilier",
                "Wahoo",
                "Mahi-mahi (Coryphène)",
                "Thazard bâtard",
                "Bonite"
            ],
            .dcp: [
                "Thon jaune",
                "Bonite",
                "Mahi-mahi",
                "Wahoo",
                "Loche",
                "Thazard",
                "Voilier",
                "Marlin"
            ]
        ]
    }
    
    /// Espèces pêchables à la traîne uniquement, par zone
    var especesTraineParZone: [Zone: [String]] {
        var result: [Zone: [String]] = [:]
        for zone in Zone.allCases {
            let especes = especesTrainePourZone(zone).map { $0.nomCommun }
            if !especes.isEmpty {
                result[zone] = especes
            }
        }
        return result
    }
}
