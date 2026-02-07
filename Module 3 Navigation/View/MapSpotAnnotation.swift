//
//  MapSpotAnnotation.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Pin personnalisé pour affichage spots sur MapKit
//

import SwiftUI
import MapKit

/// Annotation personnalisée pour un spot de pêche
struct MapSpotAnnotation: Identifiable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let title: String
    let isRecent: Bool
    let hasNotes: Bool
    
    init(spot: FishingSpot) {
        self.id = spot.id
        self.coordinate = spot.coordinate
        self.title = spot.name
        self.isRecent = spot.isRecent
        self.hasNotes = spot.notes != nil && !spot.notes!.isEmpty
    }
}

/// Vue du pin personnalisé
struct SpotAnnotationView: View {
    let annotation: MapSpotAnnotation
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Pin avec icône poisson
            ZStack {
                // Forme du pin
                Circle()
                    .fill(pinColor)
                    .frame(width: 36, height: 36)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                
                // Bordure si sélectionné
                if isSelected {
                    Circle()
                        .stroke(Color.yellow, lineWidth: 3)
                        .frame(width: 40, height: 40)
                }
                
                // Icône poisson
                Image(systemName: "fish.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                // Badge notes si présent
                if annotation.hasNotes {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "note.text")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(pinColor)
                        )
                        .offset(x: 12, y: -12)
                }
            }
            
            // Pointe du pin
            // Ligne 71 - APRÈS
            PinArrowTriangle()
                .fill(pinColor)
                .frame(width: 12, height: 8)
                .offset(y: -4)
        }
        .frame(width: 40, height: 48)
    }
    
    private var pinColor: Color {
        annotation.isRecent ? Color(red: 0, green: 0.47, blue: 0.75) : Color.gray
    }
}

/// Forme triangle pour la pointe du pin
struct PinArrowTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Preview

#if DEBUG
struct SpotAnnotationView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            // Pin récent non sélectionné
            SpotAnnotationView(
                annotation: MapSpotAnnotation(spot: FishingSpot.preview),
                isSelected: false
            )
            .previewDisplayName("Récent - Non sélectionné")
            
            // Pin récent sélectionné
            SpotAnnotationView(
                annotation: MapSpotAnnotation(spot: FishingSpot.preview),
                isSelected: true
            )
            .previewDisplayName("Récent - Sélectionné")
            
            // Pin ancien
            SpotAnnotationView(
                annotation: MapSpotAnnotation(
                    spot: FishingSpot(
                        name: "Ancien spot",
                        latitude: -22.3,
                        longitude: 166.4,
                        createdAt: Date().addingTimeInterval(-86400 * 30),
                        notes: "Vieux spot"
                    )
                ),
                isSelected: false
            )
            .previewDisplayName("Ancien")
            
            // Pin sans notes
            SpotAnnotationView(
                annotation: MapSpotAnnotation(
                    spot: FishingSpot(
                        name: "Sans notes",
                        latitude: -22.3,
                        longitude: 166.4,
                        notes: nil
                    )
                ),
                isSelected: false
            )
            .previewDisplayName("Sans notes")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
#endif//
//  MapSpotAnnotation.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//

