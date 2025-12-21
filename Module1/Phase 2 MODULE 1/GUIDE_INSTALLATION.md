# Guide d'Installation - Module 1 Phase 2
## Go Les Picots V.4 - Édition et gestion des leurres

---

## Résumé des fichiers créés

```
GoLesPicots_Phase2/
├── Models/
│   └── Leurre.swift              ← Modèle révisé (TypePeche + champs déduits)
│
├── ViewModels/
│   └── LeureViewModel.swift      ← ViewModel enrichi (CRUD + recalcul auto)
│
├── Views/
│   ├── LeurreFormView.swift      ← Formulaire création/édition
│   └── Components/
│       └── ImagePickerView.swift ← Sélection photo (caméra/galerie)
│
└── Services/
    └── LeurreStorageService.swift ← Persistance JSON + photos
```

---

## Étapes d'installation

### Étape 1 : Sauvegarder le projet actuel

Avant toute modification, fais une copie de sauvegarde de ton projet Xcode.

### Étape 2 : Remplacer/Ajouter les fichiers

#### Option A : Remplacement complet (recommandé)

1. **Leurre.swift** → Remplace l'ancien fichier `Models/Leurre.swift`
   - Ce fichier contient le nouveau modèle avec `TypePeche` et les champs déduits
   - ⚠️ Backup ton ancien fichier au cas où

2. **LeureViewModel.swift** → Remplace `ViewModels/LeureViewModel.swift`
   - Contient les nouvelles méthodes CRUD et le recalcul automatique

3. **LeurreStorageService.swift** → Nouveau fichier dans `Services/`
   - Crée le dossier `Services` s'il n'existe pas
   - Glisse-dépose le fichier

4. **LeurreFormView.swift** → Nouveau fichier dans `Views/`

5. **ImagePickerView.swift** → Nouveau fichier dans `Views/Components/`
   - Crée le dossier `Components` s'il n'existe pas

#### Option B : Intégration progressive

Si tu préfères intégrer progressivement, commence par :
1. `LeurreStorageService.swift` (indépendant)
2. `ImagePickerView.swift` (indépendant)
3. `Leurre.swift` (modifie le modèle)
4. `LeureViewModel.swift` (adapte le ViewModel)
5. `LeurreFormView.swift` (ajoute le formulaire)

### Étape 3 : Ajouter les fichiers au Target

Pour chaque fichier ajouté dans Xcode :
1. Sélectionne le fichier dans le navigateur
2. Ouvre l'inspecteur de fichiers (⌥⌘1)
3. Coche ta cible "Go les Picots" dans "Target Membership"

### Étape 4 : Configurer Info.plist pour la caméra

Pour utiliser la caméra, ajoute ces clés dans `Info.plist` :

```xml
<key>NSCameraUsageDescription</key>
<string>Go les Picots utilise la caméra pour photographier vos leurres</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>Go les Picots accède à votre galerie pour importer des photos de leurres</string>
```

**Dans Xcode :**
1. Sélectionne ton projet dans le navigateur
2. Sélectionne ta cible
3. Onglet "Info"
4. Ajoute les clés :
   - `Privacy - Camera Usage Description`
   - `Privacy - Photo Library Usage Description`

### Étape 5 : Modifier les vues existantes

#### 5.1 Ajouter le bouton "+" dans BoiteView

Dans ton fichier `BoiteView.swift`, ajoute dans la toolbar :

```swift
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button {
            showAjouterLeurre = true
        } label: {
            Image(systemName: "plus")
        }
    }
}
.sheet(isPresented: $showAjouterLeurre) {
    LeurreFormView(viewModel: viewModel, mode: .creation)
}
```

Et déclare l'état :
```swift
@State private var showAjouterLeurre = false
```

#### 5.2 Ajouter les boutons dans DetailLeurreView

Dans ton fichier `DetailLeurreView.swift` :

```swift
// États
@State private var showEditer = false
@State private var showConfirmationSuppression = false
@Environment(\.dismiss) private var dismiss

// Dans la toolbar
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Menu {
            Button {
                showEditer = true
            } label: {
                Label("Modifier", systemImage: "pencil")
            }
            
            Button(role: .destructive) {
                showConfirmationSuppression = true
            } label: {
                Label("Supprimer", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

// Sheets et alerts
.sheet(isPresented: $showEditer) {
    LeurreFormView(viewModel: viewModel, mode: .edition(leurre))
}
.alert("Supprimer ce leurre ?", isPresented: $showConfirmationSuppression) {
    Button("Annuler", role: .cancel) { }
    Button("Supprimer", role: .destructive) {
        viewModel.supprimerLeurre(leurre)
        dismiss()
    }
} message: {
    Text("Cette action est irréversible.")
}
```

### Étape 6 : Migration du JSON existant

Le nouveau modèle `Leurre` a des champs supplémentaires. Pour migrer les 63 leurres existants :

#### Option 1 : Migration automatique au premier lancement

Le `LeurreStorageService` copie automatiquement le fichier du bundle vers Documents au premier lancement. Les champs manquants auront des valeurs par défaut.

#### Option 2 : Mettre à jour le JSON manuellement

Ajoute ces champs à chaque leurre dans ton JSON :

```json
{
  "id": 1,
  "nom": "Magnum Stretch 30+",
  "typePeche": "traine",        // ← NOUVEAU (obligatoire)
  "typeLeurre": "poissonNageurPlongeant",
  "isComputed": false,          // ← NOUVEAU
  // ... autres champs existants
}
```

Les champs déduits seront calculés automatiquement au chargement.

### Étape 7 : Compiler et tester

1. **Cmd+B** pour compiler
2. Corriger les éventuelles erreurs de syntaxe
3. **Cmd+R** pour lancer

#### Tests à effectuer :

- [ ] L'app se lance sans crash
- [ ] La liste des leurres s'affiche
- [ ] Le bouton "+" ouvre le formulaire de création
- [ ] Créer un nouveau leurre fonctionne
- [ ] Modifier un leurre existant fonctionne
- [ ] Supprimer un leurre fonctionne
- [ ] Les photos (caméra/galerie/URL) fonctionnent
- [ ] Les champs traîne apparaissent uniquement si TypePeche = Traîne

---

## Résolution des problèmes courants

### Erreur : "Cannot find type 'TypePeche' in scope"
→ Vérifie que le nouveau `Leurre.swift` est bien ajouté au target

### Erreur : "Value of type 'Leurre' has no member 'typePeche'"
→ Tu utilises l'ancien modèle. Remplace par le nouveau `Leurre.swift`

### Erreur JSON : "keyNotFound"
→ Le JSON existant n'a pas les nouveaux champs. Ajoute `"typePeche": "traine"` et `"isComputed": false` à chaque leurre

### La caméra ne s'ouvre pas
→ Vérifie les permissions dans Info.plist (voir Étape 4)

### Les photos ne se sauvegardent pas
→ Le dossier `photos_leurres` est créé automatiquement dans Documents. Vérifie les permissions d'écriture.

---

## Prochaines étapes (Phase 2 complète)

Une fois l'installation validée :

1. ✅ Tester la création d'un nouveau leurre
2. ✅ Tester la modification d'un leurre existant
3. ✅ Tester la suppression avec confirmation
4. ✅ Tester les 3 sources de photos
5. ✅ Vérifier le recalcul automatique des champs déduits
6. 🔜 Intégration avec le Module 2 (moteur de suggestion)

---

## Besoin d'aide ?

Si tu rencontres des erreurs de compilation, copie-colle le message d'erreur et je t'aiderai à le corriger.
