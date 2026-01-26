//
//  StatistiquesView.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 18/01/2026.
//
//  RUBRIQUE 4 : Statistiques - VERSION MINIMALISTE
//  Vue d'ensemble, stats par spot, par leurre, graphiques temporels
//

import SwiftUI

struct StatistiquesView: View {
    // MARK: - Properties
    @State private var selectedPeriod: StatPeriod = .month
    
    enum StatPeriod: String, CaseIterable {
        case week = "Semaine"
        case month = "Mois"
        case year = "Année"
        case all = "Tout"
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sélecteur période
                    periodSelector
                    
                    // Placeholder en attendant intégration
                    placeholderContent
                }
                .padding()
            }
            .navigationTitle("Statistiques")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - Period Selector
    private var periodSelector: some View {
        Picker("Période", selection: $selectedPeriod) {
            ForEach(StatPeriod.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Placeholder Content
    private var placeholderContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple)
            
            Text("Statistiques")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Contenu à venir")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                FeatureRowStats(icon: "chart.pie", text: "Vue d'ensemble : prises, sorties, distance")
                FeatureRowStats(icon: "mappin.circle", text: "Statistiques par spot")
                FeatureRowStats(icon: "camera.macro", text: "Statistiques par leurre")
                FeatureRowStats(icon: "chart.line.uptrend.xyaxis", text: "Graphiques temporels")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Exemple de chiffres clés (placeholder)
            statsGrid
        }
        .padding(.top, 40)
    }
    
    // MARK: - Stats Grid (placeholder data)
    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            StatCard(value: "0", label: "Sorties", color: .green)
            StatCard(value: "0", label: "Prises", color: .blue)
            StatCard(value: "0 km", label: "Distance", color: .orange)
            StatCard(value: "0", label: "Spots", color: .purple)
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRowStats: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Stat Card Component
struct StatCard: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    StatistiquesView()
}
