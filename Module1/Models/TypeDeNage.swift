//
//  TypeDeNage.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 29/12/2025.
//

import Foundation

// MARK: - Type de Nage Enrichi (Version 2.0 avec Wobbling Large/Serré)

enum TypeDeNage: String, CaseIterable, Codable {
    case rectiligneStable = "Nage rectiligne stable"
    case wobbling = "Wobbling"  // ← Déclencheur de choix
    case wobblingLarge = "Wobbling large"
    case wobblingSerré = "Wobbling serré"
    case rolling = "Rolling"
    case wobblingRolling = "Wobbling + rolling"
    case darting = "Darting"
    case walkTheDog = "Walk the Dog"
    case slashing = "Slashing"
    case flutter = "Flutter"
    case falling = "Falling"
    case jigging = "Jigging"  // ← Déclencheur de choix
    case slowJigging = "Slow jigging"
    case fastJigging = "Fast jigging"
    case paddleSwimming = "Paddle swimming"
    case vibration = "Vibration"
    case rattling = "Rattling"
    case popping = "Popping"
    case thumping = "Thumping"
    case balayageLarge = "Nage de balayage large"
    case plongeanteControlee = "Nage plongeante contrôlée"
    case deriveNaturelle = "Dérive naturelle"
    case nageSuspendue = "Nage suspendue"
    
    // MARK: - Indicateur si c'est un déclencheur de choix
    var requiresChoice: Bool {
        return self == .wobbling || self == .jigging
    }
    
