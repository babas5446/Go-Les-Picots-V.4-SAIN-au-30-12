# 📊 Architecture Visuelle - Type de Nage v2.0

**Date :** 28 Décembre 2024  
**Version :** 2.0 Multi-Sélection

---

## 🏗️ Structure des Données

```
┌────────────────────────────────────────────────────────────┐
│                        Leurre                              │
├────────────────────────────────────────────────────────────┤
│ - id: Int                                                  │
│ - nom: String                                              │
│ - marque: String                                           │
│ - ...                                                      │
│                                                            │
│ 🆕 TypeDeNage: [TypeDeNageEntry]?    ◄─── NOUVEAU (v2)  │
│                                                            │
│ ⚠️ typeDeNage: TypeDeNage?            ◄─── DEPRECATED     │
│ ⚠️ typeDeNageCustom: TypeDeNageCustom? ◄─── DEPRECATED    │
└────────────────────────────────────────────────────────────┘
                           │
                           │ contient 0 à N
                           ▼
┌────────────────────────────────────────────────────────────┐
│                   TypeDeNageEntry                          │
├────────────────────────────────────────────────────────────┤
│ - id: UUID                                                 │
│ - typeStandard: TypeDeNage?        ◄─┐                    │
│ - typeCustom: TypeDeNageCustom?    ◄─┼─ Un des deux       │
│ - contexte: String?                  │   obligatoire      │
│                                      │                     │
│ Computed Properties:                 │                     │
│ - displayName: String                │                     │
│ - fullDisplayName: String            │                     │
│ - categorie: CategorieNage?          │                     │
│ - isValid: Bool                      │                     │
└──────────────────────────────────────┘                     │
            │                        │                       │
            │                        │                       │
            ▼                        ▼                       │
┌─────────────────────┐  ┌──────────────────────────────────┤
│    TypeDeNage       │  │   TypeDeNageCustom               │
│    (enum)           │  │   (struct)                       │
├─────────────────────┤  ├──────────────────────────────────┤
│ 17 cas standards    │  │ - nom: String                    │
│                     │  │ - categorie: CategorieNage       │
│ - wobbling          │  │ - description: String?           │
│ - rolling           │  │ - motsClés: [String]             │
│ - darting           │  │                                  │
│ - flutter           │  │ Stockés dans UserDefaults        │
│ - ...               │  │ via TypeDeNageCustomService      │
└─────────────────────┘  └──────────────────────────────────┘
```

---

## 🔄 Flux de Données : Création d'un Leurre

```
┌──────────────────┐
│  Utilisateur     │
└────────┬─────────┘
         │
         │ 1. Saisie des notes
         ▼
┌─────────────────────────────────────┐
│  TypeDeNageExtractor                │
│  .extraireEntries(depuis: notes)    │
└────────┬────────────────────────────┘
         │
         │ 2. Détection automatique
         ▼
┌─────────────────────────────────────┐
│  typesDetectes: [TypeDeNageDetecte] │
│  - Wobbling                         │
│  - Rolling                          │
└────────┬────────────────────────────┘
         │
         │ 3. Affichage badge
         ▼
┌─────────────────────────────────────┐
│  TypeDeNageMultiSelectField         │
│  Badge: "✨ 2 type(s) détectés"    │
└────────┬────────────────────────────┘
         │
         │ 4. Utilisateur ouvre picker
         ▼
┌─────────────────────────────────────┐
│  Picker (Sheet)                     │
│  ▼ Détectés dans les notes          │
│    • Wobbling              [ ]      │
│    • Rolling               [ ]      │
│                                     │
│  ▼ I. Nages linéaires               │
│    • Nage rectiligne       [ ]      │
│    • Wobbling              [ ]      │
│    • Rolling               [ ]      │
│    ...                              │
└────────┬────────────────────────────┘
         │
         │ 5. Sélection de types
         ▼
┌─────────────────────────────────────┐
│  selectedTypes: [TypeDeNageEntry]   │
│  - TypeDeNageEntry(wobbling)        │
│  - TypeDeNageEntry(rolling)         │
└────────┬────────────────────────────┘
         │
         │ 6. Édition contexte (optionnel)
         ▼
┌─────────────────────────────────────┐
│  ContextEditorView                  │
│  Wobbling                           │
│  Contexte: [vitesse 2-3 nœuds]     │
└────────┬────────────────────────────┘
         │
         │ 7. Mise à jour
         ▼
┌─────────────────────────────────────┐
│  selectedTypes (avec contextes)     │
│  - wobbling (vitesse 2-3 nœuds)     │
│  - rolling (vitesse 4-6 nœuds)      │
└────────┬────────────────────────────┘
         │
         │ 8. Sauvegarde
         ▼
┌─────────────────────────────────────┐
│  Leurre.TypeDeNage                 │
│  = [TypeDeNageEntry, TypeDeNageEntry]│
└────────┬────────────────────────────┘
         │
         │ 9. Encodage JSON
         ▼
┌─────────────────────────────────────┐
│  {                                  │
│    "TypeDeNage": [                 │
│      {                              │
│        "id": "UUID-123",            │
│        "typeStandard": "wobbling",  │
│        "contexte": "vitesse 2-3..."│
│      },                             │
│      { ... }                        │
│    ]                                │
│  }                                  │
└─────────────────────────────────────┘
```

