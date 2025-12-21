# Guide rapide : Ajouter l'image du spread au projet

## 📸 Image requise

**Fichier fourni** : `Spread_template_complet_ok.png`  
**Dimensions** : 1024 × 1536 pixels  
**Format** : PNG

---

## 🔧 Étapes dans Xcode

### 1. Ouvrir le catalogue d'assets

1. Dans le navigateur de projet (panneau gauche), localiser **Assets.xcassets**
2. Cliquer dessus pour l'ouvrir

### 2. Ajouter l'image

**Option A : Glisser-déposer**
1. Ouvrir le Finder et localiser `Spread_template_complet_ok.png`
2. Glisser le fichier directement dans Assets.xcassets
3. Xcode créera automatiquement un nouvel asset

**Option B : Menu contextuel**
1. Clic droit dans Assets.xcassets
2. Choisir **"New Image Set"**
3. Renommer en `spread_template_ok`
4. Glisser l'image dans la case "Universal" ou "1x"

### 3. Renommer l'asset (si nécessaire)

**Nom requis** : `spread_template_ok`

Si Xcode a gardé le nom original :
1. Sélectionner l'asset dans la liste
2. Dans l'inspecteur (panneau droit), section "Name"
3. Changer en `spread_template_ok` (sans extension)

### 4. Vérifier les paramètres

Dans l'inspecteur de l'image (panneau droit) :

**Devices** : Universal (ou cocher iPhone + iPad)  
**Scale Factors** : 1x, 2x, 3x (Xcode générera les variantes automatiquement)  
**Render As** : Default Image

### 5. Optimisation (recommandé)

Pour réduire la taille de l'app :

1. Ouvrir l'image dans **Aperçu** (Preview.app)
2. **Outils > Ajuster la taille...**
3. Vérifier que les dimensions sont bien 1024 × 1536
4. **Fichier > Exporter...**
5. Format : PNG
6. Qualité : Bonne (pas besoin de "Meilleure")
7. Remplacer l'image dans Assets.xcassets

---

## ✅ Vérification

### Test 1 : Dans le code
Le code suivant doit fonctionner sans erreur :
```swift
Image("spread_template_ok")
    .resizable()
```

### Test 2 : Dans l'app
1. Lancer l'app
2. Module 2 > Générer des suggestions
3. Onglet "Schéma"
4. L'image du spread doit s'afficher avec les bulles interactives

### Test 3 : Taille du build
Vérifier que l'image est bien compressée :
1. Product > Archive
2. Organizer > Archives
3. Vérifier la taille de l'app (ne devrait pas augmenter de plus de 500 KB)

---

## 🐛 Dépannage

### Problème : Image n'apparaît pas

**Cause possible 1** : Nom incorrect
- **Solution** : Vérifier que le nom est exactement `spread_template_ok` (sans `.png`)

**Cause possible 2** : Image dans le mauvais target
- **Solution** :
  1. Sélectionner l'asset
  2. Inspecteur (panneau droit) > Target Membership
  3. Cocher la cible principale de l'app

**Cause possible 3** : Cache Xcode
- **Solution** :
  1. Product > Clean Build Folder (⇧⌘K)
  2. Fermer Xcode
  3. Supprimer `~/Library/Developer/Xcode/DerivedData/`
  4. Relancer Xcode

### Problème : Image floue

**Cause** : Résolution insuffisante
- **Solution** : Vérifier que l'image source est bien 1024 × 1536 pixels minimum

### Problème : Image déformée

**Cause** : Proportions incorrectes
- **Solution** :
  1. L'image doit avoir un ratio 2:3 (1024:1536)
  2. Si votre image a des proportions différentes, recadrer ou redimensionner avant import

---

## 📐 Si vous n'avez pas l'image

Si vous devez créer une nouvelle image de spread :

### Dimensions
- Largeur : 1024 pixels
- Hauteur : 1536 pixels
- Résolution : 72 ou 144 dpi

### Éléments à inclure
1. Bateau vu du dessus en haut (y ≈ 200-400)
2. Sillage (vagues blanches)
3. Tangons visibles (gauche et droite)
4. Lignes de pêche dessinées
5. Cercles/bulles vides aux positions :
   - Libre gauche : (138.5, 558.5) - ø 162
   - Libre centre : (515.0, 558.5) - ø 162
   - Short Corner : (779.5, 494.0) - ø 168.5
   - Long Corner : (515.0, 826.5) - ø 157.5
   - Short Rigger : (879.5, 953.5) - ø 163
   - Long Rigger : (145.0, 956.5) - ø 165.5
   - Shotgun : (657.0, 1201.0) - ø 165
6. Fond bleu dégradé (océan)

### Outils suggérés
- **Sketch** (Mac)
- **Figma** (Web)
- **Adobe Illustrator** (pro)
- **Affinity Designer** (abordable)

### Template SVG disponible ?
Si vous avez le fichier fourni `Spread_template_complet_ok.png`, utilisez-le directement.

---

## 🎨 Alternative : Image placeholder temporaire

Si vous voulez tester sans l'image finale :

1. Créer une image temporaire 1024 × 1536
2. Fond bleu uni
3. Texte "SPREAD TEMPLATE" au centre
4. L'ajouter comme `spread_template_ok` dans Assets.xcassets

**Avantage** : Permet de tester l'intégration UI avant d'avoir l'image finale

**Code pour générer une image de test (Swift Playgrounds)** :
```swift
import UIKit

let size = CGSize(width: 1024, height: 1536)
let renderer = UIGraphicsImageRenderer(size: size)

let image = renderer.image { ctx in
    // Fond bleu
    UIColor.systemBlue.setFill()
    ctx.fill(CGRect(origin: .zero, size: size))
    
    // Texte
    let text = "SPREAD\nTEMPLATE"
    let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 72, weight: .bold),
        .foregroundColor: UIColor.white
    ]
    
    let textSize = text.size(withAttributes: attributes)
    let textRect = CGRect(
        x: (size.width - textSize.width) / 2,
        y: (size.height - textSize.height) / 2,
        width: textSize.width,
        height: textSize.height
    )
    
    text.draw(in: textRect, withAttributes: attributes)
}

// Sauvegarder
if let data = image.pngData() {
    try? data.write(to: URL(fileURLWithPath: "/path/to/spread_template_ok.png"))
}
```

---

**Besoin d'aide ?** Vérifiez les logs Xcode pour tout message d'erreur lié au chargement d'image.
