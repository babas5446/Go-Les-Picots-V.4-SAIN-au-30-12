# 🧪 Tests des nouveaux sites - Nomad Tackle & Walmart

## 📅 Date : 17 décembre 2024

---

## 🎯 Objectif

Valider l'extraction d'informations depuis les nouveaux parsers :
- **Nomad Tackle** (nomadtackle.com.au)
- **Walmart** (walmart.com)

---

## 🧪 Scénarios de test

### Test 1 : Nomad Tackle - DTX Minnow

**URL de test :**
```
https://www.nomadtackle.com.au/collections/dtx-offshore-trolling-minnow#spec-table
```

**Données attendues :**

| Champ | Valeur attendue |
|-------|----------------|
| Marque | "Nomad" |
| Nom | "DTX OFFSHORE TROLLING MINNOW" ou similaire |
| Type | Poisson nageur (si "trolling" détecté) |
| Variantes | Multiple (si tableau #spec-table présent) |
| Photo | URL image produit |

**Cas particuliers Nomad :**
- ✅ Acronymes en majuscules (DTX)
- ✅ Extraction depuis tableaux HTML
- ✅ Support millimètres (95mm → 9.5cm)
- ✅ Profondeur de nage (ex: 3-6m)

**Étapes de test :**
1. Ouvrir l'app
2. Créer un nouveau leurre (bouton "+")
3. Cliquer sur "Importer depuis une page produit"
4. Coller l'URL Nomad
5. Attendre l'extraction (3-5 secondes)
6. **Vérifier** :
   - ✅ Marque = "Nomad"
   - ✅ Nom contient "DTX"
   - ✅ Si variantes multiples → Sélecteur affiché
   - ✅ Photo téléchargée
   - ✅ Type = Poisson nageur

---

### Test 2 : Walmart - Mann's Bait Company

**URL de test :**
```
https://www.walmart.com/ip/Mann-s-Bait-Company-Magnum-Stretch-30-Hard-Bait-Pink/...
```

**Ou URL complète fournie par l'utilisateur :**
```
(URL image : https://i5.walmartimages.com/seo/Mann-s-Bait-Company-Magnum-Stretch-30-Hard-Bait-Pink_2b27384f-b67e-4085-a01b-8307349ae40b.f0392e535f422351d3f93d4960a7c59d.jpeg?odnHeight=573&odnWidth=573&odnBg=FFFFFF)
```

**Données attendues :**

| Champ | Valeur attendue |
|-------|----------------|
| Marque | "Mann's Bait Company" |
| Nom | "Magnum Stretch 30 Hard Bait" |
| Type | Poisson nageur (détecté depuis "Hard Bait") |
| Longueur | 30 cm (extrait depuis "30" dans le titre) |
| Photo | URL walmartimages.com |

**Cas particuliers Walmart :**
- ✅ Marques composées (3 mots)
- ✅ Détection apostrophes ("Mann's")
- ✅ Extraction depuis titre format : "MARQUE Nom, Couleur"
- ✅ CDN Images : i5.walmartimages.com

**Étapes de test :**
1. Ouvrir l'app
2. Créer un nouveau leurre (bouton "+")
3. Cliquer sur "Importer depuis une page produit"
4. Coller l'URL Walmart
5. Attendre l'extraction (3-5 secondes)
6. **Vérifier** :
   - ✅ Marque = "Mann's Bait Company" (complet)
   - ✅ Nom contient "Magnum Stretch"
   - ✅ Longueur = 30 cm
   - ✅ Type = Poisson nageur
   - ✅ Photo rose visible (Mann's Pink)

---

## 📊 Grille de validation

### Nomad Tackle

| Critère | Résultat | Notes |
|---------|----------|-------|
| ✅ Marque extraite | [ ] Oui / [ ] Non | |
| ✅ Nom extrait | [ ] Oui / [ ] Non | |
| ✅ Type détecté | [ ] Oui / [ ] Non | |
| ✅ Variantes (si tableau) | [ ] Oui / [ ] Non / [ ] N/A | |
| ✅ Photo téléchargée | [ ] Oui / [ ] Non | |
| ✅ Longueur(s) extraite(s) | [ ] Oui / [ ] Non | |
| ✅ Poids extraits | [ ] Oui / [ ] Non | |
| ✅ Profondeur extraite | [ ] Oui / [ ] Non | |

### Walmart

| Critère | Résultat | Notes |
|---------|----------|-------|
| ✅ Marque complète extraite | [ ] Oui / [ ] Non | Doit inclure "Bait Company" |
| ✅ Nom extrait | [ ] Oui / [ ] Non | |
| ✅ Type détecté | [ ] Oui / [ ] Non | "Hard Bait" → Poisson nageur |
| ✅ Longueur extraite | [ ] Oui / [ ] Non | Depuis "30" dans titre |
| ✅ Photo CDN Walmart | [ ] Oui / [ ] Non | i5.walmartimages.com |

---

## 🐛 Cas d'erreur à tester

### Erreur réseau

**Test :**
1. Désactiver le Wi-Fi/données
2. Essayer d'importer une URL
3. **Attendre** : Message "Impossible de se connecter au site"

### URL invalide

**Test :**
1. Coller une URL incorrecte : `https://nomadtackle`
2. **Attendre** : Message "L'URL fournie n'est pas valide"

### Page sans informations de leurre

**Test :**
1. Coller une URL de page d'accueil : `https://www.walmart.com/`
2. **Attendre** : Message "Aucune information de leurre trouvée"

---

## 📝 Format de rapport de bug

Si un test échoue, documenter :

```
🐛 Bug détecté

Site : [Nomad / Walmart]
URL testée : [URL complète]
Étape : [Étape où le problème survient]

Comportement attendu :
[Ce qui devrait se passer]

Comportement observé :
[Ce qui se passe réellement]

Logs console (si disponibles) :
[Copier les messages console]
```

---

## ✅ Validation finale

Une fois les tests passés :

- [ ] Nomad Tackle : Extraction marque ✅
- [ ] Nomad Tackle : Extraction nom ✅
- [ ] Nomad Tackle : Extraction variantes ✅
- [ ] Nomad Tackle : Photo téléchargée ✅
- [ ] Nomad Tackle : Type détecté ✅

- [ ] Walmart : Extraction marque complète ✅
- [ ] Walmart : Extraction nom ✅
- [ ] Walmart : Extraction longueur depuis titre ✅
- [ ] Walmart : Photo CDN téléchargée ✅
- [ ] Walmart : Type "Hard Bait" détecté ✅

- [ ] Gestion d'erreurs : Réseau ✅
- [ ] Gestion d'erreurs : URL invalide ✅
- [ ] Gestion d'erreurs : Page vide ✅

---

## 🚀 Prochaines étapes après validation

1. ✅ Marquer les tests comme réussis
2. 📝 Mettre à jour la documentation utilisateur
3. 🎉 Déployer en production
4. 📊 Monitorer les taux de succès réels

**Date de test prévue** : 17 décembre 2024  
**Testeur** : [Nom]  
**Version** : Phase 1 - Ajout Nomad & Walmart
