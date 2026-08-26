//
//  LeurrePickerView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Sélecteur de leurre depuis la boîte, présenté en feuille modale.
//
//  Remplace le Picker menu textuel : beaucoup de leurres partagent le même
//  radical de nom, la photo est le seul critère d'identification fiable.
//
//  Architecture :
//  - @Query déclaré dans la vue (convention Module 1 / Journal)
//  - Ne connaît rien du Journal : renvoie le Leurre complet par callback,
//    l'appelant décide quoi en recopier (photoData notamment)
//  - onSelection(nil) = désélection explicite
//

import SwiftUI
import SwiftData

// MARK: - LeurrePickerView

struct LeurrePickerView: View {

    // MARK: - Données

    @Query(sort: \Leurre.nom) private var leurres: [Leurre]
    @Environment(\.dismiss) private var dismiss

    // MARK: - Paramètres

    /// Identifiant du leurre déjà sélectionné, pour afficher la coche.
    let selectionCourante: Int?

    /// Callback de sélection. nil signifie « aucun leurre ».
    let onSelection: (Leurre?) -> Void

    // MARK: - Recherche

    @State private var recherche: String = ""

    private var leurresFiltres: [Leurre] {
        let texte = recherche.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !texte.isEmpty else { return leurres }
        return leurres.filter { leurre in
            leurre.nom.localizedStandardContains(texte)
            || leurre.marque.localizedStandardContains(texte)
            || (leurre.modele?.localizedStandardContains(texte) ?? false)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {

                // Désélection
                Section {
                    Button {
                        onSelection(nil)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: "F5F5F5"))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "nosign")
                                        .foregroundColor(.secondary)
                                )
                            Text("Aucun leurre")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectionCourante == nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Color(hex: "0277BD"))
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Liste des leurres
                Section {
                    if leurresFiltres.isEmpty {
                        Text("Aucun leurre ne correspond à cette recherche.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 12)
                    } else {
                        ForEach(leurresFiltres) { leurre in
                            Button {
                                onSelection(leurre)
                                dismiss()
                            } label: {
                                LeurrePickerLigne(
                                    leurre: leurre,
                                    estSelectionne: leurre.id == selectionCourante
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text(leurresFiltres.count > 1
                         ? "\(leurresFiltres.count) leurres"
                         : "\(leurresFiltres.count) leurre")
                }
            }
            .listStyle(.insetGrouped)
            .searchable(text: $recherche, prompt: "Nom, marque ou modèle")
            .navigationTitle("Choisir un leurre")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Ligne de la liste

struct LeurrePickerLigne: View {

    let leurre: Leurre
    let estSelectionne: Bool

    var body: some View {
        HStack(spacing: 12) {

            miniature

            VStack(alignment: .leading, spacing: 3) {
                Text(leurre.nom)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(sousTitre)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    pastilleCouleur
                    Text(leurre.descriptionCouleurs)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 6) {
                Text("\(Int(leurre.longueur)) cm")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if estSelectionne {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: "0277BD"))
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    // MARK: - Sous-titre

    private var sousTitre: String {
        if let modele = leurre.modele, !modele.isEmpty {
            return "\(leurre.marque) — \(modele)"
        }
        return leurre.marque
    }

    // MARK: - Miniature

    @ViewBuilder
    private var miniature: some View {
        if let data = leurre.photoData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "F5F5F5"))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "fish")
                        .foregroundColor(.secondary)
                )
        }
    }

    // MARK: - Pastille de couleur

    private var pastilleCouleur: some View {
        let affichage = leurre.couleurPrincipaleAffichage
        let style: AnyShapeStyle = affichage.isRainbow
            ? AnyShapeStyle(
                AngularGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple, .red],
                    center: .center
                )
              )
            : AnyShapeStyle(affichage.color)

        return Circle()
            .fill(style)
            .frame(width: 10, height: 10)
            .overlay(
                Circle().stroke(Color.secondary.opacity(0.4), lineWidth: 0.5)
            )
    }
}