---

## 🎨 Interface Utilisateur : États

### État 1 : Aucun Type Sélectionné
```
┌──────────────────────────────────────┐
│ 🌊 Types de nage              [+]   │
├──────────────────────────────────────┤
│ Aucun type de nage sélectionné       │
│                                      │
│ ✨ 2 type(s) détecté(s) dans notes >│
└──────────────────────────────────────┘
```

### État 2 : Un Type Sélectionné (sans contexte)
```
┌──────────────────────────────────────┐
│ 🌊 Types de nage              [+]   │
├──────────────────────────────────────┤
│ 🏷️ Wobbling                   [⋯]  │
└──────────────────────────────────────┘
```

### État 3 : Un Type Avec Contexte
```
┌──────────────────────────────────────┐
│ 🌊 Types de nage              [+]   │
├──────────────────────────────────────┤
│ 🏷️ Wobbling                   [⋯]  │
│    vitesse 2-3 nœuds                │
└──────────────────────────────────────┘
```

### État 4 : Plusieurs Types (scroll horizontal)
```
┌──────────────────────────────────────┐
│ 🌊 Types de nage              [+]   │
├──────────────────────────────────────┤
│ ◄──────────────────────────────────► │
│ 🏷️ Wobbling [⋯] 🏷️ Rolling [⋯] 🏷️ Da│
│    vitesse 2-3       vitesse 4-6    │
└──────────────────────────────────────┘
```

---

## 🔀 Migration Automatique

```
┌──────────────────────────────────────────────┐
│         Décodage JSON (Leurre)               │
└──────────┬───────────────────────────────────┘
           │
           │ Try decode 'TypeDeNage'
           ▼
     ┌─────────┐
     │ Trouvé? │
     └────┬────┘
          │
    ┌─────┴─────┐
    │           │
   OUI         NON
    │           │
    ▼           ▼
┌──────┐   ┌────────────────────────┐
│ v2.0 │   │ Try decode 'typeDeNage'│
│ OK   │   └──────┬─────────────────┘
└──────┘          │
                  │ Try decode 'typeDeNageCustom'
                  ▼
            ┌─────────┐
            │ Trouvé? │
            └────┬────┘
                 │
           ┌─────┴─────┐
           │           │
      typeDeNage   typeDeNageCustom
       trouvé?       trouvé?
           │           │
           ▼           ▼
      ┌────────┐  ┌────────┐
      │Migrer  │  │Migrer  │
      │vers    │  │vers    │
      │array   │  │array   │
      └────────┘  └────────┘
           │           │
           └─────┬─────┘
                 ▼
        ┌─────────────────┐
        │ TypeDeNage     │
        │ = [Entry(...)]  │
        └─────────────────┘
                 │
                 ▼
           ✅ Migration OK
```

---

## 📊 Comparaison v1.0 vs v2.0

| Aspect | v1.0 (Single) | v2.0 (Multi) |
|--------|---------------|--------------|
| **Structure** | 2 propriétés séparées | 1 array unifié |
| **Contexte** | ❌ Non supporté | ✅ Par type |
| **Nombre de types** | 1 maximum | Illimité |
| **Interface** | Champ unique | Chips multiples |
| **Édition** | Remplacement | Ajout/suppression |
| **Détection auto** | 1 type → remplissage<br>N types → badge | Badge toujours affiché |
| **JSON** | Flat (2 clés) | Nested (1 array) |
| **Migration** | - | ✅ Automatique |

