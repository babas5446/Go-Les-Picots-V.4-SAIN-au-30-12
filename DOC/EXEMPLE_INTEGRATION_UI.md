# 💡 Exemple d'intégration dans LeurreFormView

## Code à ajouter dans LeurreFormView.swift

### 1. Composant ConfidenceIndicator

Créer un nouveau fichier `ConfidenceIndicator.swift` ou ajouter dans `LeurreFormView.swift` :

```swift
import SwiftUI

struct ConfidenceIndicator: View {
    let score: Double
    let showPercentage: Bool
    
    init(score: Double, showPercentage: Bool = true) {
        self.score = score
        self.showPercentage = showPercentage
    }
    
    var body: some View {
        if score > 0 {
            HStack(spacing: 3) {
                Image(systemName: iconName)
                    .font(.caption)
                
                if showPercentage {
                    Text("\(Int(score * 100))%")
                        .font(.caption2)
                        .monospacedDigit()
                }
            }
            .foregroundStyle(color)
            .help(helpText)
        }
    }
    
    private var iconName: String {
        if score > 0.8 {
            return "checkmark.circle.fill"
        } else if score > 0.5 {
            return "exclamationmark.triangle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var color: Color {
        if score > 0.8 {
            return .green
        } else if score > 0.5 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var helpText: String {
        let percentage = Int(score * 100)
        if score > 0.8 {
            return "Très fiable (\(percentage)%)"
        } else if score > 0.5 {
            return "À vérifier (\(percentage)%)"
        } else {
            return "Incertain (\(percentage)%)"
        }
    }
}

// Prévisualisation
#Preview {
    VStack(spacing: 20) {
        HStack {
            Text("Haute confiance")
            Spacer()
            ConfidenceIndicator(score: 0.95)
        }
        
        HStack {
            Text("Moyenne confiance")
            Spacer()
            ConfidenceIndicator(score: 0.65)
        }
        
        HStack {
            Text("Faible confiance")
            Spacer()
            ConfidenceIndicator(score: 0.30)
        }
        
        HStack {
            Text("Sans pourcentage")
            Spacer()
            ConfidenceIndicator(score: 0.85, showPercentage: false)
        }
    }
    .padding()
}
```

---

### 2. Modifications dans LeurreFormView

#### A. Variables d'état à ajouter

```swift
struct LeurreFormView: View {
    // ... variables existantes ...
    
    // 🆕 NOUVEAU : Stocker les infos extraites avec scores de confiance
    @State private var infosExtraites: LeurreInfosExtraites?
    
    // 🆕 NOUVEAU : État du cache
    @State private var utiliseCacheURL: Bool = false
    
    var body: some View {
        // ... reste du code
    }
}
```

#### B. Section "Importer depuis URL" améliorée

```swift
Section {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Label("Importer depuis une page produit", systemImage: "link.circle.fill")
                .font(.headline)
            
            Spacer()
            
            // 🆕 Indicateur de cache
            if utiliseCacheURL {
                Label("Cache", systemImage: "clock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help("Résultat depuis le cache")
            }
        }
        
        HStack {
            TextField("Coller l'URL ici", text: $urlProduit)
                .textFieldStyle(.roundedBorder)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !urlProduit.isEmpty {
                Button(action: { urlProduit = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        
        HStack(spacing: 12) {
            // Bouton d'import principal
            Button {
                Task {
                    await importerDepuisURL(forceRefresh: false)
                }
            } label: {
                HStack {
                    if estEnCoursImport {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                    }
                    Text(estEnCoursImport ? "Import en cours..." : "Importer")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(urlProduit.isEmpty || estEnCoursImport)
            
            // 🆕 Bouton refresh (forcer)
            if infosExtraites != nil {
                Button {
                    Task {
                        await importerDepuisURL(forceRefresh: true)
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.bordered)
                .disabled(estEnCoursImport)
                .help("Forcer le rafraîchissement (ignorer le cache)")
            }
        }
        
        // 🆕 Info sur la méthode d'extraction
        if let methode = infosExtraites?.methodeExtraction {
            HStack {
                Image(systemName: "info.circle")
                    .font(.caption)
                Text("Extraction via : \(methode)")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.secondary)
        }
    }
} header: {
    Text("Import automatique")
} footer: {
    Text("Collez l'URL d'une page produit (Rapala, Nomad, Amazon, etc.)")
}
```

#### C. Champs du formulaire avec indicateurs

