//
//  SpotFormView.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Formulaire ajout/édition spot
//

import SwiftUI
import CoreLocation

struct SpotFormView: View {
    let coordinate: CLLocationCoordinate2D
    let existingSpot: FishingSpot?
    let onSave: (FishingSpot) -> Void
    let onCancel: () -> Void
    
    // Form state
    @State private var spotName: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: Field?
    
    @Environment(\.dismiss) private var dismiss
    
    init(
        coordinate: CLLocationCoordinate2D,
        existingSpot: FishingSpot? = nil,
        onSave: @escaping (FishingSpot) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.coordinate = coordinate
        self.existingSpot = existingSpot
        self.onSave = onSave
        self.onCancel = onCancel
        
        // Pré-remplissage si édition
        if let spot = existingSpot {
            _spotName = State(initialValue: spot.name)
            _notes = State(initialValue: spot.notes ?? "")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section coordonnées (lecture seule)
                Section {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(formattedCoordinates)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Text(formattedDate)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Informations")
                }
                
                // Section nom (obligatoire)
                Section {
                    TextField("Nom du spot", text: $spotName)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .notes
                        }
                } header: {
                    Text("Nom *")
                } footer: {
                    Text("Obligatoire")
                        .foregroundColor(.secondary)
                }
                
                // Section notes (optionnel)
                Section {
                    TextEditor(text: $notes)
                        .focused($focusedField, equals: .notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Notes")
                } footer: {
                    Text("Profondeur, courant, espèces, etc.")
                        .foregroundColor(.secondary)
                }
                
                // Warning si hors Nouvelle-Calédonie
                if !isInNewCaledonia {
                    Section {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Spot hors Nouvelle-Calédonie")
                                    .font(.subheadline.bold())
                                Text("Ces coordonnées ne sont pas en NC")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(existingSpot == nil ? "Nouveau spot" : "Modifier spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveSpot()
                    }
                    .disabled(spotName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Focus automatique sur le nom
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    focusedField = .name
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Actions
    
    private func saveSpot() {
        let trimmedName = spotName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let finalNotes = trimmedNotes.isEmpty ? nil : trimmedNotes
        
        let spot: FishingSpot
        
        if let existing = existingSpot {
            // Édition : copie avec nouvelles valeurs
            spot = FishingSpot(
                id: existing.id,
                name: trimmedName,
                latitude: existing.latitude,
                longitude: existing.longitude,
                createdAt: existing.createdAt,
                notes: finalNotes,
                depth: existing.depth,
                category: existing.category,
                targetSpecies: existing.targetSpecies,
                successfulLures: existing.successfulLures,
                photos: existing.photos
            )
        } else {
            // Création
            spot = FishingSpot(
                name: trimmedName,
                coordinate: coordinate,
                notes: finalNotes
            )
        }
        
        onSave(spot)
        dismiss()
        
        // Feedback haptique
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Computed Properties
    
    private var formattedCoordinates: String {
        CoordinateFormatter.format(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            format: .decimalDegrees
        )
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: existingSpot?.createdAt ?? Date())
    }
    
    private var isInNewCaledonia: Bool {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let latInRange = lat >= -22.7 && lat <= -19.5
        let lonInRange = lon >= 163.5 && lon <= 168.5
        return latInRange && lonInRange
    }
    
    // MARK: - Field
    
    enum Field: Hashable {
        case name
        case notes
    }
}

// MARK: - Preview

#if DEBUG
struct SpotFormView_Previews: PreviewProvider {
    static var previews: some View {
        // Nouveau spot
        SpotFormView(
            coordinate: CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580),
            onSave: { _ in },
            onCancel: {}
        )
        .previewDisplayName("Nouveau spot")
        
        // Édition spot existant
        SpotFormView(
            coordinate: CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580),
            existingSpot: FishingSpot.preview,
            onSave: { _ in },
            onCancel: {}
        )
        .previewDisplayName("Édition spot")
        
        // Spot hors NC
        SpotFormView(
            coordinate: CLLocationCoordinate2D(latitude: -33.8688, longitude: 151.2093), // Sydney
            onSave: { _ in },
            onCancel: {}
        )
        .previewDisplayName("Hors Nouvelle-Calédonie")
    }
}
#endif
