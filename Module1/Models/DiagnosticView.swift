//
//  DiagnosticView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Vue de diagnostic pour identifier les problèmes de chargement
//  Affiche l'état du système de fichiers et des ressources
//
//  Created: 2024-12-19
//

import SwiftUI

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
                            Text("Analyse en cours...")
                                .foregroundColor(.secondary)
                        }
                    }
                } else if let diag = diagnostics {
                    // Section Fichiers
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
                            DiagnosticRow(
                                label: "Taille du fichier",
                                value: diag.fileSize,
                                status: .info
                            )
                            
                            DiagnosticRow(
                                label: "Dernière modification",
                                value: diag.lastModified,
                                status: .info
                            )
                        }
                    }
                    
                    // Section Données
                    Section(header: Text("📊 DONNÉES")) {
                        DiagnosticRow(
                            label: "Nombre de leurres",
                            value: "\(diag.leuresCount)",
                            status: diag.leuresCount > 0 ? .success : .warning
                        )
                        
                        if diag.leuresCount > 0 {
                            DiagnosticRow(
                                label: "Leurres de traîne",
                                value: "\(diag.traineCount)",
                                status: .info
                            )
                            
                            DiagnosticRow(
                                label: "Avec photos",
                                value: "\(diag.photosCount)",
                                status: .info
                            )
                        }
                        
                        if let error = diag.loadError {
                            DiagnosticRow(
                                label: "Erreur de chargement",
                                value: error,
                                status: .error
                            )
                        }
                    }
                    
                    // Section Images
                    Section(header: Text("🖼️ RESSOURCES")) {
                        DiagnosticRow(
                            label: "Template Spread",
                            value: diag.spreadTemplateExists ? "✅ Présent" : "❌ Manquant",
                            status: diag.spreadTemplateExists ? .success : .warning,
                            detail: diag.spreadTemplateExists ? "Image trouvée dans Assets" : "Utilisera le fallback"
                        )
                    }
                    
                    // Section Système
                    Section(header: Text("⚙️ SYSTÈME")) {
                        DiagnosticRow(
                            label: "Chemin Documents",
                            value: diag.documentsPath,
                            status: .info
                        )
                        
                        DiagnosticRow(
                            label: "Bundle ID",
                            value: diag.bundleID,
                            status: .info
                        )
                    }
                    
                    // Section Actions
                    Section(header: Text("🔧 ACTIONS")) {
                        Button(action: forceMigration) {
                            Label("Forcer migration depuis bundle", systemImage: "arrow.clockwise")
                        }
                        
                        Button(action: clearDocuments) {
                            Label("Supprimer fichiers Documents", systemImage: "trash")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        // Fermeture gérée par le parent
                    }
                }
            }
        }
        .onAppear {
            refresh()
        }
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
    
    private func forceMigration() {
        let service = LeurreStorageService.shared
        do {
            try service.reinitialiserBase()
            refresh()
        } catch {
            print("❌ Erreur migration : \(error)")
        }
    }
    
    private func clearDocuments() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonURL = documentsURL.appendingPathComponent("leurres_database_COMPLET.json")
        
        do {
            if fileManager.fileExists(atPath: jsonURL.path) {
                try fileManager.removeItem(at: jsonURL)
                print("✅ Fichier JSON supprimé")
            }
            refresh()
        } catch {
            print("❌ Erreur suppression : \(error)")
        }
    }
}

// MARK: - Diagnostic Row

struct DiagnosticRow: View {
    let label: String
    let value: String
    let status: DiagnosticStatus
    var detail: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(status.color)
            }
            
            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Diagnostic Status

enum DiagnosticStatus {
    case success
    case warning
    case error
    case info
    
    var color: Color {
        switch self {
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .info: return .blue
        }
    }
}

// MARK: - Diagnostic Info

struct DiagnosticInfo {
    // Fichiers
    let jsonInBundle: Bool
    let jsonInDocuments: Bool
    let bundleJSONPath: String
    let documentsJSONPath: String
    let fileSize: String
    let lastModified: String
    
    // Données
    let leuresCount: Int
    let traineCount: Int
    let photosCount: Int
    let loadError: String?
    
    // Ressources
    let spreadTemplateExists: Bool
    
    // Système
    let documentsPath: String
    let bundleID: String
    
    static func gather() -> DiagnosticInfo {
        let fileManager = FileManager.default
        
        // Chemins
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let jsonURL = documentsURL.appendingPathComponent("leurres_database_COMPLET.json")
        let bundleURL = Bundle.main.url(forResource: "leurres_database_COMPLET", withExtension: "json")
        
        // Vérification fichiers
        let jsonInBundle = bundleURL != nil
        let jsonInDocuments = fileManager.fileExists(atPath: jsonURL.path)
        
        // Taille et date
        var fileSize = "N/A"
        var lastModified = "N/A"
        
        if jsonInDocuments {
            if let attributes = try? fileManager.attributesOfItem(atPath: jsonURL.path) {
                if let size = attributes[.size] as? Int64 {
                    fileSize = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                }
                if let date = attributes[.modificationDate] as? Date {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .short
                    formatter.timeStyle = .short
                    lastModified = formatter.string(from: date)
                }
            }
        }
        
        // Chargement des données
        var leuresCount = 0
        var traineCount = 0
        var photosCount = 0
        var loadError: String?
        
        do {
            let service = LeurreStorageService.shared
            let leurres = try service.chargerLeurres()
            leuresCount = leurres.count
            traineCount = leurres.filter { $0.typePeche == .traine }.count
            photosCount = leurres.filter { $0.photoPath != nil }.count
        } catch {
            loadError = error.localizedDescription
        }
        
        // Ressources
        let spreadTemplateExists = UIImage(named: "spread_template_ok") != nil
        
        // Système
        let documentsPath = documentsURL.path
        let bundleID = Bundle.main.bundleIdentifier ?? "N/A"
        
        return DiagnosticInfo(
            jsonInBundle: jsonInBundle,
            jsonInDocuments: jsonInDocuments,
            bundleJSONPath: bundleURL?.path ?? "Non trouvé",
            documentsJSONPath: jsonURL.path,
            fileSize: fileSize,
            lastModified: lastModified,
            leuresCount: leuresCount,
            traineCount: traineCount,
            photosCount: photosCount,
            loadError: loadError,
            spreadTemplateExists: spreadTemplateExists,
            documentsPath: documentsPath,
            bundleID: bundleID
        )
    }
}

// MARK: - Preview

struct DiagnosticView_Previews: PreviewProvider {
    static var previews: some View {
        DiagnosticView()
    }
}
