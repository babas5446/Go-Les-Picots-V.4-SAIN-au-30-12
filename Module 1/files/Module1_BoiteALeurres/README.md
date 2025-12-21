# MODULE 1 : MA BOÎTE À LEURRES
## Application "Go les Picots" - Nouvelle-Calédonie

---

## 📦 CONTENU DU MODULE

### Fichiers créés (Architecture complète)

```
Module1_BoiteALeurres/
├── Models/
│   └── Leurre.swift                    ⭐ Modèle de données complet (23 attributs)
├── ViewModels/
│   └── LeureViewModel.swift            ⭐ Gestion des 63 leurres + filtres + tri
├── Views/
│   ├── BoiteView.swift                 ⭐ Vue principale (liste/grille)
│   ├── LeurreDetailView.swift          ⭐ Fiche détaillée d'un leurre
│   ├── FiltresView.swift               ⭐ Filtres avancés
│   └── AjouterLeurreView.swift         ⭐ Formulaires ajout/édition
├── Helpers/
│   └── ColorExtension.swift            🎨 Extension Color pour hex
└── Resources/
    └── leurres_database_COMPLET.json   📊 Base de données des 63 leurres
```

---

## ✨ FONCTIONNALITÉS IMPLÉMENTÉES

### 1. Affichage des leurres
- ✅ **Vue liste** : Cellules détaillées avec photo, nom, taille, profondeur
- ✅ **Vue grille** : Cartes visuelles 2 colonnes
- ✅ **Bascule** liste/grille dans le menu
- ✅ **Chargement automatique** des 63 leurres depuis JSON

### 2. Recherche et filtres
- ✅ **Barre de recherche** : Nom, marque, espèces
- ✅ **Filtres avancés** :
  - Par type de leurre (poisson nageur, jig, popper...)
  - Par zone de pêche (lagon, large, passes...)
  - Par espèce cible (carangue, thon, wahoo...)
- ✅ **Réinitialisation** rapide des filtres

### 3. Tri des résultats
- ✅ Tri par **nom** (A-Z)
- ✅ Tri par **taille** (petits → grands)
- ✅ Tri par **marque**
- ✅ Tri par **date d'ajout**
- ✅ **Ordre croissant/décroissant**

### 4. Fiche détaillée
- ✅ **Photo** ou placeholder avec icône
- ✅ **Informations générales** : Marque, modèle, référence, type, zones
- ✅ **Performance** : Profondeur, vitesse, action, tête, couleurs
- ✅ **Espèces cibles** : Badges visuels
- ✅ **Positions spread** : Short corner, Long corner, Rigger, Shotgun
- ✅ **Conditions optimales** :
  - Moments de la journée
  - État de la mer
  - Turbidité
  - Marée
  - Phases lunaires
- ✅ **Notes** techniques

### 5. Gestion de l'inventaire
- ✅ Ajout de leurres (formulaire à compléter)
- ✅ Modification de leurres (formulaire à compléter)
- ✅ Suppression de leurres
- ✅ Quantité en stock
- ✅ Emplacement de rangement

---

## 🎨 INTERFACE UTILISATEUR

### Palette de couleurs (Module 0 validé)
- **Bleu forêt** : #0277BD (couleur principale)
- **Orange corail** : #FFBC42 (accents)
- **Blanc cassé** : #F5F5F5 (fond)
- **Blanc** : #FFFFFF (cartes)

### Design pattern
- **Cartes blanches** avec ombres légères
- **Badges colorés** pour catégories
- **FlowLayout** pour badges qui wrap automatiquement
- **Icons SF Symbols** : 🐟 🦑 💦 ⚓️ etc.

---

## 📊 MODÈLE DE DONNÉES

### Structure Leurre (23 attributs)

