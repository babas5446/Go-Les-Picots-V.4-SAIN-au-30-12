//
//  NavigationSidebar.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Sidebar gauche avec 7 fonctionnalités de navigation
//
//  Created: 2026-01-19
//

import SwiftUI
import MapKit

struct NavigationSidebar: View {
    // MARK: - Properties
    
    /// Coordonnées GPS du point tapé sur la carte
    let tappedCoordinate: CLLocationCoordinate2D
    
    /// Binding pour fermer le sidebar
    @Binding var isPresented: Bool
    
    /// État pour afficher la météo en fullScreenCover
    @State private var showMeteo = false
    
    /// Indique si les coordonnées proviennent de la géolocalisation ou d'un tap
    var isFromUserLocation: Bool = false
    
    // MARK: - Sidebar Items
    
    private let sidebarItems: [(icon: String, title: String, color: Color)] = [
        ("list.bullet.clipboard", "Mes Sorties", Color(hex: "0277BD")),
        ("mappin.circle", "Gestion des spots", Color(hex: "FFBC42")),
        ("figure.walk.circle", "Parcours GPS", Color(hex: "0277BD")),
        ("map.circle", "Couches cartographiques", Color(hex: "FFBC42")),
        ("location.circle", "Navigation vers spot", Color(hex: "0277BD")),
        ("cloud.sun", "Météo du spot", Color(hex: "FFBC42")),
        ("square.and.arrow.up", "Export GPX", Color(hex: "0277BD"))
    ]
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            // SIDEBAR GAUCHE
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Navigation")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0277BD"))
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.95))
                
                Divider()
                
                // Coordonnées du point tapé
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: isFromUserLocation ? "location.fill" : "mappin")
                            .foregroundColor(isFromUserLocation ? .blue : Color(hex: "FFBC42"))
                            .font(.caption)
                        Text(isFromUserLocation ? "Ma position" : "Position sélectionnée")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Text("Lat: \(String(format: "%.4f", tappedCoordinate.latitude))°")
                        .font(.caption)
                        .foregroundColor(Color(hex: "0277BD"))
                    Text("Lon: \(String(format: "%.4f", tappedCoordinate.longitude))°")
                        .font(.caption)
                        .foregroundColor(Color(hex: "0277BD"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(hex: "F5F5F5"))
                
                Divider()
                
                // Liste des 7 fonctionnalités
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(Array(sidebarItems.enumerated()), id: \.offset) { index, item in
                            SidebarItemButton(
                                icon: item.icon,
                                title: item.title,
                                color: item.color,
                                action: {
                                    handleAction(index: index)
                                }
                            )
                            
                            if index < sidebarItems.count - 1 {
                                Divider()
                                    .padding(.leading, 60)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .frame(width: 300)
            .background(
                // Glassmorphism effect
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 2, y: 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
            .padding(.leading, 10)
            .padding(.vertical, 10)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    
    private func handleAction(index: Int) {
        switch index {
        case 0: // Mes Sorties
            print("🚧 Mes Sorties - À implémenter")
            // TODO: Ouvrir MesSortiesView avec navigation ou sheet
            
        case 1: // Gestion des spots
            print("🚧 Gestion des spots - À implémenter")
            // TODO: Ouvrir liste/gestion spots
            
        case 2: // Parcours GPS
            print("🚧 Parcours GPS - À implémenter")
            // TODO: Démarrer/arrêter enregistrement parcours
            
        case 3: // Couches cartographiques
            print("🚧 Couches cartographiques - À implémenter")
            // TODO: Toggle overlays (bathymétrie, etc.)
            
        case 4: // Navigation vers spot
            print("🚧 Navigation vers spot - À implémenter")
            // TODO: Démarrer guidage GPS
            
        case 5: // Météo du spot
            showMeteo = true
            
        case 6: // Export GPX
            print("🚧 Export GPX - À implémenter")
            // TODO: Export données GPS
            
        default:
            break
        }
    }
}

// MARK: - Sidebar Item Button

struct SidebarItemButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct NavigationSidebar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.blue.opacity(0.3)
                .ignoresSafeArea()
            
            NavigationSidebar(
                tappedCoordinate: CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580),
                isPresented: .constant(true)
            )
        }
    }
}
