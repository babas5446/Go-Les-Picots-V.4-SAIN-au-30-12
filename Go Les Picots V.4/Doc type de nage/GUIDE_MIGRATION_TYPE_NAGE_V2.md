# 🚀 Guide de Migration Rapide : Type de Nage v1 → v2

**Date :** 28 Décembre 2024  
**Durée estimée :** 30 minutes  
**Difficulté :** ⭐⭐ Moyenne

---

## 📋 Checklist Complète

### ✅ Étape 1 : Fichiers à Modifier (5 min)

- [x] **TypeDeNage.swift** - Ajouter `struct TypeDeNageEntry`
- [x] **Leurre.swift** - Changer propriété en array
- [ ] **LeurreFormView.swift** - Utiliser nouveau composant

### ✅ Étape 2 : Fichier à Créer (2 min)

- [x] **TypeDeNageMultiSelectField.swift** - Nouveau composant UI

### ✅ Étape 3 : Tests (20 min)

- [ ] Compilation réussie
- [ ] Création leurre avec 0 types
- [ ] Création leurre avec 1 type
- [ ] Création leurre avec 3+ types
- [ ] Édition contexte
- [ ] Migration anciens leurres

---

## 🔧 Modification de LeurreFormView.swift

### AVANT (v1.0 - single)

```swift
struct LeurreFormView: View {
    @State private var typeDeNage: TypeDeNage?
    @State private var typeDeNageCustom: TypeDeNageCustom?
    @StateObject private var typeDeNageService = TypeDeNageCustomService.shared
    
    var body: some View {
        Form {
            // ...
            
            Section(header: Text("Type de nage (optionnel)")) {
                TypeDeNageSearchField(
                    selectedType: $typeDeNage,
                    selectedCustomType: $typeDeNageCustom,
                    notes: $notes,
                    service: typeDeNageService
                )
            }
        }
    }
    
    init(leurre: Leurre?) {
        if let leurre = leurre {
            _typeDeNage = State(initialValue: leurre.typeDeNage)
            _typeDeNageCustom = State(initialValue: leurre.typeDeNageCustom)
        }
    }
    
    private func sauvegarderLeurre() {
        let leurre = Leurre(
            // ...
            typeDeNage: typeDeNage,
            typeDeNageCustom: typeDeNageCustom
        )
    }
}
```

### APRÈS (v2.0 - multi)

```swift
struct LeurreFormView: View {
    @State private var TypeDeNage: [TypeDeNageEntry] = []  // ⭐ CHANGÉ
    @StateObject private var typeDeNageService = TypeDeNageCustomService.shared
    
    var body: some View {
        Form {
            // ...
            
            Section(header: Text("Types de nage (optionnels)")) {  // ⭐ pluriel
                TypeDeNageMultiSelectField(  // ⭐ NOUVEAU composant
                    selectedTypes: $TypeDeNage,
                    notes: $notes,
                    service: typeDeNageService
                )
            }
        }
    }
    
    init(leurre: Leurre?) {
        if let leurre = leurre {
            _TypeDeNage = State(initialValue: leurre.TypeDeNage ?? [])  // ⭐ CHANGÉ
        }
    }
    
    private func sauvegarderLeurre() {
        let leurre = Leurre(
            // ...
            TypeDeNage: TypeDeNage.isEmpty ? nil : TypeDeNage  // ⭐ CHANGÉ
        )
    }
}
```

---

## 🔍 Différences Clés

| Aspect | v1.0 (single) | v2.0 (multi) |
|--------|---------------|--------------|
| **Type de données** | `TypeDeNage?` | `[TypeDeNageEntry]?` |
| **Composant UI** | `TypeDeNageSearchField` | `TypeDeNageMultiSelectField` |
| **Affichage** | 1 champ texte | Chips horizontaux |
| **Contextes** | ❌ Non | ✅ Oui |
| **Détection auto** | Badge unique | Badge multiple |
| **Édition** | Remplacement | Ajout/suppression |

---

## 💾 Exemples JSON

### v1.0 (ancien)
```json
{
  "id": 1,
  "nom": "Magnum",
  "typeDeNage": "wobbling"
}
```

### v2.0 (nouveau)
```json
{
  "id": 1,
  "nom": "Magnum",
  "TypeDeNage": [
    {
      "id": "UUID-123",
      "typeStandard": "wobbling",
      "contexte": "vitesse 2-3 nœuds"
    },
    {
      "id": "UUID-456",
      "typeStandard": "rolling",
      "contexte": "vitesse 4-6 nœuds"
    }
  ]
}
```

---

## ⚠️ Points d'Attention

1. **Ne pas supprimer les anciennes propriétés** `typeDeNage` et `typeDeNageCustom`
   - Marquées `@available(*, deprecated)`
   - Utilisées pour migration automatique

2. **Tester avec de vrais JSON existants**
   - La migration doit être transparente
   - Aucune perte de données

3. **Interface adaptée au nombre de types**
   - 0-2 types : Affichage compact
   - 3-5 types : Scroll horizontal
   - 5+ types : Vertical scrolling dans picker

---

## 🧪 Script de Test Rapide

```swift
import Testing

@Test("Migration v1 → v2")
func testMigration() throws {
    // JSON v1.0 (ancien format)
    let jsonV1 = """
    {
        "id": 1,
        "nom": "Test Leurre",
        "marque": "Test",
        "typeDeNage": "wobbling"
    }
    """
    
    let leurre = try JSONDecoder().decode(Leurre.self, from: jsonV1.data(using: .utf8)!)
    
    // Vérifier migration automatique
    #expect(leurre.TypeDeNage != nil)
    #expect(leurre.TypeDeNage?.count == 1)
    #expect(leurre.TypeDeNage?.first?.typeStandard == .wobbling)
    
    // Vérifier encodage v2.0
    let encoded = try JSONEncoder().encode(leurre)
    let decoded = try JSONDecoder().decode(Leurre.self, from: encoded)
    
    #expect(decoded.TypeDeNage?.count == 1)
}
```

---

## 🎯 Validation Finale

Avant de considérer la migration terminée :

- [ ] Code compile sans warnings
- [ ] Anciens leurres se chargent correctement
- [ ] Nouveaux leurres se sauvegardent en v2.0
- [ ] Édition de leurres fonctionne
- [ ] Duplication copie tous les types
- [ ] Détection automatique opérationnelle
- [ ] Contextes sauvegardés/chargés

---

## 📞 En Cas de Problème

### Erreur de compilation
```
Type 'Leurre' has no member 'TypeDeNage'
```
**Solution :** Vérifier que `Leurre.swift` a bien été modifié.

### Types non affichés
**Solution :** Vérifier binding `$TypeDeNage` dans `TypeDeNageMultiSelectField`.

### Migration ne fonctionne pas
**Solution :** Vérifier logique dans `init(from decoder:)` de `Leurre.swift`.

---

**✅ Migration Complète !**

Une fois ces étapes validées, votre application supporte la multi-sélection de types de nage avec contextes. 🎣
