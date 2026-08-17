//
//  DiagnosticView.swift
//  Go les Picots V.4 — Module 1
//
//  Vue de diagnostic — état du système SwiftData et des fichiers.
//
//  V4 — Adaptations SwiftData :
//  - service.chargerLeurres() → FetchDescriptor sur ModelContext
//  - service.reinitialiserBase() supprimé → non applicable en SwiftData
//  - LeurreStorageService.shared utilisé uniquement pour accès ModelContainer
//

import SwiftUI
import SwiftData

struct DiagnosticView: View {
    @State private var diagnostics: DiagnosticInfo?
    @State private var isLoading = true

    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Analyse en cours...").foregroundColor(.secondary)
                        }
                    }
                } else if let diag = diagnostics {

                    Section(header: Text("📁 FICHIERS")) {
                        DiagnosticRow(
                            label: "JSON dans Bundle",
                            value: diag.jsonInBundle ? "✅ Présent" : "❌ Manquant",
                            status: diag.jsonInBundle ? .success : .error,
                            detail: diag.bundleJSONPath
                        )
                        DiagnosticRow(
                            label: "JSON dans Documents",
                            value: diag.jsonInDocuments ? "✅ Présent" : "❌ Manquant",
                            status: diag.jsonInDocuments ? .success : .error,
                            detail: diag.documentsJSONPath
                        )
                        if diag.jsonInDocuments {
                            DiagnosticRow(label: "Taille du fichier",     value: diag.fileSize,     status: .info)
                            DiagnosticRow(label: "Dernière modification", value: diag.lastModified,  status: .info)
                        }
                    }

                    Section(header: Text("📊 DONNÉES")) {
                        DiagnosticRow(
                            label: "Leurres dans SwiftData",
                            value: "\(diag.leuresCount)",
                            status: diag.leuresCount > 0 ? .success : .warning
                        )
                        if diag.leuresCount > 0 {
                            DiagnosticRow(label: "Leurres de traîne", value: "\(diag.traineCount)", status: .info)
                            DiagnosticRow(label: "Avec photos",       value: "\(diag.photosCount)", status: .info)
                        }
                        if let error = diag.loadError {
                            DiagnosticRow(label: "Erreur", value: error, status: .error)
                        }
                    }

                    Section(header: Text("🖼️ RESSOURCES")) {
                        DiagnosticRow(
                            label: "Template Spread",
                            value: diag.spreadTemplateExists ? "✅ Présent" : "❌ Manquant",
                            status: diag.spreadTemplateExists ? .success : .warning,
                            detail: diag.spreadTemplateExists ? "Image trouvée dans Assets" : "Utilisera le fallback"
                        )
                    }

                    Section(header: Text("⚙️ SYSTÈME")) {
                        DiagnosticRow(label: "Chemin Documents", value: diag.documentsPath, status: .info)
                        DiagnosticRow(label: "Bundle ID",        value: diag.bundleID,      status: .info)
                    }

                    Section(header: Text("🔧 ACTIONS")) {
                        // ✅ V4 : reinitialiserBase supprimé — non applicable SwiftData
                        Button(action: clearDocumentsJSON) {
                            Label("Supprimer leurres.json.bak", systemImage: "trash")
                        }
                        .foregroundColor(.red)

                        Button(action: refresh) {
                            Label("Actualiser diagnostic", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                }
            }
            .navigationTitle("Diagnostic")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear { refresh() }
    }

    private func refresh() {
        isLoading = true
        Task {
            await MainActor.run {
                diagnostics = DiagnosticInfo.gather()
                isLoading = false
            }
        }
    }

    private func clearDocumentsJSON() {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let bak  = docs.appendingPathComponent("leurres.json.bak")
        try? fm.removeItem(at: bak)
        print("🗑️ leurres.json.bak supprimé")
        refresh()
    }
}

// MARK: - DiagnosticRow

struct DiagnosticRow: View {
    let label: String
    let value: String
    let status: DiagnosticStatus
    var detail: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label).font(.subheadline).foregroundColor(.secondary)
                Spacer()
                Text(value).font(.subheadline).fontWeight(.semibold).foregroundColor(status.color)
            }
            if let detail = detail {
                Text(detail).font(.caption).foregroundColor(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - DiagnosticStatus

enum DiagnosticStatus {
    case success, warning, error, info

    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error:   return .red
        case .info:    return .blue
        }
    }
}

// MARK: - DiagnosticInfo

struct DiagnosticInfo {
    let jsonInBundle:       Bool
    let jsonInDocuments:    Bool
    let bundleJSONPath:     String
    let documentsJSONPath:  String
    let fileSize:           String
    let lastModified:       String
    let leuresCount:        Int
    let traineCount:        Int
    let photosCount:        Int
    let loadError:          String?
    let spreadTemplateExists: Bool
    let documentsPath:      String
    let bundleID:           String

    @MainActor
    static func gather() -> DiagnosticInfo {
        let fm    = FileManager.default
        let docsURL  = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonURL  = docsURL.appendingPathComponent("leurres.json")
        let bundleURL = Bundle.main.url(forResource: "leurres_database_COMPLET", withExtension: "json")

        let jsonInBundle    = bundleURL != nil
        let jsonInDocuments = fm.fileExists(atPath: jsonURL.path)

        var fileSize     = "N/A"
        var lastModified = "N/A"
        if jsonInDocuments,
           let attrs = try? fm.attributesOfItem(atPath: jsonURL.path) {
            if let size = attrs[.size] as? Int64 {
                fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
            }
            if let date = attrs[.modificationDate] as? Date {
                let fmt = DateFormatter()
                fmt.dateStyle = .short
                fmt.timeStyle = .short
                lastModified = fmt.string(from: date)
            }
        }

        // ✅ V4 : lecture via ModelContext SwiftData
        var leuresCount = 0
        var traineCount = 0
        var photosCount = 0
        var loadError: String?

        do {
            let context = LeurreStorageService.shared.mainContext
            let descriptor = FetchDescriptor<Leurre>()
            let leurres = try context.fetch(descriptor)
            leuresCount = leurres.count
            traineCount = leurres.filter { $0.typePeche == .traine }.count
            photosCount = leurres.filter { $0.photoData != nil }.count
        } catch {
            loadError = error.localizedDescription
        }

        return DiagnosticInfo(
            jsonInBundle:        jsonInBundle,
            jsonInDocuments:     jsonInDocuments,
            bundleJSONPath:      bundleURL?.path ?? "Non trouvé",
            documentsJSONPath:   jsonURL.path,
            fileSize:            fileSize,
            lastModified:        lastModified,
            leuresCount:         leuresCount,
            traineCount:         traineCount,
            photosCount:         photosCount,
            loadError:           loadError,
            spreadTemplateExists: UIImage(named: "spread_template_ok") != nil,
            documentsPath:       docsURL.path,
            bundleID:            Bundle.main.bundleIdentifier ?? "N/A"
        )
    }
}

// MARK: - Preview

struct DiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosticView()
    }
}
