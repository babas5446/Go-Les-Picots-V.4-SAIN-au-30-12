# Go Les Picots V.4 - Récapitulatif des modifications du 19 décembre 2024

## 📋 Vue d'ensemble

Mise en œuvre complète des améliorations du Module 2 (Suggestion IA) selon la feuille de route d'Opus 4.5.

---

## ✅ Phase 1 : Mise à jour enum PositionSpread

### Fichiers modifiés
- `Leurre.swift`
- `SuggestionEngine.swift`
- `SpreadVisualizationView.swift`
- `EspecesDatabase.swift`

### Modifications

#### 1.1 Nouvelle nomenclature (Leurre.swift)

**Anciennes valeurs supprimées** :
- `.rigger`
- `.riggerBabord`
- `.riggerTribord`

**Nouvelles valeurs** :
- `.shortRigger` (Short Rigger 40-60m)
- `.longRigger` (Long Rigger 50-70m)

**Ordre logique** :
```swift
enum PositionSpread {
    case libre           // Variable
    case shortCorner     // 10-20m - Agressif, naturel, dans les bulles
    case longCorner      // 30-50m - Sombre, silhouette
    case shortRigger     // 40-60m - Flashy, attracteur latéral
    case longRigger      // 50-70m - Flashy, couleur différente
    case shotgun         // 70-100m - Discret, fort contraste, très loin
}
```

#### 1.2 Mise à jour des références

**SuggestionEngine.swift** :
- Attribution des positions selon nombre de lignes :
  - 1 ligne : `.libre`
  - 2 lignes : `.shortCorner`, `.shortRigger`
  - 3 lignes : `.shortCorner`, `.longCorner`, `.shortRigger`
  - 4 lignes : `.shortCorner`, `.longCorner`, `.shortRigger`, `.longRigger`
  - 5 lignes : toutes + `.shotgun`

**EspecesDatabase.swift** :
- Toutes les occurrences de `.riggerBabord` → `.shortRigger`
- Toutes les occurrences de `.riggerTribord` → `.longRigger`

**SpreadVisualizationView.swift** :
- Emoji et couleurs mis à jour
- Positions de départ des lignes ajustées

---

## ✅ Phase 2 : Profil Bateau

### Fichiers modifiés
- `Leurre.swift`
- `ConditionsPeche.swift`
- `SuggestionInputView.swift`

### Modifications

#### 2.1 Enum ProfilBateau (Leurre.swift)

```swift
enum ProfilBateau: String, Codable, CaseIterable, Hashable {
    case classique = "classique"
    case clark429 = "clark429"
    
    var vitesseReference: Double {
        // Classique: 7.0 nœuds
        // Clark 4,29 m: 5.5 nœuds
    }
    
    var vitesseOptimaleMin/Max: Double
    var nombreLignesRecommande: Int
    var description: String
}
```

**Caractéristiques** :
- **Classique** : Vitesse 6-12 nœuds, jusqu'à 5 lignes, shotgun autorisé
- **Clark 4,29 m** : Vitesse 5.2-6.2 nœuds, max 4 lignes recommandé, shotgun conditionnel

#### 2.2 Intégration ConditionsPeche

Ajout du champ :
```swift
var profilBateau: ProfilBateau = .classique
```

#### 2.3 Interface utilisateur (SuggestionInputView)

Nouveau sélecteur dans la section "Configuration spread" :
- Deux boutons : Classique / Clark 4,29 m
- Ajustement automatique : Si Clark sélectionné et > 4 lignes → réduction à 4 lignes
- Description du profil affichée

---

## ✅ Phase 3 : Calcul Dynamique des Distances

### Fichier modifié
- `SuggestionEngine.swift`

### Modifications

#### 3.1 Fonctions ajoutées

**`wavesVersMètres(_ waves: Double) -> Int`**
- Convertit les waves en mètres
- Formule : `ceil(waves * 7.5)`
- Exemples : 1 wave → 8m, 2.5 waves → 19m

**`shotgunAutorise(profil, vitesse, profondeur, zone) -> Bool`**
- Vérifie si le shotgun est autorisé
- Clark 4,29 m : vitesse ≥ 6.5 nœuds, profondeur > 20m, zone ouverte
- Classique : toujours autorisé si 5 lignes

**`calculerDistancesDynamiques(conditions) -> [PositionSpread: Int]`**
- Calcul complet des distances adaptées

#### 3.2 Algorithme de calcul

**Étape 1 : Presets par espèce (en waves)**

| Espèce | Short Corner | Long Corner | Short Rigger | Long Rigger | Shotgun |
|--------|--------------|-------------|--------------|-------------|---------|
| Thazard | 1.2 | 2.2 | 2.8 | 3.2 | 4.5 |
| Wahoo | 1.5 | 2.8 | 3.6 | 4.2 | 5.5 |
| Carangue GT | 1.0 | 2.0 | 2.4 | 3.0 | 0 (non) |
| Loche | 0.9 | 1.7 | 2.2 | 2.8 | 0 (non) |
| Thon jaune | 1.3 | 2.4 | 3.2 | 3.8 | 5.5 |
| Mahi-mahi | 1.0 | 2.0 | 2.6 | 3.2 | 4.5 |
| Bonite | 1.1 | 2.1 | 2.7 | 3.2 | 5.0 |
| Mix (défaut) | 1.0 | 2.0 | 2.8 | 3.5 | 5.0 |

