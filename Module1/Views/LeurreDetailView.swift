//
//  LeurreDetailView.swift
//  Go les Picots - Module 1 : Ma Boîte à Leurres
//
//  Vue détaillée d'un leurre avec toutes ses caractéristiques
//
//  MODIFIÉ: 2024-12-10 - Adaptation Phase 2 (nouveau modèle + LeurreFormView)
//

import SwiftUI

struct LeurreDetailView: View {
    let leurre: Leurre
    @ObservedObject var viewModel: LeureViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditer = false
    @State private var showingDupliquer = false
    @State private var showingSupprimer = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Photo principale
                photoPrincipale
                
                // Informations de base
                carteInformationsBase
                
                // Performance (seulement si traîne)
                if leurre.typePeche == .traine {
                    cartePerformance
                }
                
                // Espèces cibles (affichage des valeurs FINALES)
                // ✅ Toujours afficher (déduction automatique si JSON vide)
                if !leurre.especesCiblesFinales.isEmpty {
                    carteEspecesCibles
                }
                
                // Zones adaptées (affichage des valeurs FINALES)
                // ✅ Toujours afficher (déduction automatique si JSON vide)
                if !leurre.zonesAdapteesFinales.isEmpty {
                    carteZonesAdaptees
                }
                
                // Positions spread (si calculées et traîne)
                if leurre.typePeche == .traine,
                   let positions = leurre.positionsSpread, !positions.isEmpty {
                    cartePositionsSpread
                }
                
                // Conditions optimales (si calculées)
                if let conditions = leurre.conditionsOptimales {
                    carteConditionsOptimales(conditions)
                }
                
                // Notes
                if let notes = leurre.notes, !notes.isEmpty {
                    carteNotes(notes)
                }
                
