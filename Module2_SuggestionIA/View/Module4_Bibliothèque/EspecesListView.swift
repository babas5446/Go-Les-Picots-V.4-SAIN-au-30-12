//
//  EspecesListView.swift
//  Go Les Picots V.4
//
//  Module 4 : Section "Bibliothèque d'espèces"
//  (Anciennement BibliothequeView.swift - renommé et enrichi)
//
//  Created by LANES Sebastien on 02/01/2026.
//

import SwiftUI

struct EspecesListView: View {
    
    @State private var searchText = ""
    @State private var showFiltres = false
    
    // Filtres cumulatifs
    @State private var filtreZones: Set<Zone> = []
    @State private var filtreTechniques: Set<TypePeche> = []
    @State private var filtreCiguatera: Set<RisqueCiguatera> = []
    @State private var filtreFamilles: Set<String> = []
    
    private let database = EspecesDatabase.shared
    
    // MARK: - Computed Properties
    
    private var especesFiltrees: [EspeceInfo] {
        var especes = database.especesTraine
        
        // Filtre zones (si au moins une sélectionnée)
        if !filtreZones.isEmpty {
            especes = especes.filter { espece in
                !Set(espece.zones).isDisjoint(with: filtreZones)
            }
        }
        
        // Filtre techniques (si au moins une sélectionnée)
        if !filtreTechniques.isEmpty {
            especes = especes.filter { espece in
                !Set(espece.typesPecheCompatibles).isDisjoint(with: filtreTechniques)
            }
        }
        
        // Filtre ciguatera (si au moins un niveau sélectionné)
        if !filtreCiguatera.isEmpty {
            especes = especes.filter { espece in
                filtreCiguatera.contains(espece.risqueCiguatera)
            }
        }
        
        // Filtre familles (si au moins une sélectionnée)
        if !filtreFamilles.isEmpty {
            especes = especes.filter { espece in
                filtreFamilles.contains(espece.famille)
            }
        }
        
        // Recherche textuelle
        if !searchText.isEmpty {
            let recherche = searchText.lowercased()
            especes = especes.filter {
                $0.nomCommun.lowercased().contains(recherche) ||
                $0.nomScientifique.lowercased().contains(recherche)
            }
        }
        
        return especes.sorted { $0.nomCommun < $1.nomCommun }
    }
    
    private var filtresActifs: Bool {
        !filtreZones.isEmpty ||
        !filtreTechniques.isEmpty ||
        !filtreCiguatera.isEmpty ||
        !filtreFamilles.isEmpty
    }
    
    private var nombreFiltres: Int {
        filtreZones.count +
        filtreTechniques.count +
        filtreCiguatera.count +
        filtreFamilles.count
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Banner Espèces
            BannerView(
                iconName: "Bibliotheque2_icon",
                title: "Bibliothèque d'espèces",
                subtitle: "Identification, habitat et techniques de pêche",
                accentColor: Color.blue
            )
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            // Liste des espèces
            List {
                ForEach(especesFiltrees) { espece in
                    NavigationLink {
                        EspeceDetailView(espece: espece)
                    } label: {
                        EspeceCardView(espece: espece)
                    }
                }
                
                if especesFiltrees.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("Aucune espèce trouvée")
                            .font(.headline)
                        
                        Text("Essayez de modifier vos critères de recherche")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                    .listRowBackground(Color.clear)
                }
            }
            .searchable(text: $searchText, prompt: "Rechercher une espèce")
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showFiltres = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: filtresActifs ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            .foregroundColor(filtresActifs ? .orange : .blue)
                        
                        if nombreFiltres > 0 {
                            Text("\(nombreFiltres)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(filtresActifs ? .orange : .blue)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showFiltres) {
            FiltresEspecesSheet(
                filtreZones: $filtreZones,
                filtreTechniques: $filtreTechniques,
                filtreCiguatera: $filtreCiguatera,
                filtreFamilles: $filtreFamilles
            )
        }
    }
}

// MARK: - Subviews (EN DEHORS de EspecesListView)