**Étape 2 : Ajustement selon vitesse**

Coefficients par nœud d'écart avec vitesse de référence :
- Short/Long Corner : ±0.20 wave/nœud
- Short/Long Rigger : ±0.30 wave/nœud
- Shotgun : ±0.40 wave/nœud

**Étape 3 : Ajustements selon conditions**

| Condition | Ajustement |
|-----------|------------|
| Mer formée/agitée | -0.4 wave (toutes positions) |
| Eau très claire | +0.3 wave (riggers uniquement) |
| Eau trouble | -0.3 wave (toutes positions) |
| Zone lagon | -0.3 wave (toutes positions) |

**Étape 4 : Garde-fous**

**Profil Classique** :
- Short Corner : 1.0-3.0 waves (8-23m)
- Long Corner : 2.0-4.0 waves (15-30m)
- Short Rigger : 3.0-6.0 waves (23-45m)
- Long Rigger : 4.0-7.0 waves (30-53m)
- Shotgun : 5.0-9.0 waves (38-68m)

**Profil Clark 4,29 m** :
- Short Corner : 0.8-2.0 waves (6-15m)
- Long Corner : 1.5-3.0 waves (12-23m)
- Short Rigger : 2.0-4.0 waves (15-30m)
- Long Rigger : 2.5-4.5 waves (19-34m)
- Shotgun : 4.0-5.0 waves (30-38m)

**Étape 5 : Ordre strict**

Vérification : Short Corner < Long Corner < Short Rigger < Long Rigger < Shotgun

Si une position ≤ position précédente → ajout de 0.5 wave minimum

Shotgun jamais < Long Rigger + 0.7 wave

#### 3.3 Intégration dans genererSpread()

- Appel de `calculerDistancesDynamiques()`
- Attribution des distances calculées à chaque suggestion
- Vérification shotgun autorisé pour Clark 4,29 m
- Justifications de position mises à jour avec distances réelles
- Distance moyenne calculée depuis positions réelles

---

## ✅ Phase 4 : SpreadSchemaView - Vue interactive

### Fichier créé
- `SpreadSchemaView.swift` (nouveau)

### Fichier modifié
- `SuggestionResultView.swift`

### Modifications

#### 4.1 SpreadSchemaView.swift

**Architecture** :
- Vue GeometryReader pour adaptation responsive
- Image de fond : `spread_template_ok.png` (1024 × 1536)
- 7 bulles interactives positionnées précisément

**Positions des bulles** (coordonnées design 1024×1536) :

| ID | Position | Centre (x, y) | Diamètre |
|----|----------|---------------|----------|
| 0L | Libre gauche | (138.5, 558.5) | 162.0 |
| 0 | Libre centre | (515.0, 558.5) | 162.0 |
| 1 | Short Corner | (779.5, 494.0) | 168.5 |
| 2 | Long Corner | (515.0, 826.5) | 157.5 |
| 3 | Short Rigger | (879.5, 953.5) | 163.0 |
| 4 | Long Rigger | (145.0, 956.5) | 165.5 |
| 5 | Shotgun | (657.0, 1201.0) | 165.0 |

**Fonctionnalités** :
- Calcul automatique du scale selon taille d'écran
- Animation d'apparition (fade in 1.2s)
- Bulles avec gradient radial et couleur selon position
- Affichage : emoji, nom position, distance
- Style de bouton avec animation de pression (scale effect)

**Interaction** :
- Tap sur bulle → surimpression fiche détaillée du leurre
- Tap sur fond ou fiche → fermeture avec animation spring
- Transition fluide (opacity + spring)

#### 4.2 LeurreDetailSheet (fiche détaillée)

**Contenu** :
- En-tête : emoji position + nom position + nom leurre + marque
- Score total (badge coloré /100)
- Couleur principale avec rond coloré
- Caractéristiques : longueur, profondeur, vitesse
- Barres de score (Technique /40, Couleur /30, Conditions /30)
- Justifications complètes dans boîtes colorées
- Astuce pro avec icône ampoule
- Distance recommandée

**Design** :
- Scroll vertical pour contenu long
- Fond blanc avec coins arrondis (24px)
- Ombre portée importante pour effet modal
- Max width 600pt pour tablettes
- Padding 24pt

#### 4.3 SuggestionResultView.swift

**Nouvel onglet "Schéma"** :
- 4 onglets au total : Top / Spread / **Schéma** / Tous
- Icône : `photo.fill`
- Tag : 2
- Affiche `SpreadSchemaView` si configuration disponible

---

## 🔧 Corrections de bugs

### Bug 1 : Extension PositionSpread avec anciennes valeurs
**Fichier** : `SpreadVisualizationView.swift`
**Erreur** : Références à `.rigger`, `.riggerBabord`, `.riggerTribord`
**Correction** : Mise à jour des emoji et couleurs avec nouvelles positions

