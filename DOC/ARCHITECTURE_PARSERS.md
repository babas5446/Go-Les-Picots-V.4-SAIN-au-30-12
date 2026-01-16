# 🏗️ Architecture des parsers - Vue d'ensemble

## 📐 Structure globale

```
┌──────────────────────────────────────────────────────────────┐
│                    LeurreFormView.swift                      │
│                    (Interface utilisateur)                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────┐         │
│  │ [Importer depuis une page produit]              │         │
│  │                                                 │         │
│  │ URL : [https://www.example.com/produit]        │         │
│  │                                                 │         │
│  │         [Bouton "Importer"]                     │         │
│  └────────────────────────────────────────────────┘         │
│                         │                                    │
└─────────────────────────┼────────────────────────────────────┘
                          ↓
                          │ URL fournie par l'utilisateur
                          ↓
┌──────────────────────────────────────────────────────────────┐
│           LeurreWebScraperService.swift                      │
│              (Service de scraping)                           │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. extraireInfosDepuisURL(url)                             │
│     ├─> Valider l'URL                                       │
│     ├─> Télécharger le HTML                                 │
│     └─> Dispatcher vers le bon parser                       │
│                                                              │
└──────────────────────────────────────────────────────────────┘
                          ↓
           ┌──────────────┴──────────────┐
           │     Router (extraireInfos)   │
           │   Détecte le site depuis URL │
           └──────────────┬──────────────┘
                          │
    ┌─────────────────────┼─────────────────────┐
    │                     │                     │
    ↓                     ↓                     ↓
┌─────────┐         ┌──────────┐         ┌──────────┐
│ Rapala  │         │  Nomad   │         │ PrestaShop│
│ Parser  │         │  Parser  │         │  Parsers  │
└─────────┘         └──────────┘         └──────────┘
    │                     │                     │
    │                     │                     ├─> Des Poissons Si Grands
    │                     │                     └─> Pêch'Extrême
    │                     │
    └─────────────────────┴─────────────────────┘
                          │
                          ↓
              ┌───────────────────────┐
              │  LeurreInfosExtraites │
              │  (Données structurées)│
              └───────────────────────┘
                          │
                          ↓
              ┌───────────────────────┐
              │   Retour vers UI      │
              │   (Pré-remplissage)   │
              └───────────────────────┘
```

---

## 🔀 Flux de décision - Router

```
                    extraireInfos(html, url)
                            │
                            ↓
                ┌───────────────────────┐
                │  url.contains("...")  │
                └───────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ↓                   ↓                   ↓
┌───────────────┐   ┌───────────────┐   ┌──────────────┐
│ rapala.fr/com │   │ pecheur.com   │   │ decathlon.fr │
└───────────────┘   └───────────────┘   └──────────────┘
        │                   │                   │
        ↓                   ↓                   ↓
  extraireRapala()   extrairePecheur()  extraireDecathlon()
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ↓                   ↓                   ↓
┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────┐
│ nomadtackle.com │  │  walmart.com    │  │ despoissonssigrands  │ ⭐ NOUVEAU
└─────────────────┘  └─────────────────┘  └──────────────────────┘
        │                   │                   │
        ↓                   ↓                   ↓
extraireNomadTackle() extraireWalmart() extraireDesPoissonsSiGrands()
                            │
        ┌───────────────────┘
        │
        ↓
┌──────────────────┐
│ pechextreme.com  │ ⭐ NOUVEAU
└──────────────────┘
        │
        ↓
 extrairePechExtreme()
                            │
        ┌───────────────────┘
        │
        ↓
┌───────────────────┐
│ Tous autres sites │
└───────────────────┘
        │
        ↓
 extraireUniversel()
```

---

## 🧩 Anatomie d'un parser

### Structure type d'un parser

