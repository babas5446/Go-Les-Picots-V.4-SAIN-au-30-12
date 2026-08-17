//
//  JournalView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Liste des sorties de pêche.
//
//  - @Query SwiftData pour la liste des sorties
//  - Navigation vers NouvelleSortieView (création / édition)
//  - Swipe to delete
//  - Badge "En cours" si une sortie est active
//

import SwiftUI
import SwiftData

struct JournalView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel = JournalViewModel()

    // MARK: - SwiftData

    @Query(sort: \Sortie.date, order: .reverse)
    private var sorties: [Sortie]

    @Environment(\.modelContext) private var context

    // MARK: - Navigation

    @State private var afficherNouvelleSortie: Bool = false
    @State private var sortieSelectionnee: Sortie?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if sorties.isEmpty {
                    vueVide
                } else {
                    listeSorties
                }
            }
            .navigationTitle("Journal de pêche")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        afficherNouvelleSortie = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $afficherNouvelleSortie) {
                NouvelleSortieView(viewModel: viewModel)
            }
            .sheet(item: $sortieSelectionnee) { sortie in
                NouvelleSortieView(viewModel: viewModel, sortie: sortie)
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Erreur inconnue")
            }
        }
    }

    // MARK: - Liste

    private var listeSorties: some View {
        List {
            ForEach(sorties) { sortie in
                SortieCellule(sortie: sortie, enCours: viewModel.sortieEnCours?.id == sortie.id)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sortieSelectionnee = sortie
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .onDelete { indices in
                viewModel.supprimerSorties(indices, dans: sorties)
            }
        }
        .listStyle(.plain)
        .background(Color(hex: "F5F5F5"))
    }

    // MARK: - Vue vide

    private var vueVide: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "0277BD").opacity(0.4))

            VStack(spacing: 8) {
                Text("Aucune sortie enregistrée")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Appuyez sur + pour créer votre première sortie.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                afficherNouvelleSortie = true
            } label: {
                Label("Nouvelle sortie", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "0277BD"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F5"))
    }
}

// MARK: - Cellule de sortie

struct SortieCellule: View {

    let sortie: Sortie
    let enCours: Bool

    private var dateFormatee: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale    = Locale(identifier: "fr_FR")
        return f.string(from: sortie.date)
    }

    var body: some View {
        HStack(spacing: 12) {

            // Indicateur couleur
            RoundedRectangle(cornerRadius: 3)
                .fill(enCours ? Color.green : Color(hex: "0277BD"))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {

                // Ligne 1 : spot + badge en cours
                HStack {
                    Text(sortie.nomSpot.isEmpty ? "Sortie sans nom" : sortie.nomSpot)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if enCours {
                        Text("EN COURS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green)
                            .cornerRadius(4)
                    }

                    Spacer()

                    // Nombre de prises
                    if !sortie.prises.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "fish.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FFBC42"))
                            Text("\(sortie.prises.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FFBC42"))
                        }
                    }
                }

                // Ligne 2 : date
                Text(dateFormatee)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Ligne 3 : durée + points GPS
                HStack(spacing: 12) {
                    if let duree = sortie.dureeFormatee {
                        Label(duree, systemImage: "clock")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !sortie.pointsGPS.isEmpty {
                        Label("\(sortie.pointsGPS.count) pts GPS", systemImage: "location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if !sortie.notes.isEmpty {
                        Image(systemName: "note.text")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
