//
//  NavigationMapView.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Carte interactive avec sidebar de navigation
//
//  Created: 2026-01-19
//

import SwiftUI
import MapKit

struct NavigationMapView: View {
    // MARK: - Properties
    
    @State private var locationService = LocationService()
    @State private var position: MapCameraPosition = .automatic
    @State private var showSidebar = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var mapProxy: MapProxy?
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // CARTE MAPKIT avec MapReader pour obtenir les coordonnées précises
            MapReader { proxy in
                Map(position: $position) {
                    // Marqueur de la position actuelle (si disponible)
                    if let userLocation = locationService.currentLocation {
                        Annotation("Ma position", coordinate: userLocation.coordinate) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 20, height: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 3)
                                )
                        }
                    }
                    
                    // Marqueur du point tapé (si disponible)
                    if let tapped = tappedCoordinate {
                        Annotation("Point sélectionné", coordinate: tapped) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(Color(hex: "FFBC42"))
                        }
                    }
                    
                    // TODO: Ajouter annotations des spots enregistrés
                }
                .mapStyle(.standard)
                .onTapGesture { screenLocation in
                    // Conversion précise du point tapé en coordonnées GPS
                    if let coordinate = proxy.convert(screenLocation, from: .local) {
                        handleMapTap(coordinate: coordinate)
                    }
                }
                .onAppear {
                    mapProxy = proxy
                }
            }
            
            // SIDEBAR (overlay gauche)
            if showSidebar, let coordinate = tappedCoordinate {
                ZStack {
                    // Backdrop semi-transparent
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3)) {
                                showSidebar = false
                            }
                        }
                    
                    // Sidebar
                    NavigationSidebar(
                        tappedCoordinate: coordinate,
                        isPresented: $showSidebar
                    )
                    .transition(.move(edge: .leading))
                }
            }
            
            // OVERLAY BOUTON "Enregistrer ce spot" (en bas)
            if !showSidebar {
                VStack {
                    Spacer()
                    
                    Button(action: {
                        // TODO: Action enregistrer spot
                        print("🚧 Enregistrer spot - À implémenter")
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Enregistrer ce spot")
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(hex: "FFBC42")) // Orange
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                    }
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Navigation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: centerOnUserLocation) {
                    Image(systemName: "location.fill")
                        .foregroundColor(Color(hex: "0277BD"))
                }
            }
        }
        .task {
            // Demander autorisation et démarrer localisation
            locationService.requestAuthorization()
            locationService.startUpdatingLocation()
            
            // Centrer sur position utilisateur si disponible
            if let userLocation = locationService.currentLocation {
                position = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        }
        .onDisappear {
            locationService.stopUpdatingLocation()
        }
    }
    
    // MARK: - Methods
    
    /// Gère le tap sur la carte avec les coordonnées précises
    private func handleMapTap(coordinate: CLLocationCoordinate2D) {
        tappedCoordinate = coordinate
        
        withAnimation(.spring(response: 0.3)) {
            showSidebar = true
        }
        
        print("📍 Carte tapée - Coordonnées: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    /// Centre la carte sur la position actuelle de l'utilisateur
    private func centerOnUserLocation() {
        if let userLocation = locationService.currentLocation {
            withAnimation {
                position = .region(
                    MKCoordinateRegion(
                        center: userLocation.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                    )
                )
            }
        } else {
            print("⚠️ Position utilisateur non disponible")
            // Fallback sur Nouméa si pas de position
            let noumea = CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580)
            withAnimation {
                position = .region(
                    MKCoordinateRegion(
                        center: noumea,
                        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                    )
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NavigationMapView()
    }
}