```swift
private func extraireXXX(html: String, url: String) -> LeurreInfosExtraites {
    var infos = LeurreInfosExtraites(pageURL: url)
    
    // Étape 1 : Extraire le titre
    if let titre = extraireBalise(html: html, tag: "title") {
        infos.pageTitle = titre
        // Parser le titre pour extraire marque/nom
    }
    
    // Étape 2 : Extraire la marque
    infos.marque = "..." // depuis titre, métadonnée, ou classe CSS
    
    // Étape 3 : Extraire le nom du produit
    infos.nom = "..." // depuis titre, URL, ou balise H1
    
    // Étape 4 : Extraire les variantes (tailles)
    infos.variantes = extraireVariantes(html: html)
    // ou : infos.variantes = extraireVariantesSpecifiques(html: html)
    
    // Étape 5 : Extraire la photo
    infos.urlPhoto = extrairePremiereImage(html: html)
    // ou : infos.urlPhoto = extraireImageSpecifique(html: html)
    
    // Étape 6 : Détecter le type de leurre
    let texteAnalyse = (infos.pageTitle ?? "") + " " + (infos.nom ?? "")
    infos.typeLeurre = detecterTypeLeurre(texte: texteAnalyse.lowercased())
    
    return infos
}
```

---

## 🏭 Parsers spécialisés

### 1. Parser Rapala

```
┌─────────────────────────────────────────┐
│       extraireRapala(html, url)         │
├─────────────────────────────────────────┤
│ Stratégie :                             │
│ • Marque : Toujours "Rapala"            │
│ • Nom : Extrait depuis URL              │
│   Ex: /countdown-magnum                 │
│       → "Countdown Magnum"              │
│ • Variantes : Pattern générique         │
│   (9 cm, 14 cm, 22g, etc.)              │
│ • Photo : Première image trouvée        │
│ • Type : Détecté depuis titre           │
└─────────────────────────────────────────┘
```

### 2. Parser Nomad Tackle (amélioré)

```
┌─────────────────────────────────────────┐
│      extraireNomadTackle(html, url)     │
├─────────────────────────────────────────┤
│ Étape 1 : Détecter type de page         │
│   url.contains("/collections/")         │
│     ├─> Page collection                 │
│     │   • Extraction depuis URL         │
│     │   • Chercher H1                   │
│     │   • Variantes depuis listing      │
│     └─> Page produit                    │
│         • Extraction standard           │
│         • Variantes depuis tableau      │
│                                         │
│ Étape 2 : Extraire variantes            │
│   Essayer 3 méthodes :                  │
│   1. extraireVariantesNomad()           │
│      (tableaux #spec-table)             │
│   2. extraireVariantes()                │
│      (patterns génériques)              │
│   3. extraireVariantesNomadCollection() │ ⭐ NOUVEAU
│      (listing collection)               │
│                                         │
│ Étape 3 : Détection type étendue        │
│   • "trolling" → Poisson nageur         │
│   • "minnow" → Poisson nageur           │ ⭐ NOUVEAU
└─────────────────────────────────────────┘
```

### 3. Parser PrestaShop (Des Poissons Si Grands + Pêch'Extrême)

```
┌─────────────────────────────────────────────────────┐
│  extraireDesPoissonsSiGrands / extrairePechExtreme  │
├─────────────────────────────────────────────────────┤
│ Stratégie commune (PrestaShop) :                    │
│                                                     │
│ 1. Métadonnées Open Graph                          │
│    <meta property="og:title" content="...">         │
│    <meta property="og:image" content="...">         │
│                                                     │
│ 2. Classes CSS PrestaShop                          │
│    class="product-manufacturer" → Marque           │
│    class="product-title" → Nom                     │
│    class="product-cover" → Photo                   │
│                                                     │
│ 3. Détection spécifique                            │
│    Des Poissons Si Grands :                        │
│      • URL contient "traine" → Poisson nageur      │
│    Pêch'Extrême :                                  │
│      • URL contient "big-game"                     │
│      • Contenu HTML analysé pour type précis       │
└─────────────────────────────────────────────────────┘
```

---

## 🛠️ Fonctions utilitaires

### Extraction de base

```
┌──────────────────────────────────────┐
│   extraireBalise(html, tag)          │
│   Ex: tag = "title"                  │
│   → Retourne contenu de <title>      │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│   extraireDepuisURL(url, pattern)    │
│   Ex: pattern = "/([a-z0-9-]+)$"     │
│   → Extrait dernière partie URL      │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│   extraireVariantes(html)            │
│   Cherche patterns :                 │
│   • "9 cm", "14 cm", "22 cm"         │
│   • "15g", "22g", "35g"              │
│   • "3-6m" (profondeur)              │
└──────────────────────────────────────┘
```

### Extraction PrestaShop ⭐ NOUVEAU

