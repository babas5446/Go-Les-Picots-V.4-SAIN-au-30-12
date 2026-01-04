//
//  TechniquesListView.swift
//  Go Les Picots V.4
//
//  Module 4 : Section Techniques de pêche
//  Sprint 3 - À développer
//
//  Created by LANES Sebastien on 03/01/2026.
//

import SwiftUI

struct TechniquesListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Banner avec icône
                BannerView(
                    iconName: "Techniques_icon",
                    title: "Techniques de pêche",
                    subtitle: "Traîne, jigging, montages et stratégies",
                    accentColor: Color.orange
                )
                .padding(.horizontal)
                
                // Contenu placeholder - Sprint 3
                VStack(spacing: 20) {
                    Image(systemName: "fish.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.orange.opacity(0.5))
                    
                    Text("Section Techniques de pêche")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("À développer dans Sprint 3")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Contenus prévus :")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Techniques de traîne", systemImage: "waveform.path")
                        Label("Montages et bas de ligne", systemImage: "link")
                        Label("Jigging et lancer", systemImage: "arrow.up.and.down")
                        Label("Stratégies par zone", systemImage: "map")
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.top, 40)
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    NavigationView {
        TechniquesListView()
    }
}
