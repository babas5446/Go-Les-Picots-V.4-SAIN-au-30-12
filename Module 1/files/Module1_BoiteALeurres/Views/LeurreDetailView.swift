//
//  LeurreDetailView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue détaillée d'un leurre avec toutes ses caractéristiques
//
//  Created: 2024-12-04
//

import SwiftUI

struct LeurreDetailView: View {
    let leurre: Leurre
    @ObservedObject var viewModel: LeureViewModel
    
    @State private var showingEditer = false
    @State private var showingSupprimer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo principale
                photoPrincipale
                
                // Informations de base
                carteInformationsBase
                
                // Performance
                cartePerformance
                
                // Espèces cibles
                carteEspecesCibles
                
                // Positions spread
                cartePositionsSpread
                
                // Conditions optimales
                carteConditionsOptimales
                
                // Notes
                if let notes = leurre.notes, !notes.isEmpty {
                    carteNotes
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(hex: "F5F5F5"))
        .navigationTitle(leurre.nom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingEditer = true }) {
                        Label("Modifier", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: { showingSupprimer = true }) {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingEditer) {
            EditerLeurreView(leurre: leurre, viewModel: viewModel)
        }
        .alert("Supprimer ce leurre ?", isPresented: $showingSupprimer) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                viewModel.supprimerLeurre(leurre)
            }
        } message: {
            Text("Cette action est irréversible.")
        }
    }
    
    // MARK: - Photo principale
    
    private var photoPrincipale: some View {
        ZStack(alignment: .topTrailing) {
            if let photoData = leurre.photo, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "E0E0E0"))
                        .frame(height: 200)
                    VStack(spacing: 12) {
                        Text(leurre.type.icon)
                            .font(.system(size: 80))
                        Text("Aucune photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Badge contraste
            Text(leurre.contraste.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(leurre.contraste.color)
                .foregroundColor(.white)
                .cornerRadius(12)
                .padding(12)
        }
    }
    
    // MARK: - Carte informations de base
    
    private var carteInformationsBase: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Informations générales", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                InfoRow(label: "Marque", value: leurre.marque)
                if let modele = leurre.modele {
                    InfoRow(label: "Modèle", value: modele)
                }
                if let reference = leurre.reference {
                    InfoRow(label: "Référence", value: reference)
                }
                InfoRow(label: "Type", value: leurre.type.displayName)
                
                // Catégories de pêche
                HStack(alignment: .top) {
                    Text("Zones :")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 100, alignment: .leading)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(leurre.categoriePeche, id: \.self) { categorie in
                            BadgeView(text: categorie.displayName, color: Color(hex: "0277BD"))
                        }
                    }
                }
                
                InfoRow(label: "Longueur", value: "\(Int(leurre.longueur)) cm")
                if let poids = leurre.poids {
                    InfoRow(label: "Poids", value: "\(Int(poids)) g")
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte performance
    
    private var cartePerformance: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance", icon: "gauge.high")
            
            VStack(spacing: 12) {
                // Profondeur
                HStack {
                    Text("Profondeur")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(Color(hex: "0277BD"))
                        Text(leurre.profondeurFormatee)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                // Vitesse
                HStack {
                    Text("Vitesse")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 100, alignment: .leading)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                            .foregroundColor(Color(hex: "FFBC42"))
                        Text(leurre.vitesseFormatee)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                // Action de nage
                InfoRow(label: "Action", value: leurre.actionNage.displayName)
                
                // Type de tête
                if let typeTete = leurre.typeTete {
                    InfoRow(label: "Tête", value: typeTete.displayName)
                }
                
                // Couleurs
                HStack(alignment: .top) {
                    Text("Couleurs :")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 100, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(leurre.couleurPrincipale.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        if !leurre.couleursSecondaires.isEmpty {
                            ForEach(leurre.couleursSecondaires, id: \.self) { couleur in
                                Text("+ " + couleur.displayName)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        if let finition = leurre.finition {
                            Text(finition.displayName)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte espèces cibles
    
    private var carteEspecesCibles: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Espèces cibles", icon: "fish.fill")
            
            FlowLayout(spacing: 8) {
                ForEach(leurre.especesCibles, id: \.self) { espece in
                    BadgeView(text: espece.displayName, color: Color(hex: "FFBC42"), large: true)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte positions spread
    
    private var cartePositionsSpread: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Positions traîne", icon: "map.fill")
            
            FlowLayout(spacing: 8) {
                ForEach(leurre.positionsSpread, id: \.self) { position in
                    BadgeView(text: position.displayName, color: Color(hex: "0277BD"), large: false)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte conditions optimales
    
    private var carteConditionsOptimales: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Conditions optimales", icon: "sun.max.fill")
            
            VStack(alignment: .leading, spacing: 12) {
                ConditionSection(
                    title: "Moments",
                    items: leurre.conditionsOptimales.moments.map { $0.displayName }
                )
                
                ConditionSection(
                    title: "État de la mer",
                    items: leurre.conditionsOptimales.etatMer.map { $0.displayName }
                )
                
                ConditionSection(
                    title: "Turbidité",
                    items: leurre.conditionsOptimales.turbidite.map { $0.displayName }
                )
                
                ConditionSection(
                    title: "Marée",
                    items: leurre.conditionsOptimales.maree.map { $0.displayName }
                )
                
                ConditionSection(
                    title: "Phases lunaires",
                    items: leurre.conditionsOptimales.phasesLunaires.map { $0.displayName }
                )
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte notes
    
    private var carteNotes: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes", icon: "note.text")
            
            Text(leurre.notes ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Composants réutilisables

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "0277BD"))
            Text(title)
                .font(.headline)
                .foregroundColor(Color(hex: "0277BD"))
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + " :")
                .font(.subheadline)
                .foregroundColor(.gray)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    var large: Bool = false
    
    var body: some View {
        Text(text)
            .font(large ? .subheadline : .caption)
            .fontWeight(.medium)
            .padding(.horizontal, large ? 12 : 8)
            .padding(.vertical, large ? 8 : 4)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

struct ConditionSection: View {
    let title: String
    let items: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
                .textCase(.uppercase)
            
            FlowLayout(spacing: 6) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0277BD").opacity(0.1))
                        .foregroundColor(Color(hex: "0277BD"))
                        .cornerRadius(6)
                }
            }
        }
    }
}

// MARK: - FlowLayout (pour badges qui wrap)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var height: CGFloat = 0
        var lineHeight: CGFloat = 0
        var currentX: CGFloat = 0
        let maxWidth = proposal.width ?? 0
        
        for size in sizes {
            if currentX + size.width > maxWidth && currentX > 0 {
                height += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height += lineHeight
        
        return CGSize(width: maxWidth, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += lineHeight + spacing
                currentX = bounds.minX
                lineHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

// MARK: - Preview

struct LeurreDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LeurreDetailView(
                leurre: LeureViewModel.leurreTest(),
                viewModel: LeureViewModel()
            )
        }
    }
}
