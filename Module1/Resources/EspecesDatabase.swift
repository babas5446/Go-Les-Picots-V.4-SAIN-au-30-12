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
    
    // ═══ 🆕 NOUVELLES PROPRIÉTÉS (SPRINT 2) ═══
        
        // Identification visuelle
        let photoNom: String?
        let illustrationNom: String?
        let signesDistinctifs: String?
        
        // Biologie
        let tailleMinLegale: Double?
        let tailleMaxObservee: Double?
        let poidsMaxObserve: Double?
        let descriptionPhysique: String?
        
        // Habitat détaillé
        let habitatDescription: String?
        let comportementDetail: String?
        
        // Pêche pratique
        let techniquesDetail: String?
        let leuresSpecifiques: [String]?
        let appatsNaturels: [String]?
        let meilleursHoraires: String?
        let conditionsOptimales: String?
        
        // Valorisation
        let qualiteCulinaire: String?
        let risqueCiguatera: RisqueCiguatera
        let ciguateraDetail: String?
        
        // Réglementation
        let reglementationNC: String?
        let quotas: String?
        let zonesInterdites: String?
        let statutConservation: String?
        
        // Pédagogie
        let leSaviezVous: String?
        let nePasPecher: Bool
        let raisonProtection: String?
    
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
        
        // ═══════════════════════════════════════════════════════════════════════════
        // THON JAUNE (ALBACORE) - VERSION ENRICHIE (Sprint 2 - Module 4)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "thonJaune",
            nomCommun: "Thon jaune (Albacore)",
            nomScientifique: "Thunnus albacares",
            famille: "Scombridae",
            
            // Où la trouver
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 100,
            
            // Comment la pêcher
            typesPecheCompatibles: [.traine],
            
            // Spécifique TRAINE
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "0-50m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["jupe", "bavette plongeante", "flying fish"],
                couleursRecommandees: ["bleu/blanc", "vert/doré", "rose", "chartreuse", "naturel (sardine)"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shortRigger],
                notes: "Chasse en banc à la surface. DCP très efficaces. Meilleur en début de matinée ou fin d'après-midi."
            ),
            
            // Comportement
            comportement: "Chasse en banc à la surface, attaque rapide",
            momentsFavorables: [.aube, .matinee, .crepuscule],
            
            // ═══ 🆕 ENRICHISSEMENT SPRINT 2 ═══
            
            // Identification visuelle
            photoNom: "ThonJaune_photo",
            illustrationNom: "ThonJaune_illustration",
            signesDistinctifs: "Adulte fusiforme au corps robuste et hydrodynamique. Haut du corps noir métallique à bleu foncé, ventre jaune à argenté. CARACTÉRISTIQUE DISTINCTIVE : Seconde nageoire dorsale et anale jaunes, allongées de manière très prononcée (finlets jaunes). Juvénile : barres verticales courbes, rapprochées et régulièrement espacées, séparées par des rangées de petites taches sur le bas du corps.",
            
            // Biologie
            tailleMinLegale: nil,  // Pas de réglementation taille minimale spécifique en NC pour le thon jaune
            tailleMaxObservee: 210.0,  // cm (LF)
            poidsMaxObserve: 200.0,  // kg
            descriptionPhysique: "Grand poisson pélagique au corps fusiforme très hydrodynamique, parfaitement adapté à la nage rapide. Museau pointu. Nageoires pectorales relativement longues n'atteignant généralement pas la seconde dorsale. Présence caractéristique de pinnules dorsales et anales jaune vif bordées de noir. Caudale en forme de croissant de lune prononcé. Coloration dorsale bleu-noir métallique, flancs argentés avec reflets dorés, ventre jaune à blanc argenté.",
            
            // Habitat détaillé
            habitatDescription: "Espèce pélagique hauturière par excellence, fréquentant les eaux du large en pleine mer. Très présent autour des DCP (dispositifs de concentration de poissons) où il forme des bancs importants. Se rencontre également près des passes et des zones de tombants. Préfère les eaux chaudes tropicales (température optimale 24-28°C). Évolue principalement en surface et sub-surface (0-100m), mais peut descendre plus profond. Espèce grégaire formant des bancs selon la taille.",
            comportementDetail: "Prédateur pélagique actif chassant en bancs organisés. Se nourrit principalement de petits poissons (sardines, anchois, maquereaux, poissons volants), de calmars et de crustacés. Comportement de chasse coopératif : les bancs encercle les proies et les poussent vers la surface. Très actif à l'aube et au crépuscule, périodes de chasse intense. Les oiseaux marins plongeant signalent souvent la présence de chasses de thons en surface. Attaque rapide et puissante. Migrateur, suit les courants chauds et les concentrations de proies.",
            
            // Pêche pratique
            techniquesDetail: "Traîne classique (6-8 nœuds) : Technique de référence pour le thon jaune, particulièrement efficace autour des DCP. Utiliser des leurres à tête ogive ou siffleuse pour la stabilité hydrodynamique à vitesse élevée. Privilégier les couleurs naturelles (bleu/argent, sardine) par grand soleil et eau claire, couleurs flashy (rose, chartreuse) par eau trouble. Pêche Ika-shibi (nuit) : Méthode nocturne très productive utilisant des lampes sous-marines pour attirer les calmars, qui attirent ensuite les thons. Meilleur moment autour de minuit. Pêche au lancer (casting) : Sur chasses repérées visuellement (oiseaux). Lignes dérivantes : Pour pêcher plusieurs lignes simultanément.",
            leuresSpecifiques: [
                "Jukes 8-10 pouces (têtes ogive/siffleuse/pusher)",
                "Bavettes plongeantes 15-20 cm (profondeur 3-12m)",
                "Flying fish (poisson volant artificiel)",
                "Leurres à tête bullet (stabilité haute vitesse)",
                "Poppers et stickbaits (pour le lancer sur chasses)"
            ],
            appatsNaturels: [
                "Bonite entière ou en morceaux",
                "Maquereau entier",
                "Sardines",
                "Aiguillette (poisson volant)",
                "Calmars",
                "Chinchards (sélar)"
            ],
            meilleursHoraires: "AUBE (5h-8h) et CRÉPUSCULE (17h-19h) : Périodes de chasse maximale. Début de matinée et fin d'après-midi également très favorables. L'activité diminue en milieu de journée, sauf autour des DCP où le thon peut mordre toute la journée. Pêche nocturne Ika-shibi : autour de minuit (lever/coucher de lune).",
            conditionsOptimales: "Présence de DCP ou objets flottants. Chasses d'oiseaux marins (frégates, fous, sternes) signalant l'activité en surface. Mer calme à légèrement formée. Eau claire à température 24-28°C. Courants actifs (marée montante/descendante). Vitesse de traîne 6-8 nœuds constante. Couleurs adaptées à la luminosité : naturel par soleil, flashy à l'aube/crépuscule. Leurres placés en Short Corner, Long Corner et Short Rigger pour coverage optimal.",
            
            // Valorisation
            qualiteCulinaire: "Chair EXCELLENTE, très prisée mondialement. Qualité variable selon la fraîcheur et la manipulation. Chair rouge foncé caractéristique, dense et ferme. Goût prononcé mais délicat. Se prête parfaitement au : Sashimi et sushi (qualité premium), Tataki (mi-cuit), Grillades et poêlées, Tartare, Conserves (thon en boîte). La chair s'oxyde rapidement : saignée immédiate et mise sur glace INDISPENSABLES pour préserver la couleur rouge vif. Très recherché sur les marchés locaux et à l'exportation (Japon, États-Unis, Australie). Prix élevé pour les spécimens de qualité sashimi.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière : AUCUN risque de ciguatera. Le thon jaune ne fréquente pas les récifs coralliens et ne consomme pas les algues toxiques responsables de l'intoxication. Totalement sûr à la consommation, quelle que soit la taille. C'est l'une des raisons de sa forte valorisation commerciale.",
            
            // Réglementation
            reglementationNC: "Pas de taille minimale légale spécifique en Nouvelle-Calédonie pour le thon jaune (espèce hauturière). Pêche libre pour les pêcheurs plaisanciers. Respecter les règles générales de navigation et de sécurité en mer. Certains pays du Pacifique ont des quotas ou restrictions (se renseigner selon la zone).",
            quotas: "Aucun quota pour la pêche récréative en NC. Les pêcheurs commerciaux peuvent être soumis à des limitations selon les accords internationaux de gestion des thonidés (WCPFC - Commission des Pêches du Pacifique Occidental et Central).",
            zonesInterdites: "Aucune zone spécifiquement interdite pour le thon jaune en NC. Respecter les zones marines protégées générales.",
            statutConservation: "Espèce exploitée commercialement à l'échelle mondiale. Statut UICN : Quasi menacé (Near Threatened) au niveau global en raison de la pression de pêche industrielle. Populations du Pacifique Ouest relativement stables mais surveillées. Gestion par quotas internationaux pour assurer la durabilité.",
            
            // Pédagogie
            leSaviezVous: "Le thon jaune peut nager à plus de 75 km/h en pointe grâce à sa morphologie hydrodynamique parfaite ! Sa température corporelle est légèrement supérieure à l'eau environnante (endothermie partielle), ce qui lui permet de maintenir une activité musculaire intense. Les DCP (dispositifs de concentration) sont extrêmement efficaces car les thons, comme beaucoup de pélagiques, ont un comportement instinctif d'association aux objets flottants. Un thon jaune de 100 kg peut avoir une vingtaine d'années. Record IGFA : 193,68 kg capturé au Mexique. En Nouvelle-Calédonie, les prises varient de 10 à 80 kg, avec une moyenne de 20-30 kg. Les thons juvéniles (< 30 cm) sont identifiables par leurs barres verticales rapprochées, distinctes du thon obèse qui a des barres plus larges et espacées.",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // THON OBÈSE - VERSION ENRICHIE (Sprint 2 - Module 4 - VAGUE 2)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "thon_obese",
            nomCommun: "Thon obèse (Bigeye)",
            nomScientifique: "Thunnus obesus",
            famille: "Scombridae",
            
            zones: [.large, .dcp, .tombant],
            profondeurMin: 50,
            profondeurMax: 300,
            
            typesPecheCompatibles: [.traine, .palangrotte],
            
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 9.0,
                vitesseOptimale: 7.5,
                profondeurNageOptimale: "50-200m (eaux profondes)",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["juke", "bavette profonde", "teaser"],
                couleursRecommandees: ["bleu/blanc", "violet foncé", "naturel", "argenté"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "Thon des PROFONDEURS. Très prisé sashimi. Actif NUIT et aube. DCP essentiels. Vitesse 6-9 nœuds. Leurres profonds."
            ),
            
            comportement: "Prédateur de profondeur, très actif la nuit et à l'aube",
            momentsFavorables: [.aube, .nuit],
            
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "PINNULES DORSALES ET ANALES JAUNE VIF BORDÉES DE NOIR = signature visuelle ! Corps fusiforme typique thonidés. Haut du corps noir métallique à bleu très foncé, ventre jaune à blanc argenté. YEUX TRÈS GRANDS (d'où le nom 'bigeye' = gros yeux) - plus gros proportionnellement que thon jaune. Nageoires pectorales TRÈS LONGUES atteignant seconde dorsale (différence majeure avec thon jaune : pectorales courtes). Juvénile : barres verticales LARGES et IRRÉGULIÈREMENT ESPACÉES sur bas du corps (différent thon jaune : barres rapprochées régulières). Première dorsale jaune, seconde dorsale et anale jaune vif avec liseré noir caractéristique. Caudale en croissant de lune. Ligne latérale ondulée. Peau lisse avec corselet d'écailles.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 220.0,
            poidsMaxObserve: 210.0,
            descriptionPhysique: "Grand thonidé robuste et puissant, corps plus trapu que thon jaune. Morphologie typique thonidés : corps fusiforme hydrodynamique, pédoncule caudal fin avec double carène latérale permettant nage rapide. YEUX DISPROPORTIONNÉS : les plus gros de tous les thons par rapport à la taille du corps - adaptation vision nocturne et eaux profondes. Nageoires pectorales EXCEPTIONNELLEMENT LONGUES : atteignent ou dépassent début seconde dorsale = critère identification majeur. Première dorsale haute et rétractable, seconde dorsale et anale jaune vif bordé noir. 7-10 pinnules dorsales et anales jaune vif. Caudale puissante en croissant lunaire. Corselet écailles bien développé. Muscles rouges massifs riches en myoglobine (endurance). Tête conique. Bouche terminale avec dents fines. Coloration : dos bleu-noir profond métallique, flancs argentés irisés, ventre jaune pâle à blanc.",
            
            habitatDescription: "Grand pélagique MÉSO-PÉLAGIQUE (eaux moyennes et profondes). Espèce des PROFONDEURS : fréquente couche 50-300m beaucoup plus que autres thons. Remonte en surface principalement NUIT et AUBE (thermocline). Présence très marquée autour DCP où concentrations importantes. Également tombants abrupts, monts sous-marins, zones upwellings. Préfère eaux tropicales et subtropicales (13-29°C) mais tolère eaux plus froides que thon jaune. Espèce grégaire : bancs mono-spécifiques ou mixtes (avec thon jaune). Migrations grande échelle suivant courants et proies. Plus abondant eaux océaniques profondes que zones côtières.",
            comportementDetail: "Prédateur pélagique NOCTURNE et CRÉPUSCULAIRE marqué. Comportement vertical prononcé : plonge profond (200-300m) pendant JOUR, remonte surface (0-100m) pendant NUIT pour chasser. Cette migration verticale nycthémérale suit les proies (calmars, poissons lanternes). Régime : calmars (proie principale), poissons pélagiques profonds (poissons lanternes), crustacés, petits thons, sardines. Chasseur actif formant bancs cohésifs. Gros yeux = adaptation chasse nocturne et eaux sombres profondes. Pic activité : AUBE (5h-8h) remontée spectaculaire en surface, NUIT (18h-6h) chasse active zone 0-100m, JOUR moins actif (en profondeur). Concentrations massives autour DCP. Nage rapide : 70-80 km/h pointe. Combat puissant : plongées profondes caractéristiques, endurance exceptionnelle. Moins acrobatique que thon jaune (rarement saute).",
            
            techniquesDetail: "Traîne moyenne-profonde (6-9 nœuds) : vitesse inférieure thon jaune. Leurres 15-25 cm, couleurs SOMBRES (bleu foncé, violet, noir) pour eaux profondes, naturelles (argenté, bleu/blanc) pour surface. Bavettes PLONGEANTES essentielles (zone 5-15m). HORAIRE CRITIQUE : AUBE (5h-8h) = période OPTIMALE quand thons remontent surface. NUIT également très productive (technique ika-shibi avec lampes possibles). JOUR : pêche profonde palangre verticale ou downrigger (50-200m). Stratégie DCP : passes autour, thons obèses concentrés en profondeur sous DCP. Teaming fréquent avec thon jaune. Spread : Short/Long Corner (leurres profonds). Ligne 30-50 kg. Bas de ligne fluoro 80-100 lb (dents moins agressives que wahoo). Combat : plongées PUISSANTES et LONGUES caractéristiques, pomper patiemment. Palangre verticale très efficace NUIT (multi-profondeurs simultanées). Appâts naturels excellents : calmars entiers, bonites.",
            leuresSpecifiques: [
                "Bavettes plongeantes profondes 15-20 cm (ESSENTIELLES)",
                "Jukes 6-8 pouces couleurs sombres",
                "Poissons nageurs coulants",
                "Teasers (moins efficaces que pour marlin)",
                "Leurres bleu foncé/violet (eaux profondes)",
                "Leurres naturels bleu/blanc argenté (surface aube)"
            ],
            appatsNaturels: [
                "Calmars entiers (APPÂT ROI)",
                "Bonite entière ou morceaux",
                "Maquereaux entiers",
                "Poissons lanternes (si disponibles)",
                "Sardines grosses"
            ],
            meilleursHoraires: "AUBE (5h-8h) : PÉRIODE OPTIMALE ABSOLUE ! Thons obèses remontent massivement en surface après chasse nocturne profonde. NUIT (20h-6h) : très productif, thons actifs en surface et sub-surface (0-100m). JOUR (9h-17h) : MOINS productif, thons en profondeur (palangre verticale requise). Crépuscule (17h-19h) : début remontée.",
            conditionsOptimales: "Présence DCP (essentiel). Tombants abrupts ou monts. Fronts thermiques. Upwellings. AUBE ou NUIT = horaires critiques. Mer calme à modérée. Eau température 20-29°C. Vitesse 6-9 nœuds (inférieure thon jaune). Leurres 15-25 cm PLONGEANTS. Couleurs sombres (bleu/violet/noir) en profondeur, naturelles (argenté) en surface. Bavettes profondes 5-15m. Positions Short/Long Corner. Ligne 30-50 kg. Technique : passes autour DCP, prospecter couches profondes. Palangre verticale NUIT très efficace.",
            
            qualiteCulinaire: "Chair de qualité EXCEPTIONNELLE - LA MEILLEURE pour sashimi ! Texture ultra-ferme, grain fin, saveur riche et délicate. Chair ROUGE PROFOND presque bordeaux (teneur myoglobine très élevée). TRÈS PRISÉ marché japonais et restaurants haute gamme. Prix ÉLEVÉ : valeur commerciale supérieure thon jaune. Gras intramusculaire optimal pour sashimi (o-toro, chu-toro). Usages : Sashimi/Sushi (usage roi), Tataki mi-cuit, Tartare, Carpaccio, Grillades haute température courte (qualité chair préservée). Conserves premium. Saignée immédiate et mise sur glace CRITIQUE. Traitement ike-jime recommandé (qualité maximale). Ventre (toro) particulièrement recherché et cher.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière : AUCUN risque ciguatera. Prédateur sommital eaux profondes océaniques. Ne fréquente JAMAIS récifs coralliens. Alimentation exclusivement pélagique profonde (calmars, poissons lanternes). Totalement sûr quelle que soit taille. Garantie sanitaire absolue.",
            
            reglementationNC: "Espèce commerciale hautement valorisée. Pas de taille minimale légale spécifique NC pour pêche récréative. Quotas possibles pêche commerciale. Respecter règles générales navigation et sécurité. Déclaration captures volumineuses recommandée. Espèce non menacée localement mais surveillance stocks nécessaire. Gestion internationale WCPFC.",
            quotas: "Pas de quota spécifique pêche récréative NC actuellement. Quotas commerciaux stricts (gestion WCPFC). Auto-limitation éthique encouragée compte tenu valeur espèce et pression commerciale.",
            zonesInterdites: "Aucune zone spécifiquement interdite thon obèse. Respecter zones marines protégées générales et réserves intégrales.",
            statutConservation: "Statut UICN : Vulnérable (Vulnerable). Populations SOUS PRESSION par pêche commerciale industrielle intensive (palangriers, senneurs). Stocks Pacifique en DÉCLIN préoccupant. Surpêche avérée dans plusieurs zones. Croissance lente, maturité tardive (3-4 ans), longévité élevée (10-15 ans) = faible résilience. Espèce CRITIQUE pour industrie thonière (sashimi premium). Gestion internationale WCPFC avec quotas stricts. Surveillance étroite recommandée. Pêche récréative impact marginal mais consommation responsable encouragée.",
            
            leSaviezVous: "Le Thon obèse est LE ROI du sashimi ! Chair plus grasse et savoureuse que thon jaune, d'où prix 20-50% supérieur sur marchés. Record IGFA : 210 kg (Pérou 1957) ! En NC : prises 20-80 kg moyenne. Ses YEUX GÉANTS (jusqu'à 10 cm diamètre !) lui permettent chasser dans obscurité totale à 300m profondeur. Le thon obèse effectue MIGRATIONS VERTICALES spectaculaires : plonge 250-300m le jour, remonte 0-50m la nuit - amplitude 250m ! Son nom 'obèse' vient NON de son poids mais de ses yeux énormes ('bigeye' en anglais). Au Japon, le thon obèse premium (hon-maguro) se vend 50-100€/kg ! Le VENTRE gras (o-toro) peut atteindre 500€/kg marchés Tokyo ! Contrairement thon jaune, le thon obèse TOLÈRE eaux froides (13°C) grâce système contre-courant sanguin maintenant température musculaire. Technique IKA-SHIBI japonaise : pêche NOCTURNE avec lampes sous-marines attirant calmars puis thons = très efficace ! Le thon obèse peut vivre 15 ans et atteindre 2,20m. Ses plongées lors du combat peuvent durer 45 minutes ! C'est l'espèce de thon la plus valorisée commercialement avec thon rouge. Populations en déclin : consommation responsable essentielle.",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // BONITE (LISTAO / SKIPJACK TUNA) - VERSION ENRICHIE (Sprint 2 - Module 4)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "bonite",
            nomCommun: "Bonite (Listao)",
            nomScientifique: "Katsuwonus pelamis",
            famille: "Scombridae",
            
            // Où la trouver
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 80,
            
            // Comment la pêcher
            typesPecheCompatibles: [.traine],
            
            // Spécifique TRAINE
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 8.0,
                vitesseOptimale: 7.0,
                profondeurNageOptimale: "0-50m (surface et sub-surface)",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["juke", "bavette", "poisson nageur"],
                couleursRecommandees: ["bleu/blanc", "argenté", "rose", "chartreuse", "naturel (sardine)"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shortRigger],
                notes: "Chasse en BANCS compacts. Présence autour DCP. Utilisée comme APPÂT pour gros poissons. Début matinée et fin après-midi."
            ),
            
            // Comportement
            comportement: "Chasse en bancs denses, attaque rapide en surface",
            momentsFavorables: [.aube, .matinee, .crepuscule],
            
            // ═══ 🆕 ENRICHISSEMENT SPRINT 2 ═══
            
            // Identification visuelle
            photoNom: nil,  // À ajouter plus tard
            illustrationNom: nil,  // À ajouter plus tard
            signesDistinctifs: "Corps fusiforme robuste typique des thonidés. Haut du corps violet argenté foncé à bleu-noir métallique, ventre argenté clair. CARACTÉRISTIQUE DISTINCTIVE MAJEURE : 3 à 6 bandes longitudinales foncées (brun-noir) EXCLUSIVEMENT SUR LE VENTRE, parallèles entre elles. Ces bandes constituent le signe d'identification le plus fiable. Absence de bandes dorsales. Nageoires pectorales courtes. Caudale en croissant de lune prononcé. Corps sans écailles sauf sur la ligne latérale et le corselet. Peau lisse et hydrodynamique.",
            
            // Biologie
            tailleMinLegale: nil,  // Pas de taille minimale légale en NC
            tailleMaxObservee: 100.0,  // cm (LF)
            poidsMaxObserve: 34.0,  // kg
            descriptionPhysique: "Thonidé de taille moyenne au corps fusiforme compact et très musclé, parfaitement adapté à la nage rapide et aux migrations longues distances. Tête conique, bouche relativement petite comparée aux autres thons. Nageoires pectorales courtes n'atteignant pas le milieu de la première dorsale. Deux nageoires dorsales bien séparées. Présence de 7-9 pinnules dorsales et 7-8 pinnules anales caractéristiques des scombridés. Ligne latérale ondulante. Coloration : dos bleu-noir métallique, flancs argentés, ventre blanc argenté avec les fameuses bandes longitudinales sombres.",
            
            // Habitat détaillé
            habitatDescription: "Espèce pélagique épioceanique (surface et sub-surface) par excellence. Fréquente les eaux du large en pleine mer, généralement dans la couche des 0-80 premiers mètres. Présence marquée autour des DCP (dispositifs de concentration de poissons) où elle forme des bancs très denses. Se rencontre également près des passes et des tombants. Préfère les eaux chaudes tropicales (température optimale 25-30°C). Espèce hautement grégaire : forme des bancs mono-spécifiques très compacts pouvant compter plusieurs centaines d'individus. Migration à grande échelle suivant les courants chauds.",
            comportementDetail: "Prédateur pélagique extrêmement actif chassant en bancs organisés très cohésifs. Se nourrit principalement de petits poissons pélagiques (sardines, anchois, juvéniles), de calmars, de crustacés et de zooplancton. Comportement de chasse coopératif spectaculaire : les bancs encerclent les proies en surface, créant des 'boules d'appâts' (baitballs). Attaque rapide et frénétique. Très actif à l'AUBE et au CRÉPUSCULE. Les chasses en surface sont souvent signalées par les oiseaux marins (fous, sternes, frégates) qui plongent sur les petits poissons poussés vers la surface. Nageur très rapide pouvant atteindre 65-75 km/h en pointe.",
            
            // Pêche pratique
            techniquesDetail: "Traîne classique (6-8 nœuds) : Technique principale pour la bonite. Particulièrement efficace autour des DCP où les bancs sont concentrés. Repérer les chasses d'oiseaux en surface = signe infaillible de présence. Privilégier couleurs naturelles (bleu/argent, sardine) par eau claire, couleurs flashy (rose, chartreuse) par eau trouble. Traîne lente lagon (4-8 nœuds) : Pour les petites bonites côtières. Lancer (casting) sur chasses : Très efficace quand les bonites chassent en surface. Utiliser poppers ou stickbaits. Ligne dérivante : Technique complémentaire. IMPORTANT : La bonite est largement utilisée comme APPÂT NATUREL pour la pêche des gros pélagiques (thazards, marlins, wahoo) - c'est son usage principal dans la pêche hauturière.",
            leuresSpecifiques: [
                "Jukes/Octopus 3-5 pouces",
                "Bavettes plongeantes 10-15 cm",
                "Poissons nageurs 10-16 cm (imitation sardine/anchois)",
                "Poppers de surface (pour le lancer)",
                "Stickbaits (pour chasses en surface)",
                "Cuillers tournantes"
            ],
            appatsNaturels: [
                "Petits poissons entiers (sardines, anchois)",
                "Chinchards",
                "Calmars",
                "Aiguillettes"
            ],
            meilleursHoraires: "AUBE (5h-8h) et CRÉPUSCULE (17h-19h) : périodes de chasse maximale avec activité frénétique en surface. Début de matinée (8h-10h) et fin d'après-midi (16h-18h) également très productifs. L'activité diminue nettement en milieu de journée (10h-15h), sauf autour des DCP où les bonites peuvent être actives toute la journée.",
            conditionsOptimales: "Présence de DCP ou concentrations de petits poissons. Chasses d'OISEAUX MARINS = indicateur visuel essentiel (fous plongeant en surface). Mer calme à légèrement formée. Eau claire température 25-30°C. Courants actifs. Vitesse traîne 6-8 nœuds. Couleurs adaptées : naturel (bleu/argenté) par soleil, flashy (rose/chartreuse) à l'aube/crépuscule. Repérer les remous/éclaboussures en surface signalant les chasses. Leurres placés en Short Corner, Long Corner et Short Rigger.",
            
            // Valorisation
            qualiteCulinaire: "Chair de qualité BONNE à TRÈS BONNE. Texture ferme et dense. Saveur prononcée caractéristique des thonidés, plus forte que le thon jaune. Chair ROUGE FONCÉ à bordeaux. Se prête bien au : Tataki (mi-cuit excellent), Grillades et poêlées, Currys et ragoûts, Conserves (thon en boîte), Sashimi (fraîcheur absolue requise). USAGE MAJEUR : Très prisée comme APPÂT NATUREL pour la pêche des gros pélagiques - c'est l'appât de choix pour marlins, wahoo et gros thazards. Ventrèche de bonite particulièrement recherchée pour appâter. Saignée immédiate et mise sur glace indispensables. Prix modéré sur les marchés locaux (espèce abondante).",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière : AUCUN risque de ciguatera. La bonite ne fréquente jamais les récifs coralliens et ne consomme pas les algues toxiques responsables de l'intoxication. Totalement sûre à la consommation, quelle que soit la taille. C'est l'une des raisons de sa popularité comme espèce de table et comme appât.",
            
            // Réglementation
            reglementationNC: "Pas de taille minimale légale spécifique en Nouvelle-Calédonie pour la bonite (espèce hauturière abondante). Pêche libre pour les pêcheurs plaisanciers. Respecter les règles générales de navigation et de sécurité en mer. Espèce non menacée et abondante.",
            quotas: "Aucun quota pour la pêche récréative en NC. La bonite n'est pas soumise à des quotas commerciaux en NC en raison de l'abondance des stocks.",
            zonesInterdites: "Aucune zone spécifiquement interdite pour la bonite. Respecter les zones marines protégées générales.",
            statutConservation: "Espèce NON menacée. Statut UICN : Préoccupation mineure (Least Concern). Populations mondiales abondantes et stables. C'est l'espèce de thon la PLUS ABONDANTE au monde. Stocks du Pacifique en excellente santé. Croissance relativement rapide et maturité sexuelle précoce (1-2 ans) assurent une très bonne résilience à la pression de pêche. Espèce très répandue géographiquement (toutes eaux tropicales et tempérées chaudes).",
            
            // Pédagogie
            leSaviezVous: "La bonite (listao) est l'espèce de THON LA PLUS ABONDANTE au monde ! Elle représente environ 60% des captures mondiales de thonidés. C'est THE poisson des conserves 'thon' ! Son nom scientifique 'Katsuwonus pelamis' vient du japonais 'katsuo' (bonite). Les bandes longitudinales sur le VENTRE sont uniques parmi les thonidés - aucune autre espèce ne présente ce motif. La bonite peut nager à 65-75 km/h en pointe grâce à sa morphologie parfaite. Elle effectue des migrations transpacifiques de plusieurs milliers de kilomètres ! Les pêcheurs polynésiens traditionnels la considéraient comme un poisson sacré. Record IGFA : 34,4 kg capturé au Mexique. En Nouvelle-Calédonie, les prises varient de 2 à 10 kg, avec une moyenne de 4-6 kg. USAGE PRINCIPAL : La bonite est LE meilleur appât naturel pour la pêche aux gros pélagiques - marlins, wahoo, gros thazards se jettent dessus ! La ventrèche de bonite est l'appât roi de la pêche hauturière.",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // WAHOO - VERSION ENRICHIE (Sprint 2 - Module 4)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        // ═══════════════════════════════════════════
        // WAHOO
        // ═══════════════════════════════════════════
        
        EspeceInfo(
            identifiant: "wahoo",
            nomCommun: "Thazard-bâtard / Wahoo",
            nomScientifique: "Acanthocybium solandri",
            famille: "Scombridae",
            
            // Où la trouver
            zones: [.large, .tombant, .passe, .dcp],
            profondeurMin: 0,
            profondeurMax: 100,
            
            // Comment la pêcher
            typesPecheCompatibles: [.traine],
            
            // Spécifique TRAINE
            traineInfo: TraineInfo(
                vitesseMin: 10.0,
                vitesseMax: 16.0,
                vitesseOptimale: 13.0,
                profondeurNageOptimale: "5-20m",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["bullet haute vitesse", "bavette high speed", "juke rapide"],
                couleursRecommandees: ["rose", "violet", "chartreuse", "noir/rose", "bleu/blanc contrasté"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "VITESSE EXTRÊME essentielle ! 12-16 nœuds. Leurres lourds haute vitesse. DENTS RASOIR = câble métallique obligatoire ! Combatif explosif."
            ),
            
            // Comportement
            comportement: "Prédateur ultra-rapide solitaire, chasseur en embuscade, attaque éclair",
            momentsFavorables: [.aube, .midi, .apresMidi],
            
            // ═══ 🆕 ENRICHISSEMENT SPRINT 2 ═══
            
            // Identification visuelle
            photoNom: nil,  // À ajouter plus tard
            illustrationNom: nil,  // À ajouter plus tard
            signesDistinctifs: "Corps TRÈS ALLONGÉ et fusiforme = silhouette de torpille ! Dos bleu acier métallique foncé, flancs argentés brillants avec 25-30 BARRES VERTICALES ONDULÉES bleu foncé caractéristiques (zigzag). Ventre blanc argenté. Tête longue et effilée. BOUCHE IMMENSE avec MÂCHOIRES PUISSANTES garnies de DENTS TRIANGULAIRES ACÉRÉES COMME RASOIRS disposées sur UNE SEULE RANGÉE = signature dangereuse ! Ligne latérale ondulée descendant progressivement. Première dorsale longue et basse. Caudale en croissant de lune très large et puissante. Nageoires pectorales petites. Absence de corselet écailles (différent thons). Peau lisse argentée. Corps comprimé latéralement. Pédoncule caudal très fin avec carènes latérales prononcées.",
            
            // Biologie
            tailleMinLegale: nil,  // Pas de réglementation spécifique NC connue
            tailleMaxObservee: 250.0,  // cm (LF)
            poidsMaxObserve: 83.0,  // kg
            descriptionPhysique: "Grand scombridé pélagique à morphologie UNIQUE optimisée vitesse pure. Corps exceptionnellement allongé et effilé en torpille. Tête longue pointue. Bouche DÉMESURÉE s'ouvrant largement avec mâchoires armées de 30-40 dents triangulaires TRANCHANTES disposées en rangée unique = DANGER manipulation ! Ces dents coupent TOUT (lignes, doigts). Œil moyen. Première dorsale très longue basse rétractable. Seconde dorsale et anale petites suivies 8-9 pinnules. Pectorales courtes collées corps. Caudale lunaire IMMENSE très puissante (propulsion). Pédoncule caudal extrêmement FIN renforcé double carène latérale. Ligne latérale ondulée unique. Écailles petites cycloïdes. Muscles rouges puissants. Coloration spectaculaire : dos bleu acier électrique, barres verticales ondulées bleu foncé sur flancs argentés (25-30 barres), ventre blanc pur argenté. Nageoires grisâtres.",
            
            // Habitat détaillé
            habitatDescription: "Grand pélagique HAUTURIER des eaux océaniques profondes. Fréquente principalement LARGE et zones tombants abrupts, passes profondes, monts sous-marins, DCP. Préfère eaux claires bleues tropicales et subtropicales chaudes (24-30°C). Espèce SOLITAIRE ou couples lâches (rarement groupes). Effectue patrouilles régulières le long structures (tombants, DCP) chassant à l'affût. Présence marquée zones forts courants et upwellings (concentrations proies). Moins côtier que thons. Espèce hautement mobile : déplacements rapides grandes distances suivant proies et courants. Distribution circumtropicale mais densités variables.",
            comportementDetail: "PRÉDATEUR ULTRA-RAPIDE = LE PLUS VÉLOCE DES SCOMBRIDÉS ! Vitesse pointe RECORD : 77-80 km/h = FUSÉE sous-marine ! Technique chasse : EMBUSCADE depuis profondeur puis CHARGE FULGURANTE verticale vers banc proies en surface. Mord/COUPE proies d'un coup mâchoires (dents rasoirs). Régime : bonites, maquereaux, calmars, poissons volants, petits thons, mulets. Chasseur opportuniste solitaire. Pic activité : AUBE (5h-9h) et MATINÉE (9h-12h) excellents. APRÈS-MIDI (14h-17h) productif. Midi moins actif. Attaque leurres de manière EXPLOSIVE : touche violente souvent spectaculaire (saute hors eau). Combat RAPIDE et PUISSANT mais BREF : courses ultrarapides, quelques sauts, puis fatigue vite (muscles blancs sprint). Combat 10-30 minutes typique. Curieux : suit leurres avant d'attaquer. DANGER : dents coupent TOUT = câble métallique OBLIGATOIRE ! Espèce réputée pour vitesse et qualité chair.",
            
            // Pêche pratique
            techniquesDetail: "Traîne HAUTE VITESSE (12-16 nœuds) : TECHNIQUE EXCLUSIVE pour wahoo ! Seul poisson ciblé à vitesse si élevée. Leurres LOURDS haute vitesse obligatoires : bullets, bavettes 'high speed trolling', jukes rapides. Taille 15-25 cm. Couleurs CONTRASTÉES (rose/violet, chartreuse, noir/rose) excellentes. Leurres doivent rester STABLES haute vitesse (sinon décrochent). Profondeur 0-20m (leurres plongeants 6-12m). BAS DE LIGNE CÂBLE MÉTALLIQUE OBLIGATOIRE (dents rasoirs coupent monofilament instantanément) : câble 30-50 lb, 1-1,5m longueur. Stratégie : passes longues le long tombants, autour DCP, zones courants. Spread : Short/Long Corner. Ligne 30-50 kg. Combat : garder tension constante, ne pas donner mou (décroche facilement). Gaffe prudente (dents !). ATTENTION manipulation : DENTS EXTRÊMEMENT DANGEREUSES = gants obligatoires, gaffe ou pince marine. Ne JAMAIS mettre doigts près bouche même poisson mort ! Traîne rapide fatigue équipage mais seule technique vraiment efficace.",
            leuresSpecifiques: [
                "Bullets lourds haute vitesse 18-25 cm (ESSENTIELS)",
                "Bavettes 'High Speed Trolling' plongeantes 15-20 cm",
                "Jukes rapides 6-8 pouces",
                "Leurres rose fuchsia (EXCELLENT)",
                "Leurres violet foncé/chartreuse",
                "Leurres noir/rose contrasté",
                "Têtes lourdes Plunger/Bullet stables haute vitesse"
            ],
            appatsNaturels: [
                "Bonite entière ou en filet",
                "Maquereau entier",
                "Poisson volant entier",
                "Aiguillette",
                "Mulet entier",
                "Calmar entier"
            ],
            meilleursHoraires: "Milieu de journée (10h-14h) et après-midi (14h-17h). Contrairement aux thons qui préfèrent l'aube et le crépuscule, le wahoo est particulièrement actif en pleine journée sous fort ensoleillement. Aube et crépuscule moins productifs qu epour les autres  pélagiques. Le ahoo préfère le lumière vive",
            conditionsOptimales: "Présence tombants abrupts ou DCP. Zones forts courants. Passes profondes. Mer calme à modérée. Eau BLEUE claire température > 24°C. VITESSE CRITIQUE : Vitesse de bateau élevée et constante (12-16 nœuds) OBLIGATOIRE (wahoo ignore leurres lents). Leurres LOURDS haute vitesse 15-25 cm. Couleurs CONTRASTÉES flashy (rose, violet, chartreuse, noir/rose). Leurres STABLES (ne décrochent pas haute vitesse). Profondeur 6-12m (bavettes). Positions Short/Long Corner pour exploitation optimale du sillage. Ligne 30-50 kg. BAS DE LIGNE CÂBLE MÉTALLIQUE 1-1,5m OBLIGATOIRE !",
            
            // Valorisation
            qualiteCulinaire: "Chair de qualité EXCEPTIONNELLE = une des MEILLEURES tous poissons ! Texture ULTRA-FERME et DENSE (la plus ferme des scombridés). Saveur DÉLICATE légèrement sucrée. Chair BLANCHE à rosée immaculée (pas rouge comme thons) = très prisée ! Grain très fin. Usages : Sashimi/Sushi (EXCELLENT - chair ferme parfaite), Tataki, Carpaccio, Grillades haute température, Fumage (exceptionnel), Ceviche. Prix ÉLEVÉ marchés (30-50€/kg poisson entier, 60-80€/kg filets). Très recherché restauration haut gamme et pour l'exportation.  CRITIQUE : Conservation délicate (se détériore rapidement) : saignée et mise sur glace immédiate. Chair se conserve très bien. Filetage facile (peu arêtes). Rendement excellent (70-75% chair). Valeur commerciale ET sportive exceptionnelle.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière : risque ciguatera TRÈS FAIBLE à quasi NUL. Wahoo fréquente très rarement récifs coralliens (habitat hauturier). Prédateur sommital se nourrissant quasi exclusivement autres pélagiques (bonites, maquereaux, calmars). Cas ciguatera wahoo extrêmement RARES mondialement. Néanmoins principe précaution : éviter très gros spécimens (> 40 kg) zones récifales si doute. Généralement considéré totalement SÛR toute taille. Une des espèces les plus fiables.",
            
            // Réglementation
            reglementationNC: "Espèce hauturière commerciale valorisée. Pas de taille minimale légale spécifique NC pêche récréative. Quotas possibles pêche commerciale. Respecter règles générales navigation et sécurité. Espèce non menacée localement. Captures volumineuses commerciales soumises déclaration. Pêche libre plaisanciers quantités raisonnables.",
            quotas: "Pas de quota spécifique pêche récréative NC actuellement. Gestion internationale via WCPFC (quotas commerciaux). Auto-limitation raisonnable encouragée compte tenu valeur commerciale élevée espèce.",
            zonesInterdites: "Aucune zone spécifiquement interdite wahoo. Respecter zones marines protégées générales et réserves intégrales.",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations mondiales globalement STABLES. Espèce largement distribuée circumtropicale. Croissance rapide, maturité précoce (1-2 ans), reproduction prolifique = bonne résilience. Pêche commerciale impact modéré (espèce secondaire prises palangrières thonières). Stocks Pacifique en bon état. Surveillance continue recommandée compte tenu valeur commerciale croissante. Gestion durable via WCPFC.",
            
            // Pédagogie
            leSaviezVous: "Le Wahoo est LE POISSON LE PLUS RAPIDE DE LA FAMILLE DES THONS ! Vitesse pointe 77-80 km/h = RECORD absolu scombridés ! Record IGFA : 83,46 kg (Bahamas 2005) - MONSTRE ! Record Pacifique : 71 kg. En NC : prises 8-25 kg moyenne, 30-40 kg excellents spécimens. Son nom 'Wahoo' vient du cri poussé par pêcheurs lors touche explosive ! Nom français 'Thazard-bâtard' car ressemble thazards mais BEAUCOUP plus gros. Ses DENTS sont LÉGENDAIRES : tranchantes comme rasoirs, coupent monofilament 80 lb INSTANTANÉMENT ! Nombreux accidents doigts coupés par manipulation imprudente. Sa chair BLANCHE est unique parmi scombridés (thons = chair rouge). Prix marchés Tokyo : 40-70€/kg filets = très valorisé ! Le wahoo peut parcourir 100+ km en UNE JOURNÉE lors patrouilles ! Attaque leurre à 70+ km/h = touche la plus VIOLENTE pêche traîne ! Combat typique : 3-4 courses ultrarapides de 50-100m, quelques sauts spectaculaires, puis fatigue en 15-20 minutes. Chair ferme résiste parfaitement congélation (rare poissons). Wahoo fumé = DÉLICE absolu recherché connaisseurs ! Certains pêcheurs pros considèrent wahoo meilleur poisson manger au monde.",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // MAHI-MAHI (Dorade coryphène) - VERSION ENRICHIE (Sprint 2 - Module 4)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "mahiMahi",
            nomCommun: "Mahi-mahi (Dorade coryphène)",
            nomScientifique: "Coryphaena hippurus",
            famille: "Coryphaenidae",
            
            // Où la trouver
            zones: [.large],
            profondeurMin: 0,
            profondeurMax: 50,
            
            // Comment la pêcher
            typesPecheCompatibles: [.traine],
            
            // Spécifique TRAINE
            traineInfo: TraineInfo(
                vitesseMin: 7.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "Surface (0-5m)",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["juke pusher", "flying fish", "popper de surface"],
                couleursRecommandees: ["rose", "chartreuse", "vert/doré lumineux", "bleu/blanc flashy"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shotgun],
                notes: "ATTIRÉ PAR DÉBRIS FLOTTANTS ET ALGUES. Couleurs VIVES ET FLASHY essentielles. Têtes pusher (agressives) très efficaces."
            ),
            
            // Comportement
            comportement: "Chasse en surface près débris flottants, attaque agressive",
            momentsFavorables: [.matinee, .apresMidi],
            
            // ═══ 🆕 ENRICHISSEMENT SPRINT 2 ═══
            
            // Identification visuelle
            photoNom: "Mahi_Mahi_photo",
            illustrationNom: "Mahi_Mahi_illustration",
            signesDistinctifs: "Corps comprimé latéralement, profil unique. Livrée argent bleuté à reflets jaunes et verts IRIDESCENTS, s'estompant rapidement après la mort. DIMORPHISME SEXUEL PRONONCÉ : Mâle adulte : front très haut et abrupt (quasi vertical), formant une protubérance caractéristique. Femelle : front plus arrondi et moins prononcé. Nageoire dorsale unique et très longue courant sur toute la longueur du dos. Caudale profondément fourchue. Coloration extrêmement vive et chatoyante vivant (or, bleu électrique, vert).",
            
            // Biologie
            tailleMinLegale: nil,  // Pas de taille minimale légale en NC
            tailleMaxObservee: 180.0,  // cm (LF)
            poidsMaxObserve: 40.0,  // kg
            descriptionPhysique: "Poisson pélagique de taille moyenne au corps allongé et fortement comprimé latéralement. Tête au profil très caractéristique avec front abrupt chez le mâle adulte. Nageoire dorsale unique et très longue s'étendant du front jusqu'au pédoncule caudal (50-65 rayons). Caudale profondément fourchue. Coloration spectaculaire : dos bleu-vert métallique iridescent, flancs dorés à argentés avec reflets turquoise et verts, nombreuses taches noires éparses. Les couleurs s'estompent très rapidement après la mort (devient gris argenté terne).",
            
            // Habitat détaillé
            habitatDescription: "Espèce pélagique de surface par excellence. Habite exclusivement les eaux du large en pleine mer, généralement dans la couche des 0-50 premiers mètres. PARTICULARITÉ MAJEURE : association systématique aux débris flottants, algues dérivantes, troncs d'arbres, noix de coco, et objets flottants de toute nature. Les bancs de mahi-mahi se regroupent sous ces abris flottants qui concentrent également les petits poissons fourrage. Préfère les eaux chaudes tropicales (température > 24°C). Espèce grégaire formant des groupes de quelques individus à plusieurs dizaines.",
            comportementDetail: "Prédateur pélagique de surface ultra-actif et agressif. Chasse en petits groupes ou bancs organisés. Se nourrit principalement de petits poissons pélagiques (poissons volants, sardines, maquereaux), de calmars et de crustacés. COMPORTEMENT DISTINCTIF : attaque violente et spectaculaire en surface avec sauts hors de l'eau. Très attiré par le mouvement, les éclaboussures et les couleurs vives. Les leurres à action agressive (têtes pusher/plunger créant turbulences et bulles) sont particulièrement efficaces. Espèce très curieuse et peu méfiante. Croissance rapide : atteint 15-20 kg en 1 an. Combat spectaculaire avec de nombreux sauts acrobatiques.",
            
            // Pêche pratique
            techniquesDetail: "Traîne moyenne à rapide (7-10 nœuds) : Technique principale et la plus productive. STRATÉGIE CLÉ : Repérer et pêcher autour des débris flottants (arbres morts, algues dérivantes, objets divers). Faire des PASSES AUTOUR des débris sans traverser le banc. Couleurs FLASHY OBLIGATOIRES : rose, chartreuse, vert fluo, bleu/blanc éclatant. Têtes pusher/plunger (tête tronquée) TRÈS EFFICACES car créent beaucoup de turbulences, éclaboussures et bulles en surface - exactement ce qui attire le mahi-mahi. Flying fish également excellent. Lignes dérivantes : Technique complémentaire permettant de pêcher plusieurs lignes simultanément loin du bateau. Casting sur chasses : Quand les mahi-mahi chassent en surface (repérables aux sauts), lancer des poppers ou stickbaits.",
            leuresSpecifiques: [
                "Jukes 8-12 pouces à tête PUSHER/PLUNGER (action agressive)",
                "Flying fish (poisson volant artificiel) - EXCELLENT",
                "Poppers de surface (cup face)",
                "Leurres à action bulle intense",
                "Têtes siffleuses (créent traînée de bulles)",
                "Stickbaits pour le lancer"
            ],
            appatsNaturels: [
                "Poisson volant entier (appât naturel par excellence)",
                "Maquereau entier",
                "Calmar entier",
                "Sardines",
                "Bonite en morceaux"
            ],
            meilleursHoraires: "Toute la journée quand présent autour de débris flottants. MATINÉE (6h-11h) et APRÈS-MIDI (14h-17h) généralement plus productifs. Actif même en plein soleil contrairement au thon. Rechercher les chasses d'oiseaux marins en surface qui signalent souvent la présence de mahi-mahi en train de chasser.",
            conditionsOptimales: "PRÉSENCE DE DÉBRIS FLOTTANTS OU ALGUES DÉRIVANTES = CONDITION ESSENTIELLE. Repérage visuel crucial : troncs d'arbres, palettes, bidons, algues sargasses, tout objet flottant. Mer calme à légèrement formée. Eau claire. Température chaude (> 24°C). COULEURS FLASHY OBLIGATOIRES : rose vif, chartreuse, vert lumineux. Têtes pusher (action agressive) par mer calme, têtes bullet (stables) par mer formée. Leurres placés en Short Corner, Long Corner et Shotgun. Vitesse 7-10 nœuds.",
            
            // Valorisation
            qualiteCulinaire: "Chair EXCELLENTE, très prisée. Texture ferme et dense. Saveur délicate, légèrement sucrée. Chair blanche à rosée pâle. Se prête parfaitement au : Filets grillés ou poêlés, Sashimi et ceviche (ultra-frais), Poisson cru à la tahitienne, Curry de poisson. La fraîcheur est CRUCIALE : saignée immédiate et mise sur glace INDISPENSABLES. La chair se détériore rapidement. Très recherché sur les marchés locaux et restaurants. Prix élevé pour les spécimens frais de qualité. Chair plus délicate que le thon, moins dense.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique de pleine eau : AUCUN risque de ciguatera. Le mahi-mahi ne fréquente jamais les récifs coralliens et ne consomme pas les algues toxiques. Totalement sûr à la consommation, quelle que soit la taille. Espèce 100% sûre pour la table.",
            
            // Réglementation
            reglementationNC: "Pas de réglementation spécifique en Nouvelle-Calédonie pour le mahi-mahi (espèce hauturière). Pêche libre pour les pêcheurs plaisanciers. Respecter les règles générales de navigation et de sécurité en mer. Espèce non menacée.",
            quotas: "Aucun quota pour la pêche récréative en NC. Pas de restrictions particulières.",
            zonesInterdites: "Aucune zone spécifiquement interdite. Respecter les zones marines protégées générales.",
            statutConservation: "Espèce NON menacée à l'échelle mondiale. Statut UICN : Préoccupation mineure (Least Concern). Populations stables et en bonne santé dans le Pacifique. Croissance très rapide et maturité sexuelle précoce (4-5 mois) assurent une bonne résilience. Espèce abondante et bien distribuée géographiquement.",
            
            // Pédagogie
            leSaviezVous: "Le mahi-mahi est l'un des poissons à la croissance LA PLUS RAPIDE de l'océan ! Il peut atteindre 20 kg en seulement 1 an et vit rarement plus de 4-5 ans. Son nom 'mahi-mahi' vient du hawaïen et signifie 'fort-fort', en référence à son combat spectaculaire. En anglais, on l'appelle aussi 'dolphin fish' (poisson-dauphin) à cause de son front bombé, mais il n'a AUCUN lien avec les dauphins mammifères ! Les couleurs iridescentes spectaculaires (or, bleu électrique, vert) disparaissent en quelques minutes après la mort du poisson. Le dimorphisme sexuel est très prononcé : le mâle adulte développe un front quasi vertical très caractéristique. Record IGFA : 39,91 kg capturé au Costa Rica. En Nouvelle-Calédonie, les prises varient de 5 à 25 kg, avec une moyenne de 8-12 kg. Poisson extrêmement acrobatique : peut effectuer des sauts de plusieurs mètres hors de l'eau lors du combat !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
    
        /// ════════════════════════════════════════════════════════
        // MARLIN & VOILIER - VERSION ENRICHIE (Sprint 2 - Module 4 - VAGUE 2)
        // À remplacer dans EspecesDatabase.swift
        // ═══════════════════════════════════════════════════════════════════════════

        // ═══════════════════════════════════════════
        // MARLIN BLEU / MARLIN NOIR
        // ═══════════════════════════════════════════

        EspeceInfo(
            identifiant: "marlin",
            nomCommun: "Marlin (Bleu/Noir)",
            nomScientifique: "Makaira nigricans / Makaira mazara",
            famille: "Istiophoridae",
            
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 200,
            
            typesPecheCompatibles: [.traine],
            
            traineInfo: TraineInfo(
                vitesseMin: 8.0,
                vitesseMax: 12.0,
                vitesseOptimale: 10.0,
                profondeurNageOptimale: "0-50m (surface et sub-surface)",
                tailleLeurreMin: 18.0,
                tailleLeurreMax: 30.0,
                typesLeurresRecommandes: ["juke big game", "flying fish", "bavette haute vitesse", "teaser"],
                couleursRecommandees: ["noir/violet", "bleu/blanc", "rose", "orange", "contraste fort"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shotgun],
                notes: "Roi des pélagiques. Flying Fish ESSENTIEL. Teasers pour provoquer. Vitesse 8-12 nœuds. Passes autour DCP. Combat épique."
            ),
            
            comportement: "Grand prédateur pélagique solitaire, chasse en surface",
            momentsFavorables: [.matinee, .apresMidi],
            
            photoNom: "MarlinBleu_photo",
            illustrationNom: "MarlinBleu_illustration",
            signesDistinctifs: "ROSTRE ALLONGÉ en épée = signe distinctif absolu des Istiophoridés. Corps massif et puissant bleu-noir métallique sur le dos, flancs argentés brillants, ventre blanc. Marlin BLEU : nageoire dorsale bleue haute à l'avant, barres verticales argentées sur flancs. Marlin NOIR : dorsale noire, corps uniformément noir-bleu sans barres. Nageoires pectorales rigides NON rétractables (différent du voilier). Caudale en croissant très puissante. Ligne latérale peu visible. Corps fusiforme massif très hydrodynamique. Absence d'écailles visibles. Taille IMPOSANTE : plus grand poisson à rostre du Pacifique.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 500.0,
            poidsMaxObserve: 900.0,
            descriptionPhysique: "Poisson à rostre (billfish) le plus imposant du Pacifique. Corps extrêmement puissant et musclé, parfaitement adapté à la nage rapide et aux combats prolongés. Rostre long et pointu utilisé pour frapper et étourdir les proies. Première nageoire dorsale très haute à l'avant (falciforme), se replie dans une rainure dorsale. Nageoires pectorales rigides et pointues ne se rétractant PAS contre le corps. Seconde dorsale et anale très réduites. Queue haute et puissante avec pédoncule caudal renforcé par carènes latérales. Peau lisse sans écailles apparentes, sécrétant mucus abondant. Coloration spectaculaire : dos bleu électrique métallique, flancs irisés argent-bleu, ventre blanc pur.",
            
            habitatDescription: "Grand pélagique du large en pleine eau. Fréquente principalement les eaux profondes océaniques (0-200m) mais chasse régulièrement en surface. Présence marquée autour des DCP, tombants abrupts, monts sous-marins et fronts thermiques. Préfère eaux tropicales et subtropicales chaudes (24-31°C). Espèce SOLITAIRE ou en petits groupes lâches (2-4 individus). Effectue migrations saisonnières suivant courants chauds et concentrations de proies. Espèce hautement mobile parcourant plusieurs centaines de km.",
            comportementDetail: "APEX PREDATOR absolu des pélagiques. Chasse active spectaculaire en surface utilisant rostre pour frapper et étourdir bancs de poissons ou calmars. Technique : charge à grande vitesse, frappe latérale du rostre, puis revient manger proies étourdies. Régime : thons, bonites, mahi-mahi, poissons volants, calmars, maquereaux. Chasseur opportuniste extrêmement puissant et agressif. Pic d'activité : MATIN (6h-11h) et FIN APRÈS-MIDI (15h-18h). Comportement territorial autour structures (DCP, monts). Combat LÉGENDAIRE : sauts spectaculaires hors de l'eau (tail-walking), courses longues et puissantes, combat pouvant durer plusieurs heures. Vitesse pointe : 80-90 km/h. Curiosité prononcée : suit bateaux, inspecte leurres, attaque teasers.",
            
            techniquesDetail: "Traîne big game (8-12 nœuds) : Technique EXCLUSIVE pour marlins. Indispensable : leurres TRÈS GRANDS (20-30 cm), têtes big game (pusher/plunger lourds), couleurs CONTRASTÉES. Flying fish = leurre roi (imitation poisson volant). TEASERS : leurres sans hameçon traînés pour provoquer attaque, puis présenter leurre armé. Stratégie DCP : passes larges AUTOUR du DCP (50-100m), ne jamais traverser. Repérer chasses oiseaux marins. Spread spécifique : Short Corner (flashy), Long Corner (naturel), Shotgun (flying fish loin 70-100m). Ligne PUISSANTE obligatoire : 50-80 kg minimum. Bas de ligne ACIER ou FLUORO épais (rostre). Combat technique : garder tension constante, laisser courir, pomper progressivement. Gaffe obligatoire ou bill grab (saisir rostre). NO-KILL fortement encouragé.",
            leuresSpecifiques: [
                "Flying Fish 20-30 cm (LEURRE ROI)",
                "Jukes/Octopus big game 10-12 pouces",
                "Teasers (sans hameçon pour provoquer)",
                "Bavettes plongeantes haute vitesse 20-25 cm",
                "Têtes Pusher/Plunger lourdes",
                "Leurres à contraste fort (noir/violet, bleu/blanc, rose/orange)"
            ],
            appatsNaturels: [
                "Bonite entière (appât roi)",
                "Mahi-mahi entier",
                "Thon entier",
                "Poisson volant entier"
            ],
            meilleursHoraires: "MATIN (6h-11h) : période optimale avec activité maximale en surface. FIN APRÈS-MIDI (15h-18h) : seconde fenêtre productive. Midi moins productif (marlins en profondeur). Aube et crépuscule également intéressants.",
            conditionsOptimales: "Présence DCP ou monts sous-marins. Fronts thermiques. Chasses d'oiseaux marins. Mer calme à légèrement formée. Eau bleue claire température > 24°C. Courants actifs. Vitesse 8-12 nœuds. Leurres TRÈS GRANDS (20-30 cm). Couleurs contrastées (noir/violet, bleu/blanc, rose). Flying fish indispensable. Teasers pour provoquer. Positions Shotgun (70-100m), Short/Long Corner. Ligne 50-80 kg. Bas de ligne acier/fluoro épais.",
            
            qualiteCulinaire: "Chair de qualité EXCELLENTE mais rarement consommée (espèce trophée, no-kill). Texture ferme et dense. Saveur délicate proche thon. Chair ROUGE FONCÉ riche en myoglobine. Préparations : Tataki (mi-cuit), Sashimi (ultra-frais), Grillades, Fumage. Texture plus ferme que thon jaune. Valeur EXCEPTIONNELLE comme TROPHÉE sportif (catch & release fortement encouragé). Prix prohibitif sur marchés (espèce rare). Saignée immédiate et mise sur glace CRITIQUE si conservé.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière pure : AUCUN risque de ciguatera. Ne fréquente jamais récifs coralliens. Prédateur sommital se nourrissant exclusivement d'autres pélagiques. Totalement sûr quelle que soit taille. C'est la garantie sanitaire des grands pélagiques du large.",
            
            reglementationNC: "Espèce emblématique et prestigieuse. Pas de taille minimale légale spécifique en NC (espèce hauturière rare). Pêche sportive fortement encouragée en NO-KILL (catch & release) pour préservation stocks. Déclaration captures recommandée. Respecter règles navigation et sécurité. Interdiction vente commerciale poissons à rostre dans certains pays (vérifier réglementation locale).",
            quotas: "Pas de quota spécifique pêche récréative NC actuellement. Limitations internationales possibles (WCPFC). Auto-limitation éthique fortement encouragée : 1 marlin/sortie maximum, relâche systématique si possible.",
            zonesInterdites: "Aucune zone spécifiquement interdite pour marlin. Respecter zones marines protégées générales et réserves intégrales.",
            statutConservation: "Statut VARIABLE selon espèce. Marlin BLEU : Vulnérable (UICN). Marlin NOIR : Quasi menacé. Populations SOUS PRESSION par pêche commerciale palangrière. Stocks Pacifique en DÉCLIN modéré. Croissance lente, maturité tardive (3-4 ans), longévité élevée (10-15 ans) = faible résilience. Pêche sportive NO-KILL ESSENTIELLE pour conservation. Gestion internationale via WCPFC.",
            
            leSaviezVous: "Le Marlin est LE GRAAL absolu de la pêche sportive ! Record IGFA Marlin BLEU : 818 kg (Hawaï 1982) - un MONSTRE ! Record Marlin NOIR : 707 kg. En NC, prises 100-300 kg. Le marlin peut atteindre 80-90 km/h et SAUTER plusieurs mètres hors de l'eau lors du combat - spectacle INOUBLIABLE ! Son rostre peut mesurer 50 cm et est utilisé comme épée pour frapper bancs de poissons. Le combat peut durer 2-6 HEURES avec un gros spécimen ! Hemingway a immortalisé le marlin dans 'Le Vieil Homme et la Mer'. Le marlin peut plonger à 200m de profondeur pendant le combat. TAIL-WALKING : danse verticale du marlin sur sa queue en surface = moment magique ! La pêche au marlin a créé des légendes : Cabo San Lucas, Cairns, Kona... NO-KILL est devenu la norme éthique : 'Un marlin vaut plus vivant que mort'. Flying fish = leurre MAGIQUE pour marlins depuis des décennies.",
            nePasPecher: false,
            raisonProtection: nil
        ),

        // ═══════════════════════════════════════════
        // VOILIER (SAILFISH)
        // ═══════════════════════════════════════════

        EspeceInfo(
            identifiant: "Espadon voilier",
            nomCommun: "Voilier (Sailfish)",
            nomScientifique: "Istiophorus platypterus",
            famille: "Istiophoridae",
            
            zones: [.large, .dcp, .passe],
            profondeurMin: 0,
            profondeurMax: 100,
            
            typesPecheCompatibles: [.traine],
            
            traineInfo: TraineInfo(
                vitesseMin: 7.0,
                vitesseMax: 10.0,
                vitesseOptimale: 8.0,
                profondeurNageOptimale: "0-30m (surface)",
                tailleLeurreMin: 15.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["juke", "flying fish", "bavette", "teaser", "popper"],
                couleursRecommandees: ["bleu/blanc", "noir/violet", "rose", "flashy"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shotgun],
                notes: "Le plus rapide des pélagiques. Voile IMMENSE. Teasers efficaces. Chasse en groupe. Vitesse 7-10 nœuds. Combat acrobatique spectaculaire."
            ),
            
            comportement: "Chasseur de surface ultra-rapide, chasse souvent en groupes",
            momentsFavorables: [.matinee, .apresMidi],
            
            photoNom: "Sailfish_photo",
            illustrationNom: "Sailfish_illustration",
            signesDistinctifs: "VOILE DORSALE GIGANTESQUE = signe unique et spectaculaire ! Première dorsale IMMENSE parcourant toute longueur du dos (du cou à la queue), parsemée de nombreux points noirs caractéristiques. Cette voile peut se déployer complètement lors chasse ou combat. Rostre long et effilé (plus fin que marlin). Corps élancé et comprimé latéralement bleu cobalt sur dos, flancs argentés avec ~20 barres verticales bleu clair fugaces, ventre blanc argenté. Nageoires pectorales LONGUES se repliant contre corps (différent du marlin). Ligne latérale visible. Caudale en croissant lunaire très échancrée. Taille plus modeste que marlin mais silhouette SPECTACULAIRE.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 350.0,
            poidsMaxObserve: 100.0,
            descriptionPhysique: "Poisson à rostre élancé et magnifique. Corps comprimé latéralement plus svelte que marlin, optimisé pour vitesse pure. La VOILE DORSALE est sa signature : jusqu'à 1,5m de hauteur quand déployée, parcourant tout le dos, membrane bleue parsemée points noirs. Cette voile sert à la fois de stabilisateur rapide, de signal visuel (chasse coopérative), et de thermorégulation. Rostre effilé légèrement plus court que marlin. Nageoires pectorales longues et étroites se repliant parfaitement dans rainure latérale. Peau lisse recouverte petites écailles cycloïdes. Pédoncule caudal fin avec double carène latérale. Muscles rouges puissants pour endurance. Coloration éclatante : dos bleu électrique cobalt, flancs argent irisé avec barres verticales pâles, ventre blanc pur.",
            
            habitatDescription: "Pélagique épioceanique du large, plus côtier que marlin. Fréquente couche 0-100m avec préférence surface (0-30m). Présence marquée autour DCP, tombants côtiers, passes et fronts thermiques. Préfère eaux chaudes tropicales (25-30°C). Espèce GRÉGAIRE : chasse en groupes organisés de 3-30 individus (tactique coopérative unique chez istiophoridés). Migrations saisonnières moins étendues que marlin. Plus abondant en eaux côtières riches en nutriments.",
            comportementDetail: "LE PLUS RAPIDE des poissons océaniques ! Vitesse pointe record : 110 km/h (controversé, 80-90 km/h confirmé). Chasseur de surface spectaculaire utilisant VOILE comme arme : la déploie pour rabattre et concentrer proies, créant mur visuel effrayant bancs. Chasse COOPÉRATIVE remarquable : groupe encercle banc, individus déploient voiles à tour de rôle, attaques coordonnées. Utilise aussi rostre pour frapper proies. Régime : sardines, anchois, maquereaux, calmars, poissons volants, petits thons. Pic activité : MATINÉE (7h-11h) très productif. Combat ACROBATIQUE exceptionnel : enchaîne sauts spectaculaires (10-20 sauts possible), tail-walking, courses rapides. Beaucoup plus aérien que marlin. Combats plus courts (30min-2h) mais extrêmement spectaculaires. Curieux : suit leurres, teasers, même bateaux.",
            
            techniquesDetail: "Traîne moyenne (7-10 nœuds) : vitesse légèrement inférieure au marlin. Leurres 15-25 cm, couleurs flashy (bleu/blanc, rose) ou contrastées (noir/violet). Flying fish excellent. TEASERS TRÈS EFFICACES : voiliers adorent attaquer teasers, technique du 'bait and switch' (teaser puis présenter leurre armé) redoutable. Stratégie DCP : passes autour, voiliers chassent souvent EN GROUPE. Repérer chasses : multiples voiles déployées en surface = spectacle magique ! Spread : Short Corner (flashy proche), Long Corner (naturel), Shotgun (flying fish loin). Ligne 20-50 kg. Bas de ligne acier fin ou fluoro 50-80 lb. Combat : garder tension, laisser sauter, pomper progressivement. Beaucoup plus rapide à combattre que marlin. NO-KILL fortement encouragé (relâche facile). Casting sur chasses possible avec poppers/stickbaits quand voiliers en surface.",
            leuresSpecifiques: [
                "Flying Fish 18-25 cm",
                "Jukes 6-8 pouces",
                "Teasers colorés (TRÈS efficaces)",
                "Bavettes 15-20 cm",
                "Poppers de surface (casting)",
                "Stickbaits (casting sur chasses)",
                "Têtes Pusher colorées"
            ],
            appatsNaturels: [
                "Poisson volant entier",
                "Bonite moyenne",
                "Maquereau entier",
                "Calmar entier",
                "Sardines en chapelet"
            ],
            meilleursHoraires: "MATINÉE (7h-11h) : période OPTIMALE avec chasses spectaculaires en surface. APRÈS-MIDI (14h-17h) : seconde fenêtre productive. Aube également excellent. Midi moins productif.",
            conditionsOptimales: "Présence DCP ou fronts. Chasses VISIBLES en surface (voiles déployées = signal). Mer calme. Eau bleue claire 25-30°C. Vitesse 7-10 nœuds. Leurres moyens 15-25 cm. Couleurs flashy ou contrastées. Flying fish et teasers ESSENTIELS. Positions Short/Long Corner + Shotgun. Ligne 20-50 kg. Groupes de voiliers = chasse coopérative spectaculaire.",
            
            qualiteCulinaire: "Chair de qualité EXCELLENTE mais consommation rare (espèce sportive, no-kill préféré). Texture ferme similaire espadon. Saveur délicate. Chair rose-rouge. Préparations : Tataki, Sashimi, Grillades, Fumage. Moins prisé commercialement que marlin (taille plus modeste). Valeur comme TROPHÉE sportif mais no-kill dominant. Saignée immédiate si conservé.",
            risqueCiguatera: .aucun,
            ciguateraDetail: "Espèce pélagique hauturière : AUCUN risque ciguatera. Prédateur sommital pleine eau. Ne fréquente jamais récifs. Totalement sûr toute taille.",
            
            reglementationNC: "Espèce sportive emblématique. Pas de taille minimale légale NC. Pêche NO-KILL fortement encouragée pour conservation. Déclaration captures recommandée. Respecter règles navigation/sécurité. Vente commerciale limitée (espèce sportive).",
            quotas: "Pas de quota spécifique récréatif NC. Gestion internationale WCPFC. Auto-limitation éthique : relâche systématique encouragée.",
            zonesInterdites: "Aucune zone spécifique. Respecter réserves marines générales.",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations globalement STABLES. Plus abondant et résilient que marlin. Croissance plus rapide. Maturité 2-3 ans. Pêche commerciale palangrière impact modéré. Stocks Pacifique en bon état. No-kill maintient populations saines.",
            
            leSaviezVous: "Le Voilier est LE POISSON LE PLUS RAPIDE du monde ! Record vitesse : 110 km/h (débattu) mais 80-90 km/h confirmé = INCROYABLE ! Record IGFA : 100,24 kg (Équateur). En NC : prises 20-50 kg moyenne. Sa VOILE peut mesurer 1,5m de hauteur - plus haute que le corps ! Il déploie cette voile pour rabattre bancs de proies lors chasse coopérative. Le voilier peut faire 10-20 SAUTS lors du combat - show spectaculaire garanti ! Il change de COULEUR rapidement : bleu vif quand excité, terne quand calme. Contrairement au marlin, le voilier CHASSE EN GROUPE avec tactique coordonnée rare chez grands pélagiques. Son nom anglais 'Sailfish' vient évidemment de sa voile gigantesque. Le voilier est DEUX FOIS plus rapide qu'Usain Bolt ! Il peut traverser Pacifique (10 000 km) en quelques mois. NO-KILL est devenu standard : voilier se relâche facilement et survit très bien. Espèce préférée des tournois de pêche sportive mondiale (Guatemala, Mexique, Costa Rica légendaires). Sa voile sert aussi de thermorégulateur (surface vasculaire énorme).",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // THAZARDS
        // ─────────────────────────────────────────────────────────────────────
        
        // ═══════════════════════════════════════════════════════════════════════════
        // THAZARD RAYÉ - Scomberomorus commerson
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "thazard_raye",
            nomCommun: "Thazard rayé indo-pacifique",
            nomScientifique: "Scomberomorus commerson",
            famille: "Scombridae",
            
            zones: [.passe, .recif, .tombant, .hauturier],
            profondeurMin: 0,
            profondeurMax: 150,
            
            typesPecheCompatibles: [.traine, .lancer],
            
            traineInfo: TraineInfo(
                vitesseMin: 6.0,
                vitesseMax: 10.0,
                vitesseOptimale: 7.5,
                profondeurNageOptimale: "0-20m (surface)",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 22.0,
                typesLeurresRecommandes: ["cuiller rapide", "poisson nageur bavette", "stickbait", "leurre souple"],
                couleursRecommandees: ["bleu/argent", "maquereau", "rose/chartreuse", "naturel"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner, .shotgun],
                notes: "SCOMBRIDÉ RAPIDE ! Traîne RAPIDE 6-10 nœuds obligatoire. Leurres HYDRODYNAMIQUES bavette profondeur 2-4m. Imiter poissons fourrages."
            ),
            
            comportement: "Prédateur pélagique chasseur rapide en groupes actifs",
            momentsFavorables: [.aube, .matinee, .crepuscule],
            
            photoNom: "Thazard_photo",
            illustrationNom: "Thazard_illustration",
            signesDistinctifs: "SCOMBRIDÉ côtier élégant ! Haut du corps GRIS BLEUTÉ magnifique, ventre ARGENTÉ brillant. PINNULES DORSALES ET ANALES caractéristiques famille = petites nageoires triangulaires séparées après dorsale/anale principales (signature scombridés). NOMBREUSES BARRES ÉTROITES VERTICALES SOMBRES forme IRRÉGULIÈRE sur flancs = motif diagnostic ! Ces barres parfois fugaces selon angle lumière. EXTRÉMITÉ SECONDE DORSALE ET ANALE BLANCHE distinctive. Corps fusiforme hydrodynamique parfait. Caudale en croissant lunaire très puissante. Tête pointue effilée. Bouche grande avec DENTS ACÉRÉES visibles (canines). Ligne latérale ondulée descendant abruptement sous seconde dorsale. Taille max 180 cm. Aspect général : TORPILLE ARGENTÉE RAYÉE élégante.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 180.0,
            poidsMaxObserve: 70.0,
            descriptionPhysique: "Poisson FUSIFORME ALLONGÉ à morphologie HYDRODYNAMIQUE extrême. Corps élancé comprimé latéralement modérément. Tête conique pointue effilée. Museau pointu. Bouche grande terminale oblique avec MÂCHOIRE INFÉRIEURE légèrement proéminente. DENTS ACÉRÉES nombreuses : canines pointues + dents comprimées tranchantes alignées = arsenal prédateur efficace. Yeux moyens latéraux. DEUX DORSALES bien séparées : première haute triangulaire (15-18 épines), seconde plus basse longue molle (15-20 rayons) suivie de 8-10 PINNULES DORSALES séparées caractéristiques. Anale opposée seconde dorsale (17-21 rayons) suivie 9-10 PINNULES ANALES. Pectorales courtes insérées bas. Pelviennes petites abdominales. CAUDALE EN CROISSANT LUNAIRE très puissante pédonculée. Carènes latérales pédoncule caudal. Ligne latérale ondulée caractéristique : descend abruptement sous seconde dorsale. Écailles petites cycloides. Coloration : DOS GRIS BLEUTÉ métallique, FLANCS argentés brillants, VENTRE blanc argenté. BARRES VERTICALES SOMBRES nombreuses étroites forme irrégulière = zigzags caractéristiques ! Ces barres parfois fugaces (visibilité variable angle/lumière). EXTRÉMITÉ seconde dorsale et anale BLANCHE distinctive. Pinnules grises. Caudale gris foncé. Aspect général : SCOMBRIDÉ élégant argenté rayé. Taille adulte typique 60-120 cm. Spécimens > 150 cm rares. Record 180 cm 70 kg.",
            
            habitatDescription: "Espèce PÉLAGIQUE CÔTIÈRE occupant eaux côtières à hauturières moyennes profondeurs. Passes : zones courants forts, embouchures. Récifs frangeants : platiers externes, zones transition. Tombants côtiers jusqu'à 150m. Hauturier pélagique modéré. SURFACE à MI-EAU principalement (0-20m). Préfère eaux claires tropicales/subtropicales 24-30°C. Comportement : GROUPES ACTIFS (5-50 individus) = espèce grégaire marquée ! Parfois bancs massifs (100+ individus) zones très riches. Patrouilles rapides étendues chassant bancs poissons fourrages. Juvéniles zones côtières protégées (baies externes, passes). Sub-adultes/adultes habitats pélagiques. Espèce MIGRATRICE saisonnière localement (suit bancs proies). Grands déplacements. Présence marquée passes, tombants, zones upwelling, chasses surface spectaculaires. Association fréquente DCP, objets flottants. Activité diurne principalement.",
            comportementDetail: "PRÉDATEUR PÉLAGIQUE CHASSEUR RAPIDE EN GROUPES = stratégie coopérative efficace ! Technique : CHASSE ACTIVE coordonnée - groupes encerclent bancs poissons fourrages (sardines, maquereaux, selars, anchois, poissons volants), attaques simultanées créant panique = CHASSES SURFACE spectaculaires avec remous, sauts ! Vitesse pointe : 75 km/h. Vitesse croisière : 30-45 km/h. Régime : PISCIVORE strict 100% ! Petits poissons pélagiques argentés (sardines, maquereaux, selars, anchois, fusiliers, aiguillettes, poissons volants), calmars petits. SÉLECTIVITÉ taille proies : 5-15 cm optimal. Pic activité : AUBE (5h-8h) excellent, MATINÉE (8h-12h) très bon, APRÈS-MIDI (12h-16h) correct, FIN APRÈS-MIDI/CRÉPUSCULE (16h-19h) bon. Comportement diurne marqué. Attaque leurres VIOLEMMENT à PLEINE VITESSE : touche DÉVASTATRICE foudroyante caractéristique ! Combat SPECTACULAIRE EXPLOSIF : courses ultra-rapides 50-150m, SAUTS ACROBATIQUES impressionnants multiples 1-2m hors eau, résistance acharnée 15-40 minutes selon taille. TRÈS combatif ! DENTS ACÉRÉES tranchantes coupent bas de ligne facilement : câble métallique fin/moyen OBLIGATOIRE. Comportement grégaire fort : suit congénères. Curiosité envers leurres rapides hydrodynamiques. Chasses coordonnées = efficacité maximale.",
            
            techniquesDetail: "TRAÎNE RAPIDE (6-10 nœuds) : technique PRINCIPALE obligatoire ! Thazard = espèce RAPIDE nécessitant leurres HYDRODYNAMIQUES stables vitesse élevée. Leurres 12-22 cm : cuillers rapides, poissons nageurs bavette (plongée 2-4m), stickbaits rapides, leurres souples effilés. Couleurs BLEU/ARGENTÉ imitant maquereaux/sardines (optimal), ROSE/CHARTREUSE eaux troubles/faible lumière (excellent). Profondeur 0-20m (surface à mi-eau). Traîne 6-8 nœuds optimal général, 8-10 nœuds high speed trolling ciblant thazards actifs. Leurres bavette créent WOBBLING serré rapide + plongent 2-4m = zone chasse thazards. LANCER efficace technique complémentaire : stickbaits 12-18 cm, cuillers, leurres souples. Repérer CHASSES SURFACE spectaculaires, lancer dans mêlée, animation TRÈS RAPIDE linéaire. HORAIRES : AUBE et MATINÉE = périodes OPTIMALES ! Ligne 15-30 kg. BAS DE LIGNE : CÂBLE métallique FIN (10-20 lb) OBLIGATOIRE = dents tranchantes coupent nylon/fluoro instantanément ! Spread traîne : Short/Long Corner, Shotgun (positions rapprochées bateau). Combat : tension forte, pompage rapide, ATTENTION sauts violents (décroches fréquentes). Épuisette rapide. MANIPULATION PRUDENTE : dents très coupantes (gants). Pêche passes/tombants traîne rapide = technique optimale. ASTUCE PRO : leurres bavette action SERRÉ RAPIDE + cliquetis/billes internes = déclencheur optimal thazards ! Chasses surface : lancer immédiatement, récupération ultra-rapide.",
            leuresSpecifiques: [
                "Cuillers RAPIDES argentées 12-18 cm (EXCELLENT)",
                "Poissons nageurs bavette 12-18 cm action serré",
                "Stickbaits rapides 12-20 cm",
                "Leurres souples effilés 12-18 cm",
                "Rapala/Yo-Zuri modèles high speed",
                "Couleurs JOUR : BLEU/ARGENTÉ, maquereau naturel (optimal)",
                "Couleurs LUMIÈRE FAIBLE : ROSE, chartreuse, flashy (excellent)",
                "Leurres CLIQUETIS/BILLES internes = +efficacité",
                "ACTION RAPIDE HYDRODYNAMIQUE obligatoire"
            ],
            appatsNaturels: [
                "Petits maquereaux vivants/morts (APPÂT ROI)",
                "Sardines moyennes",
                "Selars/chinchards",
                "Anchois moyens",
                "Aiguillettes petites/moyennes",
                "Poissons volants",
                "Lanières filets poisson frais",
                "Calmars petits/moyens"
            ],
            meilleursHoraires: "AUBE (5h-8h) : période OPTIMALE ++ ! MATINÉE (8h-12h) : très bon. APRÈS-MIDI (12h-16h) : correct. FIN APRÈS-MIDI/CRÉPUSCULE (16h-19h) : bon. NUIT : peu actif. Thazard = espèce DIURNE activité maximale matin. Synchroniser sorties avec marées montantes/descendantes passes = meilleurs résultats.",
            conditionsOptimales: "Passes courants forts. Tombants. Zones chasses surface. Proximité bancs poissons fourrages. Eaux claires 24-30°C. TRAÎNE RAPIDE 6-10 nœuds : leurres hydrodynamiques 12-22 cm bavette 2-4m, couleurs BLEU/ARGENTÉ ou ROSE/CHARTREUSE, profondeur 0-20m. LANCER chasses surface : stickbaits/cuillers 12-18 cm récupération ultra-rapide. Ligne 15-30 kg. BAS DE LIGNE CÂBLE métallique fin 10-20 lb OBLIGATOIRE (dents tranchantes). Positions Short/Long Corner, Shotgun. HORAIRES : AUBE et MATINÉE critiques ! Marées fortes passes = déclencheur.",
            
            qualiteCulinaire: "Chair de qualité EXCELLENTE très appréciée ! Texture FERME agréable. Saveur DÉLICATE fine légèrement sucrée. Chair ROSE PÂLE à BLANCHE. Grain FIN. Considéré POISSON NOBLE gastronomie Pacifique ! Usages : Sashimi/sushi (EXCELLENT - ultra-frais), Filets grillés/poêlés (excellent), Ceviche (parfait), Tartare (délicat), Fumage (traditionnel apprécié), Currys, Fritures. Prix ÉLEVÉ marchés locaux (18-35€/kg) = espèce recherchée ! Demande FORTE. Saignée immédiate ESSENTIELLE qualité optimale. Mise sur glace immédiate. Éviscération rapide. Filetage facile propre. Rendement BON (70% chair). Valeur culinaire ET sportive ÉLEVÉE. Chair périssable rapidement = consommation rapide ou congélation immédiate.",
            risqueCiguatera: .faible,
            ciguateraDetail: "Risque FAIBLE à TRÈS FAIBLE. Thazard rayé = espèce PÉLAGIQUE côtière accumulant PEU toxines ciguatera. Habitat pélagique surface + régime piscivore poissons pélagiques = exposition minimale toxines récifales. TAILLES toutes généralement SÛRES consommation (< 180 cm). Petits/moyens thazards (< 10 kg) : risque TRÈS FAIBLE à quasi NUL. Gros thazards (10-30 kg) : risque FAIBLE. Très gros (> 30 kg rares) : risque FAIBLE à MODÉRÉ zones récifales. Thazards pélagiques hauturiers : risque QUASI NUL. SE RENSEIGNER localement zones connues problématiques par précaution. En NC : thazards rayés généralement considérés SÛRS autorités sanitaires. CAS ciguatera thazards TRÈS RARES. Espèce largement CONSOMMÉE populations Pacifique sans problèmes. Privilégier spécimens pélagiques plutôt que côtiers récifaux si doute.",
            
            reglementationNC: "Pas de taille minimale légale spécifique thazard rayé actuellement NC. Pêche récréative libre quantités raisonnables. Respecter règles générales zones protégées. Espèce non menacée localement. Prélèvement acceptable consommation personnelle. Commercialisation autorisée (espèce recherchée marchés). Pratique NO-KILL possible petits spécimens.",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation raisonnable encouragée. Espèce abondante mais exploitation commerciale modérée. Prélèvement personnel acceptable. Stocks généralement bons.",
            zonesInterdites: "Aucune zone spécifiquement interdite thazards. Respecter zones marines protégées générales, réserves intégrales, zones interdites pêche générale.",
            statutConservation: "Statut UICN : Quasi menacé (Near Threatened) - surveillance recommandée. Populations globalement STABLES mais DÉCLIN local certaines zones surpêche. Espèce largement distribuée Indo-Pacifique tropical/subtropical. Croissance rapide, maturité 2-3 ans, reproduction régulière saisonnière, longévité 12-18 ans = résilience correcte. Stocks généralement bons mais pression pêche MODÉRÉE à ÉLEVÉE (espèce commerciale recherchée). Surpêche locale possible zones forte exploitation. Gestion via tailles minimales et quotas commerciaux certains pays. Surveillance populations recommandée.",
            
            leSaviezVous: "Le Thazard rayé est un SCOMBRIDÉ côtier = cousin Wahoo et thons ! Morphologie hydrodynamique PARFAITE : coefficient traînée ultra-bas, vitesse pointe 75 km/h, accélération foudroyante = performances remarquables ! PINNULES dorsales/anales = signature anatomique famille Scombridae (thons, thazards, maquereaux) facilitant hydrodynamique vitesse élevée. DENTS ACÉRÉES tranchantes : canines + dents comprimées = outils coupe précis découpant proies. BARRES VERTICALES irrégulières = camouflage perturbant silhouette contre lumière surface vue dessous (contre-prédateurs). Record mondial IGFA : 45 kg (Australie). Records fiables fréquents : 180 cm 70 kg. En NC : spécimens 5-15 kg courants, 20-30 kg beaux poissons, 35+ kg exceptionnels. Nom 'commerson' honore naturaliste français Philibert Commerson (1727-1773) explorateur Pacifique ! CHASSES SURFACE spectaculaires : groupes 20-50 thazards encerclent bancs sardines/maquereaux, attaques simultanées créant REMOUS BOUILLONNANTS explosifs, sauts multiples = spectacle naturel impressionnant ! Combat EXPLOSIF légendaire : touches à 60-70 km/h DÉVASTATRICES arrachant ligne, sauts acrobatiques 5-10 consécutifs 1-2m hors eau, courses 100-150m ultra-rapides = sensations HALLUCINANTES ! MIGRATION saisonnière locale : suit bancs proies (sardines, maquereaux) = concentrations temporaires zones riches. Espèce TRÈS appréciée pêche sportive Pacifique = combativité + qualité culinaire excellente. Chair rose pâle DÉLICATE = sashimi/sushi exquis fraîcheur absolue (< 6h pêche). Technique traditionnelle Pacifique : traîne RAPIDE appâts naturels (maquereaux entiers) vitesse 6-8 nœuds = efficacité maximale. DENTS coupent câble acier < 10 lb parfois : utiliser 15-20 lb sécurité. Thazards juvéniles (< 2 kg) côtiers baies/passes = nurseries importantes. Espèce indicatrice santé écosystème pélagique côtier. Pêche commerciale artisanale importante nombreux pays Pacifique = ressource économique significative communautés côtières. Consommation largement répandue populations océaniennes depuis siècles = poisson traditionnel apprécié. Records personnels nombreux pêcheurs : thazard 25+ kg = trophée mémorable combativité exceptionnelle !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // CARANGUES
        // ─────────────────────────────────────────────────────────────────────
        
        // ═══════════════════════════════════════════════════════════════════════════
        // CARANGUE GT (GIANT TREVALLY) - Caranx ignobilis
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "carangueGT",
            nomCommun: "Carangue GT (Giant Trevally / Carangue Grosse Tête)",
            nomScientifique: "Caranx ignobilis",
            famille: "Carangidae",
            
            zones: [.passe, .recif, .tombant, .lagon, .large],
            profondeurMin: 0,
            profondeurMax: 100,
            
            typesPecheCompatibles: [.traine, .lancer, .jigging],
            
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "0-20m (surface à mi-eau)",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["popper", "stickbait", "bavette", "jig lourd"],
                couleursRecommandees: ["naturel", "blanc/rouge", "chartreuse", "rose", "argenté"],
                positionsSpreadRecommandees: [.shortCorner, .longCorner],
                notes: "LE TITAN des carangues ! Embuscade structures. Attaque VIOLENTE. LANCER souvent préféré à traîne. Poppers EXCELLENTS."
            ),
            
            comportement: "Prédateur apex embuscade, attaque foudroyante ultra-puissante",
            momentsFavorables: [.aube, .crepuscule, .nuit, .matinee],
            
            photoNom: "CarangueGT_photo",
            illustrationNom: "CarangueGT_illustration",
            signesDistinctifs: "LE GÉANT de la famille ! Corps massif argenté. Haut du corps sombre (gris-bronze à presque noir chez gros adultes), bas du corps argent. NOMBREUSES TACHES NOIRES sur flancs (surtout adultes) = signe DIAGNOSTIC majeur. FRONT ABRUPT caractéristique chez adultes de grande taille (> 80 cm) = profil massif impressionnant ! Petite zone noire à base supérieure pectorales. Ligne latérale arquée avec scutelles prononcées. Caudale en croissant très puissante. Corps trapu musclé. Tache noire sur opercule variable. Juvéniles : corps plus élancé, front arrondi, peu/pas de taches noires. Taille max 160 cm (LF) ! Poids max 80 kg ! En NC : spécimens 20-50 kg réguliers.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 160.0,
            poidsMaxObserve: 80.0,
            descriptionPhysique: "LE PLUS GRAND Carangidé ! Morphologie MASSIVE et PUISSANTE. Corps comprimé latéralement très profond et trapu. Tête volumineuse avec FRONT ABRUPT prononcé chez adultes (> 80 cm) créant profil quasi vertical = signature visuelle spectaculaire ! Front arrondi chez juvéniles puis s'aplatit progressivement avec âge. Bouche grande oblique avec mâchoires puissantes. Dents fines. Œil relativement petit (proportionnellement à taille corps). Ligne latérale fortement arquée antérieurement puis droite, bordée scutelles osseuses très développées sur moitié postérieure. Deux dorsales : première courte épineuse (7-8 épines) rétractable, seconde longue molle (18-21 rayons). Anale similaire seconde dorsale. Pectorales falciformes. Caudale profondément fourchue TRÈS PUISSANTE. Pédoncule caudal épais musclé. Muscles extrêmement développés. Coloration : dos gris-bronze à noir (fonce avec âge), flancs argentés avec NOMBREUSES TACHES NOIRES irrégulières (augmentent avec âge), ventre blanc argenté. Nageoires gris foncé à noires.",
            
            habitatDescription: "Espèce UBIQUISTE occupant tous habitats côtiers et récifaux. Juvéniles (< 30 cm) : baies protégées, mangroves, estuaires, herbiers. Sub-adultes (30-80 cm) : récifs frangeants, lagons, passes, tombants peu profonds. ADULTES (> 80 cm) : PASSES profondes (chasseurs embuscade ++), tombants externes, zones forts courants, entrées baies, platiers externes, épaves, DCP. Préfère zones STRUCTURES : patates corail, surplombs rocheux, épaves, tombants abrupts = postes embuscade. Eaux tropicales 24-30°C. Profondeur 0-100m mais concentration 5-40m. Comportement territorial marqué : mêmes gros GT occupent mêmes postes pendant années. Migrations quotidiennes : récifs peu profonds JOUR (repos), passes/tombants AUBE/CRÉPUSCULE/NUIT (chasse intensive). Solitaires (très gros adultes) ou petits groupes (2-5 individus).",
            comportementDetail: "PRÉDATEUR APEX = sommet chaîne alimentaire récifale ! Chasseur EMBUSCADE ultra-puissant. Stationne IMMOBILE près structures (surplombs, patates) puis CHARGE FULGURANTE sur proie. Accélération 0-70 km/h en 2 secondes ! Vitesse pointe : 70 km/h. Régime : fusiliers (proie favorite ++), mulets, sardines, carangues plus petites, calmars, poulpes, crabes, homards, PETITS REQUINS (oui !), même TORTUES juvéniles ! Gros GT (> 40 kg) mangent TOUT ce qui bouge. Pic activité : AUBE (5h-8h) INTENSE = chasses spectaculaires, CRÉPUSCULE (17h-20h) également maximal, NUIT (20h-6h) très actif (chasse passes). Jour moins actif (embuscade passive). Chasse coopérative en groupe possible : encerclent bancs fusiliers. Attaque leurres de manière ULTRA-VIOLENTE : touche la plus brutale pêche côtière ! Combat LÉGENDAIRE : courses ultrarapides 100m+, plongées puissantes vers structures (casse lignes), résistance ACHARNÉE 30-90 minutes ! Réputé poisson le plus DIFFICILE combattre au kg. Curieux : inspecte leurres, suit plongeurs. Très intelligent et méfiant (gros adultes). DANGER potentiel : gros GT peuvent être agressifs envers plongeurs (rares cas morsures/charges).",
            
            techniquesDetail: "MULTIPLES TECHNIQUES mais LANCER = TECHNIQUE REINE pour GT ! LANCER sur STRUCTURES : technique la plus efficace et sportive. Poppers surface 14-25 cm, stickbaits 15-25 cm, jigs lourds 80-200g. Repérer structures (patates, surplombs, épaves), lancer près, animation agressive. Touche EXPLOSIVE garantie ! Poppers = MAGIE absolue sur GT. TRAÎNE moyenne (4-8 nœuds) : leurres 15-25 cm, bavettes profondes, grosses jupes. Passes en zig-zag, le long tombants. Moins efficace que lancer mais fonctionne. JIGGING vertical : jigs lourds 100-250g structures profondes, tombants abrupts. Technique ultrarapide, jig descend/remonte verticalement. PÊCHE À VUE : technique ultime ! Repérer GT patrouille à vue (eau claire), lancer devant, excitation maximale. Horaires : AUBE et CRÉPUSCULE absolument CRITIQUES. Nuit passes également. Ligne PUISSANTE obligatoire : 30-60 kg (gros GT cassent 40 kg !). Bas de ligne fluoro épais 80-120 lb (abrasion scutelles ++). Combat : BLOQUER frein fort, pomper puissamment, empêcher plongée structures sinon ligne coupée garantie. Gaffe obligatoire gros GT. NO-KILL encouragé (espèce emblématique). ATTENTION manipulation : scutelles coupent comme rasoirs ! Gants obligatoires.",
            leuresSpecifiques: [
                "POPPERS de surface 14-25 cm (ARME ABSOLUE GT !)",
                "Stickbaits 15-25 cm (surface et coulants)",
                "Jigs métalliques lourds 80-250g",
                "Bavettes profondes 15-22 cm (traîne)",
                "Leurres souples 18-25 cm + têtes plombées lourdes",
                "Couleurs : naturel (argenté, bleu/blanc), flashy (rose, chartreuse), rouge/blanc",
                "Leurres ROBUSTES obligatoires (GT détruisent leurres fragiles)"
            ],
            appatsNaturels: [
                "Fusiliers vivants (APPÂT ROI)",
                "Mulets vivants gros",
                "Sardines grosses",
                "Petites carangues vivantes",
                "Calmars gros entiers",
                "Poulpes",
                "Crabes gros"
            ],
            meilleursHoraires: "AUBE (5h-8h) : période OPTIMALE ABSOLUE avec chasses intenses passes ! CRÉPUSCULE (17h-20h) : égale aube, activité maximale. NUIT (20h-6h) : très actif passes (gros GT ++). MATINÉE (8h-11h) : productif structures. JOUR (11h-17h) : moins actif, embuscade passive mais gros GT possibles.",
            conditionsOptimales: "Présence STRUCTURES (passes, patates corail, surplombs, épaves, tombants). Marée ACTIVE (courants) = excellent déclencheur. Chasses fusiliers visibles. Eau claire 24-30°C. LANCER structures : poppers/stickbaits 15-25 cm, animation agressive. TRAÎNE passes : zig-zag 5-8 nœuds, leurres 15-25 cm robustes. JIGGING : jigs 100-250g structures profondes. Ligne 30-60 kg PUISSANTE. Bas de ligne fluoro 80-120 lb. AUBE et CRÉPUSCULE = horaires ABSOLUS. Passes en marée = zones HOT. Repérer patrouilles GT à vue si possible.",
            
            qualiteCulinaire: "Chair de qualité VARIABLE selon taille. Petits GT (< 5 kg) : chair BONNE, texture ferme, saveur correcte. GT moyens (5-15 kg) : chair CORRECTE mais texture ferme parfois dure. GROS GT (> 15 kg) : chair MÉDIOCRE, très ferme, saveur forte, parfois désagréable. Chair BLANCHE. Préparations : Filets (petits GT), Currys épicés (masquent texture), Fumage possible. Prix faible marchés locaux (demande limitée qualité moyenne). Valeur ESSENTIELLEMENT SPORTIVE : GT recherché pour COMBAT LÉGENDAIRE, pas qualité culinaire ! Nombreux pêcheurs pratiquent NO-KILL systématique. Saignée immédiate si conservé. GT considéré TROPHÉE sportif majeur Indo-Pacifique.",
            risqueCiguatera: .modere,
            ciguateraDetail: "Risque MODÉRÉ À ÉLEVÉ selon taille et zone ! GT = prédateur apex récifal accumulant toxines. RÈGLES STRICTES : JAMAIS consommer GT > 10 kg (risque ÉLEVÉ). GT 5-10 kg : risque MODÉRÉ, prudence zones récifales. Petits GT < 5 kg : risque FAIBLE à MODÉRÉ. SE RENSEIGNER LOCALEMENT zones à risque. Certaines zones NC ont GT systématiquement toxiques. GT passes/tombants externes généralement plus sûrs que GT récifs frangeants. En cas DOUTE : NE PAS CONSOMMER. Privilégier NO-KILL. Ciguatera GT peut être SÉVÈRE (grande taille = forte accumulation).",
            
            reglementationNC: "Pas de taille minimale légale spécifique GT actuellement NC. Pêche récréative libre quantités raisonnables. Respecter règles générales zones protégées. Espèce emblématique non menacée mais surveillance recommandée. NO-KILL fortement ENCOURAGÉ pour préserver gros géniteurs et valeur sportive espèce. Certaines zones peuvent avoir restrictions locales (vérifier). Déclaration captures exceptionnelles (> 40 kg) appréciée.",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation FORTE encouragée : prélever uniquement petits GT (< 5 kg) consommation si nécessaire, relâcher systématiquement gros GT (> 10 kg) = géniteurs essentiels + risque ciguatera + valeur sportive. Éthique NO-KILL dominante communauté pêcheurs GT.",
            zonesInterdites: "Aucune zone spécifiquement interdite GT. Respecter zones marines protégées générales, réserves intégrales. Certaines passes/zones peuvent avoir recommandations locales protection (vérifier pêcheurs locaux).",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations globalement STABLES mais SURVEILLANCE nécessaire. Espèce largement distribuée Indo-Pacifique. Croissance lente (8-10 ans atteindre 1m), maturité tardive (3-5 ans), longévité élevée (25+ ans) = vulnérabilité modérée surpêche. Gros GT (> 30 kg) peuvent être sensibles pression pêche ciblée zones accessibles. Stocks généralement bons mais déclin local possible zones forte pression. Gestion via sensibilisation NO-KILL et protection gros géniteurs recommandée. GT = espèce EMBLÉMATIQUE pêche sportive Indo-Pacifique : conservation essentielle maintenir populations saines.",
            
            leSaviezVous: "Le GT est LE GRAAL de la pêche au lancer Indo-Pacifique ! Record IGFA : 80,6 kg (Japon 2006) - TITAN absolu ! Record officieux : 90+ kg rapportés ! En NC : spécimens 20-40 kg réguliers passes, 50-60 kg possibles ! Nom 'GT' = 'Giant Trevally' anglais, devenu universel. Nom scientifique 'ignobilis' = 'ignoble, vil' latin car chair qualité médiocre (ironique pour poisson si noble combattre !). Le GT a FRONT ABRUPT spectaculaire gros adultes = adaptation hydronamique chasse charges puissantes. Combat GT > 30 kg = EXPÉRIENCE ULTIME pêche côtière : puissance HALLUCINANTE, courses 100-150m filant 200m ligne en secondes, plongées structures cassant matériel, résistance 1-2 HEURES possibles ! Certains pêcheurs considèrent GT livre pour livre PLUS DUR combattre que marlin ! GT INTELLIGENT : gros adultes ultra-méfiants, refusent leurres voyants, examinent avant attaquer. Technique 'GT popping' = discipline pêche entière dédiée ! Festivals mondiaux : Japon, Australie, Seychelles. GT peut vivre 30+ ans ! Gros GT deviennent quasi NOIRS avec âge. GT connus CHARGER plongeurs zones territoriales (rares mais impressionnant !). GT mangent REQUINS pointe noire (1-1,5m) et TORTUES juvéniles ! Scutelles GT coupent comme rasoirs : nombreux pêcheurs blessés manipulation sans gants. Popper surface déclenche attaque GT = EXPLOSION visuelle inoubliable ! NO-KILL GT > 10 kg = éthique standard communauté mondiale pêcheurs GT.",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // CARANGUE BLEUE / AILE BLEUE - Caranx melampygus
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "carangueBleue",
            nomCommun: "Carangue bleue / Carangue aile bleue",
            nomScientifique: "Caranx melampygus",
            famille: "Carangidae",
            
            zones: [.tombant, .passe, .recif, .lagon],
            profondeurMin: 5,
            profondeurMax: 80,
            
            typesPecheCompatibles: [.traine, .lancer, .jigging],
            
            traineInfo: TraineInfo(
                vitesseMin: 5.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.5,
                profondeurNageOptimale: "5-30m (mi-eau)",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 20.0,
                typesLeurresRecommandes: ["bavette", "jig rapide", "popper", "stickbait"],
                couleursRecommandees: ["bleu/jaune fusiliers", "rose", "chartreuse", "argenté"],
                positionsSpreadRecommandees: [.longCorner, .shortCorner],
                notes: "Espèce TOMBANTS chassant FUSILIERS ! Traîne ZIG-ZAG le long structures. Lancer et jigging EXCELLENTS. Combat puissant."
            ),
            
            comportement: "Prédateur tombants, chasse fusiliers en migration verticale",
            momentsFavorables: [.aube, .matinee, .apresMidi, .crepuscule],
            
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "Corps argenté à reflets VERT BLEUTÉ caractéristiques. NOMBREUX POINTS BLEUS ET NOIRS sur deux tiers supérieurs du corps = signature visuelle ABSOLUE ! Dorsales, anale et caudale BLEU VIF éclatant = magnifique ! Ligne latérale arquée avec scutelles. Caudale en croissant puissante. Taille moyenne : 40-80 cm. Corps comprimé latéralement élégant. Plus élancé que GT. Coloration spectaculaire quand excité : bleu électrique intensifié ! Tache noire sur opercule variable. Taille max 100 cm (rare, 70-80 cm typique).",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 100.0,
            poidsMaxObserve: 18.0,
            descriptionPhysique: "Carangue de taille moyenne à morphologie élégante. Corps comprimé latéralement modérément profond, plus élancé que ignobilis. Profil arrondi harmonieux. Bouche oblique moyenne avec mâchoires modérées. Dents fines. Œil moyen. Ligne latérale arquée antérieurement puis droite, bordée scutelles osseuses bien développées sur moitié postérieure. Deux dorsales : première courte épineuse (8 épines) rétractable, seconde longue molle (19-22 rayons). Anale similaire seconde dorsale. Pectorales falciformes moyennes. Caudale profondément fourchue puissante. Pédoncule caudal robuste. Coloration SPECTACULAIRE : corps argenté avec reflets VERT BLEUTÉ magnifiques, NOMBREUX POINTS BLEUS ET NOIRS caractéristiques sur dos et flancs (deux tiers supérieurs corps), ventre blanc argenté. NAGEOIRES BLEU VIF éclatant (dorsales, anale, caudale) = signature visuelle superbe ! Intensité couleur bleue augmente quand excité. Tache noire variable sur opercule.",
            
            habitatDescription: "Espèce TOMBANTS ET PASSES spécialisée suivant migrations verticales fusiliers. Habitat principal : TOMBANTS EXTERNES 10-60m, pentes récifales abruptes, zones transitions plateau/tombant. Passes profondes avec courants actifs. Récifs frangeants externes. Lagon profond (> 15m) près structures. Préfère zones STRUCTURES avec fusiliers abondants : surplombs, canyons, formations coralliennes, tombants abrupts. Eaux claires tropicales 24-30°C. Comportement : petits groupes (3-8 individus) ou solitaires (gros adultes). MIGRATION VERTICALE QUOTIDIENNE suivant proies fusiliers : descente JOUR vers 40-60m (fusiliers en profondeur), remontée AUBE/CRÉPUSCULE vers 10-30m (fusiliers montent). Patrouille active le long tombants. Juvéniles zones moins profondes (5-20m).",
            comportementDetail: "Prédateur SPÉCIALISÉ FUSILIERS = adaptation écologique unique ! Suit migrations verticales quotidiennes bancs fusiliers : descend/monte avec proies. Vitesse pointe : 65 km/h. Technique chasse : patrouille ACTIVE le long tombants, charge rapide sur bancs fusiliers. Régime : FUSILIERS (85% régime ++), sardines, anchois, petits maquereaux, calmars. Pic activité : AUBE (6h-9h) excellent (fusiliers remontent), FIN APRÈS-MIDI (16h-19h) très bon (fusiliers actifs), CRÉPUSCULE productif. MATINÉE et APRÈS-MIDI corrects si fusiliers présents. Chasse en petits groupes coordonnés : encerclent bancs fusiliers, attaques simultanées. Attaque leurres VIOLEMMENT : touche brutale caractéristique. Combat PUISSANT et AÉRIEN : courses rapides le long tombant, plongées vers structures, sauts spectaculaires, résistance acharnée 15-40 minutes selon taille. Moins puissant que GT mais très combatif. Curieux : inspecte leurres. Intelligence marquée.",
            
            techniquesDetail: "TRAÎNE ZIG-ZAG tombants (5-8 nœuds) : technique CLASSIQUE efficace. Leurres 12-20 cm imitant fusiliers (bleu/jaune), bavettes moyennes, jigs rapides, petites jupes. Trajectoire ZIG-ZAG ou HUIT le long tombant = optimal (intercepte patrouilles). Profondeur 10-30m. LANCER structures très efficace : repérer carangues bleues chassant, lancer stickbaits 12-18 cm, poppers 12-16 cm, cuillers. Animation rapide saccadée. JIGGING vertical tombants EXCELLENT : jigs rapides 60-150g, descente rapide le long tombant, récupération saccadée ultra-rapide. Technique très productive ! Horaires : AUBE et FIN APRÈS-MIDI optimaux (migrations fusiliers). Ligne 20-35 kg. Bas de ligne fluoro 50-70 lb (abrasion scutelles). Spread traîne : Long/Short Corner. Combat : garder tension, pomper fermement. Gaffe ou épuisette si gros. NO-KILL possible (espèce robuste). ASTUCE PRO : repérer bancs fusiliers = trouver carangues bleues garanties ! Observer oiseaux marins plongeant = indicateur.",
            leuresSpecifiques: [
                "Bavettes 12-18 cm imitation fusiliers bleu/jaune (EXCELLENT)",
                "Jigs métalliques rapides 60-150g (jigging vertical ++)",
                "Poppers surface 12-16 cm",
                "Stickbaits 12-18 cm",
                "Cuillers argentées/bleutées",
                "Leurres souples 12-18 cm + têtes plombées",
                "Couleurs : bleu/jaune (imitation fusiliers ROI), rose, chartreuse, argenté",
                "Leurres ACTION RAPIDE obligatoires (carangue bleue = très rapide)"
            ],
            appatsNaturels: [
                "Fusiliers vivants (APPÂT ABSOLU)",
                "Petits maquereaux",
                "Sardines moyennes",
                "Anchois gros",
                "Calmars moyens"
            ],
            meilleursHoraires: "AUBE (6h-9h) : période OPTIMALE avec fusiliers remontant du fond ! FIN APRÈS-MIDI (16h-19h) : excellent également. CRÉPUSCULE (18h-20h) : productif. MATINÉE (9h-12h) : correct si fusiliers actifs. APRÈS-MIDI (13h-16h) : moins actif mais possible. Synchronisation avec migrations verticales fusiliers = CLÉ succès.",
            conditionsOptimales: "Présence TOMBANTS ABRUPTS avec fusiliers abondants. Passes profondes courants actifs. Zones transitions plateau/tombant. Eau claire 24-30°C. TRAÎNE ZIG-ZAG le long tombant : 5-8 nœuds, leurres 12-20 cm imitation fusiliers (bleu/jaune), profondeur 10-30m. LANCER si chasses visibles : stickbaits/poppers 12-18 cm. JIGGING vertical : jigs 60-150g descente rapide, récupération ultra-rapide saccadée. Ligne 20-35 kg. Bas de ligne fluoro 50-70 lb. AUBE et FIN APRÈS-MIDI = horaires clés synchronisés migrations fusiliers. Repérer bancs fusiliers (oiseaux, remous) = localiser carangues bleues.",
            
            qualiteCulinaire: "Chair de qualité BONNE à TRÈS BONNE. Texture ferme agréable. Saveur délicate. Chair BLANCHE à rosée. Grain moyen. Meilleure que GT ! Usages : Sashimi/Ceviche (frais excellents), Grillades, Filets poêlés, Currys, Fumage. Prix modéré marchés locaux (15-30€/kg). Assez recherché restauration. Saignée immédiate recommandée. Mise sur glace rapide. Filetage facile. Rendement correct (65% chair). Valeur culinaire ET sportive équilibrée. Chair appréciée consommateurs.",
            risqueCiguatera: .modere,
            ciguateraDetail: "Risque MODÉRÉ selon zones et taille. Carangue bleue = prédateur récifal/tombants accumulant toxines modérément. RÈGLES PRUDENCE : éviter spécimens > 10 kg zones récifales connues à risque. Carangues bleues 3-8 kg : risque FAIBLE à MODÉRÉ. Petites carangues bleues < 3 kg : risque FAIBLE. Carangues bleues TOMBANTS EXTERNES généralement plus sûres que récifs frangeants. SE RENSEIGNER LOCALEMENT zones problématiques. En cas doute : privilégier petits/moyens < 5 kg. Carangue bleue généralement considérée moins risquée que GT mais prudence nécessaire.",
            
            reglementationNC: "Pas de taille minimale légale spécifique carangue bleue actuellement NC. Pêche récréative libre quantités raisonnables. Respecter règles générales zones protégées. Espèce non menacée localement mais surveillance populations. NO-KILL encouragé gros spécimens (> 8 kg). Prélèvement raisonnable petits/moyens acceptable consommation.",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation raisonnable encouragée. Prélever uniquement quantités consommation personnelle. Relâcher gros spécimens (> 8 kg) recommandé. Espèce relativement abondante ne nécessite pas restrictions strictes actuellement.",
            zonesInterdites: "Aucune zone spécifiquement interdite carangue bleue. Respecter zones marines protégées générales, réserves intégrales. Certains tombants peuvent avoir recommandations locales (vérifier).",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations globalement STABLES. Espèce largement distribuée Indo-Pacifique tropical. Croissance modérée, maturité 3-4 ans, reproduction régulière, longévité 15-20 ans = résilience correcte. Stocks généralement bons. Pression pêche modérée (espèce secondaire après GT). Surveillance continue recommandée zones forte fréquentation. Gestion locale via sensibilisation bonnes pratiques et protection tombants.",
            
            leSaviezVous: "La Carangue bleue est LE SPÉCIALISTE des fusiliers ! Suit migrations verticales quotidiennes proies : fusiliers descendent 50-60m JOUR (protection lumière), remontent 10-20m AUBE/CRÉPUSCULE (plancton). Carangues bleues suivent exactement = adaptation écologique fascinante ! Record taille : 100 cm, 18 kg (rare). En NC : spécimens 3-10 kg courants, 12-15 kg beaux poissons. Nom 'melampygus' = 'à fesses noires' grec (référence pédoncule sombre certains individus). Nom français 'aile bleue' vient NAGEOIRES BLEU VIF spectaculaires ! Coloration bleu ÉLECTRIQUE s'intensifie quand excité ou agressif. Certains pêcheurs considèrent carangue bleue PLUS BELLE que GT ! Combat spectaculaire : enchaîne 3-5 sauts acrobatiques hors eau le long tombant. Vitesse 65 km/h = très rapide. Carangue bleue INDICATEUR santé récifs : abondance = tombant sain avec fusiliers nombreux. Technique JIGGING ultra-rapide tombants = spécialité Japon/Australie pour carangue bleue : jig 100g descendu 40m, remonté 30m en 10 secondes = excitation maximale ! Fusiliers constituent 85% régime alimentaire = dépendance quasi-totale ! Carangues bleues chassent parfois avec thons jaunes sur mêmes bancs fusiliers. Juvéniles ont points bleus ENCORE PLUS brillants que adultes. Espèce peut former groupes mixtes avec autres carangues (ignobilis, lugubris). ASTUCE : traîne trajectoire HUIT perpendiculaire tombant = traverse zones patrouilles carangues bleues à différentes profondeurs !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // CARANGUE PAILLETÉE - Carangoides fulvoguttatus
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "caranguePailletee",
            nomCommun: "Carangue pailletée",
            nomScientifique: "Carangoides fulvoguttatus",
            famille: "Carangidae",
            
            zones: [.lagon, .passe, .recif, .tombant],
            profondeurMin: 5,
            profondeurMax: 50,
            
            typesPecheCompatibles: [.traine, .lancer],
            
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 7.0,
                vitesseOptimale: 5.5,
                profondeurNageOptimale: "5-20m",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 18.0,
                typesLeurresRecommandes: ["bavette", "jupe petite", "stickbait", "cuiller"],
                couleursRecommandees: ["orange", "cuivré", "doré", "argenté", "naturel"],
                positionsSpreadRecommandees: [.longCorner, .shortRigger],
                notes: "Carangue côtière élégante. Leurres COULEURS CUIVRÉES/ORANGÉES imitant livrée naturelle excellents. Taches noires adultes = identification."
            ),
            
            comportement: "Chasseur actif zones récifales et lagonaires, groupes mobiles",
            momentsFavorables: [.aube, .matinee, .apresMidi, .crepuscule],
            
            photoNom: "CaranguePointsJaunes_photo",
            illustrationNom: nil,
            signesDistinctifs: "Livrée argentée PARSEMÉE de NOMBREUX PETITS POINTS CUIVRÉS/ORANGE sur flancs = signature visuelle magnifique et unique ! Chez ADULTES de grande taille (> 80 cm), apparition de 3 à 4 TACHES NOIRES caractéristiques sur flancs (absentes juvéniles). Barres sombres fugaces parfois visibles sur flancs. Corps comprimé latéralement modéré, élégant. Ligne latérale arquée avec scutelles. Caudale en croissant. Taille moyenne : 50-90 cm. Juvéniles : corps argenté brillant avec points cuivrés déjà présents mais pas de taches noires. Nageoires teintées orange/jaunâtre. Tache noire sur opercule. Taille max 120 cm !",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 120.0,
            poidsMaxObserve: 18.0,
            descriptionPhysique: "Carangue de grande taille à morphologie élégante. Corps comprimé latéralement modérément profond. Profil harmonieux ovale. Bouche oblique moyenne avec mâchoires modérées. Dents fines. Œil moyen. Ligne latérale arquée antérieurement puis droite, bordée scutelles osseuses développées sur moitié postérieure. Deux dorsales : première courte épineuse (8 épines) rétractable, seconde longue molle (19-22 rayons). Anale similaire seconde dorsale. Pectorales falciformes. Caudale profondément fourchue puissante. Pédoncule caudal robuste. Coloration ÉLÉGANTE : corps argenté brillant PARSEMÉ de NOMBREUX PETITS POINTS CUIVRÉS/ORANGE sur flancs créant effet pailleté décoratif, ventre blanc argenté. Chez ADULTES > 80 cm : 3-4 TACHES NOIRES prononcées apparaissent sur flancs = diagnostic maturité. Barres verticales sombres fugaces parfois présentes. Nageoires teintées orange/jaunâtre. Tache noire opercule.",
            
            habitatDescription: "Espèce CÔTIÈRE et LAGONAIRE fréquentant habitats variés peu profonds à moyens. Lagon : zones ouvertes, chenaux profonds, patates coralliennes isolées. Récifs frangeants : platiers externes, zones herbiers adjacents. Passes : zones courants modérés. Tombants côtiers peu profonds (5-30m). Préfère eaux claires tropicales 24-30°C. Comportement : petits groupes mobiles (3-10 individus) ou solitaires (gros adultes). Patrouilles régulières le long structures lagonaires. Juvéniles zones protégées (baies, herbiers). Sub-adultes zones plus ouvertes. Adultes patrouillent large gamme habitats côtiers. Espèce résidente mais mobile localement. Présence marquée zones transitions lagon/récif.",
            comportementDetail: "Prédateur actif chassant proies variées. Vitesse pointe : 60 km/h. Technique chasse : patrouille active puis charge rapide. Régime : petits poissons récifaux (fusiliers, sardines, anchois), calmars, crustacés, invertébrés. Pic activité : AUBE (6h-9h) très bon, MATINÉE (9h-12h) productif, APRÈS-MIDI (14h-17h) correct, CRÉPUSCULE (17h-20h) bon. Chasse en petits groupes coordonnés parfois. Attaque leurres RAPIDEMENT : touche vive caractéristique. Combat SPORTIF : courses rapides, résistance soutenue, quelques sauts possibles, 10-25 minutes selon taille. Moins puissant que GT ou carangue bleue mais combatif. Curieux : suit leurres, inspecte avant attaquer. Comportement social : interactions vocales possibles entre individus groupe.",
            
            techniquesDetail: "TRAÎNE moyenne (4-7 nœuds) : technique principale. Leurres 10-18 cm imitant petits poissons, bavettes, petites jupes, stickbaits. Couleurs CUIVRÉES/ORANGÉES (imitation livrée naturelle) excellentes, aussi argenté/naturel. Profondeur 5-20m. Lagon : traîne 4-6 nœuds le long chenaux. Passes : 5-7 nœuds. Trajectoire le long structures lagonaires productive. LANCER également efficace : stickbaits 12-16 cm, cuillers, poppers moyens. Repérer groupes patrouille ou chasses, lancer, animation rapide. Horaires : AUBE et MATINÉE optimaux. Ligne 15-25 kg. Bas de ligne fluoro 40-60 lb (scutelles). Spread traîne : Long Corner, Short Rigger. Combat : garder tension, pomper régulièrement. Épuisette si taille moyenne. NO-KILL possible (robuste). Pêche zones transitions lagon/récif productive.",
            leuresSpecifiques: [
                "Bavettes 12-16 cm couleurs cuivrées/orangées (EXCELLENT)",
                "Petites jupes 5-7 pouces teintes orange/doré",
                "Stickbaits 12-16 cm",
                "Cuillers argentées/cuivrées",
                "Poppers surface 12-15 cm",
                "Leurres souples 12-16 cm teintes naturelles",
                "Couleurs : CUIVRÉ/ORANGE (imitation ++), doré, argenté, naturel",
                "Leurres action modérée à rapide"
            ],
            appatsNaturels: [
                "Petits poissons vivants (sardines, fusiliers petits)",
                "Anchois",
                "Calmars moyens",
                "Crevettes grosses",
                "Petits mulets"
            ],
            meilleursHoraires: "AUBE (6h-9h) : période très productive. MATINÉE (9h-12h) : bon. APRÈS-MIDI (14h-17h) : correct. CRÉPUSCULE (17h-20h) : bon retour activité. Midi moins actif mais possible.",
            conditionsOptimales: "Zones lagon ouvertes avec structures. Passages entre patates. Chenaux profonds. Eau claire 24-30°C. TRAÎNE 4-7 nœuds : leurres 10-18 cm couleurs CUIVRÉES/ORANGÉES, profondeur 5-20m. LANCER si groupes repérés : stickbaits/cuillers 12-16 cm. Ligne 15-25 kg. Bas de ligne fluoro 40-60 lb. Positions Long Corner, Short Rigger. AUBE et MATINÉE = horaires meilleurs. Zones transitions lagon/récif favorables.",
            
            qualiteCulinaire: "Chair de qualité BONNE. Texture ferme agréable. Saveur correcte. Chair BLANCHE à rosée pâle. Grain moyen. Usages : Filets frais (grillades, poêlés), Currys, Ceviche (frais), Fumage possible. Prix modéré marchés locaux (12-25€/kg). Demande modérée. Saignée immédiate recommandée. Mise sur glace. Filetage facile. Rendement correct (65% chair). Valeur culinaire correcte et sportive.",
            risqueCiguatera: .modere,
            ciguateraDetail: "Risque MODÉRÉ selon zones et taille. Carangue pailletée = prédateur côtier/récifal accumulant toxines modérément. RÈGLES PRUDENCE : éviter gros spécimens (> 10 kg) zones récifales connues à risque. Carangues pailletées moyennes 3-8 kg : risque FAIBLE à MODÉRÉ. Petites < 3 kg : risque FAIBLE. Lagonaires généralement plus sûres que récifales. SE RENSEIGNER LOCALEMENT zones problématiques. En cas doute : privilégier petits/moyens < 5 kg. Espèce généralement moins risquée que GT mais prudence.",
            
            reglementationNC: "Pas de taille minimale légale spécifique carangue pailletée actuellement NC. Pêche récréative libre quantités raisonnables. Respecter règles générales zones protégées. Espèce non menacée localement. Prélèvement raisonnable acceptable consommation personnelle.",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation raisonnable encouragée. Prélever uniquement quantités consommation. Espèce relativement abondante.",
            zonesInterdites: "Aucune zone spécifiquement interdite carangue pailletée. Respecter zones marines protégées générales, réserves intégrales.",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations globalement STABLES. Espèce distribuée Indo-Pacifique tropical. Croissance modérée, maturité 3-4 ans, reproduction régulière, longévité 12-18 ans = résilience correcte. Stocks généralement bons. Pression pêche faible à modérée (espèce secondaire).",
            
            leSaviezVous: "La Carangue pailletée tire son nom de ses MAGNIFIQUES POINTS CUIVRÉS qui créent un effet PAILLETÉ décoratif sur ses flancs argentés ! Record taille : 120 cm, 18 kg. En NC : spécimens 3-8 kg courants, 10-15 kg beaux poissons. Nom scientifique 'fulvoguttatus' = 'à gouttes fauves/rousses' latin = référence directe aux points cuivrés ! Chez ADULTES > 80 cm apparaissent 3-4 TACHES NOIRES sur flancs = signe maturité et permettant différenciation avec juvéniles. Juvéniles ont déjà points cuivrés caractéristiques mais pas taches noires. Coloration cuivrée peut varier en intensité selon excitation : points deviennent plus brillants quand poisson excité ! Certains pêcheurs utilisent leurres COULEURS CUIVRÉES/ORANGÉES spécifiquement pour carangues pailletées = imitation livrée naturelle très efficace. Espèce peut former groupes mixtes avec autres carangues (ignobilis, melampygus, autres Carangoides). Combat vif : courses 30-50m, résistance soutenue 15-25 minutes. Chair correcte consommation mais prudence ciguatera gros spécimens zones récifales. Nom anglais 'Yellowspotted Trevally' ou 'Turrum' (Australie). Points cuivrés ressemblent à paillettes dorées sous lumière solaire = très beau poisson !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // CARANGUE JOUE BARRÉE - Carangoides orthogrammus
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "carangueJoueBarree",
            nomCommun: "Carangue joue barrée",
            nomScientifique: "Carangoides orthogrammus",
            famille: "Carangidae",
            
            zones: [.lagon, .passe, .recif],
            profondeurMin: 3,
            profondeurMax: 35,
            
            typesPecheCompatibles: [.traine, .lancer],
            
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 6.5,
                vitesseOptimale: 5.0,
                profondeurNageOptimale: "3-15m",
                tailleLeurreMin: 8.0,
                tailleLeurreMax: 16.0,
                typesLeurresRecommandes: ["bavette petite", "jupe petite", "stickbait", "cuiller"],
                couleursRecommandees: ["argenté", "naturel", "blanc", "rose pâle"],
                positionsSpreadRecommandees: [.shortRigger, .shotgun],
                notes: "Petite carangue côtière. Ligne noire OPERCULE = signature ! Leurres PETITS obligatoires. Espèce grégaire groupes actifs."
            ),
            
            comportement: "Chasseur actif zones côtières peu profondes, groupes mobiles",
            momentsFavorables: [.aube, .matinee, .apresMidi],
            
            photoNom: "CarangueJouesBarrees_photo",
            illustrationNom: nil,
            signesDistinctifs: "Livrée argentée brillante élégante. OPERCULE BORDÉ D'UNE LIGNE NOIRE PRONONCÉE = signature visuelle ABSOLUE unique parmi carangues ! Cette ligne noire distinctive part du haut de l'opercule et descend le long du bord = identification immédiate garantie ! Corps comprimé latéralement élancé. Ligne latérale arquée avec scutelles. Caudale en croissant modérée. Taille PETITE à MOYENNE : 20-35 cm courant. Corps argenté uniforme sans motifs complexes (pas de points ni taches). Silhouette harmonieuse. Taille max 45 cm (rare, spécimens 25-35 cm typiques).",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 45.0,
            poidsMaxObserve: 1.5,
            descriptionPhysique: "Petite carangue à morphologie élancée élégante. Corps comprimé latéralement modérément profond. Profil arrondi harmonieux. Bouche oblique petite avec mâchoires fines. Dents petites fines. Œil moyen proportionné. Ligne latérale arquée antérieurement puis droite, bordée scutelles osseuses sur partie postérieure. Deux dorsales : première courte épineuse (8 épines) rétractable, seconde longue molle (19-21 rayons). Anale similaire seconde dorsale. Pectorales falciformes. Caudale fourchue modérée. Pédoncule caudal fin. Coloration SIMPLE et ÉLÉGANTE : corps argenté brillant UNIFORME, ventre blanc argenté. LIGNE NOIRE PRONONCÉE sur bord OPERCULE = signature diagnostic unique ! Pas de points, taches ou motifs complexes. Nageoires translucides à légèrement grisâtres. Aspect général épuré argenté.",
            
            habitatDescription: "Espèce CÔTIÈRE stricte fréquentant habitats peu profonds. Lagon : zones ouvertes peu profondes (3-15m), chenaux lagonaires, herbiers adjacents récifs. Récifs frangeants : platiers externes peu profonds, zones transition herbiers/récif. Passes : zones calmes à courants faibles. Préfère fonds sableux à sablo-vaseux avec structures éparses. Eaux claires tropicales 24-30°C. Comportement : GROUPES ACTIFS (5-20 individus) mobiles. Bancs parfois importants (50+ individus) zones favorables. Patrouilles régulières le long zones côtières. Juvéniles zones très protégées (baies, herbiers denses). Adultes zones plus ouvertes mais restent côtiers. Espèce résidente habitats côtiers. Rarement en zones profondes ou hauturières.",
            comportementDetail: "Prédateur actif chassant proies variées petite taille. Vitesse pointe : 55 km/h. Technique chasse : patrouille en groupes coordonnés, charges simultanées sur bancs petits poissons. Régime : petits poissons côtiers (anchois, sardines juvéniles, athérines), crevettes, petits crabes, invertébrés. Pic activité : AUBE (6h-9h) très bon, MATINÉE (9h-12h) bon, APRÈS-MIDI (13h-16h) correct. Crépuscule moins actif. Chasse COOPÉRATIVE en groupes : encerclent proies, attaques coordonnées. Attaque leurres RAPIDEMENT mais touche moins violente que grandes carangues (petite taille). Combat SPORTIF proportionnel taille : courses rapides courtes, résistance vive 5-15 minutes. Moins puissant que autres carangues mais combatif. Comportement grégaire marqué : rarement solitaires. Interactions sociales groupe nombreuses.",
            
            techniquesDetail: "TRAÎNE lente (4-6.5 nœuds) : technique principale. Leurres PETITS 8-16 cm obligatoires (grande bouche refuse gros leurres), petites bavettes, mini-jupes 4-5 pouces, petits stickbaits. Couleurs argentées/naturelles/blanc. Profondeur 3-15m. Lagon : traîne 4-5 nœuds zones peu profondes. Passes : 5-6.5 nœuds. Trajectoire zones côtières productive. LANCER très efficace : petits stickbaits 10-14 cm, cuillers, mini-poppers. Repérer groupes actifs, lancer, animation rapide. Horaires : AUBE et MATINÉE optimaux. Ligne 10-15 kg (légère suffisante). Bas de ligne fluoro 20-30 lb. Spread traîne : Short Rigger, Shotgun (positions proches bateau). Combat : légère tension suffit (petite taille). Épuisette ou main. NO-KILL facile (robuste). Pêche zones herbiers/récifs peu profonds productive. ATTENTION : petite bouche refuse leurres > 16 cm !",
            leuresSpecifiques: [
                "Petites bavettes 8-14 cm (OBLIGATOIRE taille réduite)",
                "Mini-jupes 4-5 pouces",
                "Petits stickbaits 10-14 cm",
                "Cuillers petites argentées",
                "Mini-poppers surface 8-12 cm",
                "Leurres souples 8-12 cm fins",
                "Couleurs : ARGENTÉ (imitation ++), blanc, naturel, rose pâle",
                "Leurres action rapide légère"
            ],
            appatsNaturels: [
                "Petits poissons vivants (anchois, athérines)",
                "Petites crevettes",
                "Petits crabes mous",
                "Vers marins"
            ],
            meilleursHoraires: "AUBE (6h-9h) : période très productive. MATINÉE (9h-12h) : bon. APRÈS-MIDI (13h-16h) : correct. Crépuscule moins actif. Midi possible.",
            conditionsOptimales: "Zones lagon côtières peu profondes. Herbiers avec structures. Chenaux peu profonds. Eau claire 24-30°C. TRAÎNE lente 4-6.5 nœuds : leurres PETITS 8-16 cm argentés/naturels, profondeur 3-15m. LANCER si groupes repérés : petits stickbaits/cuillers 10-14 cm. Ligne légère 10-15 kg. Bas de ligne fluoro 20-30 lb. Positions Short Rigger, Shotgun. AUBE et MATINÉE = horaires meilleurs. Zones côtières protégées favorables.",
            
            qualiteCulinaire: "Chair de qualité CORRECTE. Texture ferme. Saveur correcte. Chair BLANCHE. Grain fin. PETITE TAILLE limite intérêt culinaire (rendement faible). Usages : Filets frais si quantité suffisante, Friture entière (petits spécimens), Currys, Soupe poisson. Prix faible marchés locaux (5-12€/kg). Demande faible (petite taille). Saignée rapide. Filetage difficile (petite taille). Rendement faible (55% chair). Valeur PRINCIPALEMENT SPORTIVE. Souvent relâchée. Consommation occasionnelle acceptable.",
            risqueCiguatera: .faible,
            ciguateraDetail: "Risque FAIBLE. Carangue joue barrée = petite carangue côtière peu profonde accumulant peu toxines. PETITE TAILLE (< 45 cm max) = faible accumulation toxines. Habitat côtier peu profond herbiers/sable = zones généralement moins risquées. Régime alimentaire bas chaîne alimentaire (petits poissons, invertébrés). Espèce généralement considérée SÛRE consommation. Prudence reste recommandée zones récifales connues problématiques. Privilégier spécimens zones herbiers/lagon ouvert.",
            
            reglementationNC: "Pas de taille minimale légale spécifique carangue joue barrée NC. Pêche récréative libre quantités raisonnables. Respecter règles générales zones protégées. Espèce non menacée localement. PETITE TAILLE favorise naturellement NO-KILL. Prélèvement occasionnel acceptable.",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation raisonnable encouragée. PETITE TAILLE rend prélèvement peu intéressant. NO-KILL pratique courante. Espèce abondante.",
            zonesInterdites: "Aucune zone spécifiquement interdite carangue joue barrée. Respecter zones marines protégées générales, réserves intégrales.",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern). Populations globalement STABLES et ABONDANTES. Espèce distribuée Indo-Pacifique tropical. Croissance rapide, maturité précoce 2-3 ans, reproduction régulière, longévité 8-12 ans = résilience ÉLEVÉE. Stocks bons. Pression pêche TRÈS FAIBLE (petite taille, faible intérêt commercial). Espèce robuste ne nécessitant pas mesures conservation spécifiques.",
            
            leSaviezVous: "La Carangue joue barrée tire son nom de sa LIGNE NOIRE PRONONCÉE sur l'opercule = signature unique permettant identification immédiate ! C'est la SEULE carangue avec cette marque distinctive opercule ! Record taille : 45 cm, 1.5 kg (rare). En NC : spécimens 20-35 cm très courants. Nom scientifique 'orthogrammus' = 'à ligne droite' grec = référence ligne noire opercule ! Comportement GRÉGAIRE marqué : rarement observée solitaire, toujours en groupes 5-20+ individus. Groupes peuvent former bancs massifs 100+ individus zones très favorables ! PETITE BOUCHE limite taille leurres acceptés : leurres > 16 cm systématiquement refusés. Combat proportionnel taille : courses rapides 10-20m, résistance vive 5-15 minutes. Espèce ROBUSTE : survie excellente après relâche = parfaite pour NO-KILL. Juvéniles ont déjà ligne noire opercule caractéristique visible dès 5-8 cm ! Certains pêcheurs considèrent carangue joue barrée EXCELLENTE espèce initiation enfants/débutants : abondante, mord facilement, combat sportif adapté matériel léger. Chasse coopérative : groupes encerclent bancs athérines/anchois, attaques simultanées créant remous spectaculaires surface. Nom anglais 'Island Trevally' ou 'Yellowtail Trevally' (confusion possible autres espèces). Espèce peut former groupes mixtes avec autres petites carangues côtières. Habitat côtier peu profond rend espèce ACCESSIBLE pêcheurs bord/petites embarcations !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // BARRACUDAS / BÉCUNES
        // ─────────────────────────────────────────────────────────────────────
        
        // ═══════════════════════════════════════════════════════════════════════════
        // BARRACUDA - Sphyraena barracuda (ESPÈCE GÉANTE)
        // VERSION ENRICHIE COMPLÈTE
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "barracuda",
            nomCommun: "Barracuda",
            nomScientifique: "Sphyraena barracuda",
            famille: "Sphyraenidae",
            
            zones: [.lagon, .passe, .recif, .tombant, .hauturier],
            profondeurMin: 0,
            profondeurMax: 150,
            
            typesPecheCompatibles: [.traine, .lancer],
            
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "0-40m (surface à mi-eau)",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 25.0,
                typesLeurresRecommandes: ["stickbait long", "cuiller grande", "poisson nageur", "leurre souple fin"],
                couleursRecommandees: ["argenté", "naturel", "noir/pourpre (nuit)", "sombre"],
                positionsSpreadRecommandees: [.longCorner, .shortCorner, .shotgun],
                notes: "GÉANT famille Sphyraenidae ! PISCIVORE STRICT corps MASSIF. Imiter proies FINES grandes. Pic CRÉPUSCULE/NUIT = couleurs SOMBRES."
            ),
            
            comportement: "Prédateur apex embuscade et chasseur puissant, très actif crépuscule et nuit",
            momentsFavorables: [.crepuscule, .nuit, .aube],
            
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "LE GÉANT de la famille Sphyraenidae ! CORPS CYLINDRIQUE MASSIF ALLONGÉ en torpille IMPOSANTE = taille jusqu'à 170 cm ! MÂCHOIRE INFÉRIEURE PROÉMINENTE massive. GRANDE BOUCHE garnie de DENTS ACÉRÉES IMPRESSIONNANTES canines puissantes. Livrée argentée brillante. BARRES FUGACES sur flancs surtout vers CAUDALE = signature diagnostic barracuda géant ! TACHES NOIRES ÉPARSES généralement présentes sur BAS DU CORPS. POINTE BLANCHE caractéristique sur UNE OU PLUSIEURS NAGEOIRES = signe distinctif important ! Corps beaucoup plus MASSIF et IMPOSANT que bécunes (différence taille majeure). Caudale fourchue très puissante. Silhouette PRÉDATEUR APEX intimidante ! Aspect général : TORPEDO GÉANT REDOUTABLE.",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 170.0,
            poidsMaxObserve: 50.0,
            descriptionPhysique: "Poisson TRÈS ALLONGÉ CYLINDRIQUE à morphologie MASSIVE IMPOSANTE. Corps fusiforme en torpille géante. Tête massive pointue effilée. MÂCHOIRE INFÉRIEURE PROÉMINENTE dépassant largement supérieure. TRÈS GRANDE BOUCHE avec DENTS ACÉRÉES MASSIVES et NOMBREUSES (canines puissantes visibles même bouche fermée). Yeux moyens latéraux. Deux dorsales bien séparées : première courte épineuse (5 épines), seconde molle longue postérieure. Anale postérieure opposée seconde dorsale. Pectorales moyennes insérées bas. Caudale profondément fourchue TRÈS puissante. Corps recouvert petites écailles cycloides. Ligne latérale complète droite. Coloration : ARGENTÉE brillante dominante. Dos gris-bleuté, flancs argentés, ventre blanc argenté. BARRES FUGACES sur flancs surtout zone postérieure vers caudale. TACHES NOIRES ÉPARSES typiquement présentes sur bas du corps. POINTE BLANCHE caractéristique sur une ou plusieurs nageoires (souvent caudale, pectorales, première dorsale). Aspect général : GÉANT MASSIF IMPRESSIONNANT famille. Taille adulte typique 80-140 cm. Spécimens > 150 cm rares exceptionnels. Record 170 cm 50 kg.",
            
            habitatDescription: "Espèce UBIQUISTE occupant TOUS habitats côtiers à hauturiers peu profonds à moyens profonds. Lagon : zones ouvertes, chenaux profonds, patates isolées. Passes : zones courants forts, embouchures. Récifs frangeants : platiers externes, tombants. Tombants côtiers et hauturiers jusqu'à 150m. SURFACE à MI-EAU principalement (0-40m). Parfois hauturier pélagique. Préfère eaux claires tropicales 24-30°C. Comportement : SOLITAIRE strict adultes. Juvéniles petits groupes (2-4) parfois. Postes EMBUSCADE stratégiques : surplombs, épaves, patates, zones ombragées, tombants, DCP. Stationne IMMOBILE longues périodes puis CHARGE FULGURANTE. Juvéniles zones côtières protégées (baies, mangroves externes). Sub-adultes/adultes habitats plus variés incluant hauturier. Espèce résidente mais grande mobilité. Patrouilles étendues zones chasse. MIGRATION VERTICALE quotidienne : descend jour (repos profondeur), remonte CRÉPUSCULE/NUIT (chasse active surface). Présence marquée passes, tombants, zones transitions, DCP hauturiers.",
            comportementDetail: "PRÉDATEUR APEX EMBUSCADE ET CHASSEUR PUISSANT = stratégie double maximisant efficacité ! Technique 1 : EMBUSCADE - stationne IMMOBILE heures entières près structure, CHARGE ÉCLAIR ultra-violente sur proie (accélération 0-70 km/h en 0.8 seconde !). Technique 2 : CHASSE ACTIVE - patrouille rapide puissante, poursuite proies longues distances. Vitesse pointe : 70 km/h. Vitesse croisière : 25-35 km/h. Régime : PISCIVORE STRICT 100% exclusivement ! Poissons moyens à grands (mulets, sardines, maquereaux, bonites juvéniles, aiguillettes, fusiliers, carangues petites), calmars moyens. SÉLECTIVITÉ MORPHOLOGIQUE modérée : préfère proies allongées mais accepte formes variées grâce grande bouche. Pic activité : CRÉPUSCULE (17h-20h) OPTIMAL ++, NUIT (20h-6h) EXCELLENT ++, AUBE (5h-8h) très bon. JOUR (8h-17h) moins actif (embuscade passive). Comportement nocturne MARQUÉ = adaptation chasse faible luminosité supérieure. Attaque leurres ULTRA-VIOLEMMENT : touche EXPLOSIVE dévastatrice caractéristique. Combat SPECTACULAIRE PUISSANT : courses rapides longues 100-200m, sauts acrobatiques IMPRESSIONNANTS 2-3m hors eau, résistance acharnée 30-60 minutes. TRÈS combatif proportionnellement taille = fish TROPHÉE ! DENTS ACÉRÉES MASSIVES coupent bas de ligne facilement : câble métallique moyen/épais ou fluoro très épais OBLIGATOIRE. Comportement solitaire strict adultes (pas grégaire). Territorialité marquée postes embuscade favoris. CURIOSITÉ envers plongeurs/nageurs (rares attaques si provocations). Réputé INTELLIGENT et MÉFIANT (gros adultes ultra-prudents).",
            
            techniquesDetail: "TRAÎNE lente à moyenne (4-8 nœuds) : technique principale. Leurres LONGS 15-25 cm imitant mulets/maquereaux (morphologie allongée préférée), stickbaits, grosses cuillers, gros poissons nageurs, leurres souples fins. Couleurs ARGENTÉES/naturelles JOUR. Couleurs SOMBRES (noir, pourpre, bleu foncé) CRÉPUSCULE/NUIT = silhouette marquée (CRUCIAL). Profondeur 0-40m (surface à mi-eau). LANCER EXCELLENT technique : gros stickbaits 15-22 cm, grosses cuillers, leurres souples fins gros. Zones structures, passes, tombants, DCP. Animation RAPIDE SACCADÉE + PAUSES (déclencheur). HORAIRES CRITIQUES : CRÉPUSCULE et NUIT = périodes OPTIMALES ABSOLUES ! Jour moins productif (embuscade passive). Ligne PUISSANTE 25-40 kg obligatoire (taille). BAS DE LIGNE : CÂBLE métallique moyen (20-30 lb) ou FLUORO TRÈS épais (80-120 lb) OBLIGATOIRE = dents massives coupent tout ! Spread traîne : Long/Short Corner, Shotgun. Combat : tension FORTE, pompage PUISSANT, ATTENTION sauts spectaculaires dévastateurs (décroches fréquentes si tension faible). Gaffe SOLIDE obligatoire. MANIPULATION EXTRÊMEMENT PRUDENTE : dents TRÈS DANGEREUSES (gants épais LOURDS + pince longue OBLIGATOIRES, risque blessures SÉVÈRES). ASTUCE PRO : leurres pauses irrégulières = déclencheur optimal barracuda (imite poisson blessé). Pêche NUIT DCP avec leurres sombres = technique ultra-productive trophées !",
            leuresSpecifiques: [
                "Stickbaits LONGS 15-25 cm (EXCELLENT)",
                "Grosses cuillers allongées argentées",
                "Gros poissons nageurs profil effilé",
                "Leurres souples fins grands 15-22 cm",
                "Poppers allongés grands surface",
                "Rapala/Yo-Zuri modèles GRANDS fins",
                "Couleurs JOUR : ARGENTÉ, naturel, blanc brillant",
                "Couleurs CRÉPUSCULE/NUIT : NOIR, pourpre, bleu foncé (silhouette ++)",
                "ACTION RAPIDE avec PAUSES obligatoire"
            ],
            appatsNaturels: [
                "Mulets moyens/grands vivants (APPÂT ROI)",
                "Maquereaux moyens",
                "Grosses sardines",
                "Aiguillettes grandes",
                "Bonites juvéniles",
                "Calmars moyens/grands",
                "Poissons vivants allongés grands (morphologie importante)"
            ],
            meilleursHoraires: "CRÉPUSCULE (17h-20h) : période OPTIMALE ABSOLUE ++ ! NUIT (20h-6h) : EXCELLENT ++ ! AUBE (5h-8h) : très bon. JOUR (8h-17h) : correct (embuscade passive, moins actif). Barracuda = ESPÈCE CRÉPUSCULAIRE/NOCTURNE MARQUÉE typique. Synchroniser sorties pêche avec ces horaires = succès trophées garanti.",
            conditionsOptimales: "Zones structures (épaves, surplombs, patates grandes, DCP). Passes courants forts. Tombants. Eaux claires 24-30°C. TRAÎNE 4-8 nœuds : leurres LONGS 15-25 cm, couleurs ARGENTÉES jour, SOMBRES crépuscule/nuit, profondeur 0-40m. LANCER structures : gros stickbaits/cuillers 15-22 cm animation rapide + pauses. Ligne PUISSANTE 25-40 kg. BAS DE LIGNE CÂBLE métallique moyen 20-30 lb ou FLUORO TRÈS épais 80-120 lb OBLIGATOIRE (dents massives). Positions Long/Short Corner, Shotgun. HORAIRES : CRÉPUSCULE et NUIT ABSOLUMENT CRITIQUES ! Pêche nuit DCP leurres sombres = technique optimale trophées.",
            
            qualiteCulinaire: "Chair de qualité VARIABLE fortement selon taille. Petits barracudas (< 5 kg) : chair CORRECTE acceptable. Barracudas moyens (5-15 kg) : chair MÉDIOCRE, texture ferme/dure. GROS barracudas (> 15 kg) : chair MAUVAISE, texture très dure, saveur forte désagréable. Texture FERME à TRÈS FERME. Saveur correcte à forte. Chair BLANCHE. Grain grossier. Arêtes nombreuses. Usages : Filets grillés/poêlés (petits), Fumage (petits), Currys épicés. Prix faible marchés locaux (5-15€/kg). Demande TRÈS faible. Saignée immédiate si prélèvement. Filetage difficile (arêtes). Rendement faible (55% chair). Valeur QUASI-EXCLUSIVEMENT SPORTIVE ! Chair généralement peu appréciée. NOMBREUX pêcheurs pratiquent NO-KILL SYSTÉMATIQUE (trophée sportif + risque ciguatera).",
            risqueCiguatera: .treseleve,
            ciguateraDetail: "Risque TRÈS ÉLEVÉ À EXTRÊME selon zones et taille ! ATTENTION CRITIQUE MAXIMALE : Barracuda = PRÉDATEUR APEX récifal accumulant TOXINES AU MAXIMUM NIVEAU CHAÎNE ALIMENTAIRE ! RÈGLES STRICTES ABSOLUES IMPÉRATIVES : JAMAIS JAMAIS consommer barracudas > 3 kg (risque EXTRÊME). Barracudas 1-3 kg : risque TRÈS ÉLEVÉ, extrême prudence. Petits barracudas < 1 kg : risque ÉLEVÉ. TOUTES TAILLES peuvent être HAUTEMENT TOXIQUES zones récifales. Barracudas hauturiers pélagiques généralement plus sûrs MAIS risque reste ÉLEVÉ. SE RENSEIGNER IMPÉRATIVEMENT ET FORMELLEMENT localement avant TOUTE consommation. En NC : barracudas considérés ESPÈCE À TRÈS HAUT RISQUE par autorités sanitaires. TRÈS NOMBREUX CAS GRAVES ciguatera barracudas rapportés ANNUELLEMENT. Certaines zones NC barracudas SYSTÉMATIQUEMENT TOXIQUES. En cas MOINDRE doute : NE JAMAIS CONSOMMER ! PRIVILÉGIER FORTEMENT NO-KILL SYSTÉMATIQUE. Ciguatera barracudas peut être TRÈS SÉVÈRE À POTENTIELLEMENT MORTELLE. ESPÈCE À NE PAS CONSOMMER SAUF CERTITUDE ABSOLUE (rare). Barracuda = POISSON TROPHÉE SPORTIF, PAS ALIMENTAIRE !",
            
            reglementationNC: "Pas de taille minimale légale spécifique barracuda actuellement NC. Pêche récréative libre quantités raisonnables. RECOMMANDATIONS SANITAIRES TRÈS FORTES : prudence EXTRÊME consommation (ciguatera très élevé). Respecter règles générales zones protégées. Espèce non menacée localement. NO-KILL TRÈS FORTEMENT ENCOURAGÉ (risque sanitaire extrême + valeur sportive trophée).",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation TRÈS FORTEMENT encouragée. PRIVILÉGIER NO-KILL SYSTÉMATIQUE (risque ciguatera extrême). Prélèvement déconseillé toutes tailles. Espèce abondante mais consommation dangereuse.",
            zonesInterdites: "Aucune zone spécifiquement interdite barracuda. Respecter zones marines protégées générales, réserves intégrales. ZONES À TRÈS HAUT RISQUE CIGUATERA : se renseigner IMPÉRATIVEMENT auprès autorités sanitaires locales avant toute consommation (déconseillé).",
            statutConservation: "Statut UICN : Quasi menacé (Near Threatened) - surveillance nécessaire. Populations globalement STABLES mais SURVEILLANCE accrue. Espèce largement distribuée zones tropicales/subtropicales mondiales. Croissance lente, maturité tardive 3-5 ans, reproduction régulière, longévité 15-20 ans = vulnérabilité modérée surpêche. Prédateur apex = rôle écologique CRUCIAL régulation populations proies. Stocks généralement corrects mais déclin local possible zones forte pression. Pression pêche modérée (consommation limitée ciguatera). Espèce nécessitant surveillance populations locales. Gestion via protection habitats et sensibilisation NO-KILL recommandée.",
            
            leSaviezVous: "Le Barracuda est LE GÉANT de la famille Sphyraenidae = cousin géant bécunes ! Morphologie hydrodynamique PARFAITE portée extrême : coefficient traînée minimal absolu, vitesse pointe 70 km/h, accélération 0-70 km/h en 0.8 seconde = performances ÉPOUSTOUFLANTES record famille ! DENTS ACÉRÉES MASSIVES redoutables : canines très puissantes + dents fines nombreuses = arsenal mortel proies. Mâchoire inférieure proéminente massive = adaptation morphologique permettant ouverture bouche ULTRA-rapide lors charges. Record mondial IGFA : 44 kg (Ghana 1952, controversé). Records fiables : 170 cm 50 kg. En NC : spécimens 10-25 kg courants, 30-40 kg beaux trophées, 45+ kg exceptionnels rares. Nom 'Barracuda' vient espagnol 'barracuda' = origine incertaine, peut-être 'barraco' (dent) ! Comportement CRÉPUSCULAIRE/NOCTURNE TRÈS marqué : vision adaptée faible luminosité supérieure, chasse optimale nuit totale. Combat SPECTACULAIRE LÉGENDAIRE : sauts acrobatiques 2-3m hors eau IMPRESSIONNANTS, courses rapides 100-200m puissantes, résistance acharnée 30-60 minutes = FISH TROPHÉE absolu ! CONFUSION possible avec bécunes grandes MAIS taille massive + barres fugaces + taches noires + pointe blanche nageoires = identification barracuda géant. Barracudas peuvent former AGRÉGATIONS temporaires zones très riches proies (rares, généralement solitaires stricts). Technique EMBUSCADE ultra-perfectionnée : immobilité absolue HEURES puis charge 0.3 seconde = proie AUCUNE chance ! DENTS coupent bas de ligne 40-50 lb instantanément = câble métallique 20-30 lb ou fluoro 80-120 lb ABSOLUMENT OBLIGATOIRE. Nombreux pêcheurs considèrent barracuda SUMMUM espèce sportive pêche nuit leurres sombres. Leurres NOIRS/POURPRES créent silhouette marquée contre ciel nocturne = déclencheur visuel OPTIMAL barracudas nuit ! CURIOSITÉ envers humains : barracudas suivent plongeurs/nageurs par curiosité (RARES attaques documentées, généralement provocations/erreurs identification). MANIPULATION EXTRÊMEMENT DANGEREUSE : dents causent blessures TRÈS SÉVÈRES profondes, infections graves fréquentes, risque permanent = gants LOURDS épais + pince LONGUE robuste + prudence MAXIMALE ABSOLUMENT OBLIGATOIRES ! Certains guides pêche recommandent NO-KILL SYSTÉMATIQUE barracudas = poisson TROPHÉE SPORTIF pur, valeur alimentaire quasi-nulle (ciguatera), rôle écologique apex crucial. Record personnel nombreux pêcheurs : barracuda 35+ kg = GRAAL absolu pêche côtière !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ═══════════════════════════════════════════════════════════════════════════
        // BÉCUNES - Sphyraena spp. (FICHE GÉNÉRIQUE)
        // VERSION ENRICHIE COMPLÈTE
        // Principales espèces NC : S. forsteri, S. jello, S. putnamae, S. qenie, S. obtusata
        // ═══════════════════════════════════════════════════════════════════════════

        EspeceInfo(
            identifiant: "becunes",
            nomCommun: "Bécunes (espèces diverses)",
            nomScientifique: "Sphyraena spp.",
            famille: "Sphyraenidae",
            
            zones: [.lagon, .passe, .recif, .tombant],
            profondeurMin: 1,
            profondeurMax: 100,
            
            typesPecheCompatibles: [.traine, .lancer],
            
            traineInfo: TraineInfo(
                vitesseMin: 4.0,
                vitesseMax: 8.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "0-30m (surface à mi-eau)",
                tailleLeurreMin: 10.0,
                tailleLeurreMax: 20.0,
                typesLeurresRecommandes: ["stickbait", "cuiller", "poisson nageur fin", "leurre souple fin"],
                couleursRecommandees: ["argenté", "naturel", "noir/pourpre (nuit)", "sombre"],
                positionsSpreadRecommandees: [.longCorner, .shortCorner, .shotgun],
                notes: "PISCIVORE STRICT corps ALLONGÉ ! Imiter proies FINES (aiguillettes). Pic CRÉPUSCULE/NUIT = couleurs SOMBRES obligatoires silhouette."
            ),
            
            comportement: "Prédateur embuscade et chasseur rapide, actif crépuscule et nuit",
            momentsFavorables: [.crepuscule, .nuit, .aube],
            
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "CORPS CYLINDRIQUE TRÈS ALLONGÉ en forme de TORPILLE = signature absolue famille ! MÂCHOIRE INFÉRIEURE PROÉMINENTE caractéristique dépassant supérieure. GRANDE BOUCHE garnie de DENTS ACÉRÉES impressionnantes visibles même bouche fermée ! Livrée argentée brillante. Identification espèces par motifs : S. forsteri (20 barres verticales courtes + reflets jaunes nageoires), S. jello (tache noire base pectorales + dorsale/anale sombres extrémités blanches), S. putnamae (barres CHEVRON prononcées + caudale sombre), S. qenie (18-22 barres rectilignes + caudale bordée noir), S. obtusata (2 bandes longitudinales brunes + reflets jaunes caudale). Tailles : 55-160 cm selon espèces. Corps hydrodynamique parfait. Caudale fourchue puissante. Yeux moyens. Silhouette prédateur pur !",
            
            tailleMinLegale: nil,
            tailleMaxObservee: 160.0,
            poidsMaxObserve: 25.0,
            descriptionPhysique: "Poissons ALLONGÉS CYLINDRIQUES à morphologie HYDRODYNAMIQUE extrême. Corps fusiforme en torpille parfaite. Tête pointue effilée. MÂCHOIRE INFÉRIEURE PROÉMINENTE dépassant largement supérieure = signe diagnostic. GRANDE BOUCHE avec DENTS ACÉRÉES NOMBREUSES et VISIBLES (canines puissantes). Yeux moyens latéraux. Deux dorsales bien séparées : première courte épineuse (5 épines), seconde molle longue postérieure. Anale postérieure opposée seconde dorsale. Pectorales petites insérées bas. Caudale profondément fourchue très puissante. Corps recouvert petites écailles cycloides. Ligne latérale complète droite. Coloration ARGENTÉE brillante dominante toutes espèces. Dos gris-bleuté, flancs argentés, ventre blanc argenté. MOTIFS VARIABLES selon espèces : barres verticales, chevrons, bandes longitudinales, taches. Nageoires translucides à teintes jaunes/sombres selon espèces. Tailles adultes : S. obtusata 55 cm, S. jello 70 cm, S. putnamae 90 cm, S. forsteri 140 cm, S. qenie 160 cm. Aspect général : PRÉDATEUR HYDRODYNAMIQUE pur.",
            
            habitatDescription: "Famille UBIQUISTE occupant TOUS habitats côtiers et pélagiques peu profonds à moyens. Lagon : zones ouvertes, chenaux, herbiers, patates isolées. Passes : zones courants, embouchures. Récifs frangeants : platiers externes, zones transition. Tombants côtiers jusqu'à 100m (rares profond). Surface à mi-eau principalement (0-30m). Préfèrent eaux claires tropicales 24-30°C. Comportement : SOLITAIRES ou petits groupes (2-5). Postes EMBUSCADE près structures : surplombs, épaves, patates, zones ombragées. Stationnent IMMOBILES puis CHARGE FULGURANTE proie. Juvéniles zones côtières protégées (baies, herbiers). Sub-adultes/adultes habitats plus variés. Espèces résidentes mais mobiles. Patrouilles régulières zones chasse. MIGRATION VERTICALE quotidienne : descendent jour (repos), remontent CRÉPUSCULE/NUIT (chasse active). Présence marquée zones transitions lagon/récif, passes.",
            comportementDetail: "PRÉDATEUR EMBUSCADE ET CHASSEUR RAPIDE = stratégie double ! Technique 1 : EMBUSCADE - stationne IMMOBILE près structure, CHARGE ÉCLAIR sur proie passant (accélération 0-60 km/h en 1 seconde). Technique 2 : CHASSE ACTIVE - patrouille rapide, poursuite proies sur distances moyennes. Vitesse pointe : 60 km/h. Vitesse croisière : 20-30 km/h. Régime : PISCIVORE STRICT 100% ! Petits poissons allongés (aiguillettes, anchois, sardines, athérines, mulets juvéniles), calmars petits. SÉLECTIVITÉ MORPHOLOGIQUE : préfèrent proies ALLONGÉES FINES faciles avaler entières grâce bouche étroite. Pic activité : CRÉPUSCULE (17h-20h) OPTIMAL ++, NUIT (20h-6h) EXCELLENT ++, AUBE (5h-8h) très bon. JOUR (8h-17h) moins actif (embuscade passive). Comportement nocturne marqué = adaptation chasse faible luminosité. Attaque leurres VIOLEMMENT : touche BRUTALE fulgurante caractéristique. Combat SPECTACULAIRE : courses rapides surface, sauts acrobatiques impressionnants, résistance acharnée 15-30 minutes. Très combatif proportionnellement taille. DENTS ACÉRÉES coupent monofilament facilement : bas de ligne métallique/fluoro épais recommandé. Comportement solitaire dominant (pas grégaire). Territorialité modérée.",
            
            techniquesDetail: "TRAÎNE lente à moyenne (4-8 nœuds) : technique principale. Leurres LONGS et FINS 12-20 cm imitant aiguillettes/sardines (OBLIGATOIRE morphologie allongée), stickbaits, cuillers allongées, poissons nageurs fins. Couleurs ARGENTÉES/naturelles JOUR. Couleurs SOMBRES (noir, pourpre, bleu foncé) CRÉPUSCULE/NUIT = créer silhouette marquée faible luminosité (CRUCIAL). Profondeur 0-30m (surface à mi-eau). LANCER EXCELLENT : stickbaits 12-18 cm, cuillers, leurres souples fins. Zones structures, passes, récifs frangeants. Animation RAPIDE SACCADÉE imitant proie fuyant. HORAIRES CRITIQUES : CRÉPUSCULE et NUIT = périodes OPTIMALES absolues ! Jour moins productif. Ligne 15-30 kg. BAS DE LIGNE : CÂBLE métallique fin (10-15 lb) ou FLUORO épais (60-80 lb) OBLIGATOIRE = dents coupent monofilament instantanément ! Spread traîne : Long/Short Corner, Shotgun. Combat : garder tension forte, pomper fermement, ATTENTION sauts spectaculaires (décroches fréquentes). Épuisette ou gaffe. MANIPULATION PRUDENTE : dents TRÈS dangereuses (gants épais recommandés). ASTUCE PRO : leurres action ERRATIQUE saccadée = déclencheur optimal bécunes. Pêche NUIT avec leurres sombres = technique ultra-productive !",
            leuresSpecifiques: [
                "Stickbaits LONGS 12-20 cm (EXCELLENT - morphologie allongée)",
                "Cuillers allongées argentées",
                "Poissons nageurs FINS profil effilé",
                "Leurres souples fins 12-18 cm type aiguillette",
                "Poppers allongés surface",
                "Rapala/Yo-Zuri modèles fins",
                "Couleurs JOUR : ARGENTÉ, naturel, blanc",
                "Couleurs CRÉPUSCULE/NUIT : NOIR, pourpre, bleu foncé (silhouette ++)",
                "ACTION RAPIDE ERRATIQUE obligatoire"
            ],
            appatsNaturels: [
                "Aiguillettes vivantes (APPÂT ROI)",
                "Petites sardines",
                "Anchois",
                "Athérines",
                "Mulets juvéniles",
                "Petits calmars",
                "Poissons vivants allongés (morphologie importante)"
            ],
            meilleursHoraires: "CRÉPUSCULE (17h-20h) : période OPTIMALE absolue ++ ! NUIT (20h-6h) : EXCELLENT ++ ! AUBE (5h-8h) : très bon. JOUR (8h-17h) : correct (embuscade passive). Bécunes = ESPÈCES CRÉPUSCULAIRES/NOCTURNES typiques. Synchroniser sorties pêche avec ces horaires = succès garanti.",
            conditionsOptimales: "Zones structures (patates, surplombs, épaves, passes). Transitions lagon/récif. Eaux claires 24-30°C. TRAÎNE 4-8 nœuds : leurres LONGS FINS 12-20 cm, couleurs ARGENTÉES jour, SOMBRES crépuscule/nuit, profondeur 0-30m. LANCER structures : stickbaits/cuillers fins 12-18 cm animation rapide saccadée. Ligne 15-30 kg. BAS DE LIGNE CÂBLE métallique fin ou FLUORO épais 60-80 lb OBLIGATOIRE (dents). Positions Long/Short Corner, Shotgun. HORAIRES : CRÉPUSCULE et NUIT absolument CRITIQUES ! Pêche nuit leurres sombres = technique optimale.",
            
            qualiteCulinaire: "Chair de qualité VARIABLE selon espèces et taille. Texture FERME. Saveur correcte à bonne. Chair BLANCHE. Grain moyen à grossier. Petites bécunes (< 3 kg) : chair CORRECTE acceptable. Grandes bécunes (> 5 kg) : chair moins bonne, texture dure. Usages : Filets grillés/poêlés, Currys, Fumage, Soupes. Prix modéré marchés locaux (10-20€/kg). Demande modérée. Saignée immédiate ESSENTIELLE. Filetage facile. Rendement correct (60% chair). ARÊTES nombreuses fines = attention consommation. Valeur PRINCIPALEMENT SPORTIVE. Chair acceptable mais pas gastronomique. Nombreux pêcheurs pratiquent NO-KILL.",
            risqueCiguatera: .eleve,
            ciguateraDetail: "Risque ÉLEVÉ À TRÈS ÉLEVÉ selon espèces, zones et taille ! ATTENTION CRITIQUE : Bécunes = PRÉDATEURS PISCIVORES récifaux accumulant FORTEMENT toxines ! RÈGLES STRICTES ABSOLUES : JAMAIS consommer bécunes > 5 kg (risque TRÈS ÉLEVÉ). Bécunes 2-5 kg : risque ÉLEVÉ, grande prudence, se renseigner localement. Petites bécunes < 2 kg : risque MODÉRÉ à ÉLEVÉ selon zones. TOUTES TAILLES peuvent être toxiques zones récifales connues problématiques. Bécunes passes/lagon ouvert généralement plus sûres que récifales MAIS risque reste élevé. SE RENSEIGNER IMPÉRATIVEMENT localement avant TOUTE consommation. En NC : bécunes considérées espèces À RISQUE par autorités sanitaires. NOMBREUX CAS ciguatera bécunes rapportés. En cas MOINDRE doute : NE PAS CONSOMMER ! Privilégier fortement NO-KILL. Ciguatera bécunes peut être SÉVÈRE à TRÈS SÉVÈRE. ESPÈCE À CONSOMMER AVEC EXTRÊME PRUDENCE.",
            
            reglementationNC: "Pas de taille minimale légale spécifique bécunes actuellement NC. Pêche récréative libre quantités raisonnables. RECOMMANDATIONS SANITAIRES FORTES : prudence extrême consommation (ciguatera élevé). Respecter règles générales zones protégées. Espèces non menacées localement. NO-KILL fortement ENCOURAGÉ (risque sanitaire + valeur sportive).",
            quotas: "Pas de quota spécifique pêche récréative NC. Auto-limitation FORTEMENT encouragée. Privilégier NO-KILL systématique (risque ciguatera). Prélèvement occasionnel petits spécimens (< 2 kg) zones sûres acceptable avec renseignements locaux. Espèces abondantes.",
            zonesInterdites: "Aucune zone spécifiquement interdite bécunes. Respecter zones marines protégées générales, réserves intégrales. ZONES À RISQUE CIGUATERA : se renseigner auprès autorités sanitaires locales avant toute consommation.",
            statutConservation: "Statut UICN : Préoccupation mineure (Least Concern) pour la plupart des espèces. Populations globalement STABLES et ABONDANTES. Genre largement distribué zones tropicales/subtropicales mondiales. Croissance modérée, maturité 2-4 ans selon espèces, reproduction régulière, longévité 10-15 ans = résilience correcte. Stocks bons. Pression pêche modérée (consommation limitée par ciguatera). Espèces robustes ne nécessitant pas mesures conservation spécifiques actuellement.",
            
            leSaviezVous: "Les Bécunes sont les COUSINS PETITS du Barracuda géant (même famille Sphyraenidae) ! Morphologie hydrodynamique PARFAITE : coefficient traînée minimal, vitesse pointe 60 km/h, accélération 0-60 km/h en 1 seconde = performances HALLUCINANTES ! DENTS ACÉRÉES impressionnantes : canines puissantes + dents fines nombreuses = piège mortel proies. Mâchoire inférieure proéminente = adaptation morphologique permettant ouverture bouche ultra-rapide lors charge. Records taille : S. qenie 160 cm 25 kg, S. forsteri 140 cm 20 kg. En NC : spécimens 2-10 kg courants, 15 kg beaux poissons. Nom 'Bécune' vient ancien français 'bec' = référence museau pointu ! Comportement CRÉPUSCULAIRE/NOCTURNE marqué : vision adaptée faible luminosité, chasse optimale nuit. Combat SPECTACULAIRE : sauts acrobatiques 1-2m hors eau, courses rapides 50-100m, résistance acharnée. CONFUSION FRÉQUENTE avec Barracuda géant (Sphyraena barracuda) qui atteint 170 cm mais espèce différente traitée séparément. Bécunes peuvent former AGRÉGATIONS temporaires zones riches proies (rares, généralement solitaires). Technique EMBUSCADE ultra-efficace : immobilité absolue 30+ minutes puis charge 0.5 seconde = proie aucune chance ! DENTS coupent bas de ligne 20-30 lb instantanément = câble métallique fin ou fluoro 60-80 lb OBLIGATOIRE. Nombreux pêcheurs considèrent bécunes EXCELLENTES espèces sportives pêche nuit leurres sombres. Leurres NOIRS/POURPRES créent silhouette marquée contre ciel nocturne = déclencheur visuel optimal bécunes ! Espèces INTELLIGENTES : inspectent leurres, refusent présentations non naturelles. Animation ERRATIQUE saccadée imite poisson blessé = irrésistible bécunes. Certaines cultures Pacifique considèrent bécunes poissons SACRÉS protecteurs (légendes). MANIPULATION DANGEREUSE : dents causent blessures sévères, infections fréquentes = gants épais + pince OBLIGATOIRES !",
            nePasPecher: false,
            raisonProtection: nil
        ),
        
        // ─────────────────────────────────────────────────────────────────────
        // LOCHE SAUMONÉE / SAUMONÉE HIRONDELLE (Variola louti) (traîne possible mais jig/montage préféré)
        // ─────────────────────────────────────────────────────────────────────
        
        EspeceInfo(
            
            // ═══════════════════════════════════════════
            // IDENTIFICATION DE BASE
            // ═══════════════════════════════════════════
            
            identifiant: "locheSaumonee",
            nomCommun: "Loche saumonée",
            nomScientifique: "Variola louti",
            famille: "Serranidae",
            
            // ═══════════════════════════════════════════
            // LOCALISATION & HABITAT
            // ═══════════════════════════════════════════
            
            zones: [.recif, .tombant, .hauturier],  // Large amplitude profondeur (récif + profond)
            profondeurMin: 10.0,   // Peut être observée récifs peu profonds
            profondeurMax: 300.0,  // Fréquente aussi grandes profondeurs
            
            // ═══════════════════════════════════════════
            // TECHNIQUES DE PÊCHE COMPATIBLES
            // ═══════════════════════════════════════════
            
            typesPecheCompatibles: [
                .palangrotte,  // Pêche profonde principale
                .traine        // Possible traîne profonde (downrigger) zones récifales
            ],
            
            // ═══════════════════════════════════════════
            // TRAÎNE : POSSIBLE MAIS SECONDAIRE
            // ═══════════════════════════════════════════
            
            traineInfo: TraineInfo(
                vitesseMin: 3.0,
                vitesseMax: 6.0,
                vitesseOptimale: 4.5,
                profondeurNageOptimale: "15-80m (downrigger requis)",
                tailleLeurreMin: 12.0,
                tailleLeurreMax: 20.0,
                typesLeurresRecommandes: [
                    "Poissons nageurs plongeants profonds (15-30m)",
                    "Octopus jigs profonds",
                    "Leurres downrigger spécifiques"
                ],
                couleursRecommandees: [
                    "Rose/orange (imite coloration naturelle)",
                    "Violet/lavande",
                    "Argenté/bleu",
                    "Naturel poisson"
                ],
                positionsSpreadRecommandees: nil,
                notes: """
                ⚠️ Traîne SECONDAIRE pour Variola louti. Espèce principalement capturée en pêche \
                profonde démersale (palangrotte 50-300m). Traîne possible zones récifales externes \
                avec DOWNRIGGER obligatoire (profondeur 15-80m). Technique marginale vs pêche profonde \
                classique. Privilégier palangrotte profonde pour efficacité optimale.
                """
            ),
            
            // ═══════════════════════════════════════════
            // COMPORTEMENT GÉNÉRAL
            // ═══════════════════════════════════════════
            
            comportement: """
            Espèce à LARGE AMPLITUDE BATHYMÉTRIQUE (10-300m) mais principalement DÉMERSALE PROFONDE. \
            Fréquente tombants récifaux, monts sous-marins, épaulements rocheux. Prédateur carnivore \
            chassant poissons et crustacés. Solitaire ou petits groupes près structures profondes. \
            Activité crépusculaire/nocturne principalement. Comportement remontée similaire autres loches : \
            gueule ouverte, vrille ligne (émerillon indispensable). Espèce recherchée pêche profonde.
            """,
            
            momentsFavorables: [.aube, .crepuscule, .nuit],
            
            // ═══════════════════════════════════════════
            // 🆕 IDENTIFICATION VISUELLE
            // ═══════════════════════════════════════════
            
            photoNom: "LocheSaumonee_photo",
            illustrationNom: "LocheSaumonee_illustration",
            
            signesDistinctifs: """
            **IDENTIFICATION FACILE - CAUDALE UNIQUE :**
            
            Livrée ROUGE-ORANGE à BRUN ROUGEÂTRE spectaculaire. NOMBREUX PETITS POINTS ou TRAITS \
            BLEUS, VIOLETS, LAVANDE ou ROSES sur tête, corps et nageoires (motif magnifique). \
            
            ⭐ **SIGNE DISTINCTIF ABSOLU : CAUDALE EN CROISSANT caractéristique** avec MARGE \
            POSTÉRIEURE JAUNE prononcée. Cette forme caudale + couleur = IMPOSSIBLE confondre avec \
            autres espèces.
            
            Ressemble Variola albimarginata (Croissant queue blanche) mais V. louti possède MARGE \
            JAUNE nageoires (vs liseré blanc fin V. albimarginata).
            
            Corps élancé, élégant. Nageoires dorsale/anale également bordées jaune. Coloration \
            évoque saumon (origine nom "saumonée"). Aspect général = l'une des plus belles loches !
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 BIOLOGIE
            // ═══════════════════════════════════════════
            
            tailleMinLegale: nil,  // Pas de réglementation spécifique NC
            tailleMaxObservee: 80.0,  // cm (Longueur Fourche selon CPS)
            poidsMaxObserve: nil,     // Données non disponibles sources
            
            descriptionPhysique: """
            Loche de taille moyenne à corps élancé et élégant. Taille commune 50-70 cm. Coloration \
            spectaculaire rouge-orange à brun rougeâtre avec points/traits bleus-violets-lavandes \
            créant motif complexe magnifique. Caudale profondément fourchue EN CROISSANT avec lobes \
            pointus (caractéristique genre Variola vs Epinephelus caudale arrondie). Marge postérieure \
            nageoires (dorsale, anale, caudale) JAUNE VIF diagnostic. Tête pointue, profil élégant. \
            Bouche large adaptée capture poissons. Hermaphrodite protogyne (femelle → mâle) comme \
            autres Serranidae. Nage gracieuse et rapide (vs loches Epinephelus plus lourdes).
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 HABITAT DÉTAILLÉ
            // ═══════════════════════════════════════════
            
            habitatDescription: """
            **AMPLITUDE BATHYMÉTRIQUE LARGE - ESPÈCE POLYVALENTE :**
            
            **Distribution profondeur : 10-300 m** (exceptionnellement large pour Serranidae)
            
            **Habitats principaux par profondeur :**
            
            • **10-40 m (RÉCIFS EXTERNES) :** Observée occasionnellement tombants récifaux peu profonds, \
            grottes, surplombs. Rare <20 m.
            
            • **40-150 m (ZONE INTERMÉDIAIRE) :** Fréquente zones transition récif/profond. Épaulements \
            rocheux, tombants abrupts.
            
            • **150-300 m (DÉMERSAL PROFOND - OPTIMAL) :** Zone préférentielle. Monts sous-marins, \
            tombants profonds, structures rocheuses complexes. Abondance maximale 150-250 m.
            
            **Types substrats :**
            • Structures rocheuses abruptes (tombants >45°)
            • Anfractuosités, grottes profondes
            • Épaulements récifaux externes
            • Monts sous-marins (sommets/flancs)
            • Évite fonds meubles sans relief
            
            **Particularité :** Contrairement Epinephelus microdon (strictement >100m), Variola louti = \
            plus plastique (récifs peu profonds → grandes profondeurs). MAIS captures commerciales = \
            principalement pêche profonde 100-300 m où abondance maximale.
            
            **Distribution géographique NC :** Tous tombants externes récif-barrière + monts sous-marins.
            """,
            
            comportementDetail: """
            **PRÉDATEUR PÉLAGICO-DÉMERSAL ACTIF :**
            
            **Régime alimentaire (carnivore piscivore) :**
            • **POISSONS (priorité 1) :** Proies principales. Petits poissons récifaux/démersaux.
            • **Crustacés :** Crabes, langoustes, crevettes profondes (secondaire)
            • **Céphalopodes :** Calmars, poulpes (occasionnel)
            
            **Mode chasse :** Plus actif qu'Epinephelus. Patrouille structures rocheuses, chasse \
            activement poissons en pleine eau. Nage rapide permet poursuite proies. Attaque fulgurante.
            
            **Activité :** Crépusculaire/nocturne principalement (pic 17h-20h + 5h-8h). Diurne aussi \
            (opportuniste) mais moins actif journée.
            
            **Comportement social :** Solitaire généralement. Parfois petits groupes (2-4 individus) \
            zones riches proies. Territorialité modérée.
            
            **Comportement lors capture :**
            • Remontée GUEULE OUVERTE (barotraumatisme profondeur)
            • VRILLE LA LIGNE fortement (rotation corps)
            • Combat VIGOUREUX et RAPIDE (espèce dynamique)
            • Vessie natatoire extériorisée si >100 m profondeur
            • Relâche impossible profondeur >80m (mortalité certaine)
            
            **Reproduction :** Hermaphrodite protogyne (femelle → mâle avec âge/taille). Ponte eaux \
            profondes présumée saison chaude (nov-mars estimé). Maturité sexuelle non documentée \
            (estimée 3-5 ans, 40-50 cm).
            
            **Croissance :** Modérée à rapide (plus rapide qu'Epinephelus profonds). Longévité estimée \
            15-20 ans.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 PÊCHE PRATIQUE
            // ═══════════════════════════════════════════
            
            techniquesDetail: """
            **🎣 TECHNIQUE PRINCIPALE : PÊCHE PROFONDE DÉMERSALE (80-300m)**
            
            **MATÉRIEL (identique Epinephelus microdon) :**
            • Moulinet électrique recommandé ou manuel robuste
            • Ligne tressé PE 6-10 (300-500 m) ou nylon 50-80 lb
            • Bas de ligne fluorocarbone 80-120 lb (1.5-2.5 m)
            • Hameçons autoferrants Mustad 5/0-9/0 (avançons courts 20-30 cm)
            • Lest lourd 1-2 kg (courants profondeur)
            • Émerillon ROBUSTE (vrille ligne Variola)
            
            **APPÂTS PÊCHE PROFONDE :**
            • Bonite salée morceaux 5-10 cm (OPTIMAL)
            • Thon salé morceaux
            • Calmars entiers 10-15 cm (excellent Variola piscivore)
            • Petits poissons entiers (maquereaux, sardines)
            • Broumé sac attirance (morceaux poissons)
            
            **TECHNIQUE (voir détails fiche Epinephelus microdon) :**
            1. Positionnement tombant/mont (sondeur + GPS)
            2. Descente ligne (toucher fond puis remonter 1-2 m)
            3. Maintien contact léger fond
            4. Animation minimale (touches verticales occasionnelles)
            5. Ferrage franc si touche
            6. Remontée régulière (pompage continu, émerillon essentiel)
            
            **PROFONDEURS OPTIMALES VARIOLA LOUTI :**
            • 80-150 m : Spécimens moyens (50-65 cm)
            • 150-250 m : Zone productive maximale (gros spécimens 60-75 cm)
            • 250-300 m : Très gros individus rares (>75 cm)
            
            **MOMENTS OPTIMAUX :**
            • Aube (5h-8h) - Pic activité
            • Crépuscule (17h-20h) - Pic activité
            • Nuit - Très actif (parfois meilleur moment)
            
            ---
            
            **🎣 TECHNIQUE SECONDAIRE : TRAÎNE PROFONDE (DOWNRIGGER)**
            
            ⚠️ **MARGINALE** mais possible zones récifales externes 15-80 m.
            
            **MATÉRIEL TRAÎNE PROFONDE :**
            • Canne traîne lourde (20-50 lb)
            • Moulinet traîne capacité 300-400 m
            • DOWNRIGGER (obligatoire descendre leurres 20-80 m)
            • Ligne mère tressé PE 4-6
            • Bas de ligne fluorocarbone 60-80 lb
            
            **LEURRES TRAÎNE :**
            • Poissons nageurs plongeants profonds (diving depth 10-20m + downrigger)
            • Octopus jigs profonds (6-8 pouces)
            • Leurres souples montés lests 50-100g
            • **Couleurs :** Rose/orange, violet/lavande, argenté/bleu
            
            **VITESSE TRAÎNE :** 3-6 nœuds (optimal 4-5 nœuds)
            
            **ZONES TRAÎNE :**
            • Tombants récifaux externes (longer bordure 15-50 m)
            • Épaulements rocheux (relief accidenté)
            • Downrigger positionné 20-80 m profondeur
            
            **LIMITES TRAÎNE :**
            ❌ Technique MOINS efficace que pêche profonde statique
            ❌ Requiert downrigger (coûteux, technique)
            ❌ Espèce principalement >100 m (hors portée downrigger standard)
            ❌ Effort/résultat défavorable vs palangrotte profonde
            
            ✅ **RECOMMANDATION : PRIVILÉGIER PÊCHE PROFONDE PALANGROTTE** (technique principale \
            pêcheurs NC pour Variola louti).
            """,
            
            leuresSpecifiques: [
                // TRAÎNE PROFONDE (technique marginale)
                "Poissons nageurs plongeants profonds 15-20cm",
                "Octopus jigs 6-8 pouces (couleurs rose/violet)",
                "Leurres souples montés lourds 50-100g",
                "Couleurs : Rose/orange, violet/lavande, argenté/bleu"
                // Note : Pêche profonde = appâts naturels (voir appatsNaturels)
            ],
            
            appatsNaturels: [
                // PÊCHE PROFONDE (technique principale)
                "Bonite salée morceaux 5-10 cm - OPTIMAL",
                "Thon salé morceaux 5-10 cm",
                "Calmars entiers 10-15 cm (excellent piscivore)",
                "Calmars morceaux",
                "Petits poissons entiers (maquereaux 10-15 cm)",
                "Sardines entières (broumé attirance)",
                "Poulpes morceaux 5-8 cm",
                "Tout poisson gras salé/durci"
            ],
            
            meilleursHoraires: """
            **SAISON :** Toute l'année (espèce profonde = faibles variations saisonnières)
            
            **MOMENTS JOURNÉE :**
            • **Aube** (5h-8h) - ⭐ Pic activité alimentaire maximal
            • **Crépuscule** (17h-20h) - ⭐ Pic activité alimentaire maximal
            • **Nuit** (20h-5h) - Très actif, parfois meilleur moment (surtout pleine lune)
            • **Journée** - Actif modéré (opportuniste, chasse si proie passe)
            
            **MARÉE :**
            • Coefficients moyens (30-70) PRÉFÉRÉS
            • Courants modérés = pêche profonde facilitée
            • Éviter très grands coefficients (courants violents profondeur)
            
            **LUNE :**
            • Pleine lune : Activité nocturne maximale (lumière favorise chasse)
            • Nouvelle lune : Activité réduite nuit (obscurité totale profondeur)
            
            **MÉTÉO :** Mer calme INDISPENSABLE (précision positionnement + stabilité)
            """,
            
            conditionsOptimales: """
            **MÉTÉO & MER :**
            • Mer calme à peu agitée (<1.5 m houle)
            • Vent <15 nœuds (stabilité bateau)
            • Ciel dégagé facilite navigation tombants
            
            **COURANTS :**
            • Modérés (maintien ligne verticale possible)
            • Courant nul (étal marée) parfois idéal
            • Courants forts = pêche difficile/impossible
            
            **ÉQUIPEMENT :**
            • Sondeur performant (lecture 100-300 m)
            • GPS (repositionnement spots)
            • Émerillon robuste (CRITIQUE pour Variola)
            • Ancre + orin profondeur adaptée
            
            **PROFONDEUR OPTIMALE VARIOLA LOUTI :**
            • Zone la plus productive : **150-250 m**
            • Spécimens moyens : 80-150 m
            • Gros spécimens : 200-280 m
            
            **TYPE FOND :**
            • Tombants abrupts (pente >45°)
            • Monts sous-marins (sommets + flancs)
            • Structures rocheuses complexes
            • Anfractuosités, grottes, surplombs
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 VALORISATION CULINAIRE & SÉCURITÉ
            // ═══════════════════════════════════════════
            
            qualiteCulinaire: """
            ⭐⭐⭐⭐⭐ **CHAIR EXCEPTIONNELLE - AUCUN RISQUE CIGUATERA**
            
            **AVANTAGE MAJEUR (identique autres démersaux profonds) :**
            ✅ **JAMAIS CIGUATOXIQUE** - Habitat profond = aucun contact algues toxiques récif
            ✅ Valeur commerciale TRÈS ÉLEVÉE (sécurité + qualité chair)
            ✅ Exportation sans restriction sanitaire
            ✅ Consommation SANS LIMITE taille/âge
            
            **QUALITÉS GUSTATIVES SUPÉRIEURES :**
            • Chair BLANCHE NACRÉE, texture FERME et FINE
            • Saveur DÉLICATE, RAFFINÉE, légèrement sucrée
            • Pas goût "poisson" prononcé (finesse remarquable)
            • Tenue cuisson PARFAITE (chair ne se défait pas)
            • Peu d'arêtes, filetage facile
            • **Considérée parmi MEILLEURES loches culinairement**
            
            **PRÉPARATIONS RECOMMANDÉES :**
            • **Poisson cru** : Sashimi, carpaccio (chair ferme idéale) ⭐⭐⭐⭐⭐
            • **Grillé** : Darnes/pavés grillés (excellente tenue, peau croustillante)
            • **Poêlé** : Filets minute, cuisson rapide
            • **Au four** : Entier ou filets, aromates, papillote
            • **Vapeur** : Préserve finesse exceptionnelle chair
            • **Ceviche** : Marinade citron/coco (Pacifique)
            • **Sushi** : Chair ferme parfaite nigiri/maki
            
            **CONSERVATION :**
            • Chair dense : 3-4 jours au frais
            • Congélation excellente (texture préservée)
            • Qualité supérieure maintenue
            
            **PRIX MARCHÉ NC :**
            • **TRÈS ÉLEVÉ** (espèce recherchée + aucun risque + qualité supérieure)
            • Parmi loches les plus chères marché
            • Demande forte gastronomie haut de gamme
            • Export Japon/Asie (sashimi premium)
            """,
            
            risqueCiguatera: .aucun,
            
            ciguateraDetail: """
            ✅ **AUCUN RISQUE CIGUATERA - ESPÈCE DÉMERSALE PROFONDE**
            
            **RAISONS ABSENCE TOTALE RISQUE :**
            
            Variola louti = principalement DÉMERSALE PROFONDE (100-300 m optimal). À ces profondeurs :
            
            1. **AUCUN Gambierdiscus** (algue productrice toxine) = absence totale exposition
            2. **Chaîne alimentaire séparée** récif superficiel = proies non contaminées
            3. **Habitat profondeur** = isolation complète zones à risque
            
            **Bien que Variola louti PUISSE être observée récifs peu profonds (10-40m) occasionnellement, \
            son régime alimentaire principal = PROIES PROFONDES non ciguatoxiques.**
            
            **CONFIRMATION SOURCES :**
            • CPS Guide : Variola louti listée espèces démersales profondes
            • Preston 1999 : Genre Variola (Saumonées) = cible pêche profonde
            • Consignes moteur : Loches démersales profondes NE sont JAMAIS ciguatoxiques
            
            **CONSÉQUENCES PRATIQUES :**
            ✅ Consommation SANS RESTRICTION taille/âge
            ✅ Gros spécimens 80 cm = AUCUN DANGER
            ✅ Toutes parties comestibles (filets, joues, arêtes bouillon)
            ✅ Exportation autorisée (pas restrictions)
            
            **VALEUR AJOUTÉE :**
            Cette sécurité sanitaire ABSOLUE + qualité chair exceptionnelle = Variola louti parmi \
            **ESPÈCES LES PLUS RECHERCHÉES pêche profonde Pacifique**. Prix marché reflète cette \
            combinaison rare (sécurité + qualité + rareté).
            
            🎯 **LOCHE SAUMONÉE = TRÉSOR CULINAIRE GARANTI SÛRVAROLA LOUTI**
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 RÉGLEMENTATION & CONSERVATION
            // ═══════════════════════════════════════════
            
            reglementationNC: """
            ⚠️ **PAS DE RÉGLEMENTATION SPÉCIFIQUE ESPÈCE (2025)**
            
            **STATUT ACTUEL :**
            • Aucune taille minimale capture
            • Aucune période fermeture
            • Aucun quota spécifique Variola louti
            • Réglementation générale pêche profonde applicable
            
            **RECOMMANDATIONS GESTION (non réglementaires) :**
            
            📏 **Taille minimale suggérée : 50 cm LF**
            • Protection juvéniles (maturité estimée 40-50 cm, 3-5 ans)
            • Favorise renouvellement stock
            
            ⚠️ **Limitation prélèvement très gros (>75 cm) :**
            • Gros individus = mâles reproducteurs (hermaphrodisme protogyne)
            • Importance génétique population
            
            **PROBLÉMATIQUE SIMILAIRE AUTRES DÉMERSAUX :**
            • Croissance lente, maturité tardive = vulnérabilité surpêche
            • Stocks monts isolés = fragiles
            • Effort concentré zones accessibles = appauvrissement local
            • Observations changements composition espèces monts exploités
            
            **GESTION SOUHAITABLE :**
            1. Taille minimale 50 cm LF
            2. Quotas pêche professionnelle (limitation effort)
            3. Rotation zones pêche (préserver stocks monts)
            4. Monitoring scientifique régulier
            5. Protection monts reproducteurs (fermeture saisonnière)
            """,
            
            quotas: """
            ⚠️ **AUCUN QUOTA ACTUELLEMENT (2025)**
            
            **PROPOSITION GESTION RATIONNELLE :**
            
            **Pêche récréative :**
            • 2-3 loches/pêcheur/jour MAX (toutes espèces Serranidae profondes)
            • Taille minimale 50 cm LF
            • Relâcher gros >75 cm recommandé (reproducteurs)
            
            **Pêche professionnelle :**
            • Quotas par zone/mont (éviter épuisement)
            • Rotation obligatoire zones pêche
            • Déclarations captures (monitoring)
            • Limitation effort (nb sorties/engins)
            
            **JUSTIFICATION :**
            • Croissance modérée mais maturité tardive
            • Hermaphrodisme protogyne (capture gros = perte mâles)
            • Stocks monts isolés vulnérables
            • Valeur commerciale élevée = pression forte
            """,
            
            zonesInterdites: """
            ⚠️ **Vérifier Aires Marines Protégées incluant zones profondes**
            
            Certaines AMP NC protègent tombants/monts profonds. Vérifier réglementation avant sortie.
            
            **Recommandation :** Renseignements Affaires Maritimes, Provinces avant pêche profonde.
            """,
            
            statutConservation: """
            **STATUT CONSERVATION :**
            
            **UICN (Mondial) :** Non évalué spécifiquement Variola louti
            
            **NOUVELLE-CALÉDONIE :** Statut incertain (pêche profonde peu documentée)
            
            **VULNÉRABILITÉ INTRINSÈQUE - MODÉRÉE À ÉLEVÉE :**
            ⚠️ Croissance modérée (plus rapide qu'Epinephelus mais reste lente)
            ❌ Maturité sexuelle tardive (estimée 3-5 ans)
            ❌ Hermaphrodisme protogyne (capture gros = perte mâles)
            ⚠️ Habitat spécialisé structures profondes
            ⚠️ Stocks potentiellement isolés monts
            ✅ Amplitude bathymétrique large (10-300m) = plus plasticité qu'espèces strictement profondes
            
            **PRESSIONS :**
            • **Valeur commerciale TRÈS élevée** = pression pêche forte
            • **Espèce recherchée** gastronomie haut gamme
            • **Export Asie** (sashimi premium) = demande internationale
            • **Concentration effort** monts accessibles/productifs
            
            **MENACES :**
            • Surpêche localisée monts connus
            • Barotraumatisme (relâche impossible >80m)
            • Pêche ciblée (reconnaissance caudale croissant)
            • Stocks monts = vulnérables exploitation intensive
            
            **ACTIONS CONSERVATION PRIORITAIRES :**
            1. Inventaire scientifique stocks principaux
            2. Biologie (croissance, reproduction, déplacements)
            3. Taille minimale capture 50 cm
            4. Quotas stricts (pêche pro + récréative)
            5. Protection habitats reproducteurs
            6. Rotation zones pêche
            7. Monitoring captures déclarations
            8. Sensibilisation valeur espèce (gestion responsable)
            
            **PRINCIPE PRÉCAUTION :** Valeur commerciale élevée + caractéristiques biologiques \
            (croissance lente, maturité tardive, hermaphrodisme) = gestion conservatrice indispensable \
            préserver ressource long terme.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 PÉDAGOGIE & SENSIBILISATION
            // ═══════════════════════════════════════════
            
            leSaviezVous: """
            🌊 **CAUDALE EN CROISSANT - SIGNATURE GENRE VARIOLA :**
            La forme caudale profondément fourchue EN CROISSANT avec lobes pointus = caractéristique \
            UNIQUE genre Variola (vs Epinephelus caudale arrondie). Cette morphologie = adaptation \
            nage RAPIDE et ENDURANTE. Loches Variola = nageurs plus actifs, dynamiques, chassent \
            activement proies en pleine eau (vs Epinephelus embuscade statique). Caudale croissant + \
            corps élancé = hydrodynamisme optimal vitesse/endurance.
            
            🎨 **COLORATION SPECTACULAIRE - PARMI PLUS BELLES LOCHES :**
            Variola louti = unanimement considérée l'une des PLUS BELLES loches ! Livrée rouge-orange \
            avec innombrables points bleus-violets-lavandes créant motif complexe magnifique. Marge \
            jaune vif nageoires contraste splendide. Nom "saumonée" évoque coloration rappelant chair \
            saumon. En plongée profonde, sous éclairage artificiel, couleurs = éblouissantes. Pêcheurs \
            reconnaissent immédiatement silhouette + coloration unique en remontant capture.
            
            🏆 **TRÉSOR CULINAIRE GASTRONOMIE PACIFIQUE :**
            Variola louti = considérée **SUMMUM qualité chair** parmi loches Pacifique. Chair blanche \
            nacrée, texture ferme-fine, saveur délicate-raffinée = combinaison rare. Marchés haut gamme \
            Japon/Hong Kong paient prix premium pour sashimi Variola louti. Chefs étoilés apprécient \
            finesse permettant sublimer sans masquer. Aucun risque ciguatera + qualité exceptionnelle = \
            espèce très recherchée gastronomie.
            
            ⚖️ **HERMAPHRODISME PROTOGYNE - VULNÉRABILITÉ GESTION :**
            Comme autres Serranidae, Variola louti = hermaphrodite PROTOGYNE (femelle d'abord → mâle \
            avec âge/taille). Gros spécimens >70 cm = principalement MÂLES. Pêche sélective gros = \
            retire mâles reproducteurs, déséquilibre sex-ratio, compromet reproduction. Problématique \
            similaire mérous Méditerranée (Epinephelus marginatus) où surpêche gros = effondrement \
            populations. Protection gros individus = essentielle pérennité espèce.
            
            🎣 **COMBAT VIGOUREUX - REMONTÉE SPECTACULAIRE :**
            Variola louti = combat plus DYNAMIQUE qu'Epinephelus (corps élancé, nage rapide). Rushes \
            puissants, rotations vrillant ligne (émerillon indispensable !). Remontée profondeur >100m = \
            barotraumatisme spectaculaire : vessie natatoire extériorisée par bouche ouverte. Malheureusement \
            relâche impossible (mortalité certaine lésions internes). Variola ferrée profondeur = consommation \
            obligatoire. D'où importance gestion responsable AVANT capture (quotas, tailles, zones).
            
            🌍 **DISTRIBUTION INDO-PACIFIQUE LARGE :**
            Variola louti = largement distribuée Indo-Pacifique tropical (Mer Rouge → Polynésie). Espèce \
            commune mais PAS abondante (densités faibles). Présente tous archipels Pacifique, mais stocks \
            localisés monts/tombants = vulnérables surpêche. Importance pêche professionnelle variable : \
            marginale Polynésie (préférence vivaneaux), majeure Philippines/Indonésie (valeur commerciale).
            
            💎 **PRIX MARCHÉ REFLÈTE COMBINAISON RARE :**
            Variola louti parmi loches LES PLUS CHÈRES marchés Pacifique. Pourquoi ? Combinaison RARE :
            1. Aucun risque ciguatera (sécurité absolue)
            2. Qualité chair exceptionnelle (gastronomie haute)
            3. Beauté esthétique (valorisation visuelle)
            4. Rareté relative (densités faibles)
            5. Difficulté capture (pêche profonde spécialisée)
            Prix élevé = reconnaissance valeur intrinsèque espèce. Justifie gestion rigoureuse préserver \
            ressource précieuse.
            """,
            
            nePasPecher: false,  // Pêche autorisée mais gestion responsable essentielle
            
            raisonProtection: """
            ⚠️ **ESPÈCE PRÉCIEUSE - GESTION RESPONSABLE IMPÉRATIVE**
            
            Bien que pêche autorisée, Variola louti nécessite GESTION RIGOUREUSE :
            
            **POURQUOI VULNÉRABLE :**
            • Croissance modérée, maturité tardive (3-5 ans)
            • Hermaphrodisme protogyne (gros = mâles reproducteurs)
            • Valeur commerciale TRÈS ÉLEVÉE = pression pêche forte
            • Stocks monts potentiellement isolés
            • Demande internationale (export Asie sashimi)
            • Barotraumatisme = relâche impossible
            
            **PÊCHE RESPONSABLE - ENGAGEMENTS VOLONTAIRES :**
            
            ✅ **Respecter taille minimale 50 cm** (maturité sexuelle)
            ✅ **Limiter captures** (2-3 loches/sortie MAX)
            ✅ **Limiter prélèvement très gros >75 cm** (mâles reproducteurs)
            ✅ **Rotation zones pêche** (pas retours répétés même mont)
            ✅ **Valoriser TOTALEMENT captures** (chair exceptionnelle mérite respect)
            ✅ **Partager spots modération** (éviter concentration effort)
            ✅ **Déclarer captures si possible** (aider monitoring)
            
            **SI GESTION COLLECTIVE RESPONSABLE :**
            → Stocks préservés long terme
            → Pêche pérenne garantie
            → Trésor culinaire disponible générations futures
            → Valeur économique maintenue (tourisme pêche, export)
            
            **SANS GESTION :**
            → Risque appauvrissement monts accessibles
            → Perte espèce exceptionnelle qualité
            → Fin pêche durable ressource précieuse
            
            🎯 **Variola louti = GEMME Pacifique → PROTÉGER = HONORER**
            """
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
            momentsFavorables: [.matinee, .apresMidi],
            photoNom: nil,
                illustrationNom: nil,
                signesDistinctifs: nil,  // À compléter plus tard
                tailleMinLegale: 60.0,
                tailleMaxObservee: 200.0,
                poidsMaxObserve: 200.0,
                descriptionPhysique: nil,  // À compléter plus tard
                habitatDescription: nil,
                comportementDetail: nil,
                techniquesDetail: nil,
                leuresSpecifiques: nil,
                appatsNaturels: nil,
                meilleursHoraires: nil,
                conditionsOptimales: nil,
                qualiteCulinaire: nil,
                risqueCiguatera: .aucun,  // ⚠️ Adapter selon l'espèce
                ciguateraDetail: nil,
                reglementationNC: nil,
                quotas: nil,
                zonesInterdites: nil,
                statutConservation: nil,
                leSaviezVous: nil,
                nePasPecher: false,  // false par défaut
                raisonProtection: nil
        ),
        // ─────────────────────────────────────────────────────────────────────
        // BEC DE CANE
        // Source : IRD - Borsa, Kulbicki et al. (2009) "Biologie et écologie du bec de cane en Nouvelle-Calédonie"
        // Espèce emblématique du lagon NC - Première importance commerciale
        // ─────────────────────────────────────────────────────────────────────
        EspeceInfo(
            
            // ═══════════════════════════════════════════
            // IDENTIFICATION DE BASE
            // ═══════════════════════════════════════════
            
            identifiant: "becDeCane",
            nomCommun: "Bec-de-cane",
            nomScientifique: "Lethrinus nebulosus",
            famille: "Lethrinidae",
            
            // ═══════════════════════════════════════════
            // LOCALISATION & HABITAT
            // ═══════════════════════════════════════════
            
            zones: [.lagon, .recif],
            profondeurMin: 0.0,      // Juvéniles en herbiers très peu profonds
            profondeurMax: 40.0,     // Adultes max observés 30-40m
            
            // ═══════════════════════════════════════════
            // TECHNIQUES DE PÊCHE COMPATIBLES
            // ═══════════════════════════════════════════
            
            typesPecheCompatibles: [
                .palangrotte,  // Technique principale (palangre de fond >7m)
                .lancer        // Ligne à main + leurres (près récifs)
            ],
            
            // ═══════════════════════════════════════════
            // TRAÎNE : NON APPLICABLE
            // ═══════════════════════════════════════════
            
            traineInfo: nil,  // ⚠️ ESPÈCE BENTHIQUE - PAS DE TRAÎNE HAUTURIÈRE
            
            // ═══════════════════════════════════════════
            // COMPORTEMENT GÉNÉRAL
            // ═══════════════════════════════════════════
            
            comportement: """
            Espèce benthique strictement carnivore chassant par aspiration du sédiment. \
            Activité diurne (Grande Terre/Province Nord), possiblement nocturne à Ouvéa. \
            Migration ontogénique : juvéniles en herbiers côtiers (0-5m), adultes en milieu \
            de lagon et près récif-barrière (10-40m). Regroupements sur herbiers sous le vent \
            des îlots en période de reproduction (septembre-octobre).
            """,
            
            momentsFavorables: [.matinee, .apresMidi, .crepuscule],
            // ═══════════════════════════════════════════
            // 🆕 IDENTIFICATION VISUELLE (SPRINT 2)
            // ═══════════════════════════════════════════
            
            photoNom: "BecDeCane_photo",
            illustrationNom: "BecDeCane_illustration",
            
            signesDistinctifs: """
            Corps gris argenté avec écailles pourvues de DEUX POINTS caractéristiques \
            (un noir + un bleu pâle/blanc) donnant aspect "ÉTOILÉ" très distinctif. \
            Traits BLEUS rayonnant à partir des yeux sur les joues. Profil légèrement \
            busqué. Corps comprimé latéralement typique des Lethrinidae. \
            IMPOSSIBLE À CONFONDRE avec aspect étoilé des écailles.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 BIOLOGIE
            // ═══════════════════════════════════════════
            
            tailleMinLegale: nil,  // ⚠️ Pas de réglementation actuelle NC
            tailleMaxObservee: 69.5,  // cm (Longueur Fourche)
            poidsMaxObserve: 5.5,     // kg (femelle)
            
            descriptionPhysique: """
            Taille moyenne : 45 cm / 2.5 kg. Dimorphisme sexuel : femelles 5 cm plus \
            grandes que mâles à même âge. Sex-ratio biaisé : 58% femelles (70% chez >60 cm) \
            dû à hermaphrodisme protandre (mâle d'abord, puis femelle avec âge). Corps haut, \
            comprimé. Mâchoires puissantes adaptées au broyage de coquilles et carapaces. \
            Nageoire caudale fourchue. Écailles cycloïdes de taille moyenne.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 HABITAT DÉTAILLÉ
            // ═══════════════════════════════════════════
            
            habitatDescription: """
            **HABITAT PRÉFÉRENTIEL :** Grandes étendues sédimentaires avec préférence MARQUÉE \
            pour fonds sableux immédiatement en arrière du RÉCIF-BARRIÈRE.
            
            **JUVÉNILES (0-2 ans, <20 cm) :** Herbiers et algueraies côtiers comportant peu \
            de corail (0-5 m). Ces zones = NOURRICERIES ESSENTIELLES. Présents mars-avril.
            
            **MIGRATION ONTOGÉNIQUE :** Avec croissance, déplacement vers zones plus profondes \
            et au large. Corrélation positive taille/profondeur. Taille max observée 30-40m.
            
            **ADULTES :** Milieu de lagon et bordure récif-barrière sur fonds sableux (10-40m). \
            Évitent fonds meubles sans abris, mangroves, estuaires.
            
            **DISTRIBUTION GÉOGRAPHIQUE NC :** Tous lagons (SW, Nord, Ouvéa). Densités maximales \
            à Ouvéa. Zones urbaines (Nouméa) = stocks appauvris.
            """,
            
            comportementDetail: """
            **MODE DE CHASSE :** Aspiration du sédiment pour extraire proies benthiques enfouies. \
            Mâchoires puissantes broient coquilles (mollusques) et carapaces (crustacés).
            
            **RÉGIME ALIMENTAIRE (% volume stomacal) :**
            • Mollusques 40-50% (Bivalves >> Gastéropodes)
            • Crustacés 20-30% (Crabes > Crevettes > Squilles)  
            • Échinodermes 10-20% (Oursins sable/roche)
            • Poissons 5-15% (grands individus uniquement)
            • Vers polychètes (secondaire)
            
            **VARIATIONS RÉGIME :** Grands individus (>50 cm) = plus de poissons/crustacés/échinodermes, \
            moins de mollusques. Lagon SW = alimentation riche en proies mobiles. Ouvéa = spécialisation \
            bivalves.
            
            **ACTIVITÉ :** Diurne (Grande Terre), possiblement nocturne (Ouvéa - à confirmer). \
            Activité alimentaire chute sept-oct (reproduction). Estomacs pleins mars-août.
            
            **REPRODUCTION :** Hermaphrodite protandre (mâle → femelle). Juillet-octobre (pic sept). \
            Maturité 4-5 ans : mâles 35-40 cm, femelles 40-45 cm. Regroupements herbiers îlots <5m. \
            Phase larvaire ~37 jours.
            
            **CROISSANCE :** Rapide et linéaire jusqu'à maturité (4-5 ans), puis ralentissement \
            (énergie investie reproduction). Croissance NC > autres régions Indo-Pacifique.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 PÊCHE PRATIQUE
            // ═══════════════════════════════════════════
            
            techniquesDetail: """
            ** PALANGRE DE FOND (Technique #1 - RENDEMENT OPTIMAL) :**
            
            • **Zones :** Milieu de lagon, bordure récif-barrière
            • **Profondeur :** >7 m MINIMUM (éviter accrochages récifs)
            • **Profondeur optimale :** 15-30 m
            • **Appâts :** Crustacés (crabes, crevettes), mollusques (poulpes, calmars), petits poissons
            • **Montage :** Palangre fond classique, hameçons 2/0 à 4/0
            • **Bas de ligne :** Fluorocarbone 25-30 lb (50-60 cm)
            • **Pose :** Distance suffisante des récifs pour limiter pertes matériel
            • **Rendement :** Poids moyen 2.46 kg (lagon milieu) - 70% plus lourd qu'à la ligne
            • **Meilleur rendement :** Lagon SW > Province Nord
            • **Moment :** Mars-août (éviter sept-oct = reproduction)
            
            ** LIGNE À MAIN (Technique #2 - PRÉCISION STRUCTURES) :**
            
            • **Zones :** Près des récifs, patates coraliennes, bordures herbiers
            • **Profondeur :** Utilisable dès <7 m (avantage sur palangre)
            • **Appâts :** Identiques palangre (crustacés priorité)
            • **Montage :** Ligne simple, plomb olive coulissant 20-40g
            • **Avantages :** Accessible, précis pour cibler structures, profondeurs variées
            • **Poids moyen :** ~1.45 kg (milieu lagon)
            • **Rendement maximal :** Ouvéa (densités élevées)
            
            ** LEURRES ARTIFICIELS (Technique moderne - PRÉSENTATION LENTE) :**
            
             **CLÉ DU SUCCÈS = PRÉSENTATION LENTE + CONTACT FOND**
            
            • **Animation :** LENTE, bondissements, pauses longues (80% contact fond)
            • **Vitesse traîne :** 2-4 nœuds MAX (espèce benthique lente)
            • **Zones cibles :** Bordures herbiers, fonds sableux récif-barrière, patates (10-30m)
            • **Montages :** Drop shot, Carolina rig, Texan (herbiers), Jig tête plombée
            • **Hameçons :** 2/0 à 4/0 (bouche moyenne)
            • **Fluorocarbone :** 25-30 lb (dents présentes, pas coupantes)
            
            **ERREURS À ÉVITER :**
            ❌ Animation trop rapide (espèce lente benthique)
            ❌ Leurres trop gros (proies naturelles 3-8 cm)
            ❌ Pêche pleine eau (ignore zone alimentation)
            ❌ Absence pauses (ne laisse pas temps attaque)
            """,
            
            leuresSpecifiques: [
                // PRIORITÉ 1 - Imitation Crustacés (OPTIMAL)
                "Jigs crabe/écrevisse 10-15g (couleurs: brun/vert, orange)",
                "Leurres souples type crevette 8-12cm (couleurs: rose/orange, naturel)",
                "Jigs verticaux petite taille animation bondissante",
                "Crazy Fish type shrimp",
                
                // PRIORITÉ 2 - Imitation Petits Poissons Benthiques
                "Poissons nageurs suspending 8-12cm (diving depth 2-4m)",
                "Lipless crankbaits lents",
                "Stick baits pour lancer (animation linéaire lente)",
                "Couleurs: argenté, dos olive, ventre blanc",
                
                // PRIORITÉ 3 - Leurres de Fond
                "Jigs têtes plombées 10-20g + trailers souples",
                "Drop shot imitation ver/crevette",
                "Carolina rig leurre souple",
                "Montage texan anti-accroche (herbiers)"
            ],
            
            appatsNaturels: [
                // Par ordre d'efficacité (régime naturel)
                "Crabes (entiers ou morceaux) - OPTIMAL",
                "Crevettes (vivantes ou mortes)",
                "Poulpes (morceaux)",
                "Calmars (lanières)",
                "Bivalves (chair de bénitier, huîtres)",
                "Petits poissons entiers (mulets, sardines)",
                "Oursins (chair - technique locale)",
                "Vers marins (secondaire)"
            ],
            
            meilleursHoraires: """
            **SAISON :** Mars à Août (OPTIMAL - activité alimentaire maximale)
            
            **À ÉVITER :** Septembre-Octobre (reproduction, activité alimentaire réduite, \
            estomacs souvent vides)
            
            **JOURNÉE :** Matin et après-midi (activité diurne confirmée Grande Terre/Province Nord)
            
            **MARÉE :** Pas de préférence marquée (activité constante, pas de pic coefficient)
            
            **LUNE :** Pas de données scientifiques. Traditions locales suggèrent éviter pleine lune.
            
            **CONDITIONS OPTIMALES :** Mer calme, eau claire, début de courant entrant (dispersion \
            odeurs appâts). Meilleurs rendements Ouvéa > Lagon SW > Province Nord.
            """,
            
            conditionsOptimales: """
            **MÉTÉO :**
            • Mer calme à peu agitée (accès fonds sableux)
            • Eau claire (visibilité alimentation benthique)
            • Vent <15 nœuds (précision pose palangre/lancer)
            
            **COURANT :**
            • Début courant entrant (dispersion odeurs)
            • Courant modéré (pas trop fort = accrochages)
            
            **EAU :**
            • Température : 22-28°C (optimum espèce tropicale)
            • Clarté : Bonne à moyenne
            • Salinité : Marine normale (évite estuaires)
            
            **FOND :**
            • Sable fin à moyen (habitat préférentiel)
            • Proximité récif-barrière (meilleure zone)
            • Présence structures isolées (patates)
            • Bordures herbiers (zones transition)
            
            **PRESSION :** Zones peu fréquentées > zones urbaines (stocks moins appauvris)
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 VALORISATION CULINAIRE & SÉCURITÉ
            // ═══════════════════════════════════════════
            
            qualiteCulinaire: """
             **CHAIR TRÈS PRISÉE - ESPÈCE COMMERCIALE #1 DU LAGON**
            
            **QUALITÉS GUSTATIVES :**
            • Chair blanche, ferme et fine
            • Saveur délicate, légèrement sucrée
            • Texture excellente (pas filandreuse)
            • Très peu d'arêtes
            • Tenue parfaite à la cuisson
            
            **PRÉPARATIONS RECOMMANDÉES :**
            • **Au four :** Entier ou filets avec aromates (classique NC)
            • **Grillé :** Filets plancha ou BBQ (excellent)
            • **Papillote :** Préserve moelleux et arômes
            • **Poisson cru :** À la tahitienne (chair ferme idéale)
            • **Court-bouillon :** Tradition calédonienne
            • **Frit :** Petits individus entiers
            • **Sashimi :** Chair ferme convient (ultra-frais)
            
            **CONSERVATION :**
            • Chair délicate : consommer rapidement (24-36h au frais)
            • Congélation acceptable si ultra-frais
            • Vider et écailler immédiatement après capture
            
            **PRIX MARCHÉ NC :** Élevé (espèce très recherchée, stocks limités zones urbaines)
            """,
            
            risqueCiguatera: .faible,
            
            ciguateraDetail: """
            ⚠️ **RISQUE FAIBLE MAIS PRÉSENT - PRUDENCE SELON TAILLE**
            
            Le Bec-de-cane N'EST PAS classé comme démersal profond (risque élevé), mais comme \
            **poisson lagonaire emblématique**. Cependant, étant strictement CARNIVORE et pouvant \
            atteindre grande taille, le risque ciguatera existe par bioaccumulation.
            
            **FACTEURS DE RISQUE :**
            • **Taille :** Grands spécimens (>50 cm, >3 kg) accumulent plus de toxines
            • **Âge :** Individus âgés (>7-8 ans) = bioaccumulation prolongée  
            • **Habitat :** Zones perturbées, passes, récifs dégradés = risque accru
            • **Régime carnivore :** Mange crustacés/mollusques/poissons (bioamplification)
            • **Hermaphrodisme :** Vieux individus = femelles (œufs à ne pas consommer)
            
            **RECOMMANDATIONS SÉCURITÉ :**
            ✅ Privilégier individus <45 cm (<2 kg) - RISQUE MINIMAL
            ✅ Prudence 45-55 cm (2-3.5 kg) - RISQUE FAIBLE
            ⚠️ Éviter >55 cm (>3.5 kg) - RISQUE MODÉRÉ (surtout femelles reproductrices)
            ❌ NE JAMAIS consommer viscères, tête, œufs, foie (concentration toxines)
            ✅ Renseigner zones à risque localement (pêcheurs expérimentés)
            ✅ Varier espèces consommées (ne pas manger que bec-de-cane)
            
            **COMPARAISON RISQUE :**
            • Bien INFÉRIEUR : Loches, Vivaneaux profonds, Carangues GT, Barracudas
            • SIMILAIRE : Autres Lethrinidae (Empereurs, Picots)
            • SUPÉRIEUR : Perroquets, Poissons-chirurgiens herbivores
            
            **CONSOMMATION NC :** Espèce consommée régulièrement sans incidents majeurs si \
            tailles <50 cm. Cas de ciguatera très rares, généralement gros individus >60 cm \
            de zones à risque connues.
            
            🏥 En cas de symptômes (fourmillements, démangeaisons, inversions chaud/froid, \
            troubles digestifs) : CONSULTER IMMÉDIATEMENT services urgences.
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 RÉGLEMENTATION & CONSERVATION
            // ═══════════════════════════════════════════
            
            reglementationNC: """
            ⚠️ **ABSENCE DE RÉGLEMENTATION SPÉCIFIQUE (2025) - PROBLÉMATIQUE**
            
            **STATUT ACTUEL :**
            • Aucune taille minimale de capture légale
            • Aucune période de fermeture
            • Aucun quota
            • Aucune limitation engins de pêche
            
            **PROBLÈME :** Espèce surexploitée zones urbaines sans protection réglementaire.
            
            **RECOMMANDATIONS SCIENTIFIQUES IRD (Borsa, Kulbicki 2009) :**
            
            **Taille minimale suggérée : 40 cm LF (Longueur Fourche)**
            • Permet au moins 1 reproduction avant capture
            • Maturité sexuelle : Mâles 35-40 cm, Femelles 40-45 cm
            • Âge première reproduction : 4-5 ans
            • Taille actuelle capture moyenne : 35-40 cm (TROP PETITE)
            
            **Protection habitats juvéniles : ESSENTIEL**
            • Herbiers et algueraies côtiers = nourriceries critiques
            • Juvéniles dépendent zones 0-5 m
            • Urbanisation côtière = menace principale
            • Inclure herbiers dans périmètres AMP
            
            **Période sensible : Septembre-Octobre (reproduction)**
            • Limiter pêche durant pic reproduction
            • Regroupements herbiers îlots = vulnérabilité
            
            **Limitation captures grandes femelles (>55 cm) :**
            • Sex-ratio biaisé : 70% femelles chez >60 cm
            • Grandes femelles = reproductrices clés
            • Hermaphrodisme protandre : capturer gros = retirer femelles
            
            **AUTRES LETHRINIDAE NÉCESSITANT GESTION SIMILAIRE :**
            • Lethrinus miniatus (Empereur/Picot)
            • Lethrinus lentjan
            • Lethrinus atkinsoni
            • Lethrinus harak
            • Lethrinus obsoletus
            """,
            
            quotas: """
            ⚠️ **AUCUN QUOTA ACTUELLEMENT (2025)**
            
            **PROPOSITION GESTION RATIONNELLE :**
            
            **Pêche récréative :**
            • 5 individus/pêcheur/jour MAX (toutes espèces Lethrinidae confondues)
            • Taille minimale 40 cm
            • Limiter prélèvement gros individus >55 cm (1/jour max)
            
            **Pêche professionnelle :**
            • Quotas par zone selon densités stocks
            • Zones urbaines (Nouméa) : Réduction effort 30-50%
            • Zones préservées (Ouvéa, Province Nord éloignée) : Quotas adaptés
            • Déclarations captures obligatoires
            • Maillage minimum filets (sélectivité taille)
            
            **Zones sensibles :**
            • Herbiers juvéniles : Pêche interdite
            • Regroupements reproduction (sept-oct, herbiers îlots) : Fermeture temporaire
            """,
            
            zonesInterdites: """
            ⚠️ **Vérifier Aires Marines Protégées (AMP) locales**
            
            Certaines réserves marines NC interdisent toute pêche. Consulter réglementation \
            provinciale (Sud, Nord, Îles) avant sortie.
            
            **Zones protection recommandées (non exhaustif) :**
            • Herbiers côtiers nourriceries (0-5 m)
            • Regroupements reproduction (herbiers îlots, sept-oct)
            • Zones récifs fragiles/dégradés (reconstitution)
            
            **Rappel :** Aires marines UNESCO Grande Terre = réglementation spécifique selon zones.
            """,
            
            statutConservation: """
            **STATUT CONSERVATION :**
            
            **UICN (Mondial) :** Non évalué spécifiquement. Genre Lethrinus = Préoccupation mineure
            
            **NOUVELLE-CALÉDONIE :** ⚠️ **LOCALEMENT SUREXPLOITÉ zones urbaines**

            
            **VULNÉRABILITÉ INTRINSÈQUE - MODÉRÉE :**
            ✅ Croissance relativement rapide (résilience)
            ❌ Maturité sexuelle tardive 4-5 ans (vulnérabilité)
            ❌ Hermaphrodisme protandre (capture sélective gros = perte femelles)
            ✅ Phase larvaire longue ~37j (brassage génétique = résilience)
            ❌ Dépendance habitats spécifiques herbiers juvéniles (vulnérables urbanisation)
            
            **PRESSIONS :**
            • Pêche : Espèce commerciale #1 = pression maximale
            • Habitat : Urbanisation côtière = destruction herbiers nourriceries
            • Pollution : Dégradation qualité eau lagonaire
            • Changement climatique : Élévation température, acidification
            
            **TENDANCE :** ⬇️ Déclin continu zones urbaines / ➡️ Stable zones isolées
            
            **ACTIONS CONSERVATION PRIORITAIRES :**
            1. Taille minimale capture 40 cm (réglementation)
            2. Protection herbiers nourriceries (AMP, limitation urbanisation)
            3. Quotas pêche professionnelle zones sensibles
            4. Sensibilisation pêcheurs récréatifs (relâcher petits)
            5. Suivi scientifique régulier stocks (monitoring)
            6. Fermeture temporaire zones reproduction (sept-oct)
            7. Contrôle accru braconnage AMP
            8. Recherche aquaculture (potentiel avéré, non exploité NC)
            """,
            
            // ═══════════════════════════════════════════
            // 🆕 PÉDAGOGIE & SENSIBILISATION
            // ═══════════════════════════════════════════
            
            leSaviezVous: """
            🧬 **HERMAPHRODISME PROTANDRE FASCINANT :**
            Tous les Becs-de-cane naissent MÂLES, puis deviennent FEMELLES avec l'âge/taille ! \
            Ce changement de sexe progressif explique le sex-ratio biaisé : 58% femelles globalement, \
            mais 70% chez les grands individus (>60 cm). Mécanisme assurant reproduction même si \
            peu d'individus, mais créant vulnérabilité : capturer gros poissons = retirer femelles \
            reproductrices !
            
            🏝️ **HABITATS ESSENTIELS - CYCLE DE VIE COMPLET :**
            Le Bec-de-cane a besoin d'un ENSEMBLE d'habitats pour compléter son cycle : (1) Herbiers \
            et algueraies côtiers (juvéniles 0-2 ans, 0-5 m) = NOURRICERIES CRITIQUES, (2) Fonds \
            sableux milieu lagon (sub-adultes 3-5 ans, 5-20 m), (3) Bordure récif-barrière (adultes \
            >5 ans, 20-40 m). Détruire UN SEUL de ces habitats = compromettre population entière ! \
            Protection herbiers = protection stock futur.
            
            🎣 **IMPORTANCE SOCIO-ÉCONOMIQUE MAJEURE :**
            Espèce #1 pêche lagonaire NC (avec Empereurs). Chair très prisée = prix élevé marché. \
            Pêche professionnelle + vivrière + récréative = pression maximale. Stocks zones urbaines \
            effondrés, mais espèce encore abondante zones isolées (Ouvéa). Potentiel aquacole avéré \
            (non exploité NC) = opportunité développement durable futur.
            
            ⚖️ **EXPLOITATION PROCHE MAXIMUM SOUTENABLE :**
            Caractéristiques vie (croissance moyenne, maturité 4-5 ans, hermaphrodisme) + niveau \
            actuel pêche = proche point rupture zones urbaines. Augmentation effort pêche = risque \
            effondrement stocks irréversible. Nécessité URGENTE gestion stricte (taille min, quotas, \
            protection habitats) pour assurer pérennité ressource.
            """,
            
            nePasPecher: false,  // Pêche autorisée mais gestion responsable recommandée
            
            raisonProtection: """
            ⚠️ **ESPÈCE SUREXPLOITÉE ZONES URBAINES - PÊCHE RESPONSABLE ESSENTIELLE**
            
            Bien que pêche autorisée, le Bec-de-cane nécessite GESTION RESPONSABLE pour éviter \
            effondrement stocks :
            
            **PÊCHE RESPONSABLE - ENGAGEMENTS VOLONTAIRES :**
            
            ✅ **Respecter taille minimale 40 cm** (permet 1 reproduction minimum)
            ✅ **Relâcher individus <40 cm** (futurs reproducteurs)
            ✅ **Limiter prélèvement gros >55 cm** (femelles reproductrices clés)
            ✅ **Éviter période reproduction** (septembre-octobre)
            ✅ **Ne pas pêcher herbiers côtiers** (zones juvéniles)
            ✅ **Limiter captures** (5 individus/sortie max recommandé)
            ✅ **Varier espèces ciblées** (réduire pression stock)
            ✅ **Partager bonnes pratiques** (sensibiliser autres pêcheurs)
            
            **SI TOUT LE MONDE RESPECTE CES RÈGLES :** Stock se reconstitue zones urbaines, \
            pêche pérenne assurée générations futures, espèce emblématique préservée !
            
            **ESPÈCE À PROTÉGER, PAS À INTERDIRE.** La solution = pêche RAISONNÉE, pas arrêt total.
            """
        )
        ,

        // ─────────────────────────────────────────────────────────────────────
        // THON À DENTS DE CHIEN
        // Sources : CPS 93 « La pêche à la traîne dans les îles du Pacifique »
        // (chap. 5 C, tombant externe ; chap. 7 D) ; « Critères de choix pour le
        // leurre » (hors lagon) ; « Consignes pour moteur stratégique ».
        // Tailles et poids maximaux : FishBase (à vérifier).
        // ─────────────────────────────────────────────────────────────────────
        EspeceInfo(
            identifiant: "thonDentsDeChien",
            nomCommun: "Thon à dents de chien",
            nomScientifique: "Gymnosarda unicolor",
            famille: "Scombridae",
            zones: [.tombant, .passe, .recif],
            profondeurMin: 10,
            profondeurMax: 250,
            typesPecheCompatibles: [.traine, .jig],
            traineInfo: TraineInfo(
                vitesseMin: 5.0,
                vitesseMax: 7.0,
                vitesseOptimale: 6.0,
                profondeurNageOptimale: "4-12m le long de la paroi",
                tailleLeurreMin: 14.0,
                tailleLeurreMax: 22.0,
                typesLeurresRecommandes: ["bavette plongeante (Magnum)", "jupe lestée", "jig (pêche verticale)"],
                couleursRecommandees: ["bleu/argent", "sardine", "violet/noir (aube, crépuscule)", "rose (eau teintée)"],
                positionsSpreadRecommandees: [.longCorner, .shotgun],
                notes: "Passes et tombant externe, à l'aube et au crépuscule. Après une prise, tourner au même endroit : d'autres suivent souvent."
            ),
            comportement: "Petites bandes le long des récifs barrière et des passes ; très curieux",
            momentsFavorables: [.aube, .crepuscule],
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "Thon élancé à grande bouche garnie de fortes dents coniques bien visibles, absentes chez les autres thons. Dos bleu-noir, flancs argentés sans rayures ni taches. Ligne latérale nettement ondulée. Extrémités de la seconde dorsale et de l'anale blanches.",
            tailleMinLegale: nil,
            tailleMaxObservee: 248.0,
            poidsMaxObserve: 131.0,
            descriptionPhysique: "Corps fuselé, plus allongé que celui du thon jaune. Mâchoires puissantes armées de dents coniques. Coloration sombre et uniforme sur le dos, argentée sur les flancs et le ventre. Les adultes pèsent en général une trentaine de kilos ; les plus grands dépassent 130 kg (CPS 93).",
            habitatDescription: "Contrairement aux autres thonidés du Pacifique, il ne s'aventure pas volontiers en pleine mer : il reste à proximité des récifs barrière et des récifs du large (CPS 93). On le trouve sur le tombant externe, là où la pente devient abrupte et où le fond atteint 25 à 50 m, et surtout dans les passes, pour lesquelles il a une prédilection.",
            comportementDetail: "Évolue en petites bandes de quelques individus. Sans être agressif, il est très curieux et s'approche souvent des plongeurs. Quand on en prend un, il y en a presque toujours d'autres dans le secteur. Les populations locales s'épuisent vite, même sous une pression de pêche modérée : les bonnes prises du début durent rarement (CPS 93).",
            techniquesDetail: "Traîne plongeante le long du tombant et à l'embouchure des passes, à l'aube ou à la tombée du jour. Suivre le tombant à la limite entre l'eau verte (au-dessus du récif) et l'eau bleue (au large), une couleur de chaque bord. À l'aplomb du tombant, on peut allonger et lester les lignes ou utiliser des leurres plongeants (CPS 93). Après une touche, tourner en rond au même endroit. Le jig vertical le long de la paroi est l'autre technique de référence.",
            leuresSpecifiques: [
                "Bavettes plongeantes 14-22 cm (X-Rap Magnum, Magnum Stretch)",
                "Jupes lestées",
                "Jigs métalliques (pêche verticale le long du tombant)"
            ],
            appatsNaturels: [
                "Bonite",
                "Sélar",
                "Aiguillette"
            ],
            meilleursHoraires: "Aube et tombée du jour (CPS 93).",
            conditionsOptimales: "Courant dans les passes et sur le tombant externe, lumière basse. Bas de ligne épais : ses dents et la paroi usent le nylon fin.",
            qualiteCulinaire: "Chair rose pâle, presque blanche, et non rouge comme celle des autres thons (CPS 93). Ferme ; plutôt à cuire.",
            risqueCiguatera: .faible,
            ciguateraDetail: "Thon récifal, à la différence des thons du large : des cas de ciguatera ont été rapportés dans l'Indo-Pacifique. Prudence avec les gros sujets là où la gratte est connue. À confirmer localement.",
            reglementationNC: "Pas de règle spécifique relevée dans les documents du Projet. Vérifier la réglementation de la province (Sud, Nord, Îles) avant de garder un poisson.",
            quotas: nil,
            zonesInterdites: "Respecter les aires marines protégées et les réserves.",
            statutConservation: "Populations locales vite épuisées, même par une pêche modérée (CPS 93) : relâcher les gros sujets.",
            leSaviezVous: "C'est le seul thon du Pacifique qui vit attaché au récif plutôt qu'au large, et le seul à avoir de vraies dents. Sa curiosité le pousse à venir observer les plongeurs.",
            nePasPecher: false,
            raisonProtection: nil
        ),

        // ─────────────────────────────────────────────────────────────────────
        // SÉRIOLE
        // Sources : « DIVERS TYPES DE NAGE » (jig high pitch au large, > 150 m ;
        // flutter et slow jig) ; « FICHES PÉDAGOGIQUES » (jigging vertical sur
        // tombants et monts sous-marins). Les documents du Projet sont minces
        // sur cette espèce : morphologie, tailles et risque de ciguatera
        // viennent de connaissances générales (FishBase), à vérifier.
        // ─────────────────────────────────────────────────────────────────────
        EspeceInfo(
            identifiant: "seriole",
            nomCommun: "Sériole",
            nomScientifique: "Seriola spp. (S. dumerili, S. rivoliana, S. lalandi)",
            famille: "Carangidae",
            zones: [.tombant, .profond],
            profondeurMin: 20,
            profondeurMax: 300,
            typesPecheCompatibles: [.jig, .montage],
            traineInfo: nil,
            comportement: "Bancs ou petits groupes sur le tombant profond, les monts sous-marins et les épaves ; chasse entre deux eaux et près du fond",
            momentsFavorables: [.aube, .matinee, .crepuscule],
            photoNom: nil,
            illustrationNom: nil,
            signesDistinctifs: "Corps allongé et fuselé, dos bleu-olive à brun, flancs argentés. Bande sombre oblique de l'œil à la nuque, nette chez la sériole couronnée (S. dumerili) et la sériole limon (S. rivoliana). Bande longitudinale jaune-bronze sur le flanc, très marquée chez S. lalandi. Caudale fourchue, sans scutelles.",
            tailleMinLegale: nil,
            tailleMaxObservee: 190.0,
            poidsMaxObserve: 80.0,
            descriptionPhysique: "Grande carangue pélagique au corps puissant et hydrodynamique, sans les écailles carénées (scutelles) des carangues du genre Caranx. Nageoires dorsale et anale longues et basses.",
            habitatDescription: "Plus en profondeur que les carangues de récif : bas du tombant, monts sous-marins, ruptures de pente au large. Remonte parfois en chasse vers la surface.",
            comportementDetail: "Prédateur de pleine eau, souvent en groupe. Suit volontiers un jig jusqu'au bateau avec ses congénères.",
            techniquesDetail: "Jig vertical : high pitch au large et sur les monts sous-marins au-delà de 150 m, flutter ou slow jig plus près du fond (« DIVERS TYPES DE NAGE »). Descendre le jig jusqu'au fond, puis l'animer par des à-coups brusques en le remontant (« FICHES PÉDAGOGIQUES »). Montage à l'appât vivant au-dessus des structures. Rarement prise à la traîne : seulement avec un leurre très plongeant au-dessus d'un haut-fond.",
            leuresSpecifiques: [
                "Jigs métalliques 150-400 g (high pitch, slow pitch)",
                "Jigs flutter",
                "Gros leurres souples plombés"
            ],
            appatsNaturels: [
                "Sélar vivant",
                "Bonite",
                "Calmar"
            ],
            meilleursHoraires: "Début de matinée et crépuscule ; toute la journée en profondeur.",
            conditionsOptimales: "Courant modéré sur les monts sous-marins et le bas du tombant ; échosondeur indispensable pour repérer les bancs suspendus.",
            qualiteCulinaire: "Chair blanche et ferme, excellente crue (sashimi) comme cuite pour les sujets moyens.",
            risqueCiguatera: .modere,
            ciguateraDetail: "Les grosses sérioles, surtout la sériole couronnée, figurent parmi les poissons impliqués dans des cas de ciguatera. Prudence avec les gros sujets ; garder de préférence les poissons moyens.",
            reglementationNC: "Pas de règle spécifique relevée dans les documents du Projet. Vérifier la réglementation de la province avant de garder un poisson.",
            quotas: nil,
            zonesInterdites: "Respecter les aires marines protégées et les réserves.",
            statutConservation: nil,
            leSaviezVous: "La sériole n'est pas une « vraie » carangue du genre Caranx : elle n'a pas la rangée d'écailles dures (scutelles) le long de la queue.",
            nePasPecher: false,
            raisonProtection: nil
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
                "Bec de canne"
            ],
            .recif: [
                "Carangue GT",
                "Loche pintade",
                "Loche aréolée",
                "Bec de cane",
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
                "Bec de cane",
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