---

## 🎯 Cas d'Usage Principaux

### Cas 1 : Leurre Traîne Variable
```
Leurre: Magnum Stretch 30+
├─ Wobbling (vitesse 2-3 nœuds)
├─ Rolling (vitesse 4-6 nœuds)
└─ Darting (vitesse > 7 nœuds)
```

### Cas 2 : Leurre Jig Vertical
```
Leurre: Deep Jig 150g
├─ Flutter (en descente)
├─ Slow pitch (en animation lente)
└─ Falling (en chute libre)
```

### Cas 3 : TopWater Polyvalent
```
Leurre: Stickbait Pro
├─ Walk the Dog (animation douce)
├─ Slashing (animation agressive)
└─ Nage suspendue (pause)
```

### Cas 4 : Mix Standard + Custom
```
Leurre: Custom Tuna Killer
├─ Wobbling (standard)
├─ Rolling (standard)
└─ Ma nage custom (personnalisé)
    └─ contexte: "par mer agitée"
```

---

## 📈 Performance & Optimisation

### Stockage
```
v1.0:
typeDeNage: TypeDeNage?              ≈ 8 bytes
typeDeNageCustom: TypeDeNageCustom?  ≈ 100 bytes
TOTAL: ≈ 108 bytes

v2.0:
TypeDeNage: [TypeDeNageEntry]?
- 0 types: nil                       ≈ 0 bytes
- 1 type:  [Entry]                   ≈ 150 bytes
- 3 types: [Entry, Entry, Entry]     ≈ 450 bytes
```

### Rendering UI
```
v1.0: 1 champ TextField/Picker
v2.0: N chips + 1 picker modal
      (scroll horizontal si > 3)
```

**Optimisations v2.0 :**
- ✅ Lazy loading du picker
- ✅ Scroll virtualisé pour grandes listes
- ✅ Debouncing sur recherche
- ✅ Cache des types custom en mémoire

---

## 🔐 Sécurité & Validation

### Validation des Données

```swift
TypeDeNageEntry {
    var isValid: Bool {
        // Au moins un type défini
        typeStandard != nil || typeCustom != nil
    }
}
```

### Sanitization du Contexte

```swift
// Contextes limités à 200 caractères
var contexte: String? {
    didSet {
        if let ctx = contexte, ctx.count > 200 {
            contexte = String(ctx.prefix(200))
        }
    }
}
```

### Protection contre Duplication

```swift
// Dans TypeDeNageMultiSelectField
private func toggleType(standard: TypeDeNage?, custom: TypeDeNageCustom?) {
    if let existing = findTypeInSelection(...) {
        removeType(existing)  // Désélection
    } else {
        // Vérifier pas déjà présent
        if !selectedTypes.contains(where: { matches($0) }) {
            selectedTypes.append(...)
        }
    }
}
```

---

## 🧪 Scénarios de Test

### Test 1 : Création Vide
```
Input:  TypeDeNage = []
Output: Aucun chip affiché
        Badge détection si notes contiennent types
```

### Test 2 : Ajout/Suppression
```
1. Ajouter Wobbling       → 1 chip
2. Ajouter Rolling        → 2 chips
3. Supprimer Wobbling     → 1 chip (Rolling)
4. Supprimer Rolling      → 0 chip
```

### Test 3 : Contexte
```
1. Ajouter Wobbling
2. Éditer contexte → "vitesse lente"
3. Sauvegarder
4. Recharger
Output: Contexte préservé
```

### Test 4 : Migration
```
Input:  JSON v1 { typeDeNage: "wobbling" }
Process: Décodage automatique
Output: TypeDeNage = [Entry(wobbling)]
```

### Test 5 : Détection Auto
```
Input:  notes = "Action wobbling et rolling"
Process: Extraction automatique
Output: Badge "✨ 2 type(s) détecté(s)"
        Picker montre Wobbling et Rolling
```

---

**🎣 Architecture v2.0 Complète et Documentée !**

---

**Auteur :** Assistant IA  
**Date :** 28 Décembre 2024  
**Version :** 2.0  
**Fichiers liés :**
- `ARCHITECTURE_MULTI_SELECTION_TYPE_NAGE.md`
- `GUIDE_MIGRATION_TYPE_NAGE_V2.md`
- `RECAP_TYPE_DE_NAGE_28_DEC_2024.md`
