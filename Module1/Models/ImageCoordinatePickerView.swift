//
//  ImageCoordinatePickerView.swift
//  Go les Picots - Module 2
//
//  Outil interactif pour mesurer les coordonnées des bulles dans l'image
//  Permet de tapper sur l'image pour obtenir les coordonnées exactes
//
//  Created: 2024-12-19
//

import SwiftUI

struct ImageCoordinatePickerView: View {
    @State private var tappedPoints: [TappedPoint] = []
    @State private var imageSize: CGSize = .zero
    @State private var scale: CGFloat = 1.0
    
    let designSize = CGSize(width: 1024, height: 1536)
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Instructions
                VStack(spacing: 8) {
                    Text("📍 Outil de Mesure des Coordonnées")
                        .font(.headline)
                    
                    Text("Tappez sur les bulles blanches de l'image pour obtenir leurs coordonnées")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                
                // Image interactive
                GeometryReader { geometry in
                    let scale = min(geometry.size.width / designSize.width,
                                   geometry.size.height / designSize.height)
                    
                    let renderedSize = CGSize(width: designSize.width * scale,
                                             height: designSize.height * scale)
                    
                    ZStack {
                        // Image de fond
                        if let uiImage = UIImage(named: "spread_template_ok") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: renderedSize.width, height: renderedSize.height)
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: renderedSize.width, height: renderedSize.height)
                                .overlay(
                                    Text("Image 'spread_template_ok' non trouvée")
                                        .foregroundColor(.secondary)
                                )
                        }
                        
                        // Points tappés
                        ForEach(tappedPoints) { point in
                            PointMarker(point: point, scale: scale)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                let location = value.location
                                
                                // Convertir en coordonnées de l'image 1024×1536
                                let centerOffset = CGPoint(
                                    x: (geometry.size.width - renderedSize.width) / 2,
                                    y: (geometry.size.height - renderedSize.height) / 2
                                )
                                
                                let x = (location.x - centerOffset.x) / scale
                                let y = (location.y - centerOffset.y) / scale
                                
                                // Vérifier que c'est dans les limites
                                guard x >= 0 && x <= designSize.width &&
                                      y >= 0 && y <= designSize.height else {
                                    return
                                }
                                
                                addPoint(x: x, y: y, viewLocation: location)
                            }
                    )
                    .onAppear {
                        self.scale = scale
                        self.imageSize = renderedSize
                    }
                }
                
                // Liste des coordonnées
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 Coordonnées Mesurées")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if tappedPoints.isEmpty {
                            Text("Tappez sur l'image pour commencer")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            ForEach(Array(tappedPoints.enumerated()), id: \.element.id) { index, point in
                                CoordinateRow(index: index, point: point) {
                                    removePoint(point)
                                }
                            }
                            
                            Divider()
                            
                            // Code Swift généré
                            VStack(alignment: .leading, spacing: 8) {
                                Text("💻 Code Swift Généré")
                                    .font(.headline)
                                
                                Text(generateSwiftCode())
                                    .font(.system(.caption, design: .monospaced))
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Button(action: copyCode) {
                                    Label("Copier le code", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    }
                    .padding(.vertical)
                }
                .frame(height: 250)
                .background(Color(UIColor.systemBackground))
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Effacer tout") {
                        tappedPoints.removeAll()
                    }
                    .disabled(tappedPoints.isEmpty)
                }
            }
        }
    }
    
    private func addPoint(x: CGFloat, y: CGFloat, viewLocation: CGPoint) {
        let number = tappedPoints.count
        let label = bubbleLabel(for: number)
        
        let point = TappedPoint(
            id: UUID(),
            number: number,
            label: label,
            x: Int(x),
            y: Int(y),
            viewLocation: viewLocation
        )
        
        tappedPoints.append(point)
        
        print("📍 Point \(number) (\(label)): x=\(Int(x)), y=\(Int(y))")
    }
    
    private func removePoint(_ point: TappedPoint) {
        tappedPoints.removeAll { $0.id == point.id }
    }
    
    private func bubbleLabel(for index: Int) -> String {
        switch index {
        case 0: return "0L (Libre)"
        case 1: return "1SC (Short Corner)"
        case 2: return "2LC (Long Corner)"
        case 3: return "3SR (Short Rigger)"
        case 4: return "4LR (Long Rigger)"
        case 5: return "5SG (Shotgun)"
        default: return "\(index)"
        }
    }
    
    private func generateSwiftCode() -> String {
        guard !tappedPoints.isEmpty else {
            return "// Tappez sur les bulles pour générer le code"
        }
        
        var code = "private let bubbles: [BubbleSpec] = [\n"
        
        for point in tappedPoints.sorted(by: { $0.number < $1.number }) {
            let positionName = positionName(for: point.number)
            code += "    // \(point.label)\n"
            code += "    .init(id: \"\(point.number)\", position: .\(positionName), center: CGPoint(x: \(point.x), y: \(point.y)), diameter: 60.0),\n"
        }
        
        code += "]"
        
        return code
    }
    
    private func positionName(for index: Int) -> String {
        switch index {
        case 0: return "libre"
        case 1: return "shortCorner"
        case 2: return "longCorner"
        case 3: return "shortRigger"
        case 4: return "longRigger"
        case 5: return "shotgun"
        default: return "libre"
        }
    }
    
    private func copyCode() {
        UIPasteboard.general.string = generateSwiftCode()
    }
}

// MARK: - Models

struct TappedPoint: Identifiable {
    let id: UUID
    let number: Int
    let label: String
    let x: Int
    let y: Int
    let viewLocation: CGPoint
}

// MARK: - Point Marker

struct PointMarker: View {
    let point: TappedPoint
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 30, height: 30)
                
                Text("\(point.number)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(point.label)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 2)
        }
        .position(point.viewLocation)
    }
}

// MARK: - Coordinate Row

struct CoordinateRow: View {
    let index: Int
    let point: TappedPoint
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            // Numéro et label
            VStack(alignment: .leading, spacing: 4) {
                Text(point.label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 12) {
                    Text("X: \(point.x)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Text("Y: \(point.y)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Bouton supprimer
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

// MARK: - Preview

struct ImageCoordinatePickerView_Previews: PreviewProvider {
    static var previews: some View {
        ImageCoordinatePickerView()
    }
}
