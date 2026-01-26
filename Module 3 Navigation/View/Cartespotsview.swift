//
//  Cartespotsview.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 18/01/2026.
//
//  RUBRIQUE 2 : Carte & Spots
//  Visualisation MapKit, spots enregistrés, position actuelle
//

import SwiftUI
import MapKit

struct CarteSpotsView: View {
    // MARK: - Properties
    // TODO: Connecter au SpotManager et LocationService
    @State private var position: MapCameraPosition = .automatic
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Carte MapKit (placeholder)
                Map(position: $position) {
                    // TODO: Ajouter annotations des spots
                }
                .mapStyle(.standard)
                
                // Overlay pour bouton "Enregistrer ce spot"
                VStack {
                    Spacer()
                    
                    Button(action: {
                        // TODO: Action enregistrer spot
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Enregistrer ce spot")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(red: 1.0, green: 0.49, blue: 0.31)) // Orange corail
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Carte & Spots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        // TODO: Centrer sur position actuelle
                    }) {
                        Image(systemName: "location.fill")
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    CarteSpotsView()
}