                // Indicateur de calcul
                if !leurre.isComputed {
                    carteNonCalcule
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
                    Button(action: { showingDupliquer = true }) {
                        Label("Dupliquer", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive, action: { showingSupprimer = true }) {
                        Label("Supprimer", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // ═══════════════════════════════════════════════════════════
        // MODIFICATION PHASE 2 : Utiliser LeurreFormView
        // ═══════════════════════════════════════════════════════════
        .sheet(isPresented: $showingEditer) {
            LeurreFormView(viewModel: viewModel, mode: .edition(leurre))
        }
        .sheet(isPresented: $showingDupliquer) {
            LeurreFormView(viewModel: viewModel, mode: .duplication(leurre))
        }
        .alert("Supprimer ce leurre ?", isPresented: $showingSupprimer) {
            Button("Annuler", role: .cancel) { }
            Button("Supprimer", role: .destructive) {
                viewModel.supprimerLeurre(leurre)
                dismiss()  // Retour à la liste après suppression
            }
        } message: {
            Text("Cette action est irréversible.")
        }
    }
    
    // MARK: - Photo principale
    
    private var photoPrincipale: some View {
        ZStack(alignment: .topTrailing) {
            // Photo ou placeholder
            if let image = viewModel.chargerPhoto(pourLeurre: leurre) {
                Image(uiImage: image)
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
                        Text(leurre.typeLeurre.icon)
                            .font(.system(size: 80))
                        Text("Aucune photo")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            // Badges en haut à droite
            VStack(alignment: .trailing, spacing: 8) {
                // Badge type de pêche
                Text(leurre.typePeche.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(hex: "0277BD"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                
                // Badge contraste (si calculé)
                if let contraste = leurre.contraste {
                    Text(contraste.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "FFBC42"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(12)
        }
    }
    
    // MARK: - Carte informations de base
    
    private var carteInformationsBase: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Informations générales", icon: "info.circle.fill")
            
            VStack(spacing: 12) {
                InfoRow(label: "Marque", value: leurre.marque)
                
                if let modele = leurre.modele, !modele.isEmpty {
                    InfoRow(label: "Modèle", value: modele)
                }
                
                InfoRow(label: "Type leurre", value: leurre.typeLeurre.displayName)
                InfoRow(label: "Type pêche", value: leurre.typePeche.displayName)
                InfoRow(label: "Longueur", value: "\(Int(leurre.longueur)) cm")
                
                if let poids = leurre.poids {
                    InfoRow(label: "Poids", value: "\(Int(poids)) g")
                }
                
                // Couleurs
                HStack(alignment: .top) {
                    Text("Couleurs :")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .frame(width: 100, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            // ✅ CORRECTION : Utiliser couleurPrincipaleAffichage
                            let principaleInfo = leurre.couleurPrincipaleAffichage
                            if principaleInfo.isRainbow {
                                RainbowCircle(size: 16, showBorder: true)
                            } else {
                                Circle()
                                    .fill(principaleInfo.color)
                                    .frame(width: 16, height: 16)
                            }
                            Text(principaleInfo.nom)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        // ✅ CORRECTION : Utiliser couleurSecondaireAffichage
                        if let secondaireInfo = leurre.couleurSecondaireAffichage {
                            HStack(spacing: 8) {
                                if secondaireInfo.isRainbow {
                                    RainbowCircle(size: 16, showBorder: true)
                                } else {
                                    Circle()
                                        .fill(secondaireInfo.color)
                                        .frame(width: 16, height: 16)
                                }
                                Text("+ " + secondaireInfo.nom)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                // Finition (si présente)
                if let finition = leurre.finition {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Finition :")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .frame(width: 100, alignment: .leading)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(Color(hex: "FFBC42"))
                                    .font(.caption)
                                Text(finition.displayName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            
                            Spacer()
                        }
                        
                        // Description de la finition
                        VStack(alignment: .leading, spacing: 4) {
                            Text(finition.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(finition.conditionsIdeales)
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.leading, 100)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte performance (traîne uniquement)
    
    private var cartePerformance: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Performance traîne", icon: "gauge.high")
            
            VStack(spacing: 12) {
                // Profondeur
                if let profondeur = leurre.profondeurFormatee {
                    HStack {
                        Text("Profondeur")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(Color(hex: "0277BD"))
                            Text(profondeur)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                }
                
                // Vitesse
                if let vitesse = leurre.vitesseFormatee {
                    HStack {
                        Text("Vitesse")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .frame(width: 100, alignment: .leading)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "speedometer")
                                .foregroundColor(Color(hex: "FFBC42"))
                            Text(vitesse)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte zones adaptées
    
    private var carteZonesAdaptees: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Zones adaptées", icon: "map.fill")
            
            // ✅ UTILISATION DES VALEURS FINALES (JSON > Notes > Déduction auto)
            FlowLayout(spacing: 8) {
                ForEach(leurre.zonesAdapteesFinales, id: \.self) { zone in
                    HStack(spacing: 4) {
                        Text(zone.icon)
                        Text(zone.displayName)
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "0277BD").opacity(0.15))
                    .foregroundColor(Color(hex: "0277BD"))
                    .cornerRadius(8)
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
            
            // ✅ UTILISATION DES VALEURS FINALES (Notes > JSON > Déduction auto)
            FlowLayout(spacing: 8) {
                ForEach(leurre.especesCiblesFinales, id: \.self) { espece in
                    BadgeView(text: espece, color: Color(hex: "FFBC42"), large: true)
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
            SectionHeader(title: "Positions traîne", icon: "arrow.triangle.branch")
            
            VStack(spacing: 8) {
                ForEach(leurre.positionsSpread ?? [], id: \.self) { position in
                    HStack {
                        Text(position.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(position.caracteristiques)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "0277BD").opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte conditions optimales
    
    private func carteConditionsOptimales(_ conditions: ConditionsOptimales) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Conditions optimales", icon: "sun.max.fill")
            
            VStack(alignment: .leading, spacing: 12) {
                if let moments = conditions.moments, !moments.isEmpty {
                    ConditionSection(
                        title: "Moments",
                        items: moments.map { $0.displayName }
                    )
                }
                
                if let etatMer = conditions.etatMer, !etatMer.isEmpty {
                    ConditionSection(
                        title: "État de la mer",
                        items: etatMer.map { $0.displayName }
                    )
                }
                
                if let turbidite = conditions.turbidite, !turbidite.isEmpty {
                    ConditionSection(
                        title: "Turbidité",
                        items: turbidite.map { $0.displayName }
                    )
                }
                
                if let maree = conditions.maree, !maree.isEmpty {
                    ConditionSection(
                        title: "Marée (affinage)",
                        items: maree.map { $0.displayName }
                    )
                }
                
                if let phases = conditions.phasesLunaires, !phases.isEmpty {
                    ConditionSection(
                        title: "Phases lunaires (affinage)",
                        items: phases.map { $0.displayName }
                    )
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte notes
    
    private func carteNotes(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Notes", icon: "note.text")
            
            Text(notes)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Carte non calculé
    
    private var carteNonCalcule: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text("Champs déduits non calculés")
                .font(.headline)
                .foregroundColor(.orange)
            
            Text("Les zones, espèces et conditions optimales seront calculées automatiquement lors de la prochaine sauvegarde.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Recalculer maintenant") {
                var leurreModifie = leurre
                leurreModifie = viewModel.calculerChampsDeduits(leurreModifie)
                viewModel.modifierLeurre(leurreModifie)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
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
                leurre: Leurre(
                    id: 1,
                    nom: "Magnum Stretch 30+",
                    marque: "Manns",
                    modele: "Stretch 30+",
                    typeLeurre: .poissonNageurPlongeant,
                    typePeche: .traine,
                    longueur: 21.0,
                    poids: 130,
                    couleurPrincipale: .roseFuchsia,
                    couleurSecondaire: .blanc,
                    profondeurNageMin: 8.0,
                    profondeurNageMax: 10.0,
                    vitesseTraineMin: 6.0,
                    vitesseTraineMax: 10.0,
                    notes: "Excellent pour le wahoo par mer formée"
                ),
                viewModel: LeureViewModel()
            )
        }
    }
}
