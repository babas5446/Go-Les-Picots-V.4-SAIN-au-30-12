# 🧪 Guide de test - Nouveaux parsers (17 décembre 2024)

## 📋 Checklist de vérification

### Avant de tester

- [ ] Fichier `LeurreWebScraperService.swift` mis à jour avec les nouveaux parsers
- [ ] Compilation réussie (aucune erreur Swift)
- [ ] Connexion Internet active
- [ ] App lancée sur simulateur ou appareil

---

## 🎯 Stratégie de test

### Phase 1 : Tests automatisés (Recommandé)

**Fichier** : `ScraperTests.swift`

**Commandes Xcode** :
```
1. ⌘U → Lance tous les tests
2. Clic droit sur une fonction test → "Run test"
3. Voir les résultats dans le navigateur de test (⌘6)
```

**Tests disponibles** :
- ✅ `testNomadTackleCollection()` → Page collection Nomad
- ✅ `testDesPoissonsSiGrands()` → Site français #1
- ✅ `testPechExtreme()` → Site français #2
- ✅ `testURLInvalide()` → Gestion erreurs
- ✅ `testSiteInaccessible()` → Gestion erreurs réseau
- ✅ `testWorkflowComplet()` → Extraction + téléchargement photo

---

### Phase 2 : Tests manuels (Interface utilisateur)

#### Étape 1 : Lancer l'app

```
1. Ouvrir Go les Picots
2. Aller dans "Boîte à leurres"
3. Appuyer sur le bouton "+"
4. → LeurreFormView s'ouvre
```

#### Étape 2 : Trouver le bouton d'import

```
Dans LeurreFormView :
┌─────────────────────────────────────────┐
│ Ajouter un leurre                       │
├─────────────────────────────────────────┤
│                                         │
│ 🌐 Importer depuis une page produit    │
│ [Coller l'URL ici]                     │
│                                         │
├─────────────────────────────────────────┤
│ Marque : [Texte]                       │
│ Nom : [Texte]                          │
│ ...                                    │
└─────────────────────────────────────────┘
```

#### Étape 3 : Tester une URL

**Option A - Nomad Tackle (collection)**
```
URL à copier :
https://www.nomadtackle.com.au/collections/dtx-offshore-trolling-minnow

Résultats attendus :
✅ Marque : "Nomad"
✅ Nom : "DTX OFFSHORE TROLLING MINNOW" (ou similaire)
✅ Variantes : [9.5cm, 11cm, 14cm, 18cm, 22cm] (ou sous-ensemble)
✅ Type : Poisson nageur
✅ Photo : [IMAGE du leurre]
```

**Option B - Des Poissons Si Grands**
```
⚠️ IMPORTANT : Utiliser une URL de PRODUIT, pas de catégorie

URL de catégorie (ne fonctionne PAS) :
❌ https://www.despoissonssigrands.com/850-leurres-peche-mer

URL de produit (fonctionne) :
✅ https://www.despoissonssigrands.com/[NOM-DU-PRODUIT].html

Exemple théorique :
https://www.despoissonssigrands.com/rapala-magnum-cd18.html

Résultats attendus :
✅ Marque : Extraite depuis la page
✅ Nom : Extrait depuis le titre
✅ Photo : Image principale
✅ Variantes : Si plusieurs tailles disponibles
```

**Option C - Pêch'Extrême**
```
⚠️ IMPORTANT : Utiliser une URL de PRODUIT, pas de catégorie

URL de catégorie (ne fonctionne PAS) :
❌ https://www.pechextreme.com/fr/116-leurres-big-game

URL de produit (fonctionne) :
✅ https://www.pechextreme.com/fr/[NOM-DU-PRODUIT].html

Résultats attendus :
✅ Marque : Extraite depuis la page
✅ Nom : Extrait depuis le titre
✅ Photo : Image principale
✅ Type : Détecté (poisson nageur, jig, etc.)
✅ Variantes : Si plusieurs tailles disponibles
```

---

## 🔍 Comment trouver une URL de produit valide

### Méthode 1 : Navigation sur le site

