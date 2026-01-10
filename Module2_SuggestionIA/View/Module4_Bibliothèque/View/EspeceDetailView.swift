//
//  EspeceDetailView.swift
//  Go les Picots V.4
//
//  Module 4 - Vue détaillée espèce ENRICHIE
//  Affiche toutes les propriétés du modèle FICHES_PÉDAGOGIQUES
//
//  Created: 2026-01-02
//

import SwiftUI

struct EspeceDetailView: View {
    let espece: EspeceInfo
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Header avec images
                VStack(spacing: 16) {
                    // Photos (placeholder pour l'instant)
                    HStack(spacing: 12) {
                        // Photo réelle
                        if let photoNom = espece.photoNom {
                            Image(photoNom)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            placeholderImage(systemName: "photo", height: 180)
                        }
                        
                        // Illustration
                        if let illustrationNom = espece.illustrationNom {
                            Image(illustrationNom)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 180)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        } else {
                            placeholderImage(systemName: "fish.fill", height: 180)
                        }
                    }
                    
                    // Nom commun
                    Text(espece.nomCommun)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Nom scientifique + famille
                    VStack(spacing: 4) {
                        Text(espece.nomScientifique)
                            .font(.title3)
                            .italic()
                            .foregroundColor(.secondary)
                        
                        Text("Famille : \(espece.famille)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // MARK: - 🔍 IDENTIFICATION
                if espece.signesDistinctifs != nil || espece.descriptionPhysique != nil ||
                   espece.tailleMaxObservee != nil || espece.poidsMaxObserve != nil {
                    
                    SectionCard(icon: "🔍", title: "IDENTIFICATION") {
                        if let signes = espece.signesDistinctifs {
                            InfoRow(label: "Signes distinctifs", value: signes)
                        }
                        
                        if let description = espece.descriptionPhysique {
                            InfoRow(label: "Description", value: description)
                        }
                        
                        HStack(spacing: 16) {
                            if let tailleMax = espece.tailleMaxObservee {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Taille max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(tailleMax)) cm")
                                        .font(.headline)
                                }
                            }
                            
                            if let poidsMax = espece.poidsMaxObserve {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Poids max")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(poidsMax)) kg")
                                        .font(.headline)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - 🌊 HABITAT & COMPORTEMENT
                if espece.habitatDescription != nil || espece.comportementDetail != nil ||
                   !espece.zones.isEmpty {
                    
                    SectionCard(icon: "🌊", title: "HABITAT & COMPORTEMENT") {
                        if !espece.zones.isEmpty {
                            InfoRow(label: "Zones", value: espece.zones.map { $0.nom }.joined(separator: ", "))
                        }
                        
                        if espece.profondeurMin != espece.profondeurMax {
                            InfoRow(label: "Profondeur", value: "\(Int(espece.profondeurMin))-\(Int(espece.profondeurMax)) m")
                        }
                        
                        if let habitat = espece.habitatDescription {
                            InfoRow(label: "Habitat", value: habitat)
                        }
                        
                        if let comportement = espece.comportementDetail {
                            InfoRow(label: "Comportement", value: comportement)
                        }
                    }
                }
                
                // MARK: - 🎣 COMMENT PÊCHER
                if espece.techniquesDetail != nil || espece.leuresSpecifiques != nil ||
                   espece.appatsNaturels != nil || espece.meilleursHoraires != nil ||
                   espece.conditionsOptimales != nil || espece.momentsFavorables != nil {
                    
                    SectionCard(icon: "🎣", title: "COMMENT PÊCHER") {
                        if let techniques = espece.techniquesDetail {
                            InfoRow(label: "Techniques", value: techniques)
                        }
                        
                        if let leurres = espece.leuresSpecifiques, !leurres.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Leurres recommandés")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(leurres, id: \.self) { leurre in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(leurre)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if let appats = espece.appatsNaturels, !appats.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Appâts naturels")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                ForEach(appats, id: \.self) { appat in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                        Text(appat)
                                            .font(.body)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        if let horaires = espece.meilleursHoraires {
                            InfoRow(label: "Meilleurs moments", value: horaires)
                        } else if let moments = espece.momentsFavorables, !moments.isEmpty {
                            InfoRow(label: "Meilleurs moments", value: moments.map { $0.rawValue }.joined(separator: ", "))
                        }
                        
                        if let conditions = espece.conditionsOptimales {
                            InfoRow(label: "Conditions optimales", value: conditions)
                        }
                        
                        // Info traîne si disponible
                        if let traineInfo = espece.traineInfo {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Spécificités traîne")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                InfoRow(label: "Vitesse", value: "\(Int(traineInfo.vitesseMin))-\(Int(traineInfo.vitesseMax)) nœuds (optimal: \(Int(traineInfo.vitesseOptimale)) nd)")
                                InfoRow(label: "Profondeur leurre", value: traineInfo.profondeurNageOptimale)
                                InfoRow(label: "Taille leurre", value: "\(Int(traineInfo.tailleLeurreMin))-\(Int(traineInfo.tailleLeurreMax)) cm")
                                
                                if !traineInfo.couleursRecommandees.isEmpty {
                                    InfoRow(label: "Couleurs", value: traineInfo.couleursRecommandees.joined(separator: ", "))
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // MARK: - 🍽️ VALORISATION
                if espece.qualiteCulinaire != nil || espece.ciguateraDetail != nil {
                    
                    SectionCard(icon: "🍽️", title: "VALORISATION") {
                        if let qualite = espece.qualiteCulinaire {
                            InfoRow(label: "Qualité culinaire", value: qualite)
                        }
                        
                        // Risque ciguatera avec badge couleur
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Risque ciguatera")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                HStack(spacing: 8) {
                                    badgeCiguatera(risque: espece.risqueCiguatera)
                                    
                                    Text(espece.risqueCiguatera.rawValue)
                                        .font(.body)
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                        
                        if let ciguateraDetail = espece.ciguateraDetail {
                            InfoRow(label: "", value: ciguateraDetail)
                        }
                    }
                }
                
                // MARK: - ⚖️ RÉGLEMENTATION
                if espece.reglementationNC != nil || espece.tailleMinLegale != nil ||
                   espece.quotas != nil || espece.zonesInterdites != nil ||
                   espece.statutConservation != nil || espece.nePasPecher {
                    
                    SectionCard(icon: "⚖️", title: "RÉGLEMENTATION") {
                        if espece.nePasPecher {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("ESPÈCE PROTÉGÉE")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    
                                    if let raison = espece.raisonProtection {
                                        Text(raison)
                                            .font(.body)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        if let tailleMin = espece.tailleMinLegale {
                            InfoRow(label: "Taille minimale légale", value: "\(Int(tailleMin)) cm")
                        }
                        
                        if let reglementation = espece.reglementationNC {
                            InfoRow(label: "Réglementation NC", value: reglementation)
                        }
                        
                        if let quotas = espece.quotas {
                            InfoRow(label: "Quotas", value: quotas)
                        }
                        
                        if let zones = espece.zonesInterdites {
                            InfoRow(label: "Zones/périodes interdites", value: zones)
                        }
                        
                        if let statut = espece.statutConservation {
                            InfoRow(label: "Conservation", value: statut)
                        }
                    }
                }
                
                // MARK: - 💡 LE SAVIEZ-VOUS ?
                if let anecdote = espece.leSaviezVous {
                    SectionCard(icon: "💡", title: "LE SAVIEZ-VOUS ?") {
                        Text(anecdote)
                            .font(.body)
                            .lineSpacing(4)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 0.95, green: 0.98, blue: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle(espece.nomCommun)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Subviews
    
    private func placeholderImage(systemName: String, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.1))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(
                Image(systemName: systemName)
                    .font(.system(size: 40))
                    .foregroundColor(.gray.opacity(0.3))
            )
    }
    
    private func badgeCiguatera(risque: RisqueCiguatera) -> some View {
        let couleur: Color = {
            switch risque {
            case .aucun: return .green
            case .faible: return .blue
            case .modere: return .orange
            case .eleve: return .red
            case .treseleve: return .purple
            }
        }()
        
        return Circle()
            .fill(couleur)
            .frame(width: 12, height: 12)
    }
}

// MARK: - Composants réutilisables

struct SectionCard<Content: View>: View {
    let icon: String
    let title: String
    let content: Content
    
    init(icon: String, title: String, @ViewBuilder content: () -> Content) {
        self.icon = icon
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text(icon)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
            content
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EspeceDetailView(espece: EspecesDatabase.shared.especesTraine[0])
    }
}
