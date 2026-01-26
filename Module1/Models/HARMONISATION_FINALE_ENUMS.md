# HARMONISATION FINALE DES ENUMS

**Date :** 20 janvier 2026  
**Principe :** **Leurre.swift est la source de vérité. Les nouveaux fichiers s'adaptent.**

---

## ✅ Décision finale

### 🎯 **Leurre.swift = Source unique pour TOUS les enums de domaine**

Tous les enums métier (pêche, conditions, zones, espèces) sont dans **Leurre.swift**.  
Les nouveaux fichiers (météo, marées) **importent et utilisent** ces enums.

### 📄 **TypesCommuns.swift = Types techniques uniquement**

Contient **UNIQUEMENT** :
- `TypeMareeExtreme` (pleineMer/basseMer) - pour horaires PM/BM

**Tout le reste est dans Leurre.swift !**

---

## 📋 Liste complète des enums (dans Leurre.swift)

### ✅ Déjà présents (non modifiés)
- `Zone` (lagon, recif, passe, tombant, large, profond, dcp)
- `Espece` (thonJaune, wahoo, mahiMahi, carangue, ...)
- `TypeLeurre`, `TypePeche`, `Couleur`, `Finition`, `TypeDeNage`
- `PositionSpread`, `Contraste`, `ProfilBateau`
- `MomentJournee` (aube, matinee, midi, apresMidi, crepuscule, nuit)
- `Luminosite` (forte, diffuse, faible, sombre, nuit)
- `Turbidite` (claire, legerementTrouble, trouble, tresTrouble)
- `TypeMaree` (montante, descendante, etale)
- `PhaseLunaire` (nouvelleLune, ..., dernierCroissant)

### ✅ Ajoutés aujourd'hui
- **`PhaseMaree`** (montante, etaleHaut, descendante, etaleBas)
  - Pour ConditionsMeteo (4 cas au lieu de 3)
  - Méthode `toTypeMaree` pour conversion
- **`EtatMer`** (calme, peuAgitee, agitee, formee)
  - Utilisé par ConditionsOptimales et ConditionsMeteo

---

## 🔄 Mapping des types

### TypeMaree vs PhaseMaree

```swift
// TypeMaree (3 cas) - Utilisé par ConditionsPeche
case montante
case descendante
case etale

// PhaseMaree (4 cas) - Utilisé par ConditionsMeteo
case montante
case etaleHaut
case descendante
case etaleBas

// Conversion
let phase: PhaseMaree = .etaleHaut
let type: TypeMaree = phase.toTypeMaree  // .etale
```

### TypeMareeExtreme (TypesCommuns.swift)

```swift
// Uniquement pour horaires
case pleineMer  // PM
case basseMer   // BM

// Utilisé par:
- CalendrierMareeService.HoraireMaree
- StormglassService.Extreme
```

---

## 📦 Structure finale

```
Leurre.swift (SOURCE DE VÉRITÉ)
├── Zone
├── Espece
├── TypeLeurre, TypePeche, Couleur, Finition
├── MomentJournee
├── Luminosite
├── Turbidite
├── TypeMaree (3 cas)
├── PhaseMaree (4 cas) ← NOUVEAU
├── EtatMer ← NOUVEAU
├── PhaseLunaire
└── ProfilBateau

TypesCommuns.swift (TECHNIQUE UNIQUEMENT)
└── TypeMareeExtreme (PM/BM)

ConditionsPeche.swift (UTILISE Leurre.swift)
├── zone: Zone
├── momentJournee: MomentJournee
├── luminosite: Luminosite
├── turbiditeEau: Turbidite
├── etatMer: EtatMer
├── typeMaree: TypeMaree
├── phaseLunaire: PhaseLunaire
├── especePrioritaire: Espece
└── profilBateau: ProfilBateau

ConditionsMeteo.swift (UTILISE Leurre.swift)
├── forceVent: Int
├── directionVent: DirectionVent
├── etatMer: EtatMer
├── visibilite: Visibilite
└── phaseMaree: PhaseMaree

CalendrierMareeService.swift (UTILISE TypesCommuns.swift)
└── HoraireMaree.type: TypeMareeExtreme

StormglassService.swift (UTILISE TypesCommuns.swift)
└── Extreme.type: TypeMareeExtreme
```

