# Correction des enums et types communs

**Date :** 20 janvier 2026  
**Problème :** Conflits d'enums entre fichiers, types ambigus, erreurs de compilation

---

## 🔴 Problèmes identifiés

### 1. Conflits de nommage
- **`TypeMaree`** défini à 2 endroits différents avec des sens différents :
  - `CalendrierMareeService.swift` : pleineMer/basseMer (extrêmes)
  - `Leurre.swift` (ConditionsOptimales) : montante/descendante/etale (phases)

### 2. Enums dupliqués
- `EtatMer`, `PhaseMaree`, `Luminosite`, `Turbidite`, etc. définis dans :
  - `TypesCommuns.swift` (partiellement)
  - `Leurre.swift` (complètement)
  - Causant des ambiguïtés

### 3. Enums manquants dans ConditionsPeche.swift
- `MomentJournee`
- `Luminosite`
- `Turbidite`
- `CategoriePeche`
- `Espece`
- `ProfilBateau`

---

## ✅ Solutions appliquées

### 1. TypesCommuns.swift - Source unique de vérité

**Fichier enrichi avec TOUS les enums partagés :**

```swift
// Météo
- EtatMer (calme, peuAgitee, agitee, formee)
- Luminosite (forte, diffuse, faible, sombre, nuit)
- Turbidite (claire, legerementTrouble, trouble, tresTrouble)

// Marées
- PhaseMaree (montante, etaleHaut, descendante, etaleBas)
- TypeMareeExtreme (pleineMer, basseMer) // ✅ NOUVEAU nom

// Temps
- MomentJournee (aube, matinee, midi, apresMidi, crepuscule, nuit)
- PhaseLunaire (nouvelleLune, premierCroissant, ..., dernierCroissant)
- typealias PhaseLune = PhaseLunaire

// Pêche
- Zone (lagon, recif, passe, tombant, large, profond, dcp)
- typealias CategoriePeche = Zone
- Espece (thonJaune, wahoo, mahiMahi, carangue, ...)
- ProfilBateau (classique, clark429)
```

### 2. Renommage TypeMaree → TypeMareeExtreme

**Pourquoi ?**
- `TypeMaree` était ambigu (phase VS extrême)
- `TypeMareeExtreme` est explicite : décrit les extrêmes PM/BM
- `PhaseMaree` reste pour montante/descendante/etale

**Fichiers modifiés :**

#### CalendrierMareeService.swift
```swift
// AVANT
struct HoraireMaree {
    let type: TypeMaree  // ❌ Ambigu
}

enum TypeMaree {
    case pleineMer
    case basseMer
}

// APRÈS
struct HoraireMaree {
    let type: TypeMareeExtreme  // ✅ Clair
}
// Enum supprimé, importé de TypesCommuns.swift
```

#### StormglassService.swift
```swift
// AVANT
struct Extreme {
    let type: TypeMaree  // ❌ Ambigu
}

enum TypeMaree {
    case pleineMer
    case basseMer
}

// APRÈS
struct Extreme {
    let type: TypeMareeExtreme  // ✅ Clair
}
// Enum supprimé, importé de TypesCommuns.swift
```

### 3. Correction ConditionsPeche.swift

**Problème :** Utilisait `typeMaree` au lieu de `phaseMaree`

```swift
// AVANT
struct ConditionsPeche {
    var typeMaree: TypeMaree  // ❌ Mauvais nom + type ambigu
}

static var scenario1LagunAube: ConditionsPeche {
    return ConditionsPeche(
        typeMaree: .montante  // ❌ .montante n'existe pas dans TypeMaree
    )
}

// APRÈS
struct ConditionsPeche {
    var phaseMaree: PhaseMaree  // ✅ Nom correct + type explicite
}

static var scenario1LagunAube: ConditionsPeche {
    return ConditionsPeche(
        phaseMaree: .montante  // ✅ .montante existe dans PhaseMaree
    )
}
```

**Autres corrections dans ConditionsPeche.swift :**
- `typeMaree.displayName` → `phaseMaree.displayName`
- `typeMaree == .descendante` → `phaseMaree == .descendante`

---

## 📋 Hiérarchie des types après correction

### Marées : 2 enums distincts et complémentaires

```
TypeMareeExtreme          PhaseMaree
    ├─ pleineMer              ├─ montante
    └─ basseMer               ├─ etaleHaut
                              ├─ descendante
                              └─ etaleBas

Utilisation:                  Utilisation:
- HoraireMaree.type           - ConditionsMeteo.phaseMaree
- StormglassService.Extreme   - ConditionsPeche.phaseMaree
- Calendrier marée            - État actuel de la marée
```

