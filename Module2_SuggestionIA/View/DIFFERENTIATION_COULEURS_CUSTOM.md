# 🎨 Comment le Moteur Différencie les Nuances de Couleurs Custom

**Date** : 26 décembre 2024  
**Objectif** : Expliquer comment le moteur de suggestion utilise les couleurs personnalisées

---

## 🔍 La Question

> "Comment le moteur fait la différence entre vert foncé et vert pomme ?"

---

## 📊 Réponse : Deux Niveaux de Différenciation

### 1️⃣ **Niveau Primaire : Le Contraste** (Classification globale)

Quand vous créez une couleur personnalisée, vous lui assignez un **contraste** :

```
Vert pomme clair → contraste: .naturel
Vert foncé      → contraste: .sombre ou .naturel
```

**C'est le contraste que le moteur utilise principalement** pour :
- Recommander la position dans le spread
- Évaluer l'efficacité selon turbidité/luminosité
- Calculer le score global

### 2️⃣ **Niveau Secondaire : La Luminosité RGB** (Nuances fines)

**Nouveau** : Le système calcule maintenant la **luminosité perçue** automatiquement :

```swift
struct CouleurCustom {
    var luminositePercue: Double  // 0.0 (noir) à 1.0 (blanc)
    var estClaire: Bool            // > 0.5
    var estFoncee: Bool            // < 0.3
}
```

**Formule utilisée (ITU-R BT.709)** :
```
Luminosité = 0.2126 × R + 0.7152 × G + 0.0722 × B
```

**Exemple concret** :

| Couleur | R | G | B | Luminosité | Classification |
|---------|---|---|---|------------|----------------|
| **Vert pomme** | 0.6 | 0.9 | 0.3 | **0.68** | Clair ✅ |
| **Vert foncé** | 0.1 | 0.4 | 0.1 | **0.28** | Foncé ✅ |
| **Vert moyen** | 0.3 | 0.6 | 0.2 | **0.47** | Moyen |

---

## 🎯 Comment le Moteur Utilise Ces Infos

### Étape 1 : Scoring de Base (Contraste)

```swift
let profil = leurre.profilVisuel  // Basé sur le contraste
let scoreBase = profil.efficaciteDansContexte(
    turbidite: conditions.turbiditeEau,
    luminosite: conditions.luminosite
)
```

### Étape 2 : Ajustement Fin (Luminosité RGB)

**🆕 Proposition d'amélioration** pour `SuggestionEngine.swift` :

```swift
func calculerScoreCouleur(leurre: Leurre, conditions: ConditionsPeche) -> Double {
    var score = scoreBaseSelonContraste(leurre, conditions)
    
    // 🆕 Ajustement selon luminosité RGB de la couleur custom
    if leurre.couleurPrincipaleCustom != nil {
        score += ajustementLuminositeRGB(leurre, conditions)
    }
    
    return score
}

private func ajustementLuminositeRGB(
    _ leurre: Leurre, 
    _ conditions: ConditionsPeche
) -> Double {
    let lum = leurre.luminositePerçueCouleur
    
    switch (conditions.turbiditeEau, conditions.luminosite) {
    
    // Eau claire + Forte lumière → Couleurs claires meilleures
    case (.claire, .forte):
        if lum > 0.6 { return +1.5 }  // Vert pomme ✅
        if lum < 0.3 { return -1.0 }  // Vert foncé moins bon
        return 0.0
    
    // Eau claire + Faible lumière → Couleurs moyennes meilleures
    case (.claire, .faible):
        if lum > 0.4 && lum < 0.7 { return +1.5 }  // Vert moyen ✅
        if lum < 0.2 { return -1.0 }  // Trop foncé
        if lum > 0.8 { return -0.5 }  // Trop clair
        return 0.0
    
    // Eau trouble + Forte lumière → Couleurs foncées (silhouette)
    case (.trouble, .forte), (.tresTrouble, .forte):
        if lum < 0.3 { return +2.0 }  // Vert foncé ✅✅
        if lum > 0.6 { return -1.5 }  // Vert pomme moins bon
        return 0.0
    
    // Eau trouble + Faible lumière → Couleurs claires (tache visible)
    case (.trouble, .faible), (.tresTrouble, .faible):
        if lum > 0.6 { return +2.0 }  // Vert pomme ✅✅
        if lum < 0.3 { return -1.5 }  // Vert foncé invisible
        return 0.0
    
    default:
        return 0.0
    }
}
```

---

## 📈 Exemple Concret : Deux Verts

### Scénario : Eau claire + Forte lumière (Plein soleil)

#### Leurre 1 : "Vert pomme"
```
Contraste : naturel
RGB : (0.6, 0.9, 0.3)
Luminosité : 0.68 (CLAIR)

Score :
- Base (naturel en eau claire) : 10/10
- Ajustement RGB (clair + forte lumière) : +1.5
→ Score final : 11.5/10 ✅✅
```

