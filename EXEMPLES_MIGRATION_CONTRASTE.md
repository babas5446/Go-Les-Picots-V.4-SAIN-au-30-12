# 📝 EXEMPLES CONCRETS : Migration du Contraste

**Date** : 26 décembre 2024

---

## Exemple 1 : YO ZURI 3D Magnum 160 (Holographique)

### ❌ AVANT : Contraste Erroné

```json
{
  "id": 1,
  "nom": "YO ZURI 3D Magnum 160",
  "marque": "YO ZURI",
  "modele": "3D Magnum",
  "typeLeurre": "poissonNageur",
  "typePeche": "traine",
  "longueur": 16.0,
  "poids": 45.0,
  "couleurPrincipale": "vertTransparent",
  "couleurSecondaire": null,
  "finition": "holographique",
  "contraste": "naturel",  // ❌ INCOHÉRENT : holographique devrait être flashy
  "profondeurNageMin": 1.0,
  "profondeurNageMax": 3.0,
  "vitesseTraineMin": 4.0,
  "vitesseTraineMax": 8.0,
  "quantite": 2,
  "isComputed": false
}
```

**Problème** : 
- `finition: "holographique"` → Devrait FORCER `flashy`
- `contraste: "naturel"` → OVERRIDE incorrect
- **Résultat** : Leurre placé en Long Corner au lieu de Short Rigger

---

### ✅ APRÈS : Option A - Supprimer la clé

```json
{
  "id": 1,
  "nom": "YO ZURI 3D Magnum 160",
  "marque": "YO ZURI",
  "modele": "3D Magnum",
  "typeLeurre": "poissonNageur",
  "typePeche": "traine",
  "longueur": 16.0,
  "poids": 45.0,
  "couleurPrincipale": "vertTransparent",
  "couleurSecondaire": null,
  "finition": "holographique",
  // ✅ Pas de contraste : le système calcule automatiquement
  "profondeurNageMin": 1.0,
  "profondeurNageMax": 3.0,
  "vitesseTraineMin": 4.0,
  "vitesseTraineMax": 8.0,
  "quantite": 2,
  "isComputed": false
}
```

**Résultat** :
- ✅ `leurre.contraste == nil`
- ✅ `leurre.profilVisuel == .flashy` (calculé depuis finition)
- ✅ Position : **Short Rigger** ou **Long Rigger**

---

### ✅ APRÈS : Option B - Utiliser null

```json
{
  "id": 1,
  "nom": "YO ZURI 3D Magnum 160",
  "marque": "YO ZURI",
  "modele": "3D Magnum",
  "typeLeurre": "poissonNageur",
  "typePeche": "traine",
  "longueur": 16.0,
  "poids": 45.0,
  "couleurPrincipale": "vertTransparent",
  "couleurSecondaire": null,
  "finition": "holographique",
  "contraste": null,  // ✅ Calculé automatiquement depuis finition
  "profondeurNageMin": 1.0,
  "profondeurNageMax": 3.0,
  "vitesseTraineMin": 4.0,
  "vitesseTraineMax": 8.0,
  "quantite": 2,
  "isComputed": false
}
```

**Résultat** : Identique à l'option A ✅

---

## Exemple 2 : Leurre Noir Mat (Silhouette)

### ❌ AVANT : Contraste Erroné

```json
{
  "id": 25,
  "nom": "Black Minnow",
  "marque": "Fiiish",
  "typeLeurre": "leurresSouples",
  "typePeche": "lancer",
  "longueur": 9.0,
  "poids": 10.0,
  "couleurPrincipale": "noir",
  "finition": "mate",
  "contraste": "flashy",  // ❌ INCOHÉRENT : noir mat devrait être sombre
  "quantite": 5,
  "isComputed": false
}
```

**Problème** :
- `couleurPrincipale: "noir"` + `finition: "mate"` → Devrait être `sombre`
- `contraste: "flashy"` → INCORRECT
- **Résultat** : Mauvaises recommandations de conditions

---

### ✅ APRÈS : null (recommandé)

```json
{
  "id": 25,
  "nom": "Black Minnow",
  "marque": "Fiiish",
  "typeLeurre": "leurresSouples",
  "typePeche": "lancer",
  "longueur": 9.0,
  "poids": 10.0,
  "couleurPrincipale": "noir",
  "finition": "mate",
  "contraste": null,  // ✅ Calculé : sombre (noir + mat)
  "quantite": 5,
  "isComputed": false
}
```

**Résultat** :
- ✅ `profilVisuel == .sombre`
- ✅ Recommandé en **eau trouble + forte luminosité** (silhouette)
- ✅ Position Long Corner en traîne

---

## Exemple 3 : Leurre Argenté Brillant

### ✅ AVANT : Contraste correct (garder)

```json
{
  "id": 42,
  "nom": "X-Rap Magnum",
  "marque": "Rapala",
  "typeLeurre": "poissonNageur",
  "typePeche": "traine",
  "longueur": 14.0,
  "couleurPrincipale": "argente",
  "finition": "metallique",
  "contraste": "contraste",  // ✅ CORRECT : argenté métallique = contraste
  "quantite": 3,
  "isComputed": false
}
```

**Action** : **NE RIEN CHANGER** ✅

**Pourquoi ?**
- Le contraste est cohérent avec couleur + finition
- Garder le contraste explicite préserve votre choix