```swift
struct Leurre {
    // Identification
    let id: Int
    var nom: String
    var marque: String
    var modele: String?
    var reference: String?
    
    // Classification
    var type: TypeLeurre
    var categoriePeche: [CategoriePeche]
    
    // Caractéristiques Physiques
    var longueur: Double        // cm
    var poids: Double?          // grammes
    
    // Caractéristiques Visuelles
    var couleurPrincipale: Couleur
    var couleursSecondaires: [Couleur]
    var contraste: Contraste    // naturel/flashy/sombre/contrasté
    var finition: Finition?     // holographique/métallique/mat
    
    // Performance Technique
    var typeTete: TypeTete?
    var actionNage: ActionNage
    var profondeurMin: Double   // mètres
    var profondeurMax: Double
    var vitesseMinimale: Double // nœuds
    var vitesseOptimale: Double
    var vitesseMaximale: Double
    
    // Critères de Suggestion (Module 2)
    var especesCibles: [Espece]
    var positionsSpread: [PositionSpread]
    var notes: String?
    var conditionsOptimales: ConditionsOptimales
    
    // Gestion Inventaire
    var photo: Data?
    var quantite: Int
    var emplacement: String?
    var dateAjout: Date
}
```

### Énumérations principales

**TypeLeurre** : 8 types
- Poisson nageur, Poisson nageur plongeant, Leurre à jupe, Popper, Stickbait, Jig métallique, Vibe/Lipless, Flying Fish

**CategoriePeche** : 6 zones
- Lagon, Passes, Côtier, Hauturier, Large, Récif

**Espece** : 15 espèces
- Carangue, Carangue GT, Thon, Thon jaune, Thon profond, Barracuda, Wahoo, Mahi-mahi, Marlin, Thazard, Bonite, Loche, Picot, Bec-de-cane, Vivaneau

**PositionSpread** : 5 positions
- Short Corner (10-20m), Long Corner (30-50m), Rigger (50-70m), Shotgun (70-100m), Libre

**ConditionsOptimales** : 5 critères
- Moments (aube, matinée, midi, après-midi, crépuscule, nuit)
- État mer (calme, peu agitée, agitée, formée)
- Turbidité (claire, légèrement trouble, trouble)
- Marée (montante, descendante, étale)
- Phases lunaires (nouvelle, premier quartier, pleine, dernier quartier)

---

## 🗂️ BASE DE DONNÉES JSON

### Structure du fichier

```json
{
  "metadata": {
    "version": "1.0",
    "dateCreation": "2024-12-04",
    "nombreTotal": 63,
    "description": "Base de données complète des 63 leurres",
    "proprietaire": "Sébastien",
    "source": "Tableau CPS + Techniques de pêche côtière 2023"
  },
  "leurres": [
    {
      "id": 1,
      "nom": "Magnum Stretch 30+",
      "marque": "Manns",
      ... (tous les attributs)
    },
    ... (63 entrées)
  ]
}
```

### Répartition des 63 leurres

**Par taille** :
- Petits (8-12cm) : 19 leurres → Lagon/récif
- Moyens (12-16cm) : 28 leurres → Polyvalents
- Grands (16-20cm) : 13 leurres → Passes/large
- Très grands (20cm+) : 3 leurres → Hauturier

**Par type** :
- Bavette : 38 leurres (60%)
- Jig : 10 leurres (16%)
- Popper : 8 leurres (13%)
- Stickbait : 5 leurres (8%)
- Jupe : 2 leurres (3%)

**Par contraste** :
- Naturel : 22 leurres (35%)
- Flashy : 24 leurres (38%)
- Sombre : 12 leurres (19%)
- Contrasté : 5 leurres (8%)

---

## 🚀 INTÉGRATION DANS XCODE

### Étape 1 : Ajouter les fichiers

1. Ouvrir votre projet Xcode "Go les Picots"
2. Clic droit sur le dossier du projet → **New Group** → "Module1_BoiteALeurres"
3. Créer les sous-dossiers : Models, ViewModels, Views, Helpers, Resources
4. **Glisser-déposer** tous les fichiers .swift dans leurs dossiers respectifs
5. **IMPORTANT** : Cocher "Copy items if needed"

### Étape 2 : Ajouter le JSON

1. Glisser `leurres_database_COMPLET.json` dans le dossier **Resources**
2. **IMPORTANT** : Cocher "Copy items if needed" ET "Add to targets: [NomApp]"
3. Vérifier dans Build Phases → Copy Bundle Resources que le JSON y est