#### Leurre 2 : "Vert foncé"
```
Contraste : naturel
RGB : (0.1, 0.4, 0.1)
Luminosité : 0.28 (FONCÉ)

Score :
- Base (naturel en eau claire) : 10/10
- Ajustement RGB (foncé + forte lumière) : -1.0
→ Score final : 9.0/10 ⚠️
```

**Résultat** : Le moteur recommande **Vert pomme** en priorité ! ✅

---

### Scénario 2 : Eau trouble + Forte lumière (Eau marron, soleil)

#### Leurre 1 : "Vert pomme"
```
Contraste : naturel
Luminosité : 0.68 (CLAIR)

Score :
- Base (naturel en eau trouble) : 6/10
- Ajustement RGB (clair + trouble lumineux) : -1.5
→ Score final : 4.5/10 ❌
```

#### Leurre 2 : "Vert foncé"
```
Contraste : naturel
Luminosité : 0.28 (FONCÉ)

Score :
- Base (naturel en eau trouble) : 6/10
- Ajustement RGB (foncé + trouble lumineux) : +2.0
→ Score final : 8.0/10 ✅✅
```

**Résultat** : Le moteur recommande **Vert foncé** (silhouette) ! ✅

---

## 💡 Informations Affichées à l'Utilisateur

Dans la vue de création de couleur custom, on peut afficher :

```
┌─────────────────────────────────────┐
│ Aperçu : [Pastille vert pomme]     │
│                                     │
│ 📊 Analyse automatique :            │
│ • Luminosité : Clair (68%)          │
│ • Contraste : Naturel               │
│                                     │
│ 💡 Recommandations :                │
│ • Eau claire + Soleil               │
│ • Imitation naturelle               │
└─────────────────────────────────────┘
```

---

## 🔧 Implémentation dans le Moteur

### Fichier à modifier : `SuggestionEngine.swift`

Chercher la fonction `calculerScoreCouleur()` et ajouter :

```swift
// Après le scoring de base selon contraste
var score = scoreContraste

// 🆕 AJUSTEMENT FIN selon luminosité RGB
if leurre.couleurPrincipaleCustom != nil {
    let lumCouleur = leurre.luminositePerçueCouleur
    
    switch (conditions.turbiditeEau, conditions.luminosite) {
    case (.claire, .forte):
        if lumCouleur > 0.6 { score += 1.5 }
        else if lumCouleur < 0.3 { score -= 1.0 }
        
    case (.trouble, .forte), (.tresTrouble, .forte):
        if lumCouleur < 0.3 { score += 2.0 }
        else if lumCouleur > 0.6 { score -= 1.5 }
        
    case (.trouble, .faible), (.tresTrouble, .faible):
        if lumCouleur > 0.6 { score += 2.0 }
        else if lumCouleur < 0.3 { score -= 1.5 }
        
    default:
        break
    }
}
```

---

## 📊 Tableaux Récapitulatifs

### Luminosité RGB → Classification

| Valeur | Classification | Exemples |
|--------|----------------|----------|
| **0.0 - 0.15** | Très foncé | Noir, marron très foncé |
| **0.15 - 0.3** | Foncé | Vert foncé, bleu marine |
| **0.3 - 0.5** | Moyen | Vert moyen, bleu moyen |
| **0.5 - 0.7** | Clair | Vert pomme, bleu clair |
| **0.7 - 1.0** | Très clair | Jaune citron, blanc, rose pâle |

### Recommandations selon Conditions

| Conditions | Luminosité recommandée | Exemples |
|------------|------------------------|----------|
| **Eau claire + Soleil** | Clair (0.5-0.7) | Vert pomme, bleu clair |
| **Eau claire + Ombre** | Moyen (0.3-0.6) | Vert moyen |
| **Eau trouble + Soleil** | Foncé (0.15-0.3) | Vert foncé (silhouette) |
| **Eau trouble + Ombre** | Clair (0.6-0.8) | Vert pomme (tache visible) |

---

## ✅ Résumé

### Comment le moteur différencie les couleurs :

1. **Contraste** (primaire) :
   - Classification globale (naturel, flashy, sombre)
   - Définit le comportement de base

2. **Luminosité RGB** (secondaire) :
   - Calcul automatique à partir des valeurs RGB
   - Ajustement fin selon les conditions
   - Différencie "vert pomme" (0.68) de "vert foncé" (0.28)

3. **Résultat** :
   - Le moteur recommande **la bonne nuance** de vert selon les conditions
   - Vous voyez **exactement** votre couleur dans l'app
   - Les recommandations sont **précises et adaptées**

---

**Implémentation** : ✅ Propriétés ajoutées dans `CouleurCustom` et `Leurre`  
**À faire** : Intégrer l'ajustement RGB dans `SuggestionEngine.calculerScoreCouleur()`  
**Impact** : Différenciation fine entre nuances de couleurs custom

---

**Fin du document**