```
┌──────────────────────────────────────────────┐
│   extraireMetaProperty(html, property)       │
│   Ex: property = "og:title"                  │
│   → Retourne contenu métadonnée Open Graph   │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   extraireDepuisClassesPresta(html, infos)   │
│   Cherche classes :                          │
│   • "product-manufacturer" → Marque          │
│   • "product-title" → Nom                    │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   extraireContenuClass(html, className)      │
│   Cherche <div class="X">, <span class="X">  │
│   → Retourne contenu nettoyé                 │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   extraireImageProduit(html, patterns)       │
│   Cherche images avec classes prioritaires : │
│   1. "product-cover"                         │
│   2. "product-image"                         │
│   3. "img-fluid"                             │
│   Fallback : extrairePremiereImage()         │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│   nettoyerURLImage(url, html)                │
│   Traite :                                   │
│   • &amp; → &                                │
│   • //cdn.com/... → https://cdn.com/...      │
│   • /images/... → https://site.com/images/...│
└──────────────────────────────────────────────┘
```

### Extraction Nomad spécifique ⭐ NOUVEAU

```
┌──────────────────────────────────────────────┐
│   extraireVariantesNomadCollection(html)     │
│   Patterns détectés :                        │
│   • "95mm", "140mm" → 9.5cm, 14cm            │
│   • "DTX 140" → 14cm                         │
│   • "9.5 cm" → Direct                        │
│   Retour : Liste triée par taille croissante │
└──────────────────────────────────────────────┘
```

---

## 📊 Matrice de compatibilité

| Fonction utilitaire | Rapala | Pêcheur | Decathlon | Nomad | Walmart | DPS Grands | Pêch'Ext |
|---------------------|--------|---------|-----------|-------|---------|------------|----------|
| `extraireBalise` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `extraireDepuisURL` | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `extraireVariantes` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `extrairePremiereImage` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| `detecterTypeLeurre` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `extraireMetaProperty` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `extraireDepuisClassesPresta` | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| `extraireImageProduit` | ❌ | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ |
| `extraireVariantesNomad` | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `extraireVariantesNomadCollection` | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ | ❌ |
| `extraireImageWalmart` | ❌ | ❌ | ❌ | ❌ | ✅ | ❌ | ❌ |

---

## 🎯 Modèle de données

### LeurreInfosExtraites

```swift
struct LeurreInfosExtraites {
    var marque: String?          // Ex: "Rapala", "Nomad"
    var nom: String?             // Ex: "Countdown Magnum"
    var modele: String?          // (rarement utilisé)
    var typeLeurre: TypeLeurre?  // Ex: .poissonNageur
    var variantes: [VarianteLeurre] = []
    var urlPhoto: String?        // URL de l'image
    var pageTitle: String?       // Titre HTML (debug)
    var pageURL: String          // URL de la page
}
```

### VarianteLeurre

```swift
struct VarianteLeurre: Identifiable {
    let id = UUID()
    var longueur: Double?       // cm (ex: 14.0)
    var poids: Double?          // g (ex: 22.0)
    var profondeurMin: Double?  // m (ex: 3.0)
    var profondeurMax: Double?  // m (ex: 6.0)
    var description: String     // Ex: "14 cm - 22g - 3-6m"
}
```

---

## 🔄 Workflow complet - Exemple

### Scénario : Import depuis Nomad Tackle (page collection)

