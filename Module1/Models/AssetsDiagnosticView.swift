//
//  AssetsDiagnosticView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Vue de diagnostic pour trouver les assets manquants
//  Affiche tous les assets disponibles et aide à identifier les problèmes
//
//  Created: 2024-12-19
//

import SwiftUI

struct AssetsDiagnosticView: View {
    @State private var searchResults: [String] = []
    @State private var isSearching = false
    
    // Liste des noms d'images attendus
    let expectedImages = [
        "spread_template_ok",
        "spread_template",
        "SpreadTemplate",
        "banner",
        "Banner"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("🖼️ IMAGES ATTENDUES")) {
                    ForEach(expectedImages, id: \.self) { imageName in
                        ImageCheckRow(imageName: imageName)
                    }
                }
                
                Section(header: Text("📂 ASSETS DISPONIBLES")) {
                    if isSearching {
                        HStack {
                            ProgressView()
                            Text("Recherche...")
                                .foregroundColor(.secondary)
                        }
                    } else if searchResults.isEmpty {
                        Text("Aucun asset trouvé")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(searchResults, id: \.self) { asset in
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                Text(asset)
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                    }
                }
                
                Section(header: Text("🔧 ACTIONS")) {
                    Button(action: searchAssets) {
                        Label("Rechercher assets dans le bundle", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: listAllBundleFiles) {
                        Label("Lister tous les fichiers du bundle", systemImage: "list.bullet")
                    }
                }
                
                Section(header: Text("💡 AIDE")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comment ajouter l'image :")
                            .font(.headline)
                        
                        Text("1. Ouvrir Assets.xcassets dans Xcode")
                            .font(.caption)
                        
                        Text("2. Clic droit → New Image Set")
                            .font(.caption)
                        
                        Text("3. Nom : spread_template_ok")
                            .font(.caption)
                            .fontWeight(.bold)
                        
                        Text("4. Glisser votre PNG (1024×1536)")
                            .font(.caption)
                        
                        Text("5. Clean Build + Relancer")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Diagnostic Assets")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            searchAssets()
        }
    }
    
    private func searchAssets() {
        isSearching = true
        searchResults = []
        
        DispatchQueue.global(qos: .userInitiated).async {
            var results: [String] = []
            
            // Recherche dans le bundle principal
            if let bundlePath = Bundle.main.resourcePath {
                do {
                    let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                    let imageFiles = contents.filter { file in
                        let ext = (file as NSString).pathExtension.lowercased()
                        return ["png", "jpg", "jpeg", "pdf", "svg"].contains(ext)
                    }
                    results.append(contentsOf: imageFiles)
                    
                    print("📂 Assets trouvés dans le bundle (\(imageFiles.count)) :")
                    imageFiles.forEach { print("   - \($0)") }
                } catch {
                    print("⚠️ Erreur recherche assets : \(error)")
                }
            }
            
            // Recherche dans Assets.car (catalogue d'assets compilé)
            if let assetsURL = Bundle.main.url(forResource: "Assets", withExtension: "car") {
                results.append("✅ Assets.car trouvé (catalogue compilé)")
                print("✅ Assets.car présent : \(assetsURL.path)")
            } else {
                print("⚠️ Assets.car introuvable")
            }
            
            DispatchQueue.main.async {
                self.searchResults = results.sorted()
                self.isSearching = false
            }
        }
    }
    
    private func listAllBundleFiles() {
        print("\n🔍 === LISTE COMPLÈTE DES FICHIERS BUNDLE ===")
        
        if let bundlePath = Bundle.main.resourcePath {
            print("📂 Bundle : \(bundlePath)")
            
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
                print("📊 Total : \(contents.count) fichiers")
                print("")
                
                // Grouper par extension
                let grouped = Dictionary(grouping: contents) { file -> String in
                    let ext = (file as NSString).pathExtension.lowercased()
                    return ext.isEmpty ? "sans extension" : ext
                }
                
                for (ext, files) in grouped.sorted(by: { $0.key < $1.key }) {
                    print("📁 .\(ext) (\(files.count)) :")
                    files.sorted().forEach { print("   - \($0)") }
                    print("")
                }
            } catch {
                print("❌ Erreur : \(error)")
            }
        }
        
        print("🔍 === FIN LISTE ===\n")
    }
}

// MARK: - Image Check Row

struct ImageCheckRow: View {
    let imageName: String
    
    @State private var imageExists = false
    @State private var imageSize: CGSize?
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône statut
            Image(systemName: imageExists ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(imageExists ? .green : .red)
                .font(.title3)
            
            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(imageName)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                
                if imageExists {
                    if let size = imageSize {
                        Text("\(Int(size.width))×\(Int(size.height)) px")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Présent")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                } else {
                    Text("Non trouvé")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            // Preview
            if imageExists, let uiImage = UIImage(named: imageName) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            checkImage()
        }
    }
    
    private func checkImage() {
        if let uiImage = UIImage(named: imageName) {
            imageExists = true
            imageSize = uiImage.size
            print("✅ Image '\(imageName)' trouvée : \(uiImage.size)")
        } else {
            imageExists = false
            print("❌ Image '\(imageName)' INTROUVABLE")
        }
    }
}

// MARK: - Preview

struct AssetsDiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        AssetsDiagnosticView()
    }
}