```
1. Ouvrir le site dans Safari :
   - despoissonssigrands.com
   - pechextreme.com

2. Aller dans la catégorie "Leurres de traîne" ou "Big Game"

3. Cliquer sur UN produit spécifique

4. Copier l'URL de la barre d'adresse

Exemple d'URL valide :
✅ https://www.despoissonssigrands.com/rapala-x-rap-magnum-30-xrmag30.html
✅ https://www.pechextreme.com/fr/nomad-dtx-minnow-140mm.html
```

### Méthode 2 : Inspection de liens

```
1. Aller sur la page de catégorie

2. Clic droit sur un leurre → "Copier le lien"

3. Coller ce lien dans l'app
```

---

## ✅ Grille de vérification des résultats

### Pour chaque test, vérifier :

| Critère | Attendu | Résultat |
|---------|---------|----------|
| Marque extraite | ✅ Nom correct | ⬜ |
| Nom extrait | ✅ Nom du modèle | ⬜ |
| Type détecté | ✅ Poisson nageur / Jig / etc. | ⬜ |
| Variantes trouvées | ✅ Au moins 1 | ⬜ |
| Photo téléchargée | ✅ Image visible | ⬜ |
| Longueur extraite | ✅ Valeur en cm | ⬜ |
| Poids extrait | ✅ Valeur en g (si dispo) | ⬜ |

---

## 🐛 Debugging : Que faire si ça ne marche pas

### Erreur : "Aucune information trouvée"

**Causes possibles :**

1. **Page de catégorie au lieu de produit**
   ```
   ❌ https://example.com/850-leurres-peche-mer
   ✅ https://example.com/rapala-magnum-cd18.html
   ```
   **Solution** : Utiliser une URL de produit spécifique

2. **Site bloque les requêtes automatiques**
   ```
   Le site peut détecter que c'est un robot
   ```
   **Solution** : Essayer un autre site pour vérifier le parser

3. **Structure HTML différente**
   ```
   Le site a changé sa structure
   ```
   **Solution** : Vérifier le HTML avec Safari Inspector

### Erreur : "Impossible de se connecter"

**Causes possibles :**

1. **Pas de connexion Internet**
   **Solution** : Vérifier le Wi-Fi

2. **Site temporairement indisponible**
   **Solution** : Réessayer plus tard

3. **Timeout (15 secondes)**
   **Solution** : Site lent, augmenter le timeout dans le code

### Erreur : "URL invalide"

**Cause** : Format d'URL incorrect

**Exemples invalides** :
```
❌ rapala.com (manque https://)
❌ www.rapala.fr (manque https://)
❌ example (pas une URL)
```

**Solution** : Copier l'URL complète depuis Safari

---

## 📊 Logs de debugging

### Activer les logs détaillés

Dans `LeurreWebScraperService.swift`, les `print()` sont déjà présents :

```swift
print("✅ HTML téléchargé : \(html.count) caractères")
print("📸 Photo trouvée : \(url)")
print("✅ \(variantes.count) variante(s) trouvée(s)")
```

### Lire les logs dans Xcode

```
1. Ouvrir le panneau de console (⇧⌘Y)
2. Lancer l'app
3. Effectuer un import URL
4. Observer les logs en temps réel
```

**Exemple de logs normaux :**
```
✅ HTML téléchargé : 87234 caractères
📸 Photo trouvée : https://cdn.example.com/product.jpg
✅ 3 variante(s) trouvée(s)
```

**Exemple de logs avec problème :**
```
❌ Erreur réseau : URLError(.timedOut)
```

---

## 🧪 Tests de cas limites

### Test 1 : Site sans variantes

**URL** : Un produit avec une seule taille

**Résultat attendu** :
- ✅ 1 variante trouvée
- ✅ Pas de sélecteur de variantes affiché
- ✅ Pré-remplissage direct du formulaire

### Test 2 : Site sans photo

