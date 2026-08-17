//
//  ExportImportView.swift
//  Go Les Picots V.4 — Module 1
//
//  V4 — Adaptations SwiftData :
//  - viewModel.leurres supprimé → totalLeurres reçu en paramètre (@Query dans BoiteView)
//  - ModeImport.remplacer supprimé → import toujours en mode fusionner
//  - exporterBaseDeDonnees() reçoit leurres: en paramètre
//  - LeurreStorageService.shared.documentURL supprimé → non utilisé en V4
//  - importerBaseDeDonnees(depuis:) sans mode — fusionner uniquement
//

import SwiftUI
import UniformTypeIdentifiers
import SwiftData

struct ExportImportView: View {
    @ObservedObject var viewModel: BoiteLeurresViewModel
    @Environment(\.dismiss) private var dismiss

    /// Liste complète des leurres — fournie par @Query depuis la vue appelante.
    var leurres: [Leurre]

    @State private var exportURL: URL?
    @State private var showImportPicker  = false
    @State private var importURL: URL?
    @State private var showSuccessAlert  = false
    @State private var showErrorAlert    = false
    @State private var errorMessage      = ""
    @State private var successMessage    = ""

    var body: some View {
        NavigationView {
            List {

                // MARK: Export
                Section {
                    if let exportedURL = exportURL {
                        ShareLink(item: exportedURL) {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "0277BD"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Partager l'export")
                                        .font(.headline).foregroundColor(.primary)
                                    Text("Fichier prêt à être partagé")
                                        .font(.caption).foregroundColor(.green)
                                }
                                Spacer()
                            }
                            .padding(.vertical, 8)
                        }
                    } else {
                        Button { exporterBase() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title2)
                                    .foregroundColor(Color(hex: "0277BD"))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Exporter ma base")
                                        .font(.headline).foregroundColor(.primary)
                                    // ✅ V4 : leurres reçu en paramètre
                                    Text("\(leurres.count) leurre\(leurres.count > 1 ? "s" : "") dans la base")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Créez une sauvegarde de tous vos leurres pour la transférer sur un autre appareil")
                }

                // MARK: Import
                Section {
                    Button { showImportPicker = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(Color(hex: "FFBC42"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Importer une base")
                                    .font(.headline).foregroundColor(.primary)
                                Text("Depuis un fichier .json ou .zip")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text("Import")
                } footer: {
                    // ✅ V4 : mode remplacer supprimé — import toujours en fusion
                    Text("Importez des leurres depuis un fichier exporté. Les doublons (même ID) sont ignorés automatiquement.")
                }
            }
            .navigationTitle("Export/Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.json, .zip],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
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
        // ✅ V4 : leurres passé explicitement — plus de viewModel.leurres
        guard let url = viewModel.exporterBaseDeDonnees(leurres: leurres) else {
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
            guard url.startAccessingSecurityScopedResource() else {
                errorMessage = "Impossible d'accéder au fichier"
                showErrorAlert = true
                return
            }
            importURL = url
            // ✅ V4 : pas de choix de mode — on importe directement en fusionner
            importerBase()

        case .failure(let error):
            errorMessage = "Erreur de sélection : \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    private func importerBase() {
        guard let url = importURL else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        // ✅ V4 : importerBaseDeDonnees(depuis:) sans paramètre mode
        viewModel.importerBaseDeDonnees(depuis: url)

        successMessage = "✅ Import lancé — les doublons seront ignorés automatiquement."
        showSuccessAlert = true
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ExportImportView(viewModel: BoiteLeurresViewModel(), leurres: [])
}