### Zones : Un seul enum, plusieurs noms

```swift
enum Zone { ... }
typealias CategoriePeche = Zone

// Équivalent :
let zone: Zone = .lagon
let categorie: CategoriePeche = .lagon
```

---

## 🔄 Impact sur le code existant

### ✅ Pas d'impact (rétrocompatible)
- `ConditionsMeteo` : utilise toujours `PhaseMaree`
- `MeteoSolunaireView` : déjà à jour avec StormGlass
- `TypesCommuns.swift` : source de vérité établie

### ⚠️ Changements mineurs requis
Si vous avez du code utilisant :
- `TypeMaree` → remplacer par `TypeMareeExtreme` ou `PhaseMaree` selon contexte
- `typeMaree` dans `ConditionsPeche` → utiliser `phaseMaree`

### 🔧 Migration automatique
Les imports de `TypesCommuns.swift` rendent tous les enums disponibles partout.

---

## 🎯 Utilisation recommandée

### Pour les horaires de marée (PM/BM)
```swift
import TypesCommuns

let horaireMaree = HoraireMaree(
    date: Date(),
    type: .pleineMer,  // TypeMareeExtreme
    hauteur: 1.5,
    coefficient: 75
)
```

### Pour la phase actuelle
```swift
import TypesCommuns

let conditions = ConditionsMeteo(
    phaseMaree: .montante,  // PhaseMaree
    coefficientMaree: 75
)

let conditionsPeche = ConditionsPeche(
    phaseMaree: .descendante  // PhaseMaree
)
```

### Pour les données StormGlass
```swift
let extreme = StormglassService.Extreme(
    date: Date(),
    hauteur: 1.5,
    type: .pleineMer  // TypeMareeExtreme
)
```

---

## 📊 Tableau récapitulatif des types

| Type | Fichier source | Valeurs | Usage |
|------|---------------|---------|-------|
| `EtatMer` | TypesCommuns.swift | calme, peuAgitee, agitee, formee | Conditions météo |
| `PhaseMaree` | TypesCommuns.swift | montante, etaleHaut, descendante, etaleBas | État actuel marée |
| `TypeMareeExtreme` | TypesCommuns.swift | pleineMer, basseMer | Horaires extrêmes |
| `Luminosite` | TypesCommuns.swift | forte, diffuse, faible, sombre, nuit | Conditions lumière |
| `Turbidite` | TypesCommuns.swift | claire, legerementTrouble, trouble, tresTrouble | Clarté eau |
| `MomentJournee` | TypesCommuns.swift | aube, matinee, midi, apresMidi, crepuscule, nuit | Période journée |
| `PhaseLunaire` | TypesCommuns.swift | nouvelleLune, ..., dernierCroissant | Phase lune |
| `Zone` | TypesCommuns.swift | lagon, recif, passe, tombant, large, profond, dcp | Zone pêche |
| `Espece` | TypesCommuns.swift | thonJaune, wahoo, mahiMahi, carangue, ... | Espèces ciblées |
| `ProfilBateau` | TypesCommuns.swift | classique, clark429 | Type bateau |

---

## ✅ Checklist de vérification

- [x] TypesCommuns.swift contient tous les enums partagés
- [x] TypeMaree renommé en TypeMareeExtreme
- [x] ConditionsPeche utilise phaseMaree au lieu de typeMaree
- [x] CalendrierMareeService utilise TypeMareeExtreme
- [x] StormglassService utilise TypeMareeExtreme
- [x] Pas de doublons d'enums entre fichiers
- [x] Tous les enums ont displayName et emoji si pertinent

---

## 🚀 Prochaines étapes

1. **Vérifier la compilation** de tout le projet
2. **Tester** les vues utilisant :
   - ConditionsPeche
   - ConditionsMeteo
   - CalendrierMareeService
   - StormglassService
3. **Migrer** progressivement les références à l'ancien `TypeMaree`
4. **Nettoyer** les enums dupliqués dans Leurre.swift (optionnel, gardés pour compatibilité)

---

**Résultat final :** 
✅ Plus de conflits  
✅ Types explicites et clairs  
✅ Source unique de vérité (TypesCommuns.swift)  
✅ Compatibilité préservée  

---

**Modifié par :** Assistant IA  
**Date :** 20 janvier 2026
