//
//  ExportImportView.swift
//  Go Les Picots V.4 — Module 1
//
//  V4 — Adaptations SwiftData :
//  - viewModel.leurres supprimé → leurres reçu en paramètre (@Query dans BoiteView)
//  - ModeImport.remplacer supprimé → import toujours en mode fusionner
//    (octobre 2026 : mode « Remplacer ma boîte » rétabli, avec lecture
//    vérifiée, confirmation chiffrée et sauvegarde ZIP automatique)
//  - exporterBaseDeDonnees() reçoit leurres: en paramètre
//
//  Session 9 — correction de l'import security-scoped :
//  - Le fichier choisi est COPIÉ dans le bac à sable pendant que la fenêtre
//    d'accès security-scoped est ouverte, puis l'accès est immédiatement clos.
//    L'import travaille ensuite sur la copie locale : plus aucune dépendance
//    à une permission qui expirait avant la fin du travail asynchrone.
//  - importerBaseDeDonnees(depuis:) est async et retourne Result<Int, Error> :
//    le compteur réel et l'erreur réelle remontent jusqu'à l'écran.
//  - Une seule voie d'alerte — les @State locaux ne doublonnent plus
//    viewModel.errorMessage / viewModel.showError.
//  - Import JSON nu accepté en plus du ZIP.
//  - NavigationStack, « Fermer » à gauche (convention session 8).
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
    @State private var showImportPicker = false
    @State private var importEnCours    = false

    // Remplacement de la boîte : fichier lu, en attente de confirmation
    @State private var modeRemplacement = false
    @State private var apercuRemplacement: BoiteLeurresViewModel.ApercuRemplacement?
    @State private var showConfirmationRemplacement = false

    // Voie d'alerte unique — succès et échec passent tous deux par ici
    @State private var alerteTitre   = ""
    @State private var alerteMessage = ""
    @State private var showAlerte    = false

    var body: some View {
        NavigationStack {
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
                    Button {
                        modeRemplacement = false
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.title2)
                                .foregroundColor(Color(hex: "FFBC42"))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ajouter des leurres")
                                    .font(.headline).foregroundColor(.primary)
                                Text("Depuis un fichier .zip ou .json")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()

                            if importEnCours && !modeRemplacement {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(importEnCours)

                    Button {
                        modeRemplacement = true
                        showImportPicker = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.title2)
                                .foregroundColor(.red)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Remplacer ma boîte")
                                    .font(.headline).foregroundColor(.primary)
                                Text("Toute la boîte est remplacée par le fichier")
                                    .font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()

                            if importEnCours && modeRemplacement {
                                ProgressView()
                            } else {
                                Image(systemName: "chevron.right").foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .disabled(importEnCours)
                } header: {
                    Text("Import")
                } footer: {
                    Text("Ajouter : les leurres déjà présents (même numéro, même nom) sont ignorés. Remplacer : le fichier est d'abord lu en entier ; si tout est lisible, une sauvegarde ZIP de la boîte actuelle est rangée dans Fichiers › Sur mon iPad › Go Les Picots › Sauvegardes boîte, puis la boîte est remplacée. Numéros et photos du fichier sont conservés.")
                }
            }
            .navigationTitle("Export/Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showImportPicker,
                allowedContentTypes: [.zip, .json],
                allowsMultipleSelection: false
            ) { result in
                handleImportSelection(result)
            }
            .alert(alerteTitre, isPresented: $showAlerte) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alerteMessage)
            }
        }
        // Confirmation du remplacement, attachée hors de la List :
        // la List porte déjà l'alerte de résultat.
        .alert("Remplacer ma boîte ?",
               isPresented: $showConfirmationRemplacement,
               presenting: apercuRemplacement) { _ in
            Button("Remplacer", role: .destructive) { lancerRemplacement() }
            Button("Annuler", role: .cancel) { viewModel.annulerRemplacement() }
        } message: { apercu in
            Text(apercu.message)
        }
    }

    // MARK: - Export

    private func exporterBase() {
        guard let url = viewModel.exporterBaseDeDonnees(leurres: leurres) else {
            afficherAlerte(titre: "Erreur", message: "Impossible de créer le fichier d'export.")
            return
        }
        exportURL = url
    }

    // MARK: - Import

    /// Reçoit le choix de l'utilisateur, copie le fichier en local, lance l'import.
    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {

        case .success(let urls):
            guard let sourceURL = urls.first else { return }

            do {
                // Copie locale SYNCHRONE, pendant que l'accès est ouvert.
                let copieLocale = try copierEnLocal(sourceURL)

                // À partir d'ici, plus aucune dépendance security-scoped.
                importEnCours = true

                if modeRemplacement {
                    // Étape 1 : lecture complète, sans toucher à la boîte.
                    Task {
                        let resultat = await viewModel.preparerRemplacement(depuis: copieLocale)
                        importEnCours = false

                        switch resultat {
                        case .success(let apercu):
                            apercuRemplacement = apercu
                            showConfirmationRemplacement = true
                        case .failure(let erreur):
                            afficherAlerte(
                                titre: "Remplacement impossible",
                                message: "\(erreur.localizedDescription)\n\nTa boîte n'a pas été modifiée."
                            )
                        }
                    }
                    return
                }

                Task {
                    let resultat = await viewModel.importerBaseDeDonnees(depuis: copieLocale)
                    importEnCours = false

                    switch resultat {
                    case .success(let nb):
                        afficherResultatImport(nb)
                    case .failure(let erreur):
                        afficherAlerte(
                            titre: "Erreur",
                            message: "Import échoué : \(erreur.localizedDescription)"
                        )
                    }
                }
            } catch {
                afficherAlerte(
                    titre: "Erreur",
                    message: "Impossible de lire le fichier : \(error.localizedDescription)"
                )
            }

        case .failure(let error):
            afficherAlerte(
                titre: "Erreur",
                message: "Erreur de sélection : \(error.localizedDescription)"
            )
        }
    }

    /// Copie le fichier choisi dans le dossier temporaire de l'app.
    ///
    /// Le point critique de la correction. L'accès security-scoped est ouvert,
    /// la copie faite, l'accès refermé — le tout de façon synchrone. L'URL
    /// retournée appartient au bac à sable et reste lisible indéfiniment.
    private func copierEnLocal(_ source: URL) throws -> URL {

        let accesOuvert = source.startAccessingSecurityScopedResource()
        defer {
            if accesOuvert { source.stopAccessingSecurityScopedResource() }
        }

        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("glp_import_source_\(UUID().uuidString)")
            .appendingPathExtension(source.pathExtension)

        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.copyItem(at: source, to: destination)

        let taille = (try? FileManager.default.attributesOfItem(atPath: destination.path)[.size] as? Int) ?? 0
        print("📥 Fichier copié en local : \(destination.lastPathComponent) — \(taille ?? 0) octets")

        return destination
    }

    /// Étape 2 : après confirmation, sauvegarde puis remplacement.
    private func lancerRemplacement() {
        importEnCours = true
        Task {
            let resultat = await viewModel.confirmerRemplacement()
            importEnCours = false
            apercuRemplacement = nil

            switch resultat {
            case .success(let bilan):
                var message = "\(bilan.nombre) leurre\(bilan.nombre > 1 ? "s" : ""), dont \(bilan.photos) avec photo. "
                message += "Ancienne boîte sauvegardée dans Fichiers › Sur mon iPad › Go Les Picots › Sauvegardes boîte "
                message += "(\(bilan.sauvegarde.lastPathComponent))."
                if bilan.prisesSansFiche > 0 {
                    message += "\n\n\(bilan.prisesSansFiche) prise(s) du journal citent un numéro absent de la nouvelle boîte."
                }
                afficherAlerte(titre: "Boîte remplacée", message: message)
            case .failure(let erreur):
                afficherAlerte(
                    titre: "Remplacement échoué",
                    message: "\(erreur.localizedDescription)\n\nLa boîte d'origine a été remise en place ; une sauvegarde ZIP a pu être faite dans Fichiers › Sauvegardes boîte."
                )
            }
        }
    }

    /// Formule le message de fin d'import en fonction du compteur réel.
    private func afficherResultatImport(_ nb: Int) {
        if nb == 0 {
            afficherAlerte(
                titre: "Aucun ajout",
                message: "Aucun leurre nouveau. Tous les identifiants du fichier existent déjà dans la base."
            )
        } else {
            afficherAlerte(
                titre: "Import terminé",
                message: "\(nb) leurre\(nb > 1 ? "s" : "") ajouté\(nb > 1 ? "s" : "") à la base."
            )
        }
    }

    private func afficherAlerte(titre: String, message: String) {
        alerteTitre   = titre
        alerteMessage = message
        showAlerte    = true
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
