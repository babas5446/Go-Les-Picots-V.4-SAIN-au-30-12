//
//  ZoomableImageView.swift
//  Go les Picots - Module 4
//
//  Composant réutilisable pour afficher une image avec zoom
//  - Pinch-to-zoom (1x à 3x)
//  - Pan gesture quand zoomé
//  - Double-tap pour zoom auto
//  - Bouton reset zoom
//
//  Created: 2026-01-15
//

import SwiftUI

struct ZoomableImageView: View {
    
    // MARK: - Properties
    
    let imageName: String
    
    @State private var currentScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    // Limites de zoom
    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 3.0
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Image zoomable
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(currentScale)
                    .offset(currentOffset)
                    .gesture(
                        // Pinch-to-zoom
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value / lastScale
                                lastScale = value
                                
                                var newScale = currentScale * delta
                                newScale = min(max(newScale, minScale), maxScale)
                                currentScale = newScale
                            }
                            .onEnded { _ in
                                lastScale = 1.0
                                
                                // Si zoom < 1.0, reset
                                if currentScale < minScale {
                                    withAnimation(.spring()) {
                                        resetZoom()
                                    }
                                }
                            }
                    )
                    .simultaneousGesture(
                        // Pan gesture (déplacement)
                        DragGesture()
                            .onChanged { value in
                                // Seulement si zoomé
                                guard currentScale > 1.0 else { return }
                                
                                let newOffset = CGSize(
                                    width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height
                                )
                                
                                // Limiter le déplacement pour ne pas sortir de l'image
                                currentOffset = limitOffset(newOffset, in: geometry.size)
                            }
                            .onEnded { _ in
                                lastOffset = currentOffset
                            }
                    )
                    .onTapGesture(count: 2) {
                        // Double-tap pour zoom/dézoom
                        withAnimation(.spring()) {
                            if currentScale > 1.0 {
                                resetZoom()
                            } else {
                                currentScale = 2.0
                            }
                        }
                    }
                
                // Bouton reset zoom (si zoomé)
                if currentScale > 1.0 {
                    VStack {
                        HStack {
                            Spacer()
                            
                            Button {
                                withAnimation(.spring()) {
                                    resetZoom()
                                }
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(.trailing, 20)
                            .padding(.top, 20)
                        }
                        
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset du zoom et offset
    private func resetZoom() {
        currentScale = 1.0
        currentOffset = .zero
        lastOffset = .zero
    }
    
    /// Limite l'offset pour ne pas sortir de l'image
    private func limitOffset(_ offset: CGSize, in containerSize: CGSize) -> CGSize {
        // Calcul de la zone déplaçable
        let maxOffsetX = (containerSize.width * (currentScale - 1)) / 2
        let maxOffsetY = (containerSize.height * (currentScale - 1)) / 2
        
        return CGSize(
            width: min(max(offset.width, -maxOffsetX), maxOffsetX),
            height: min(max(offset.height, -maxOffsetY), maxOffsetY)
        )
    }
}

// MARK: - Preview

#Preview {
    ZoomableImageView(imageName: "infographie_choix_leurre")
        .background(Color.gray.opacity(0.1))
}