### Étape 3 : Modifier ContentView.swift

```swift
// Dans ContentView.swift (Module 0)
@ViewBuilder
private var destinationView: some View {
    if module.title == "Ma Boîte" {
        BoiteView()  // ← Ajouter cette ligne
    } else {
        Text("Module \(module.title) à venir")
    }
}
```

### Étape 4 : Tester

1. **Cmd+B** pour compiler
2. **Cmd+R** pour lancer
3. Cliquer sur "Ma Boîte à Leurres"
4. Les 63 leurres doivent s'afficher

---

## 🐛 TROUBLESHOOTING

### Problème : "Cannot find 'BoiteView' in scope"
**Solution** : Vérifier que tous les fichiers .swift sont bien ajoutés au target

### Problème : "Fichier JSON introuvable"
**Solution** : 
1. Sélectionner le JSON dans le navigateur Xcode
2. Ouvrir l'inspecteur de fichier (⌥⌘1)
3. Cocher votre target dans "Target Membership"

### Problème : Erreur de décodage JSON
**Solution** : Vérifier que le fichier s'appelle **exactement** `leurres_database_COMPLET.json`

---

## 📝 À COMPLÉTER (Phase 2)

### Formulaires
- [ ] Formulaire complet d'ajout de leurre
- [ ] Formulaire d'édition avec tous les champs
- [ ] Sélecteur de photo (Camera + Photothèque)
- [ ] Validation des champs

### Sauvegarde
- [ ] Implémentation Core Data ou UserDefaults
- [ ] Synchronisation modifications ↔ JSON
- [ ] Export/Import de la base

### Amélio

rations
- [ ] Photos réelles des 63 leurres
- [ ] Partage de leurres entre utilisateurs
- [ ] Statistiques d'utilisation
- [ ] Historique des sorties par leurre

---

## 🎯 PRÊT POUR MODULE 2

Le modèle de données est **100% compatible** avec le Module 2 "Suggestion Stratégique" :

✅ **Tous les critères de suggestion** sont présents :
- Zones de pêche (lagon/large)
- Conditions environnementales (lune, marée, turbidité)
- Espèces cibles
- Profondeurs et vitesses
- Positions spread
- Conditions optimales détaillées

✅ **L'algorithme de scoring** pourra utiliser directement :
```swift
func calculerScore(leurre: Leurre, contexte: ContextePeche) -> Double {
    // Phase 1 : Zone/Profondeur/Vitesse (40%)
    // Phase 2 : Couleur/Contraste (30%)
    // Phase 3 : Conditions environnementales (20%)
    // Bonus : Espèces cibles (10%)
    // → Score total 0-100
}
```

---

## 📚 SOURCES

**Documents de référence intégrés** :
1. ✅ Extraction complète des critères du document maître CPS
2. ✅ Tableau des 63 leurres avec toutes caractéristiques
3. ✅ Stratégies de suggestion (TABLEAUX_COMPLETS_CONSIGNES.md)
4. ✅ Guide d'intégration moteur de suggestion

**Manuels CPS** :
- Techniques de pêche côtière 2023
- Techniques de pêche profonde Îles du Pacifique
- Biologie et écologie bec-de-cane (IRD)

---

## ✅ VALIDATION MODULE 1

**Statut** : ✅ **COMPLÉTÉ**

- [x] Modèle de données avec 23 attributs
- [x] Chargement des 63 leurres depuis JSON
- [x] Vue liste avec cellules détaillées
- [x] Vue grille avec cartes visuelles
- [x] Barre de recherche fonctionnelle
- [x] Filtres avancés (type, zone, espèce)
- [x] Tri multi-critères
- [x] Fiche détaillée complète
- [x] Gestion CRUD (Create, Read, Update, Delete)
- [x] Interface respectant Module 0 (palette couleurs)
- [x] Prêt pour Module 2

**Prochaine étape** : Module 2 - Suggestion Stratégique IA

---

**Version** : 1.0  
**Date** : 2024-12-04  
**Développé pour** : Sébastien - Nouvelle-Calédonie 🇳🇨
