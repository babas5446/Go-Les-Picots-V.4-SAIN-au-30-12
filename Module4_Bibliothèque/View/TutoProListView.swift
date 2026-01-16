//
//  TutoProListView.swift
//  Go Les Picots V.4
//
//  Module 4 : Section Tuto de Pro
//  Sprint 4 - Vidéos YouTube Pacific Community organisées par catégorie
//
//  Created by LANES Sebastien on 03/01/2026.
//

import SwiftUI

struct TutoProListView: View {
    
    // MARK: - State
    
    @State private var categorieSelectionnee: CategorieTuto? = nil
    
    // MARK: - Computed
    
    private var categories: [CategorieTuto] {
        TutoVideoDatabase.categoriesAvecVideos
    }
    
    private var videosAffichees: [TutoVideo] {
        if let categorie = categorieSelectionnee {
            return TutoVideoDatabase.videos(pour: categorie)
        }
        return TutoVideoDatabase.videos
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Filtres catégories
            if !categories.isEmpty {
                filtreCategories
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemGroupedBackground))
            }
            
            // Liste des vidéos
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(videosAffichees) { video in
                        VideoCardView(video: video)
                            .onTapGesture {
                                ouvrirYouTube(video: video)
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Tutos Pro")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Filtre Catégories
    
    private var filtreCategories: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Bouton "Toutes"
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        categorieSelectionnee = nil
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.caption)
                        Text("Toutes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(categorieSelectionnee == nil ? .white : Color(hex: "0277BD"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(categorieSelectionnee == nil ? Color(hex: "0277BD") : Color(UIColor.secondarySystemGroupedBackground))
                    )
                }
                
                // Boutons catégories
                ForEach(categories, id: \.self) { categorie in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            categorieSelectionnee = categorie
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: categorie.icon)
                                .font(.caption)
                            Text(categorie.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(categorieSelectionnee == categorie ? .white : Color(hex: categorie.couleur))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(categorieSelectionnee == categorie ? Color(hex: categorie.couleur) : Color(UIColor.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Ouvrir la vidéo dans l'app YouTube
    private func ouvrirYouTube(video: TutoVideo) {
        guard let url = URL(string: video.urlYouTube) else { return }
        
        // Essayer d'ouvrir dans l'app YouTube
        let youtubeAppURL = URL(string: "youtube://\(video.id)")
        
        if let appURL = youtubeAppURL, UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Sinon ouvrir dans Safari
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Video Card View

struct VideoCardView: View {
    
    let video: TutoVideo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Vignette vidéo avec durée
            ZStack(alignment: .bottomTrailing) {
                // Image de la vignette YouTube
                AsyncImage(url: URL(string: video.urlVignette)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "play.rectangle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Badge durée
                Text(video.duree)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(6)
                    .padding(8)
                
                // Icône play centrale
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .opacity(0.9)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Informations vidéo
            VStack(alignment: .leading, spacing: 8) {
                // Badge catégorie
                HStack(spacing: 6) {
                    Image(systemName: video.categorie.icon)
                        .font(.caption)
                    Text(video.categorie.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color(hex: video.categorie.couleur))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: video.categorie.couleur).opacity(0.1))
                .cornerRadius(6)
                
                // Titre
                Text(video.titre)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Source
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(Color(hex: "0277BD"))
                    Text(video.source)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        TutoProListView()
    }
}