### Bug 2 : Type Turbidite incorrect
**Fichier** : `SuggestionEngine.swift`
**Erreur** : `.turbide` n'existe pas
**Correction** : Remplacé par `.tresTrouble`

### Bug 3 : Format string specifier
**Fichier** : `Leurre.swift`
**Erreur** : `\(vitesse, specifier: "%.1f")` syntaxe incorrecte
**Correction** : `\(String(format: "%.1f", vitesse))`

---

## 📦 Assets requis

### Image à ajouter au projet
**Nom** : `spread_template_ok.png` ou `spread_template_ok`
**Taille** : 1024 × 1536 pixels
**Format** : PNG
**Emplacement** : Assets.xcassets

> ⚠️ **Important** : L'image doit être ajoutée dans le catalogue d'assets Xcode avec le nom exact `spread_template_ok` pour que `SpreadSchemaView` fonctionne.

---

## 🧪 Tests recommandés

### Test 1 : Profil Classique
- Conditions : 5 lignes, 7 nœuds, large, thazard
- Vérifier : Distances croissantes, shotgun présent

### Test 2 : Profil Clark, spread court
- Conditions : 3 lignes, 5.5 nœuds, lagon
- Vérifier : Distances courtes, pas de shotgun

### Test 3 : Profil Clark, shotgun désactivé
- Conditions : 5 lignes, 5 nœuds, lagon, profondeur 10m
- Vérifier : Shotgun automatiquement désactivé (vitesse insuffisante)

### Test 4 : Profil Clark, shotgun activé
- Conditions : 5 lignes, 7 nœuds, large, profondeur 30m
- Vérifier : Shotgun présent (conditions remplies)

### Test 5 : Espèce GT
- Conditions : 5 lignes, espèce carangueGT
- Vérifier : Distances courtes, shotgun non recommandé

### Test 6 : Vitesse haute
- Conditions : 9 nœuds (classique)
- Vérifier : Distances allongées

### Test 7 : Mer formée
- Conditions : etatMer = .formee
- Vérifier : Distances raccourcies

### Test 8 : Eau très claire
- Conditions : turbiditeEau = .claire
- Vérifier : Riggers allongés

### Test 9 : Schéma interactif
- Aller dans onglet "Schéma"
- Vérifier : Image affichée, bulles positionnées
- Tap sur bulle : fiche leurre s'affiche
- Tap sur fond : fiche se ferme

### Test 10 : Ordre des positions
- Toute configuration
- Vérifier : Short Corner < Long Corner < Short Rigger < Long Rigger < Shotgun

---

## 📝 Notes techniques

### Architecture
- Calculs de distances : pur Swift (pas de dépendances externes)
- UI : 100% SwiftUI natif
- Animations : spring et easeInOut
- Responsive : GeometryReader pour adaptation écran

### Performance
- Calculs dynamiques exécutés une seule fois par génération de suggestion
- Pas de recalcul en temps réel
- Images : chargement asynchrone géré par SwiftUI

### Compatibilité
- iOS 15+
- iPadOS 15+
- Testé sur iPhone et iPad (simulateurs)

---

## 🎯 Conformité CPS

Toutes les modifications respectent :
- **Techniques de pêche CPS 2025**
- **Manuel de choix de leurre**
- **Réglage dynamique longueur de ligne** (document PDF fourni)

Distances calculées selon :
- Vitesse du bateau
- Type de bateau (classique vs Clark 4,29 m)
- Espèce ciblée
- Conditions marines (mer, turbidité)
- Zone de pêche

---

## ✅ Checklist de livraison

- [x] Phase 1 : Enum PositionSpread mise à jour
- [x] Phase 2 : Profil Bateau implémenté
- [x] Phase 3 : Calcul dynamique des distances
- [x] Phase 4 : SpreadSchemaView créé et intégré
- [x] Corrections de bugs (3 bugs résolus)
- [x] Documentation complète
- [ ] Image `spread_template_ok.png` ajoutée aux assets
- [ ] Tests utilisateur effectués

---

## 🚀 Prochaines étapes suggérées (hors scope)

1. **Animations de déploiement des lignes** (priorité moyenne)
   - Lignes qui se déploient progressivement
   - Leurres qui apparaissent au bout des lignes
   - Délai séquentiel (0.2s entre chaque)

2. **Mode paysage optimisé pour SpreadSchemaView**
   - Meilleur usage de l'espace horizontal
   - Rotation automatique de l'image si besoin

3. **Export PDF du spread**
   - Génération PDF avec schéma + détails leurres
   - Partage AirDrop/Message

4. **Historique des sessions**
   - Sauvegarder configurations testées
   - Comparaison de performances

5. **Mode nuit**
   - Adaptation des couleurs pour navigation nocturne
   - Luminosité réduite automatique

---

**Date de livraison** : 19 décembre 2024  
**Version** : Go Les Picots V.4  
**Module** : Module 2 - Suggestion IA  
**Développé avec** : Claude (Sonnet 3.5)  
**Basé sur la feuille de route de** : Opus 4.5
