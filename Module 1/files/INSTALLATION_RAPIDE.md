# 🚀 GUIDE INSTALLATION RAPIDE - MODULE 1
## "Ma Boîte à Leurres" - Go les Picots

---

## ✅ CE QUE VOUS AVEZ

- ✅ 9 fichiers Swift (modèle + vues + logique)
- ✅ 1 fichier JSON (63 leurres)
- ✅ 1 README complet (20 pages documentation)
- ✅ Architecture complète prête à l'emploi

---

## 📦 ÉTAPE 1 : EXTRACTION

1. Télécharger `Module1_BoiteALeurres_COMPLET.tar.gz`
2. Double-cliquer pour extraire
3. Vous obtenez le dossier `Module1_BoiteALeurres/`

---

## 🔧 ÉTAPE 2 : INTÉGRATION XCODE (5 min)

### A. Ajouter les fichiers

1. Ouvrir votre projet "Go les Picots" dans Xcode
2. Clic droit sur le dossier racine du projet
3. **New Group** → Nommer "Module1"
4. **Glisser-déposer** TOUT le contenu du dossier `Module1_BoiteALeurres/` dans ce group
5. ✅ **IMPORTANT** : Cocher **"Copy items if needed"** ET votre target

### B. Vérifier le JSON

1. Sélectionner `leurres_database_COMPLET.json` dans le navigateur
2. Ouvrir File Inspector (⌥⌘1)
3. Vérifier que "Target Membership" est coché pour votre app
4. Vérifier dans Build Phases → Copy Bundle Resources

### C. Connecter au Module 0

Dans `ContentView.swift` (votre Module 0 validé), ajouter :

```swift
// Trouver la section ModuleButton et ajouter :
@ViewBuilder
private var destinationView: some View {
    if module.title == "Ma Boîte" {
        BoiteView()  // ← Ligne à ajouter
    } else {
        Text("Module \(module.title) à venir")
    }
}
```

---

## ✨ ÉTAPE 3 : TESTER (30 sec)

1. **Cmd+B** → Compiler (devrait réussir sans erreur)
2. **Cmd+R** → Lancer l'app
3. Sur l'écran d'accueil, cliquer **"Ma Boîte à Leurres"**
4. ✅ **Succès** : Vous voyez vos 63 leurres !

---

## 🎯 FONCTIONNALITÉS DISPONIBLES IMMÉDIATEMENT

### Vue Liste
- Scrollez pour voir les 63 leurres
- Tapez sur un leurre → Fiche détaillée complète

### Vue Grille
- Menu (•••) en haut à droite
- Choisir "Grille"
- Affichage en 2 colonnes

### Recherche
- Tapez dans la barre de recherche : "Rapala", "Carangue", "12cm"
- Filtrage en temps réel

### Filtres Avancés
- Menu (•••) → "Filtres"
- Filtrer par Type / Zone / Espèce
- Voir les statistiques

### Tri
- En-tête de la liste : "Tri : Nom"
- Choisir Nom / Taille / Marque / Date
- Cliquer à nouveau → Inverser l'ordre

---

## 🐛 EN CAS DE PROBLÈME

### Erreur : "Cannot find 'BoiteView' in scope"
**→ Les fichiers ne sont pas ajoutés au target**
1. Sélectionner `BoiteView.swift`
2. File Inspector (⌥⌘1)
3. Cocher votre target dans "Target Membership"
4. Faire pareil pour TOUS les .swift

### Erreur : "Fichier JSON introuvable"
**→ Le JSON n'est pas dans le bundle**
1. Sélectionner `leurres_database_COMPLET.json`
2. Cocher Target Membership
3. Vérifier Build Phases → Copy Bundle Resources

### Compilation OK mais erreur à l'exécution
**→ Le nom du JSON ne correspond pas**
1. Vérifier que le fichier s'appelle **exactement** :
   `leurres_database_COMPLET.json`
2. Pas d'espace, pas de majuscule différente

---

## 📱 CAPTURES D'ÉCRAN ATTENDUES

### 1. Écran d'accueil (Module 0)
```
┌─────────────────────┐
│   Go les Picots     │  ← Bannière bleue
├─────────────────────┤
│  ┌────┐   ┌────┐   │
│  │ 📦 │   │ 🎯 │   │  ← Grille 2x2
│  │Box │   │ IA │   │
│  └────┘   └────┘   │
│  ┌────┐   ┌────┐   │
│  │ 🗺️ │   │ 📚 │   │
│  │Nav │   │Bib │   │
│  └────┘   └────┘   │
└─────────────────────┘
```

### 2. Ma Boîte (Module 1)
```
┌─────────────────────────┐
│ Ma Boîte à Leurres  ••• │
│ ┌───────────────────┐   │
│ │ 🔍 Rechercher...  │   │
│ └───────────────────┘   │
│ 63 leurres      Tri: ▼  │
├─────────────────────────┤
│ ┌──┐ X-Rap Magnum 140   │
│ │🐟│ Rapala              │
│ └──┘ 14cm • 6m • Carangue│
├─────────────────────────┤
│ ┌──┐ Frenzy Mungo 140   │
│ │🐟│ Berkley             │
│ └──┘ 14cm • 3-4m • Thon  │
│     ...                  │
└─────────────────────────┘
```

### 3. Fiche Leurre Détaillée
```
┌──────────────────────────┐
│ X-Rap Magnum 140      •••│
├──────────────────────────┤
│  ┌──────────────────┐    │
│  │   [PHOTO LEURRE] │    │
│  │     ou icône     │    │
│  └──────────────────┘    │
│                          │
│ ℹ️ Informations générales│
│ Marque: Rapala           │
│ Type: Poisson nageur     │
│ Longueur: 14 cm          │
│ Zones: [Passes][Large]   │
│                          │
│ ⚡ Performance            │
│ Profondeur: 6m           │
│ Vitesse: 6-10 nœuds      │
│ Action: Moyenne          │
│                          │
│ 🐠 Espèces cibles        │
│ [Carangue][Thon][Wahoo]  │
│                          │
│ 🗺️ Positions traîne     │
│ [Short Corner]           │
│                          │
│ ☀️ Conditions optimales  │
│ Moments: Matin, Midi     │
│ Mer: Calme, Agitée       │
│ ...                      │
└──────────────────────────┘
```

---

## 🎉 SUCCÈS !

Si vous voyez ces écrans → **Module 1 opérationnel** ✅

**Prochaine étape** : Module 2 - Suggestion Stratégique IA

---

## 📞 SUPPORT

**Problème persistant ?**
1. Vérifier que TOUS les fichiers sont dans le target
2. Clean Build Folder (⇧⌘K)
3. Rebuild (⌘B)
4. Relancer (⌘R)

**Toujours bloqué ?**
- Lire le README.md complet (20 pages de doc)
- Section "Troubleshooting" page 15

---

**Temps d'installation total** : ~5 minutes  
**Difficulté** : ⭐⭐☆☆☆ (Facile)

---

*Bonne pêche ! 🎣*