---

## ✅ Modifications apportées

### 1. Leurre.swift
```swift
// ✅ AJOUTÉ
enum PhaseMaree: String, Codable, CaseIterable, Hashable {
    case montante, etaleHaut, descendante, etaleBas
    func toTypeMaree() -> TypeMaree
}

enum EtatMer: String, Codable, CaseIterable, Hashable {
    case calme, peuAgitee, agitee, formee
}
```

### 2. TypesCommuns.swift
```swift
// ✅ SIMPLIFIÉ - Contient uniquement:
enum TypeMareeExtreme: String, Codable {
    case pleineMer = "PM"
    case basseMer = "BM"
}
```

### 3. ConditionsPeche.swift
```swift
// ✅ Utilise typeMaree (TypeMaree de Leurre.swift)
var typeMaree: TypeMaree  // montante/descendante/etale
```

### 4. ConditionsMeteo.swift
```swift
// ✅ Utilise phaseMaree (PhaseMaree de Leurre.swift)
var phaseMaree: PhaseMaree?  // montante/etaleHaut/descendante/etaleBas
```

### 5. CalendrierMareeService.swift
```swift
// ✅ Utilise TypeMareeExtreme (TypesCommuns.swift)
struct HoraireMaree {
    let type: TypeMareeExtreme  // pleineMer/basseMer
}
```

### 6. StormglassService.swift
```swift
// ✅ Utilise TypeMareeExtreme (TypesCommuns.swift)
struct Extreme {
    let type: TypeMareeExtreme  // pleineMer/basseMer
}
```

---

## 🎯 Règles à suivre

### ✅ À FAIRE
1. **Tous les nouveaux enums métier** → Leurre.swift
2. **Imports** : Les autres fichiers importent Leurre.swift
3. **Types techniques** (API, réseau, etc.) → TypesCommuns.swift si nécessaire

### ❌ NE JAMAIS FAIRE
1. ~~Dupliquer des enums entre fichiers~~
2. ~~Créer des enums métier hors de Leurre.swift~~
3. ~~Modifier les enums existants de Leurre.swift sans raison~~

---

## 🧪 Tests de validation

### ConditionsPeche compile ✅
```swift
let conditions = ConditionsPeche(
    zone: .lagon,
    typeMaree: .montante,
    etatMer: .calme,
    luminosite: .faible,
    turbiditeEau: .claire,
    momentJournee: .aube,
    phaseLunaire: .premierQuartier,
    especePrioritaire: .thazard
)
```

### ConditionsMeteo compile ✅
```swift
let meteo = ConditionsMeteo(
    etatMer: .calme,
    phaseMaree: .montante,
    coefficientMaree: 75
)
```

### StormglassService compile ✅
```swift
let extreme = Extreme(
    date: Date(),
    hauteur: 1.5,
    type: .pleineMer  // TypeMareeExtreme
)
```

---

## 🚀 Résultat

✅ **Leurre.swift = source unique** pour les enums métier  
✅ **TypesCommuns.swift = minimal** (uniquement TypeMareeExtreme)  
✅ **Pas de duplication** d'enums  
✅ **Pas de conflits** d'ambiguïté  
✅ **Compilation propre** de tous les fichiers  

---

**Principe respecté :**  
> "LES NOUVEAUX FICHIERS SUIVENT LES ENUM DES ANCIENS. ON NE TOUCHE PAS À CE QUI FONCTIONNAIT AVANT"

✅ **Validé et appliqué !**

---

**Modifié par :** Assistant IA  
**Date :** 20 janvier 2026
