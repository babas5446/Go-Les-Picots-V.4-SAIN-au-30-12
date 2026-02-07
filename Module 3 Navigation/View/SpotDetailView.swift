//
//  SpotDetailView.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Vue détail complet d'un spot
//

import SwiftUI
import MapKit

struct SpotDetailView: View {
    let spot: FishingSpot
    
    @EnvironmentObject var spotStorage: SpotStorageService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditForm = false
    @State private var showDeleteAlert = false
    @State private var showExportSheet = false
    @State private var showCopiedToast = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Mini carte
                    miniMapView
                    
                    // Informations principales
                    mainInfoSection
                    
                    // Notes
                    if let notes = spot.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                    
                    // Métadonnées optionnelles
                    if spot.depth != nil || spot.category != nil {
                        metadataSection
                    }
                    
                    // Actions principales
                    actionsSection
                    
                    // Bouton suppression
                    deleteButton
                }
                .padding()
            }
            .navigationTitle(spot.name)
            .navigationBarTitleDisplayMode(.inline)
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
                    Button {
                        showEditForm = true
                    } label: {
                        Text("Modifier")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showEditForm) {
                SpotFormView(
                    coordinate: spot.coordinate,
                    existingSpot: spot,
                    onSave: { updatedSpot in
                        Task {
                            try? await spotStorage.updateSpot(updatedSpot)
                        }
                    },
                    onCancel: {}
                )
            }
            .sheet(isPresented: $showExportSheet) {
                ExportShareView(spots: [spot])
            }
            .alert("Supprimer ce spot ?", isPresented: $showDeleteAlert) {
                Button("Annuler", role: .cancel) {}
                Button("Supprimer", role: .destructive) {
                    deleteSpot()
                }
            } message: {
                Text("Cette action est irréversible.")
            }
            .overlay(alignment: .top) {
                if showCopiedToast {
                    toastView
                }
            }
        }
    }
    
    // MARK: - Mini Map
    
    private var miniMapView: some View {
        Map(position: .constant(.region(mapRegion))) {
            Annotation(spot.name, coordinate: spot.coordinate) {
                SpotAnnotationView(
                    annotation: MapSpotAnnotation(spot: spot),
                    isSelected: true
                )
            }
        }
        .mapStyle(.imagery)
        .frame(height: 200)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            openInMaps()
        }
    }
    
    private var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: spot.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    // MARK: - Main Info Section

    private var mainInfoSection: some View {
        VStack(spacing: 12) {
            // Coordonnées
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Position")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(spot.coordinatesDetailed())
                    .fontWeight(.medium)
                    .fontDesign(.monospaced)
                    .font(.caption)
            }
            
            Divider()
            
            // Date d'enregistrement
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Enregistré le")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(formattedDate)
                    .fontWeight(.medium)
                    .font(.caption)
            }
            
            Divider()
            
            // Âge
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text("Il y a")
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(relativeAge)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Notes Section
    
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Metadata Section

    private var metadataSection: some View {
        VStack(spacing: 12) {
            if let depth = spot.depth {
                HStack {
                    Image(systemName: "arrow.down")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Profondeur")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f m", depth))
                        .fontWeight(.medium)
                }
                
                if spot.category != nil {
                    Divider()
                }
            }
            
            if let category = spot.category {
                HStack {
                    Image(systemName: "tag")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Catégorie")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(category.displayName)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 12) {
            ActionButton(
                icon: "doc.on.doc",
                title: "Copier les coordonnées",
                color: .blue
            ) {
                copyCoordinates()
            }
            
            ActionButton(
                icon: "square.and.arrow.up",
                title: "Exporter ce spot (GPX)",
                color: .green
            ) {
                showExportSheet = true
            }
            
            if spot.navionicsURL != nil {
                ActionButton(
                    icon: "map",
                    title: "Ouvrir dans Navionics",
                    color: .orange
                ) {
                    if let url = spot.navionicsURL {
                        openURL(url)
                    }
                }
            }
            
            if spot.googleMapsURL != nil {
                ActionButton(
                    icon: "map.fill",
                    title: "Ouvrir dans Google Maps",
                    color: .red
                ) {
                    if let url = spot.googleMapsURL {
                        openURL(url)
                    }
                }
            }
        }
    }
    
    // MARK: - Delete Button
    
    private var deleteButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Text("Supprimer le spot")
                .fontWeight(.semibold)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Toast
    
    private var toastView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Coordonnées copiées")
                .font(.subheadline)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
        .padding(.top, 60)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Actions
    
    private func copyCoordinates() {
        let coords = "\(spot.latitude), \(spot.longitude)"
        UIPasteboard.general.string = coords
        
        withAnimation {
            showCopiedToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedToast = false
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func openURL(_ url: URL) {
        UIApplication.shared.open(url)
    }
    
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: spot.coordinate))
        mapItem.name = spot.name
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func deleteSpot() {
        Task {
            try? await spotStorage.deleteSpot(spot)
            dismiss()
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    // MARK: - Computed Properties
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: spot.createdAt)
    }
    
    private var relativeAge: String {
        let days = spot.ageInDays
        
        if days == 0 {
            return "Aujourd'hui"
        } else if days == 1 {
            return "Hier"
        } else if days < 7 {
            return "\(days) jours"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks) semaine\(weeks > 1 ? "s" : "")"
        } else if days < 365 {
            let months = days / 30
            return "\(months) mois"
        } else {
            let years = days / 365
            return "\(years) an\(years > 1 ? "s" : "")"
        }
    }
}

// MARK: - Supporting Views

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(color)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct SpotDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SpotDetailView(spot: FishingSpot.preview)
            .environmentObject(SpotStorageService.preview)
    }
}
#endif
