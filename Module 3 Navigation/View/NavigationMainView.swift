//
//  NavigationMainView.swift
//  Go Les Picots V.4
//
//  Module 3 : Navigation
//  Vue principale carte avec marquage spots
//

import SwiftUI
import MapKit

struct NavigationMainView: View {
    // Services
    @EnvironmentObject var spotStorage: SpotStorageService
    @EnvironmentObject var locationService: LocationService
    
    // État de la carte
    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -22.2758, longitude: 166.4580),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    )
    
    // UI State
    @State private var selectedSpotId: UUID?
    @State private var showSpotForm = false
    @State private var showSpotList = false
    @State private var pendingCoordinate: CLLocationCoordinate2D?
    
    // Tracking GPS
    @State private var isTrackingUser = false
    @State private var trackingMode: TrackingMode = .none
    
    var body: some View {
        ZStack {
            // Carte MapKit
            Map(position: $cameraPosition) {
                // Position utilisateur
                if let location = locationService.currentLocation {
                    Annotation("Ma position", coordinate: location.coordinate) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                }
                
                // Spots de pêche
                ForEach(spotStorage.spots) { spot in
                    Annotation(spot.name, coordinate: spot.coordinate) {
                        SpotAnnotationView(
                            annotation: MapSpotAnnotation(spot: spot),
                            isSelected: selectedSpotId == spot.id
                        )
                        .onTapGesture {
                            selectedSpotId = spot.id
                        }
                    }
                }
            }
            .mapStyle(.imagery(elevation: .realistic))
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            
            // Overlay boutons
            VStack {
                // Toolbar haut
                HStack {
                    Text("Navigation")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.6))
                        )
                    
                    Spacer()
                    
                    // Bouton liste
                    Button {
                        showSpotList = true
                    } label: {
                        Image(systemName: "list.bullet")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                // Boutons flottants bas droite
                VStack(spacing: 16) {
                    // Bouton centrage GPS
                    Button {
                        toggleTracking()
                    } label: {
                        Image(systemName: trackingIcon)
                            .font(.title3)
                            .foregroundColor(trackingColor)
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    
                    // Bouton ajout spot
                    Button {
                        addSpotAtCurrentLocation()
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                }
                .padding(.trailing)
                .padding(.bottom, 30)
            }
            
            // Toast précision GPS
            if let error = locationService.error, case .poorAccuracy(let accuracy) = error {
                VStack {
                    HStack {
                        Image(systemName: "location.slash")
                        Text("GPS imprécis (±\(Int(accuracy))m)")
                            .font(.subheadline)
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
                    .padding()
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSpotForm) {
            if let coordinate = pendingCoordinate {
                SpotFormView(
                    coordinate: coordinate,
                    onSave: { spot in
                        Task {
                            try? await spotStorage.addSpot(spot)
                            pendingCoordinate = nil
                            selectedSpotId = spot.id
                        }
                    },
                    onCancel: {
                        pendingCoordinate = nil
                    }
                )
            }
        }
        .sheet(isPresented: $showSpotList) {
            SpotListView()
        }
        .sheet(item: Binding(
            get: { spotStorage.spots.first { $0.id == selectedSpotId } },
            set: { selectedSpotId = $0?.id }
        )) { spot in
            SpotDetailView(spot: spot)
        }
        .onAppear {
            locationService.requestAuthorization()
            locationService.startUpdatingLocation()
        }
    }
    
    // MARK: - Actions
    
    private func addSpotAtCurrentLocation() {
        guard let coordinate = locationService.currentLocation?.coordinate else {
            return
        }
        
        pendingCoordinate = coordinate
        showSpotForm = true
    }
    
    private func toggleTracking() {
        guard let location = locationService.currentLocation else {
            locationService.requestAuthorization()
            return
        }
        
        switch trackingMode {
        case .none:
            trackingMode = .follow
            isTrackingUser = true
            centerOnUser(location: location, animated: true)
            
        case .follow:
            trackingMode = .followWithHeading
            centerOnUser(location: location, animated: true)
            
        case .followWithHeading:
            trackingMode = .none
            isTrackingUser = false
        }
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func centerOnUser(location: CLLocation, animated: Bool) {
        let region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        
        if animated {
            withAnimation {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
    
    // MARK: - Computed Properties
    
    private var trackingIcon: String {
        switch trackingMode {
        case .none:
            return "location"
        case .follow:
            return "location.fill"
        case .followWithHeading:
            return "location.north.line.fill"
        }
    }
    
    private var trackingColor: Color {
        trackingMode == .none ? .gray : .blue
    }
}

// MARK: - TrackingMode

enum TrackingMode {
    case none
    case follow
    case followWithHeading
}

// MARK: - Preview

#if DEBUG
struct NavigationMainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationMainView()
            .environmentObject(SpotStorageService.preview)
            .environmentObject(LocationService())
    }
}
#endif
