//
//  ExportImportView.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 01/01/2026.
//

import SwiftUI
import UniformTypeIdentifiers

struct ExportImportView: View {
    @ObservedObject var viewModel: LeureViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportURL: URL?
    @State private var showImportPicker = false
    @State private var showModeSelection = false
    @State private var importURL: URL?
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                // Section Export
                Section {
                    if let exportedURL = exportURL {
                        // Afficher ShareLink après export
                        ShareLink(item: exportedURL) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "0277BD"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Partager l'export")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Fichier prêt à être partagé")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        Button {
                            exporterBase()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "0277BD"))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Exporter ma base")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("\(viewModel.leurres.count) leurre\(viewModel.leurres.count > 1 ? "s" : "") dans la base")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Créez une sauvegarde de tous vos leurres pour la transférer sur un autre appareil")
                }
                
                // Section Import
                Section {
                    Button {
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(Color(hex: "FFBC42"))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Importer une base")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Depuis un fichier .json ou .zip")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    #if DEBUG
                    Button {
                        recupererPhotosAncienContaineur()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("🔧 Récupérer photos ancien conteneur")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("Mode DEBUG uniquement")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                    #endif
                    
                } header: {
                    Text("Import")
                } footer: {
                    Text("Importez des leurres depuis un fichier exporté. Vous pourrez choisir de fusionner ou remplacer votre base actuelle.")
                }
            }
            .navigationTitle("Export/Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json, .zip],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
            }
            .confirmationDialog(
                "Mode d'import",
                isPresented: $showModeSelection,
                titleVisibility: .visible
            ) {
                Button("Fusionner avec ma base") {
                    importerBase(mode: .fusionner)
                }
                Button("Remplacer ma base", role: .destructive) {
                    importerBase(mode: .remplacer)
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Fusionner : ajoute les leurres importés aux vôtres\nRemplacer : supprime vos leurres et les remplace par ceux importés")
            }
            .alert("Succès", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(successMessage)
            }
            .alert("Erreur", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Actions
    
    private func exporterBase() {
        guard let url = viewModel.exporterBaseDeDonnees() else {
            errorMessage = "Impossible de créer le fichier d'export"
            showErrorAlert = true
            return
        }
        
        exportURL = url
    }
    
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            // Vérifier l'accès au fichier
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Impossible d'accéder au fichier"
                showErrorAlert = true
                return
            }
            
            importURL = url
            showModeSelection = true
            
        case .failure(let error):
            errorMessage = "Erreur de sélection : \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    
    private func importerBase(mode: LeureViewModel.ModeImport) {
        guard let url = importURL else { return }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let countAvant = viewModel.leurres.count
            try viewModel.importerBaseDeDonnees(depuis: url, mode: mode)
            let countApres = viewModel.leurres.count
            
            switch mode {
            case .fusionner:
                let nouveaux = countApres - countAvant
                successMessage = "✅ Import réussi !\n\n+\(nouveaux) leurre\(nouveaux > 1 ? "s" : "") ajouté\(nouveaux > 1 ? "s" : "")\nTotal : \(countApres) leurres"
            case .remplacer:
                successMessage = "✅ Import réussi !\n\nBase remplacée : \(countApres) leurre\(countApres > 1 ? "s" : "")"
            }
            
            showSuccessAlert = true
            
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    #if DEBUG
    private func recupererPhotosAncienContaineur() {
        let devicePath = "/Users/lanessebastien/Library/Developer/CoreSimulator/Devices/11A04561-77DE-4A64-8206-791B0DA32435/data/Containers/Data/Application/"
        
        let deviceURL = URL(fileURLWithPath: devicePath)
        
        do {
            // Lister tous les conteneurs
            let conteneurs = try FileManager.default.contentsOfDirectory(at: deviceURL, includingPropertiesForKeys: [.creationDateKey])
            
            print("🔍 Recherche dans \(conteneurs.count) conteneurs...")
            
            // Chercher un dossier photos avec des fichiers
            for conteneur in conteneurs {
                let photosURL = conteneur.appendingPathComponent("Documents/photos")
                
                if FileManager.default.fileExists(atPath: photosURL.path) {
                    let photos = try FileManager.default.contentsOfDirectory(at: photosURL, includingPropertiesForKeys: nil)
                    
                    if !photos.isEmpty {
                        print("📸 Trouvé \(photos.count) photos dans : \(conteneur.lastPathComponent)")
                        
                        // Copier vers le conteneur actuel
                        let destPhotosURL = LeurreStorageService.shared.documentURL.appendingPathComponent("photos")
                        
                        try? FileManager.default.createDirectory(at: destPhotosURL, withIntermediateDirectories: true)
                        
                        var photosCopiees = 0
                        for photo in photos {
                            let destURL = destPhotosURL.appendingPathComponent(photo.lastPathComponent)
                            
                            if !FileManager.default.fileExists(atPath: destURL.path) {
                                try? FileManager.default.copyItem(at: photo, to: destURL)
                                photosCopiees += 1
                            }
                        }
                        
                        successMessage = "✅ \(photosCopiees) photos récupérées sur \(photos.count) trouvées !"
                        showSuccessAlert = true
                        return
                    }
                }
            }
            
            errorMessage = "❌ Aucun dossier photos trouvé dans les anciens conteneurs"
            showErrorAlert = true
            
        } catch {
            errorMessage = "Erreur : \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
    #endif
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportImportView(viewModel: LeureViewModel())
}