/// Carte espèce avec badges visuels
struct EspeceCardView: View {
    let espece: EspeceInfo
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Miniature (placeholder pour l'instant - photos à fournir)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.blue.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "fish.fill")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.3))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                // Nom commun
                Text(espece.nomCommun)
                    .font(.headline)
                
                // Nom scientifique
                Text(espece.nomScientifique)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                
                // Badges
                HStack(spacing: 6) {
                    // Badge ciguatera
                    BadgeCiguatera(risque: espece.risqueCiguatera)
                    
                    // Badge zone principale
                    if let zonePrincipale = espece.zones.first {
                        BadgeZone(zone: zonePrincipale)
                    }
                    
                    // Badge technique privilégiée
                    if espece.estPechableEnTraine {
                        BadgeTechnique(technique: .traine)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badges (EN DEHORS de EspecesListView)

/// Badge risque ciguatera avec code couleur
struct BadgeCiguatera: View {
    let risque: RisqueCiguatera
    
    private var couleur: Color {
        switch risque {
        case .aucun: return .green
        case .faible: return .blue
        case .modere: return .orange
        case .eleve: return .red
        case .treseleve: return .purple
        }
    }
    
    var body: some View {
        Image("Ciguatera_icone")
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(couleur.opacity(0.15))
            .cornerRadius(4)
    }
}

/// Badge zone de pêche
struct BadgeZone: View {
    let zone: Zone
    
    var body: some View {
        Text(zone.icon)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.15))
            .foregroundColor(.blue)
            .cornerRadius(4)
    }
}

/// Badge technique de pêche
struct BadgeTechnique: View {
    let technique: TypePeche
    
    var body: some View {
        Text(technique.icon)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.orange.opacity(0.15))
            .foregroundColor(.orange)
            .cornerRadius(4)
    }
}

// MARK: - Sheet Filtres (EN DEHORS de EspecesListView)

/// Sheet modale pour sélectionner les filtres cumulatifs
struct FiltresEspecesSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @Binding var filtreZones: Set<Zone>
    @Binding var filtreTechniques: Set<TypePeche>
    @Binding var filtreCiguatera: Set<RisqueCiguatera>
    @Binding var filtreFamilles: Set<String>
    
    private let database = EspecesDatabase.shared
    
    // Liste dynamique des familles présentes dans la base
    private var famillesDisponibles: [String] {
        let familles = Set(database.especesTraine.map { $0.famille })
        return familles.sorted()
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Section Zones
                Section("Zones de pêche") {
                    ForEach(Zone.allCases, id: \.self) { zone in
                        MultipleSelectionRow(
                            title: zone.nom,
                            isSelected: filtreZones.contains(zone)
                        ) {
                            if filtreZones.contains(zone) {
                                filtreZones.remove(zone)
                            } else {
                                filtreZones.insert(zone)
                            }
                        }
                    }
                }
                
                // Section Techniques
                Section("Techniques de pêche") {
                    ForEach(TypePeche.allCases, id: \.self) { technique in
                        MultipleSelectionRow(
                            title: technique.nom,
                            isSelected: filtreTechniques.contains(technique)
                        ) {
                            if filtreTechniques.contains(technique) {
                                filtreTechniques.remove(technique)
                            } else {
                                filtreTechniques.insert(technique)
                            }
                        }
                    }
                }
                
                // Section Ciguatera
                Section("Risque ciguatera") {
                    ForEach(RisqueCiguatera.allCases, id: \.self) { risque in
                        MultipleSelectionRow(
                            title: risque.rawValue,
                            isSelected: filtreCiguatera.contains(risque)
                        ) {
                            if filtreCiguatera.contains(risque) {
                                filtreCiguatera.remove(risque)
                            } else {
                                filtreCiguatera.insert(risque)
                            }
                        }
                    }
                }
                
                // Section Familles
                Section("Familles") {
                    ForEach(famillesDisponibles, id: \.self) { famille in
                        MultipleSelectionRow(
                            title: famille,
                            isSelected: filtreFamilles.contains(famille)
                        ) {
                            if filtreFamilles.contains(famille) {
                                filtreFamilles.remove(famille)
                            } else {
                                filtreFamilles.insert(famille)
                            }
                        }
                    }
                }
                
                // Section Actions
                Section {
                    Button(action: reinitialiserFiltres) {
                        HStack {
                            Spacer()
                            Text("Réinitialiser les filtres")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Filtres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Terminé") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func reinitialiserFiltres() {
        filtreZones.removeAll()
        filtreTechniques.removeAll()
        filtreCiguatera.removeAll()
        filtreFamilles.removeAll()
    }
}

/// Ligne de sélection multiple avec checkmark
struct MultipleSelectionRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.orange)
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EspecesListView()
    }
}