**Résultat attendu** :
- ✅ Extraction réussie des autres champs
- ⚠️ Photo vide (pas d'erreur)
- ✅ Utilisateur peut ajouter une photo manuellement

### Test 3 : Site sans type détectable

**Résultat attendu** :
- ✅ Extraction réussie des autres champs
- ⚠️ Type = nil (l'utilisateur doit choisir)

### Test 4 : Plusieurs variantes (5+)

**Résultat attendu** :
- ✅ Sélecteur de variantes affiché
- ✅ Liste triée par taille croissante
- ✅ Sélection → Pré-remplissage avec bonne variante

---

## 📝 Rapport de test

### Template à remplir

```
Date : _____________
Testeur : _____________

┌─────────────────────────────────────────────────────┐
│ Test 1 : Nomad Tackle Collection                   │
├─────────────────────────────────────────────────────┤
│ URL testée : https://www.nomadtackle.com.au/...    │
│ Résultat : ✅ / ❌                                   │
│ Marque extraite : _______________                  │
│ Nom extrait : _______________                      │
│ Nombre de variantes : _____                        │
│ Photo téléchargée : Oui / Non                     │
│ Notes : _______________________________________    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Test 2 : Des Poissons Si Grands                     │
├─────────────────────────────────────────────────────┤
│ URL testée : https://www.despoissonssigrands.com/...│
│ Résultat : ✅ / ❌                                   │
│ Marque extraite : _______________                  │
│ Nom extrait : _______________                      │
│ Nombre de variantes : _____                        │
│ Photo téléchargée : Oui / Non                     │
│ Notes : _______________________________________    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Test 3 : Pêch'Extrême                               │
├─────────────────────────────────────────────────────┤
│ URL testée : https://www.pechextreme.com/fr/...     │
│ Résultat : ✅ / ❌                                   │
│ Marque extraite : _______________                  │
│ Nom extrait : _______________                      │
│ Nombre de variantes : _____                        │
│ Photo téléchargée : Oui / Non                     │
│ Notes : _______________________________________    │
└─────────────────────────────────────────────────────┘
```

---

## 🚀 Tests avancés (optionnel)

### Test de performance

**Objectif** : Mesurer le temps d'extraction

```swift
import XCTest

func testPerformanceExtraction() throws {
    measure {
        // Code à mesurer
        let _ = try? await service.extraireInfosDepuisURL(url)
    }
}
```

**Temps attendu** : 2-5 secondes par URL

### Test de stress

**Objectif** : Extraire 10 URLs d'affilée

```swift
func testMultipleExtractions() async throws {
    let urls = [
        "https://www.nomadtackle.com.au/...",
        "https://www.despoissonssigrands.com/...",
        // ... 8 autres URLs
    ]
    
    for url in urls {
        let infos = try await service.extraireInfosDepuisURL(url)
        XCTAssertNotNil(infos.marque)
    }
}
```

### Test de fiabilité

**Objectif** : Vérifier la cohérence sur 3 tentatives

```swift
func testConsistency() async throws {
    let url = "https://www.nomadtackle.com.au/..."
    
    let infos1 = try await service.extraireInfosDepuisURL(url)
    let infos2 = try await service.extraireInfosDepuisURL(url)
    let infos3 = try await service.extraireInfosDepuisURL(url)
    
    XCTAssertEqual(infos1.marque, infos2.marque)
    XCTAssertEqual(infos2.marque, infos3.marque)
}
```

---

## 📞 Support

### Si vous rencontrez un problème

1. **Vérifier ce guide** : La solution est peut-être ici
2. **Consulter les logs** : Activer le mode debug
3. **Tester avec une URL connue** : Nomad Tackle fonctionne bien
4. **Vérifier la structure HTML** : Safari Inspector

### URLs de test garanties

Ces URLs fonctionnent à coup sûr (au 17 décembre 2024) :

```
✅ https://www.nomadtackle.com.au/collections/dtx-offshore-trolling-minnow
✅ https://www.rapala.fr/eu_fr/countdown-magnum
✅ https://www.walmart.com/ip/Mann-s-Bait-Company-Magnum-Stretch-30-Hard-Bait-Pink/...
```

---

**Date de création** : 17 décembre 2024  
**Dernière mise à jour** : 17 décembre 2024  
**Version** : 1.0