    // MARK: - Description technique enrichie
    var description: String {
        switch self {
        case .rectiligneStable:
            return "Déplacement en ligne droite sans oscillation marquée. Trajectoire stable et prévisible. Imite un poisson sain en déplacement normal."
            
        case .wobbling:
            return "Oscillation latérale du leurre. Choisissez la variante adaptée à votre leurre (large ou serré) selon la largeur de la bavette."
            
        case .wobblingLarge:
            return "Oscillation latérale ample, lente à modérée. Amplitude élevée, fréquence basse. Le leurre balaie largement de gauche à droite. Déplace beaucoup d'eau, détecté de loin par la ligne latérale. Simule un poisson en difficulté ou nonchalant. Provoque des attaques réflexes violentes."
            
        case .wobblingSerré:
            return "Oscillation latérale de faible amplitude, régulière et rapide, sans grands écarts. Le leurre tremble plus qu'il n'ondule. Trajectoire très stable, signature discrète mais continue. Imite un poisson sain en déplacement normal. Ne décroche pas même à vitesse soutenue ou en courant. Provoque des attaques calculées."
            
        case .rolling:
            return "Rotation axiale continue autour de l'axe longitudinal. Effet hypnotique par les reflets lumineux. Action subtile privilégiant l'attraction visuelle plutôt que vibratoire."
            
        case .wobblingRolling:
            return "Combinaison d'oscillation latérale et rotation axiale. Action complexe et attractive générant vibrations ET reflets. Nage réaliste polyvalente."
            
        case .darting:
            return "Changements de direction brusques et imprévisibles. Écarts saccadés imitant une proie affolée ou blessée. Provoque des attaques réflexes par irritation et opportunisme."
            
        case .walkTheDog:
            return "Nage en zigzag latéral horizontal en surface. Animation saccadée gauche-droite obtenue par twitchs du scion. Crée un sillage en V attractif. Efficace sur poissons en chasse active."
            
        case .slashing:
            return "Mouvements de fuite rapides et violents. Trajectoire erratique et agressive simulant une proie terrorisée. Déclenche l'instinct de prédation par stimulation visuelle intense."
            
        case .flutter:
            return "Battements verticaux rapides en descente. Papillonnement imitant un poisson blessé tombant vers le fond. Signature vibratoire particulière en chute. Touche fréquente à la descente."
            
        case .falling:
            return "Chute libre ralentie avec léger planage. Trajectoire verticale naturelle sans rotation excessive. Descente contrôlée imitant un poisson mort ou mourant. Action passive mais efficace."
            
        case .jigging:
            return "Technique verticale avec jig métallique. Choisissez la variante adaptée à l'activité des poissons (fast pour actifs, slow pour calés)."
            
        case .slowJigging:
            return "Technique verticale japonaise de finesse et précision fondée sur la chute contrôlée. Animation : levée lente de la canne 30-60cm, descente accompagnée avec relâchement complet pour créer un papillotement désaxé et imprévisible. Le jig (plat ou asymétrique, centre de gravité décentré) papillonne, décroche latéralement, change d'axe et expose alternativement ses flancs. 70% des touches ont lieu pendant la descente. Imite une proie blessée ou mourante, non la vitesse. Principe : le contrôle excessif tue l'efficacité - si vous sentez trop votre jig, vous pêchez trop vite."
            
        case .fastJigging:
            return "Technique verticale dynamique et physique fondée sur la vitesse et la stimulation maximale. Animation : tirées franches et rythmées 1-2m + moulinage rapide constant 6-12 tours pour remonter rapidement le jig compact. Le jig vibre fortement, file droit ou en léger S, produit un signal hydrodynamique intense imitant une proie paniquée fuyant vers la surface. L'attaque se déclenche pendant la remontée par réflexe de poursuite, non par opportunisme. Technique engageante et sélective : le fast jigging ne convainc pas, il provoque. S'il n'y a pas de réaction rapide, ce n'est pas la bonne technique au moment considéré."
            
        case .paddleSwimming:
            return "Ondulations continues et fluides du corps. Nage souple imitant parfaitement le déplacement naturel d'un poisson. Signature hydrodynamique réaliste. Efficace en récupération linéaire."
            
        case .vibration:
            return "Vibrations rapides et fines, tremblements haute fréquence. Génère des ondes de pression attractives détectées par la ligne latérale même en eau trouble. Signature vibratoire dominante."
        
        case .rattling:
            return "Vibration forte et erratique où la bille accentue les ondes sonores et les secousses lors de la récupération linéaire rapide. Cette action imite une proie en panique, avec des côtés plats qui amplifient le roulis et le bruit. Le terme rattling « bruiteur » est donc fonctionnel : il renvoie à la présence de billes sonores, quelle que soit la famille du leurre. Il induit une technique de pêche légèrement différente. Cf Fiches Techniques."
            
        case .popping:
            return "Pêche spectaculaire, mais surtout très codifiée consistant à animer un popper par des tirées sèches, afin de produire un “pop” sonore, une gerbe d’eau, et une immobilisation brutale du leurre. Le popper ne nage pas. Il évoque une proie paniquée en surface, un poisson blessé, ou une intrusion sur un territoire et déclenche agressivité, réflexe de dominqtion et compétition alimentaire."
            
        case .thumping:
            return "Pulsations profondes et sourdes. Vibrations basse fréquence percutantes créant une onde de choc. Signal hydrodynamique puissant perçu à longue distance. Attractivité sur gros poissons."
            
        case .balayageLarge:
            return "Large balayage latéral en traîne. Déplacement ample et visible de loin. Amplitude importante créant une forte turbulence. Prospection large et rapide."
            
        case .plongeanteControlee:
            return "Descente progressive avec oscillations modérées. Profondeur variable selon la vitesse de traîne. Trajectoire oblique contrôlée explorant plusieurs couches d'eau."
            
        case .deriveNaturelle:
            return "Flottaison passive portée par le courant. Présentation naturelle et discrète sans action forcée. Le leurre suit le mouvement de l'eau. Efficace sur poissons très méfiants."
            
        case .nageSuspendue:
            return "Maintien en suspension à profondeur constante. Équilibre neutre (flottant ou suspending) permettant des pauses sans remontée ni descente. Animation subtile par simple secousse du scion."
        }
    }
    