```
1. Utilisateur colle l'URL :
   https://www.nomadtackle.com.au/collections/dtx-offshore-trolling-minnow

2. LeurreFormView appelle :
   service.extraireInfosDepuisURL(url)

3. Service télécharge le HTML :
   ✅ 87234 caractères téléchargés

4. Router détecte "nomadtackle.com" :
   → extraireNomadTackle(html, url)

5. Parser Nomad détecte :
   • URL contient "/collections/"
   • → C'est une page collection

6. Extraction nom :
   • Depuis URL : "dtx-offshore-trolling-minnow"
   • Formaté : "DTX OFFSHORE TROLLING MINNOW"
   • Cherche H1 : "DTX Offshore Trolling Minnow"
   • → nom = "DTX Offshore Trolling Minnow"

7. Extraction variantes :
   • Essai 1 : extraireVariantesNomad()
     → 0 variantes (pas de tableau #spec-table)
   • Essai 2 : extraireVariantes()
     → 0 variantes (pas de patterns génériques)
   • Essai 3 : extraireVariantesNomadCollection()
     → Trouve : "95mm", "115mm", "140mm", "180mm", "220mm"
     → Converti : [9.5cm, 11.5cm, 14cm, 18cm, 22cm]
     → Trié : [9.5, 11.5, 14, 18, 22]
     → 5 variantes créées

8. Extraction photo :
   extraireImageProduit(patterns: ["product-featured-image", "collection-image"])
   → Trouve : https://cdn.nomadtackle.com.au/products/dtx-140.jpg

9. Détection type :
   • URL contient "trolling" → typeLeurre = .poissonNageur

10. Retour vers LeurreFormView :
    LeurreInfosExtraites {
        marque: "Nomad"
        nom: "DTX Offshore Trolling Minnow"
        typeLeurre: .poissonNageur
        variantes: [9.5cm, 11.5cm, 14cm, 18cm, 22cm]
        urlPhoto: "https://cdn.nomadtackle.com.au/..."
    }

11. UI affiche sélecteur de variantes :
    "Quelle taille possédez-vous ?"
    [ ] 9.5 cm
    [ ] 11.5 cm
    [✓] 14 cm    ← Utilisateur sélectionne
    [ ] 18 cm
    [ ] 22 cm

12. Formulaire pré-rempli :
    • Marque : "Nomad"
    • Nom : "DTX Offshore Trolling Minnow"
    • Type : Poisson nageur
    • Longueur : 14 cm
    • Photo : [IMAGE]

13. Utilisateur complète :
    • Couleur principale : [Choisir]
    • Couleur secondaire : [Choisir]
    • Type de pêche : Traîne
    • Notes : [Optionnel]

14. Sauvegarde :
    → Leurre ajouté à la base de données ✅
```

---

## 🧪 Points d'extension

### Ajouter un nouveau site

```swift
// 1. Dans extraireInfos(), ajouter la détection :
} else if url.contains("nouveausite.com") {
    infos = extraireNouveauSite(html: html, url: url)
}

// 2. Créer le parser :
private func extraireNouveauSite(html: String, url: String) -> LeurreInfosExtraites {
    var infos = LeurreInfosExtraites(pageURL: url)
    
    // Stratégie d'extraction :
    // • Est-ce que le site utilise PrestaShop ?
    //   → Utiliser extraireDepuisClassesPresta()
    // • Est-ce que le site a des métadonnées Open Graph ?
    //   → Utiliser extraireMetaProperty()
    // • Quelle est la structure HTML ?
    //   → Inspecter avec Safari et créer patterns
    
    return infos
}
```

### Améliorer un parser existant

```swift
// Exemple : Ajouter extraction profondeur pour Rapala

private func extraireRapala(html: String, url: String) -> LeurreInfosExtraites {
    // ... code existant ...
    
    // NOUVEAU : Extraction profondeur depuis description
    if let description = extraireBalise(html: html, tag: "meta[name='description']") {
        if let profondeur = extraireProfondeur(texte: description) {
            // Appliquer la profondeur à toutes les variantes
            for i in 0..<infos.variantes.count {
                infos.variantes[i].profondeurMin = profondeur.min
                infos.variantes[i].profondeurMax = profondeur.max
            }
        }
    }
    
    return infos
}

private func extraireProfondeur(texte: String) -> (min: Double, max: Double)? {
    // Pattern : "3-6m", "0.5-1.5m"
    let pattern = "([0-9.]+)\\s*-\\s*([0-9.]+)\\s*m"
    // ... regex matching ...
}
```

---

## 📚 Ressources

### Fichiers de référence

- **Code principal** : `LeurreWebScraperService.swift`
- **Tests** : `ScraperTests.swift`
- **Documentation** : `AJOUT_SITES_FRANCAIS_17DEC2024.md`
- **Guide de test** : `GUIDE_TEST_NOUVEAUX_PARSERS.md`
- **Ce fichier** : `ARCHITECTURE_PARSERS.md`

### Outils de debugging

1. **Safari Web Inspector**
   ```
   Safari → Develop → Show Page Source
   → Inspecter la structure HTML du site
   ```

2. **Console Xcode**
   ```
   ⇧⌘Y → Voir les logs print() en temps réel
   ```

3. **Regex Tester**
   ```
   https://regex101.com/
   → Tester les patterns d'extraction
   ```

---

**Date de création** : 17 décembre 2024  
**Version** : 1.0  
**Auteur** : Documentation technique Go les Picots
