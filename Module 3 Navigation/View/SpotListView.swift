//
//  SpotListView.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Liste complète des spots avec recherche et tri
//

import SwiftUI
import CoreLocation

struct SpotListView: View {
    @EnvironmentObject var spotStorage: SpotStorageService
    @EnvironmentObject var locationService: LocationService
    
    @Environment(\.dismiss) private var dismiss
    
    // État UI
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateRecent
    @State private var selectedSpot: FishingSpot?
    @State private var showExportSheet = false
    @State private var spotsToExport: [FishingSpot] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                if filteredAndSortedSpots.isEmpty {
                    // État vide
                    emptyStateView
                } else {
                    // Liste des spots
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredAndSortedSpots) { spot in
                                SpotCard(
                                    spot: spot,
                                    currentLocation: locationService.currentLocation
                                )
                                .onTapGesture {
                                    selectedSpot = spot
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    // Supprimer
                                    Button(role: .destructive) {
                                        deleteSpot(spot)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    // Éditer
                                    Button {
                                        selectedSpot = spot
                                    } label: {
                                        Label("Modifier", systemImage: "pencil")
                                    }
                                    .tint(.blue)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Mes spots (\(spotStorage.totalSpots))")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Rechercher un spot..."
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        // Options de tri
                        Section("Trier par") {
                            Button {
                                sortOption = .dateRecent
                            } label: {
                                Label("Date (récent → ancien)", systemImage: sortOption == .dateRecent ? "checkmark" : "")
                            }
                            
                            Button {
                                sortOption = .dateOld
                            } label: {
                                Label("Date (ancien → récent)", systemImage: sortOption == .dateOld ? "checkmark" : "")
                            }
                            
                            Button {
                                sortOption = .nameAZ
                            } label: {
                                Label("Nom (A → Z)", systemImage: sortOption == .nameAZ ? "checkmark" : "")
                            }
                            
                            if locationService.currentLocation != nil {
                                Button {
                                    sortOption = .distance
                                } label: {
                                    Label("Distance", systemImage: sortOption == .distance ? "checkmark" : "")
                                }
                            }
                        }
                        
                        // Export
                        Section {
                            Button {
                                exportAllSpots()
                            } label: {
                                Label("Exporter tous (\(spotStorage.totalSpots))", systemImage: "square.and.arrow.up")
                            }
                            
                            Button {
                                exportRecentSpots()
                            } label: {
                                Label("Exporter récents (\(spotStorage.recentSpotsCount))", systemImage: "clock.arrow.circlepath")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(item: $selectedSpot) { spot in
                SpotDetailView(spot: spot)
            }
            .sheet(isPresented: $showExportSheet) {
                if !spotsToExport.isEmpty {
                    ExportShareView(spots: spotsToExport)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mappin.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(searchText.isEmpty ? "Aucun spot enregistré" : "Aucun résultat")
                .font(.title2.bold())
            
            Text(searchText.isEmpty ? "Ajoutez votre premier spot depuis la carte" : "Essayez une autre recherche")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if searchText.isEmpty {
                Button {
                    dismiss()
                } label: {
                    Text("Aller à la carte")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Actions
    
    private func deleteSpot(_ spot: FishingSpot) {
        Task {
            try? await spotStorage.deleteSpot(spot)
            
            // Feedback haptique
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private func exportAllSpots() {
        spotsToExport = spotStorage.spots
        showExportSheet = true
    }
    
    private func exportRecentSpots() {
        spotsToExport = spotStorage.getRecentSpots(days: 30)
        showExportSheet = true
    }
    
    // MARK: - Computed Properties
    
    private var filteredAndSortedSpots: [FishingSpot] {
        let filtered = searchText.isEmpty ? spotStorage.spots : spotStorage.searchSpots(query: searchText)
        
        switch sortOption {
        case .dateRecent:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .dateOld:
            return filtered.sorted { $0.createdAt < $1.createdAt }
        case .nameAZ:
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .distance:
            guard let location = locationService.currentLocation else { return filtered }
            return filtered.sorted { $0.distance(from: location) < $1.distance(from: location) }
        }
    }
    
    // MARK: - SortOption
    
    enum SortOption {
        case dateRecent
        case dateOld
        case nameAZ
        case distance
    }
}

// MARK: - ExportShareView

struct ExportShareView: View {
    let spots: [FishingSpot]
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if isExporting {
                    ProgressView("Génération du fichier GPX...")
                        .padding()
                } else if let error = exportError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("Erreur d'export")
                            .font(.title2.bold())
                        
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Réessayer") {
                            exportError = nil
                            performExport()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Export GPX")
                            .font(.title2.bold())
                        
                        Text("\(spots.count) spot\(spots.count > 1 ? "s" : "") sélectionné\(spots.count > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            performExport()
                        } label: {
                            Text("Exporter")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func performExport() {
        isExporting = true
        exportError = nil
        
        Task {
            do {
                let exporter = GPXExportService()
                let fileURL = try exporter.generateGPXFile(from: spots)
                
                // Partage iOS natif
                await MainActor.run {
                    isExporting = false
                    shareFile(url: fileURL)
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
    
    private func shareFile(url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SpotListView_Previews: PreviewProvider {
    static var previews: some View {
        SpotListView()
            .environmentObject(SpotStorageService.preview)
            .environmentObject(LocationService())
    }
}
#endif//
//  SpotListView.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//