    // MARK: - Catégorie du type de nage
    var categorie: String {
        switch self {
        case .rectiligneStable, .wobbling, .wobblingLarge, .wobblingSerré, .rolling, .wobblingRolling, .popping:
            return "I. Nages linéaires continues"
        case .darting, .walkTheDog, .slashing:
            return "II. Nages erratiques et désordonnées"
        case .flutter, .falling, .jigging, .slowJigging, .fastJigging, .rattling:
            return "III. Nages verticales et semi-verticales"
        case .paddleSwimming, .vibration, .thumping:
            return "IV. Nages ondulantes et vibratoires"
        case .balayageLarge, .plongeanteControlee:
            return "V. Nages spécifiques à la traîne"
        case .deriveNaturelle, .nageSuspendue:
            return "VI. Nages passives ou induites"
        }
    }
    
    // MARK: - Conditions d'utilisation idéales (enrichies)
    var conditionsIdeales: String {
        switch self {
        case .rectiligneStable:
            return "Eau claire, poissons actifs, vitesse constante, prospection rapide"
            
        case .wobbling:
            return "Conditions variables - choisir large (eau trouble) ou serré (eau claire)"
            
        case .wobblingLarge:
            return "Eau teintée ou chargée, faible luminosité, courant modéré, poissons actifs, bordures de patates, entrées de passes. Excellent pour déclenchement réflexe. Éviter : eau ultra-claire, poissons méfiants."
            
        case .wobblingSerré:
            return "Eau claire à légèrement teintée, forte luminosité, poissons éduqués ou sollicités, courant modéré à soutenu, bordures récifales peu profondes, passes calmes. Excellent pour poissons suiveurs. Vitesse traîne 5-6,5 nœuds."
            
        case .rolling:
            return "Eau claire, forte luminosité, effet flash recherché, poissons réactifs aux reflets, traîne moyenne"
            
        case .wobblingRolling:
            return "Conditions variables, recherche active, polyvalence maximale, compromis efficace"
            
        case .darting:
            return "Poissons chasseurs actifs, eaux vives, animations saccadées, territorialité marquée, récifs et structures"
            
        case .walkTheDog:
            return "Surface calme, poissons en chasse, aurore/crépuscule, faible profondeur, herbiers ou zones dégagées"
            
        case .slashing:
            return "Prédateurs agressifs, eaux agitées, frénésie alimentaire, mer formée, chasses visibles"
            
        case .flutter:
            return "Jigging vertical, profondeur 30-150m, poissons pélagiques, descente rapide recherchée, touche à la chute"
            
        case .falling:
            return "Pêche profonde >100m, chasses sur bancs de poissons-fourrage, verticale lente"
            
        case .jigging:
            return "Technique verticale - choisir fast (poissons actifs) ou slow (poissons calés)"
            
        case .slowJigging:
            return "Poissons calés sur le fond, peu actifs, méfiants ou éduqués. Courant modéré 1-2 nœuds, dérive lente moteur coupé, verticalité sous bateau cruciale. Lagune sud/nord 20-100m (vivaneaux, pagres, carangues, mérous), DCP/passe 50-150m (thon jaune, denti), tombants offshore 150-300m+ (loches pintade, vivaneaux profonds, thon obèse). Animation : 20-50m = 1/8 tour 40-80g, 50-150m = 1/4 tour 100-250g, >150m = 1/2 tour 250-400g. Matériel : cannes PE 1-3 slow action parabolique, tresse PE 1-2.5 multicolore, ratio 5:1 lent, jigs plats/arrondis glow. Règle : doublez le grammage par rapport à la profondeur. Pêchez fin pour détection touches, changez spots si poissons se lassent."
            
        case .fastJigging:
            return "Poissons actifs et agressifs, chasses visibles, frénésie alimentaire, courant établi, forte oxygénation, luminosité correcte. Passes lagune 30-100m (carangues GT, barracudas, thon jaune), DCP offshore 100-250m (wahoo 10-16 nds équivalent, thazard bâtard, bonites), profond >250m (thon obèse, sérioles, mahi-mahi). Animation : 30-100m = tirée 80-120cm + 6-8 tours 80-200g, 100-250m = tirée 120-180cm + 8-10 tours 200-400g, >250m = tirée 180-250cm + 10-12 tours 400-800g. Matériel : cannes extra fast PE 3-6 blank raide, moulinets 10000-30000 ratio 5.5:1+, tresse PE 4-8, jigs stick coniques/heavy tapered, câble acier wahoo/thazard. Sessions courtes 15-20min (fatigant), alternez spots DCP. Si refus, basculez en slow."
            
        case .paddleSwimming:
            return "Eau claire, imitation naturelle prioritaire, vitesse lente à moyenne, récupération linéaire, poissons calés"
            
        case .vibration:
            return "Eau trouble ou teintée, visibilité réduite, ligne latérale sensible, détection vibratoire prioritaire, nuit"
            
        case .rattling:
            return "Eau trouble, faible luminosité, en cas de mer avec clapot ou du courant. Le poisson compense la vue par ses sens mécaniques. Le bruit devient un repère spatial."
            
        case .popping:
            return "Mer ridée, eau claire à légèregement teintée, sur des poissons actifs spécialement sur chasses vsibles."
            
        case .thumping:
            return "Grande profondeur, gros poissons, attractivité longue distance, eaux profondes >50m, pélagiques de taille"
            
        case .balayageLarge:
            return "Traîne hauturière offshore, vitesse moyenne à rapide 8-12 nœuds, prospection large, pélagiques rapides"
            
        case .plongeanteControlee:
            return "Traîne côtière, profondeur ajustable 5-15m, vitesse variable, bordures de récifs"
            
        case .deriveNaturelle:
            return "Courant faible à modéré, poissons très méfiants, présentation ultra-naturelle, eau calme, forte pression"
            
        case .nageSuspendue:
            return "Eau calme, poissons suspendus en mi-eau, pauses longues efficaces, animation minimaliste, poissons apathiques"
        }
    }
    