```swift
Section("Informations du leurre") {
    // Marque avec indicateur de confiance
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Marque")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 🆕 Indicateur de confiance
                if let confiance = infosExtraites?.marqueConfiance {
                    ConfidenceIndicator(score: confiance)
                }
            }
            
            TextField("Ex: Rapala", text: $marque)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // Nom avec indicateur de confiance
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Nom / Modèle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 🆕 Indicateur de confiance
                if let confiance = infosExtraites?.nomConfiance {
                    ConfidenceIndicator(score: confiance)
                }
            }
            
            TextField("Ex: X-Rap Magnum", text: $nom)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    // Type de leurre avec indicateur
    HStack {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Type de leurre")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 🆕 Indicateur de confiance
                if let confiance = infosExtraites?.typeConfiance {
                    ConfidenceIndicator(score: confiance)
                }
            }
            
            Picker("Type", selection: $typeLeurreSelectionne) {
                ForEach(TypeLeurre.allCases) { type in
                    Text(type.description).tag(type as TypeLeurre?)
                }
            }
            .pickerStyle(.menu)
        }
    }
}
```

#### D. Fonction d'import améliorée

```swift
// 🆕 Fonction d'import mise à jour
private func importerDepuisURL(forceRefresh: Bool = false) async {
    guard !urlProduit.isEmpty else { return }
    
    estEnCoursImport = true
    messageErreur = nil
    utiliseCacheURL = false
    
    do {
        // Vérifier si c'est depuis le cache
        let service = LeurreWebScraperService.shared
        let urlExisteEnCache = service.tailleCache() > 0
        
        // Extraire les infos
        let infos = try await service.extraireInfosDepuisURL(
            urlProduit,
            forceRefresh: forceRefresh
        )
        
        // Stocker les infos complètes
        infosExtraites = infos
        
        // Déterminer si c'est depuis le cache
        // (si pas de forceRefresh et si l'URL était déjà en cache)
        utiliseCacheURL = !forceRefresh && urlExisteEnCache
        
        // Pré-remplir les champs
        if let marqueExtraite = infos.marque {
            marque = marqueExtraite
        }
        
        if let nomExtrait = infos.nom {
            nom = nomExtrait
        }
        
        if let type = infos.typeLeurre {
            typeLeurreSelectionne = type
        }
        
        // Gérer les variantes
        if !infos.variantes.isEmpty {
            variantesDisponibles = infos.variantes
            afficherSelectionVariante = true
        } else if let longueur = infos.variantes.first?.longueur {
            longueurLeurre = longueur
        }
        
        // Télécharger la photo
        if let urlPhoto = infos.urlPhoto {
            await telechargerPhoto(depuis: urlPhoto)
        }
        
        // Afficher un message de succès
        let confiance = (infos.marqueConfiance + infos.nomConfiance) / 2
        if confiance > 0.8 {
            // Extraction très fiable
            print("✅ Extraction réussie avec haute confiance")
        } else if confiance > 0.5 {
            // Extraction moyenne, avertir l'utilisateur
            messageErreur = "ℹ️ Infos extraites avec confiance moyenne. Merci de vérifier."
        } else {
            // Faible confiance
            messageErreur = "⚠️ Infos partielles extraites. Merci de compléter manuellement."
        }
        
    } catch {
        messageErreur = "Erreur : \(error.localizedDescription)"
        infosExtraites = nil
    }
    
    estEnCoursImport = false
}
```

---

### 3. Vue de gestion du cache (optionnel)

Créer une section dans les réglages ou dans LeurreFormView :

```swift
Section {
    HStack {
        Label("Entrées en cache", systemImage: "tray.fill")
        Spacer()
        Text("\(LeurreWebScraperService.shared.tailleCache())")
            .foregroundStyle(.secondary)
            .monospacedDigit()
    }
    
    Button(role: .destructive) {
        LeurreWebScraperService.shared.viderCache()
    } label: {
        Label("Vider le cache", systemImage: "trash")
    }
    
    Button {
        LeurreWebScraperService.shared.nettoyerCacheAncien()
    } label: {
        Label("Nettoyer cache ancien (>7 jours)", systemImage: "sparkles")
    }
} header: {
    Text("Cache du scraper")
} footer: {
    Text("Le cache accélère l'import d'URLs déjà scrapées. Videz-le uniquement si nécessaire.")
}
```

---

### 4. Extension pour les messages d'alerte