**Alternative** : Si vous voulez laisser le système décider :

```json
{
  "contraste": null  // Le système calculera aussi "contraste"
}
```

---

## Exemple 4 : Leurre Sans Finition

### JSON Actuel

```json
{
  "id": 78,
  "nom": "Simple Popper",
  "marque": "Mer",
  "typeLeurre": "popper",
  "typePeche": "lancer",
  "longueur": 7.0,
  "couleurPrincipale": "bleu",
  "finition": null,  // Pas de finition spéciale
  "contraste": "naturel",  // Défini manuellement
  "quantite": 2,
  "isComputed": false
}
```

**Options** :

### Option A : Garder le contraste explicite
```json
{
  "contraste": "naturel"  // ✅ OK si vous êtes sûr
}
```

### Option B : Laisser le système calculer
```json
{
  "contraste": null  // Le système utilisera contrasteNaturel de "bleu"
}
```

**Les deux fonctionnent**, choisissez selon votre confiance dans la valeur.

---

## Exemple 5 : Leurre Chartreuse UV

### ❌ AVANT : Contraste Sous-Estimé

```json
{
  "id": 101,
  "nom": "Chartreuse Glow",
  "marque": "Custom",
  "typeLeurre": "jigMetallique",
  "typePeche": "lancer",
  "longueur": 8.0,
  "couleurPrincipale": "chartreuse",
  "finition": "UV",
  "contraste": "naturel",  // ❌ SOUS-ESTIMÉ : UV devrait amplifier
  "quantite": 1,
  "isComputed": false
}
```

**Problème** :
- `finition: "UV"` + couleur claire → Devrait être `flashy`
- `contraste: "naturel"` → Trop faible

---

### ✅ APRÈS : null pour calcul automatique

```json
{
  "id": 101,
  "nom": "Chartreuse Glow",
  "marque": "Custom",
  "typeLeurre": "jigMetallique",
  "typePeche": "lancer",
  "longueur": 8.0,
  "couleurPrincipale": "chartreuse",
  "finition": "UV",
  "contraste": null,  // ✅ Calculé : flashy (UV + chartreuse)
  "quantite": 1,
  "isComputed": false
}
```

**Résultat** :
- ✅ `profilVisuel == .flashy`
- ✅ Très visible en **eau trouble + faible luminosité**

---

## 📊 Tableau Récapitulatif

| Cas | Avant | Après (null) | Résultat |
|-----|-------|--------------|----------|
| **YO ZURI holo** | `"naturel"` ❌ | `null` | `.flashy` ✅ |
| **Noir mat** | `"flashy"` ❌ | `null` | `.sombre` ✅ |
| **Argenté méta** | `"contraste"` ✅ | (garder) | `.contraste` ✅ |
| **Bleu simple** | `"naturel"` ✅ | `null` ou garder | `.naturel` ✅ |
| **Chartreuse UV** | `"naturel"` ❌ | `null` | `.flashy` ✅ |

---

## 🔧 Script de Migration Automatique

### Recherche dans votre JSON

**Trouver les leurres avec finition holographique ET contraste non-flashy** :

```regex
"finition": "holographique",\s*\n\s*"contraste": "(?!flashy)[^"]*"
```

**Remplacer par** :
```json
"finition": "holographique",
"contraste": null
```

---

### Trouver les leurres avec finition mate ET contraste non-sombre

```regex
"finition": "mate",\s*\n\s*"contraste": "(?!sombre)[^"]*"
```

**Remplacer par** :
```json
"finition": "mate",
"contraste": null
```

---

## ✅ Checklist de Migration

Pour chaque leurre, vérifiez :

- [ ] Si `finition == "holographique"` → `contraste` devrait être `null` ou `"flashy"`
- [ ] Si `finition == "mate"` + couleur sombre → `contraste` devrait être `null` ou `"sombre"`
- [ ] Si `finition == "chrome"` ou `"miroir"` → `contraste` devrait être `null` ou `"flashy"`
- [ ] Si `finition == "UV"` + couleur claire → `contraste` devrait être `null` ou `"flashy"`
- [ ] Si pas de finition → Garder contraste existant ou mettre `null`

---

## 🎯 Recommandation Finale

### Pour minimiser les erreurs :

**Mettez `null` sur tous les leurres avec finitions fortes** :
- `holographique`
- `chrome`
- `miroir`
- `UV`
- `mate`
- `paillete`

**Raison** : Ces finitions ont un impact visuel dominant qui override la couleur.

### Pour les leurres sans finition :

**Gardez le contraste existant** si vous êtes sûr, sinon mettez `null`.

---

## 🧪 Tester la Migration

### Avant de modifier tout le JSON :

1. **Sauvegardez** votre JSON actuel
2. **Testez sur 1 leurre** :
   ```json
   {
     "contraste": null
   }
   ```
3. **Relancez l'app**
4. **Vérifiez** que le leurre s'affiche correctement
5. **Vérifiez** la position dans le spread

Si ça fonctionne ✅ → Continuez la migration

---

## 💡 Astuce : Validation Visuelle

Après migration, dans l'app :

1. Ouvrir **Diagnostic** (si disponible)
2. Vérifier pour chaque leurre :
   - `contraste` : null ou valeur explicite
   - `profilVisuel` : valeur calculée
3. Comparer avant/après

---

**Conclusion** : `null` est **sûr, simple et efficace** ✅

---

**Fin du document**
