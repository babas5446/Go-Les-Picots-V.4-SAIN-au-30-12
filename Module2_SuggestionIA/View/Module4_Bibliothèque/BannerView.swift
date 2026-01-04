//
//  BannerView.swift
//  Go Les Picots V.4
//
//  Composant réutilisable de banner pour les sections
//  Module 4 - Bibliothèque
//
//  Created by LANES Sebastien on 03/01/2026.
//

import SwiftUI

struct BannerView: View {
    let iconName: String
    let title: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            // Icône personnalisée
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .padding(16)
                .background(accentColor.opacity(0.15))
                .cornerRadius(16)
            
            // Texte
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(accentColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(accentColor.opacity(0.3), lineWidth: 2)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        BannerView(
            iconName: "Bibliotheque2_icon",
            title: "Bibliothèque d'espèces",
            subtitle: "Identification, habitat et techniques de pêche",
            accentColor: Color.blue
        )
        
        BannerView(
            iconName: "Techniques_Icon",
            title: "Techniques de pêche",
            subtitle: "Traîne, jigging, montages et stratégies",
            accentColor: Color.orange
        )
        
        BannerView(
            iconName: "TutoDePro_icon",
            title: "Tuto de Pro",
            subtitle: "Vidéos CPS et conseils d'experts",
            accentColor: Color.green
        )
    }
    .padding()
}