```swift
// Extension pour afficher des alertes selon le niveau de confiance
extension LeurreFormView {
    
    private func afficherAlerteConfiance() -> Alert? {
        guard let infos = infosExtraites else { return nil }
        
        let confianceMoyenne = (infos.marqueConfiance + infos.nomConfiance + 
                               infos.typeConfiance + infos.variantesConfiance + 
                               infos.photoConfiance) / 5.0
        
        if confianceMoyenne < 0.5 {
            return Alert(
                title: Text("⚠️ Confiance faible"),
                message: Text("Les informations extraites sont incertaines. Merci de vérifier et corriger manuellement."),
                dismissButton: .default(Text("OK"))
            )
        } else if confianceMoyenne < 0.8 {
            return Alert(
                title: Text("ℹ️ Vérification recommandée"),
                message: Text("Les informations semblent correctes mais une vérification est recommandée."),
                dismissButton: .default(Text("OK"))
            )
        }
        
        return nil
    }
}
```

---

### 5. Exemple complet d'une section du formulaire

```swift
Section {
    // Marque
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Marque")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let confiance = infosExtraites?.marqueConfiance, confiance > 0 {
                ConfidenceIndicator(score: confiance, showPercentage: true)
            }
        }
        
        TextField("Ex: Rapala, Nomad, Berkley", text: $marque)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
    }
    .padding(.vertical, 4)
    
    // Nom
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Nom / Modèle")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let confiance = infosExtraites?.nomConfiance, confiance > 0 {
                ConfidenceIndicator(score: confiance, showPercentage: true)
            }
        }
        
        TextField("Ex: X-Rap Magnum 140", text: $nom)
            .textFieldStyle(.roundedBorder)
            .autocorrectionDisabled()
    }
    .padding(.vertical, 4)
    
    // Type
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Type de leurre")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let confiance = infosExtraites?.typeConfiance, confiance > 0 {
                ConfidenceIndicator(score: confiance, showPercentage: true)
            }
        }
        
        Picker("Choisir", selection: $typeLeurreSelectionne) {
            Text("Sélectionner...").tag(nil as TypeLeurre?)
            ForEach(TypeLeurre.allCases) { type in
                Text(type.description).tag(type as TypeLeurre?)
            }
        }
        .pickerStyle(.menu)
        .tint(.accentColor)
    }
    .padding(.vertical, 4)
    
    // Photo avec indicateur
    VStack(alignment: .leading, spacing: 8) {
        HStack {
            Text("Photo")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            if let confiance = infosExtraites?.photoConfiance, confiance > 0 {
                ConfidenceIndicator(score: confiance, showPercentage: true)
            }
        }
        
        if let photo = photoProduit {
            Image(uiImage: photo)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .cornerRadius(8)
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 150)
                .overlay {
                    VStack {
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Aucune photo")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
        }
    }
    .padding(.vertical, 4)
    
} header: {
    Text("Informations du leurre")
} footer: {
    if let methode = infosExtraites?.methodeExtraction {
        HStack {
            Image(systemName: "info.circle")
            Text("Extraction via : \(methode)")
        }
        .font(.caption)
    }
}
```

---

### 6. Modifier la fonction de téléchargement de photo

```swift
private func telechargerPhoto(depuis urlString: String) async {
    do {
        let image = try await LeurreWebScraperService.shared.telechargerImage(urlString: urlString)
        await MainActor.run {
            photoProduit = image
            print("📸 Photo téléchargée avec succès")
        }
    } catch {
        print("❌ Erreur téléchargement photo : \(error)")
        // Ne pas afficher d'erreur à l'utilisateur, juste logger
    }
}
```

---

## 🎨 Résultat visuel attendu

### Champ avec haute confiance (>80%)
```
┌──────────────────────────────────────┐
│ Marque                    ✅ 95%     │
│ ┌──────────────────────────────────┐ │
│ │ Rapala                           │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Champ avec confiance moyenne (50-80%)
```
┌──────────────────────────────────────┐
│ Nom                       ⚠️ 65%     │
│ ┌──────────────────────────────────┐ │
│ │ X-Rap Magnum                     │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

### Champ avec faible confiance (<50%)
```
┌──────────────────────────────────────┐
│ Type                      ❌ 30%     │
│ ┌──────────────────────────────────┐ │
│ │ Poisson nageur ▼                 │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

---

## ✅ Checklist d'intégration

- [ ] Créer `ConfidenceIndicator.swift`
- [ ] Ajouter variable `@State private var infosExtraites: LeurreInfosExtraites?`
- [ ] Ajouter variable `@State private var utiliseCacheURL: Bool = false`
- [ ] Modifier la section d'import URL
- [ ] Ajouter indicateurs à tous les champs du formulaire
- [ ] Mettre à jour la fonction `importerDepuisURL()`
- [ ] (Optionnel) Ajouter section de gestion du cache
- [ ] Compiler et tester

---

**Date** : 12 janvier 2025  
**Version** : 2.0  
**Prêt à intégrer** : ✅
