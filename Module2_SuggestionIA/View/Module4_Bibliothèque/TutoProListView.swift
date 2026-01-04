//
//  TutoProListView.swift
//  Go Les Picots V.4
//
//  Module 4 : Section Tuto de Pro
//  Sprint 4 - À développer
//
//  Created by LANES Sebastien on 03/01/2026.
//

import SwiftUI

struct TutoProListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Banner avec icône
                BannerView(
                    iconName: "TutoDePro_icon",
                    title: "Tuto de Pro",
                    subtitle: "Vidéos CPS et conseils d'experts",
                    accentColor: Color.green
                )
                .padding(.horizontal)
                
                // Contenu placeholder - Sprint 4
                VStack(spacing: 20) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.green.opacity(0.5))
                    
                    Text("Section Tuto de Pro")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("À développer dans Sprint 4")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Contenus prévus :")
                        .font(.headline)
                        .padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Vidéos pédagogiques CPS", systemImage: "play.rectangle")
                        Label("Conseils d'experts locaux", systemImage: "person.2")
                        Label("Tutoriels YouTube intégrés", systemImage: "video")
                        Label("Astuces de professionnels", systemImage: "lightbulb")
                    }
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.green.opacity(0.1))
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
        TutoProListView()
    }
}
