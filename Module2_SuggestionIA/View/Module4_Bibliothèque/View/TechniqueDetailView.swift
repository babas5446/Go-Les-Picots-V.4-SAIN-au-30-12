//
//  TechniqueDetailView.swift
//  Go Les Picots V.4
//
//  Module 4 - Sprint 3 : Vue détail d'une technique AVEC ILLUSTRATIONS
//

import SwiftUI

struct TechniqueDetailView: View {
    
    let fiche: FicheTechnique
    
    @State private var etapeExpandedId: String? = nil
    
    private var accentColor: Color {
        switch fiche.categorie {
        case .montage: return .blue
        case .animation: return .orange
        case .strategie: return .green
        case .equipement: return .purple
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - En-tête avec badges
                
                VStack(alignment: .leading, spacing: 12) {
                    // Titre
                    Text(fiche.titre)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    // Badges
                    HStack(spacing: 12) {
                        Badge(
                            icon: iconForCategorie(fiche.categorie),
                            text: fiche.categorie.rawValue,
                            color: accentColor
                        )
                        Badge(
                            icon: iconForNiveau(fiche.niveauDifficulte),
                            text: fiche.niveauDifficulte.rawValue,
                            color: colorForNiveau(fiche.niveauDifficulte)
                        )
                        Badge(
                            icon: "clock.fill",
                            text: fiche.dureeApprentissage,
                            color: .gray
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // MARK: - 🆕 ILLUSTRATION PRINCIPALE
                
                if let illustrationNom = fiche.illustrationPrincipale {
                    IllustrationCard(
                        imageName: illustrationNom,
                        title: "Illustration principale",
                        accentColor: accentColor
                    )
                    .padding(.horizontal)
                }
                
                // MARK: - Description
                
                createSectionCard(title: "Description", icon: "doc.text.fill", color: accentColor) {
                    Text(fiche.description)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // MARK: - Matériel nécessaire
                
                createSectionCard(title: "Matériel nécessaire", icon: "wrench.and.screwdriver.fill", color: accentColor) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(Array(fiche.materielNecessaire.enumerated()), id: \.offset) { index, materiel in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(accentColor)
                                
                                Text(materiel)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
                
                // MARK: - Étapes détaillées (AVEC ILLUSTRATIONS)
                
                // MARK: - Étapes détaillées (VERSION CORRIGÉE)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "list.number")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(accentColor)
                        
                        Text("Étapes détaillées")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Text("\(fiche.etapesDetaillees.count) étapes")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentColor)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ForEach(fiche.etapesDetaillees) { etape in
                            EtapeCard(
                                etape: etape,
                                accentColor: accentColor,
                                isExpanded: etapeExpandedId == etape.id,
                                // ✅ UTILISER directement la propriété de l'étape
                                illustrationNom: etape.illustrationsEtapes,
                                onToggle: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        etapeExpandedId = (etapeExpandedId == etape.id) ? nil : etape.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                // MARK: - Conseils de pro
                
                createSectionCard(title: "Conseils de pro", icon: "lightbulb.fill", color: .yellow) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(fiche.conseilsPro.enumerated()), id: \.offset) { index, conseil in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                                
                                Text(conseil)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .background(Color.yellow.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - Erreurs courantes
                
                createSectionCard(title: "Erreurs courantes à éviter", icon: "exclamationmark.triangle.fill", color: .red) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(fiche.erreursCourantes.enumerated()), id: \.offset) { index, erreur in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                                
                                Text(erreur)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(12)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                
                // MARK: - Espèces concernées
                
                if !fiche.especesConcernees.isEmpty {
                    createSectionCard(title: "Espèces concernées", icon: "fish.fill", color: accentColor) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cette technique s'applique à \(fiche.especesConcernees.count) espèce\(fiche.especesConcernees.count > 1 ? "s" : "") :")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                ForEach(fiche.especesConcernees, id: \.self) { especeId in
                                    if let espece = trouverEspece(parId: especeId) {
                                        NavigationLink(destination: EspeceDetailView(espece: espece)) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "fish.fill")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(accentColor)
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(espece.nomCommun)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    
                                                    Text(espece.nomScientifique)
                                                        .font(.caption)
                                                        .italic()
                                                        .foregroundColor(.secondary)
                                                }
                                                
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.secondary)
                                            }
                                            .padding(12)
                                            .background(Color(.secondarySystemBackground))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                        }
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .navigationTitle(fiche.titre)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 🆕 Helper pour récupérer l'illustration d'une étape
    
    // MARK: - Helpers existants
    
    private func trouverEspece(parId id: String) -> EspeceInfo? {
        return EspecesDatabase.shared.especesTraine.first { espece in
            espece.identifiant == id
        }
    }
    
    private func iconForCategorie(_ categorie: CategorieTechnique) -> String {
        switch categorie {
        case .montage: return "link.circle.fill"
        case .animation: return "waveform.path"
        case .strategie: return "map.fill"
        case .equipement: return "wrench.and.screwdriver.fill"
        }
    }
    
    private func iconForNiveau(_ niveau: NiveauDifficulte) -> String {
        switch niveau {
        case .debutant: return "star.fill"
        case .intermediaire: return "star.leadinghalf.filled"
        case .avance: return "star.circle.fill"
        }
    }
    
    private func colorForNiveau(_ niveau: NiveauDifficulte) -> Color {
        switch niveau {
        case .debutant: return .green
        case .intermediaire: return .orange
        case .avance: return .red
        }
    }
}

// MARK: - 🆕 COMPOSANT ILLUSTRATION CARD

struct IllustrationCard: View {
    let imageName: String
    let title: String
    let accentColor: Color
    var showBorder: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Titre
            HStack {
                Image(systemName: "photo.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(accentColor)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            }
            
            // Image
            if UIImage(named: imageName) != nil {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(
                                showBorder ? accentColor.opacity(0.3) : Color.clear,
                                lineWidth: showBorder ? 2 : 0
                            )
                    )
            } else {
                // Placeholder si l'image n'existe pas
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Image non disponible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(imageName)
                        .font(.caption2)
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - COMPOSANTS EXISTANTS

struct Badge: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}

func createSectionCard<Content: View>(
    title: String,
    icon: String,
    color: Color,
    @ViewBuilder content: () -> Content
) -> some View {
    VStack(alignment: .leading, spacing: 12) {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        
        content()
    }
    .padding(16)
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    )
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(color.opacity(0.2), lineWidth: 1)
    )
    .padding(.horizontal)
}

// MARK: - 🆕 COMPOSANT ETAPE CARD AVEC ILLUSTRATION

struct EtapeCard: View {
    let etape: EtapeTechnique
    let accentColor: Color
    let isExpanded: Bool
    let illustrationNom: String?
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête cliquable
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Text("\(etape.ordre)")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(accentColor)
                        .clipShape(Circle())
                    
                    Text(etape.titre)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    // 🆕 Indicateur si illustration présente
                    if illustrationNom != nil {
                        Image(systemName: "photo.fill")
                            .font(.system(size: 10))
                            .foregroundColor(accentColor.opacity(0.6))
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(isExpanded ? 12 : 12, corners: isExpanded ? [.topLeft, .topRight] : .allCorners)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Contenu expansible
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Description
                    Text(etape.description)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // 🆕 ILLUSTRATION ÉTAPE
                    if let nomIllustration = illustrationNom,
                       UIImage(named: nomIllustration) != nil {
                        Image(nomIllustration)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(accentColor.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Conseil si présent
                    if let conseil = etape.conseil {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.yellow)
                            
                            Text(conseil)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(10)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(12)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
}

// Extensions existantes
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationView {
        TechniqueDetailView(fiche: TechniqueDatabase.shared.montageTraineSimple)
    }
}
