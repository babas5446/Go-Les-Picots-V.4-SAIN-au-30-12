//
//  SpotCard.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Card pour affichage spot dans liste
//

import SwiftUI
import CoreLocation

struct SpotCard: View {
    let spot: FishingSpot
    let currentLocation: CLLocation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // En-tête : nom + âge
            HStack {
                // Indicateur récent
                Circle()
                    .fill(spot.isRecent ? Color.blue : Color.gray)
                    .frame(width: 8, height: 8)
                
                // Nom du spot
                Text(spot.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Âge relatif
                Text(relativeAge)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Coordonnées + distance
            HStack(spacing: 12) {
                // Icône position
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Coordonnées
                Text(spot.coordinatesCompact())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontDesign(.monospaced)
                
                // Distance si position connue
                if let distance = distanceText {
                    Divider()
                        .frame(height: 12)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            // Notes preview si présentes
            if let notes = spot.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            
            // Métadonnées optionnelles (V2)
            if let depth = spot.depth {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.1f m", depth))
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Computed Properties
    
    private var relativeAge: String {
        let days = spot.ageInDays
        
        if days == 0 {
            return "Aujourd'hui"
        } else if days == 1 {
            return "Hier"
        } else if days < 7 {
            return "\(days)j"
        } else if days < 30 {
            let weeks = days / 7
            return "\(weeks)s"
        } else if days < 365 {
            let months = days / 30
            return "\(months)m"
        } else {
            let years = days / 365
            return "\(years)a"
        }
    }
    
    private var distanceText: String? {
        guard let location = currentLocation else { return nil }
        return spot.formattedDistance(from: location)
    }
}

// MARK: - Preview

#if DEBUG
struct SpotCard_Previews: PreviewProvider {
    static var testLocation = CLLocation(latitude: -22.27, longitude: 166.45)
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Spot récent avec notes
                SpotCard(
                    spot: FishingSpot.preview,
                    currentLocation: testLocation
                )
                
                // Spot ancien sans notes
                SpotCard(
                    spot: FishingSpot(
                        name: "Îlot Maître",
                        latitude: -22.3241,
                        longitude: 166.4112,
                        createdAt: Date().addingTimeInterval(-86400 * 20),
                        notes: nil
                    ),
                    currentLocation: testLocation
                )
                
                // Spot avec profondeur
                SpotCard(
                    spot: FishingSpot(
                        name: "Tombant Tabou",
                        latitude: -22.1983,
                        longitude: 166.5021,
                        createdAt: Date().addingTimeInterval(-3600 * 5),
                        notes: "Très bon spot pour carangues",
                        depth: 18.5
                    ),
                    currentLocation: testLocation
                )
                
                // Spot sans position actuelle
                SpotCard(
                    spot: FishingSpot.preview,
                    currentLocation: nil
                )
            }
            .padding()
        }
        .background(Color.gray.opacity(0.1))
    }
}
#endif//
//  SpotCard.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 06/02/2026.
//

