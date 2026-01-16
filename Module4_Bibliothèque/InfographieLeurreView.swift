//
//  InfographieLeurreView.swift
//  Go les Picots - Module 4
//
//  Vue dédiée à l'infographie interactive "Guide visuel choix leurre"
//  - Affichage image HD zoomable
//  - Bouton légende détaillée
//  - Partage infographie
//
//  Created: 2026-01-15
//

import SwiftUI

struct InfographieLeurreView: View {
    
    // MARK: - State
    
    @State private var showLegende = false
    @State private var showShareSheetInfographie = false
    @State private var imageToShare: UIImage?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Infographie zoomable
                ZoomableImageView(imageName: "infographie_choix_leurre")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Barre boutons
                barreActions
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Color(UIColor.systemBackground)
                            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: -2)
                    )
            }
        }
        .navigationTitle("Guide Visuel")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    prepareShareSheetInfographie()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.body)
                }
            }
        }
        .sheet(isPresented: $showLegende) {
            LegendeDetailSheet()
        }
        .sheet(isPresented: $showShareSheetInfographie) {
            if let image = imageToShare {
                ShareSheetInfographie(items: [image])
            }
        }
    }
    
    // MARK: - Barre Actions
    
    private var barreActions: some View {
        HStack(spacing: 16) {
            // Bouton Légende (principal)
            Button {
                showLegende = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "book.fill")
                        .font(.title3)
                    
                    Text("Voir la légende détaillée")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFBC42"), Color(hex: "FF9800")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            
            // Bouton Partage (secondaire)
            Button {
                prepareShareSheetInfographie()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.title2)
                    .foregroundColor(Color(hex: "0277BD"))
                    .frame(width: 50, height: 50)
                    .background(Color(hex: "E3F2FD"))
                    .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Prépare l'image pour le partage
    private func prepareShareSheetInfographie() {
        // Charger l'image depuis les assets
        if let image = UIImage(named: "infographie_choix_leurre") {
            imageToShare = image
            showShareSheetInfographie = true
        }
    }
}

// MARK: - ShareSheetInfographie

struct ShareSheetInfographie: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Pas de mise à jour nécessaire
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        InfographieLeurreView()
    }
}
