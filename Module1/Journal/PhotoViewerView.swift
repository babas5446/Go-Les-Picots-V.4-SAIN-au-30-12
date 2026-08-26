//
//  PhotoViewerView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Visualiseur plein écran partagé, destiné aux photos du Journal.
//
//  Conçu comme un composant neutre : il ne connaît ni la Prise, ni la Sortie,
//  ni le contexte SwiftData. Il reçoit une image et deux actions facultatives,
//  ce qui lui permet de servir aussi bien la photo du poisson que, plus tard,
//  la vignette de trace GPS.
//
//  Les deux actions sont optionnelles : un appelant qui ne passe rien obtient
//  un visualiseur en lecture seule.
//
//  Remplacement : le visualiseur se ferme d'abord, puis notifie l'appelant au
//  cycle d'exécution suivant. Fermer et présenter dans le même cycle laisse
//  SwiftUI ignorer la seconde présentation — c'est le mécanisme qui avait
//  produit les feuilles inertes de la session 5.
//

import SwiftUI

struct PhotoViewerView: View {

    // MARK: - Entrées

    let image: UIImage
    let titre: String
    var onRemplacer: (() -> Void)?
    var onSupprimer: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Zoom et déplacement

    @State private var echelle: CGFloat = 1
    @State private var echelleAncrage: CGFloat = 1
    @State private var decalage: CGSize = .zero
    @State private var decalageAncrage: CGSize = .zero

    // MARK: - Alerte

    @State private var afficherConfirmationSuppression: Bool = false

    // MARK: - Bornes

    private static let echelleMin: CGFloat = 1
    private static let echelleMax: CGFloat = 5

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            imageZoomable

            VStack {
                barreOutils
                Spacer()
            }
        }
        .statusBarHidden()
        .confirmationDialog(
            "Supprimer cette photo ?",
            isPresented: $afficherConfirmationSuppression,
            titleVisibility: .visible
        ) {
            Button("Supprimer", role: .destructive) {
                onSupprimer?()
                dismiss()
            }
            Button("Annuler", role: .cancel) { }
        } message: {
            Text("La suppression ne sera effective qu'à l'enregistrement du formulaire.")
        }
    }

    // MARK: - Image

    private var imageZoomable: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(echelle)
            .offset(decalage)
            .gesture(gestePincement.simultaneously(with: gesteDeplacement))
            .onTapGesture(count: 2) { basculerZoom() }
            .animation(.easeOut(duration: 0.2), value: echelle)
    }

    // MARK: - Gestes

    private var gestePincement: some Gesture {
        MagnifyGesture()
            .onChanged { valeur in
                let proposee = echelleAncrage * valeur.magnification
                echelle = min(max(proposee, Self.echelleMin), Self.echelleMax)
            }
            .onEnded { _ in
                echelleAncrage = echelle
                if echelle <= Self.echelleMin {
                    reinitialiser()
                }
            }
    }

    /// Le déplacement n'a de sens qu'une fois l'image agrandie : à l'échelle 1,
    /// le glissement resterait sans effet visible et parasiterait le geste de
    /// fermeture attendu par l'utilisateur.
    private var gesteDeplacement: some Gesture {
        DragGesture()
            .onChanged { valeur in
                guard echelle > Self.echelleMin else { return }
                decalage = CGSize(
                    width:  decalageAncrage.width  + valeur.translation.width,
                    height: decalageAncrage.height + valeur.translation.height
                )
            }
            .onEnded { _ in
                decalageAncrage = decalage
            }
    }

    private func basculerZoom() {
        if echelle > Self.echelleMin {
            reinitialiser()
        } else {
            echelle        = 2.5
            echelleAncrage = 2.5
        }
    }

    private func reinitialiser() {
        echelle         = Self.echelleMin
        echelleAncrage  = Self.echelleMin
        decalage        = .zero
        decalageAncrage = .zero
    }

    // MARK: - Barre d'outils

    private var barreOutils: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.black.opacity(0.45))
                    .clipShape(Circle())
            }

            Spacer()

            Text(titre)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            if onRemplacer != nil || onSupprimer != nil {
                Menu {
                    if onRemplacer != nil {
                        Button {
                            demanderRemplacement()
                        } label: {
                            Label("Remplacer la photo", systemImage: "arrow.triangle.2.circlepath")
                        }
                    }
                    if onSupprimer != nil {
                        Button(role: .destructive) {
                            afficherConfirmationSuppression = true
                        } label: {
                            Label("Supprimer la photo", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Circle())
                }
            } else {
                // Réserve la place du menu, pour que le titre reste centré.
                Color.clear
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Actions

    /// Fermeture d'abord, notification ensuite : l'appelant présentera son
    /// sélecteur au cycle suivant, sans concurrence avec la fermeture en cours.
    private func demanderRemplacement() {
        dismiss()
        Task { @MainActor in
            onRemplacer?()
        }
    }
}