    // MARK: - Technique de pêche recommandée
    var techniqueRecommandee: String {
        switch self {
        case .rectiligneStable:
            return "Traîne rapide, lancer-ramener linéaire"
        case .wobbling:
            return "Traîne ou lancer - voir variantes Large/Serré"
        case .wobblingLarge:
            return "Traîne légère 5-6 nœuds, lancer-ramener lent, distance courte 20-30m"
        case .wobblingSerré:
            return "Traîne légère 5-6,5 nœuds, lancer-ramener continu sans twitch, sortie courte"
        case .rolling:
            return "Traîne moyenne, récupération continue"
        case .wobblingRolling:
            return "Traîne polyvalente, lancer-ramener varié"
        case .darting:
            return "Lancer twitché, tirées sèches, pauses courtes"
        case .walkTheDog:
            return "Lancer surface, twitchs réguliers du scion"
        case .slashing:
            return "Lancer rapide, récupération agressive"
        case .flutter:
            return "Jigging vertical, descente libre, relâcher complet"
        case .falling:
            return "Slow jigging, relâchements progressifs, pauses longues"
        case .jigging:
            return "Jigging vertical - voir variantes Slow/Fast"
        case .slowJigging:
            return "Jigging vertical lent, tirées 10-30cm, 1/8-1/2 tour moulinet, descente papillonnante"
        case .fastJigging:
            return "Jigging vertical rapide, tirées 1-2m, 6-12 tours moulinet, remontée explosive"
        case .paddleSwimming:
            return "Lancer-ramener linéaire, traîne lente"
        case .vibration:
            return "Récupération continue moyenne à rapide"
        case .rattling:
            return "Twitching/Jerking, Walking th Dog, Stop & Go, Récupération linéaire, Fast Pitch/Slow Pitch Jiggig, Montage traîne simple"
        case .popping:
            return "Lancer-Ramener, Saccadés les pauses sont plus importantes que les tirées"
        case .thumping:
            return "Jigging lourd, coups de scion amples"
        case .balayageLarge:
            return "Traîne rapide offshore"
        case .plongeanteControlee:
            return "Traîne côtière variable"
        case .deriveNaturelle:
            return "Dérive naturelle au courant, animation minime"
        case .nageSuspendue:
            return "Lancer avec pauses prolongées, jerking léger"
        }
    }
}
