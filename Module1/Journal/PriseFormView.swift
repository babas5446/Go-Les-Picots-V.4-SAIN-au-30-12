//
//  PriseFormView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Formulaire de saisie d'une prise.
//
//  Modes :
//  - Création : init(viewModel:sortie:)
//  - Édition  : init(viewModel:sortie:prise:)
//
//  Pré-remplissage :
//  - Conditions depuis UserDefaults (dernière suggestion SuggestionIA)
//  - Position GPS actuelle si disponible
//  - Photo du leurre copiée depuis la boîte si leurreID sélectionné
//
//  V4.2 — Chantier photo :
//  - Appui sur la photo : agrandissement par PhotoViewerView, au lieu de
//    rouvrir le sélecteur. La photo servait d'étiquette au bouton, ce qui
//    rendait l'agrandissement impossible.
//  - Menu à deux entrées : prise de vue directe ou bibliothèque. Seule la
//    bibliothèque était accessible jusqu'ici.
//  - Suppression possible, différée : elle n'atteint l'objet persisté qu'à
//    la validation du formulaire, comme la photo elle-même.
//  - Une seule présentation plein écran, arbitrée par PresentationPhoto :
//    deux fullScreenCover sur un même nœud de vue s'annulent silencieusement.
//  - photoAffichee supprimé : photoPoissonImage est désormais l'unique
//    source de vérité pour la photo en cours de saisie.
//  - État `notes` supprimé : jamais affiché ni sauvegardé, redondant avec
//    les notes de la Sortie.
//
//  Requiert NSCameraUsageDescription dans les réglages du projet.
//

import SwiftUI
import SwiftData
import PhotosUI

struct PriseFormView: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Données

    private let sortie: Sortie
    private let prise: Prise?
    private let modeCreation: Bool

    // MARK: - Boîte à leurres (pour résolution leurreID)

    @Query private var tousLesLeurres: [Leurre]

    // MARK: - Champs du formulaire

    @State private var especeNom: String
    @State private var especeLibre: String
    @State private var tailleCm: String
    @State private var poidsKg: String
    @State private var relache: Bool
    @State private var leurreID: Int?
    @State private var leurreLibre: String

    // MARK: - Mode saisie leurre

    enum ModeLeurre { case boite, libre, aucun }
    @State private var modeLeurre: ModeLeurre

    // MARK: - Photos

    /// Photo du leurre, copiée de la boîte à la sélection.
    @State private var leurrePhotoData: Data?

    /// Photo du poisson en cours de saisie. Source unique tant que le
    /// formulaire n'est pas validé.
    @State private var photoPoissonImage: UIImage?

    /// Intention de suppression d'une photo déjà persistée. Un simple nil sur
    /// photoPoissonImage ne suffirait pas : il signifie aussi « aucune nouvelle
    /// photo choisie », ce qui laisserait l'ancienne en place.
    @State private var photoSupprimee: Bool = false

    /// Une seule présentation plein écran à la fois.
    private enum PresentationPhoto: Int, Identifiable {
        case visualiseur, appareil
        var id: Int { rawValue }
    }
    @State private var presentationPhoto: PresentationPhoto?

    @State private var afficherChoixPhoto: Bool = false
    @State private var afficherBibliotheque: Bool = false
    @State private var photoItem: PhotosPickerItem?

    // MARK: - Localisation

    @State private var latitude: Double?
    @State private var longitude: Double?

    // MARK: - Conditions

    @State private var conditions: ConditionsPeche?

    // MARK: - Navigation

    @State private var afficherLeurrePicker: Bool = false

    // MARK: - Alertes

    @State private var afficherEspeceLibre: Bool

    // MARK: - Init création

    init(viewModel: JournalViewModel, sortie: Sortie) {
        self.viewModel    = viewModel
        self.sortie       = sortie
        self.prise        = nil
        self.modeCreation = true

        _especeNom        = State(initialValue: "")
        _especeLibre      = State(initialValue: "")
        _tailleCm         = State(initialValue: "")
        _poidsKg          = State(initialValue: "")
        _relache          = State(initialValue: false)
        _leurreID         = State(initialValue: nil)
        _leurreLibre      = State(initialValue: "")
        _modeLeurre       = State(initialValue: .aucun)
        _leurrePhotoData  = State(initialValue: nil)
        _conditions       = State(initialValue: viewModel.dernieresConditions())
        _afficherEspeceLibre = State(initialValue: false)

        // GPS : on récupèrera la position depuis TraceGPSService
        _latitude  = State(initialValue: viewModel.traceGPS.dernierPoint?.latitude)
        _longitude = State(initialValue: viewModel.traceGPS.dernierPoint?.longitude)
    }

    // MARK: - Init édition

    init(viewModel: JournalViewModel, sortie: Sortie, prise: Prise) {
        self.viewModel    = viewModel
        self.sortie       = sortie
        self.prise        = prise
        self.modeCreation = false

        _especeNom        = State(initialValue: prise.especeNom)
        _especeLibre      = State(initialValue: prise.especeLibre ?? "")
        _tailleCm         = State(initialValue: prise.tailleCm.map { String(Int($0)) } ?? "")
        _poidsKg          = State(initialValue: prise.poidsKg.map { String(format: "%.1f", $0) } ?? "")
        _relache          = State(initialValue: prise.relache)
        _leurreID         = State(initialValue: prise.leurreID)
        _leurreLibre      = State(initialValue: prise.leurreLibre ?? "")
        _leurrePhotoData  = State(initialValue: prise.leurrePhotoData)
        _conditions       = State(initialValue: prise.conditions ?? viewModel.dernieresConditions())
        _afficherEspeceLibre = State(initialValue: prise.especeLibre != nil)
        _latitude         = State(initialValue: prise.latitude)
        _longitude        = State(initialValue: prise.longitude)

        if prise.leurreID != nil {
            _modeLeurre = State(initialValue: .boite)
        } else if !(prise.leurreLibre ?? "").isEmpty {
            _modeLeurre = State(initialValue: .libre)
        } else {
            _modeLeurre = State(initialValue: .aucun)
        }
    }

    // MARK: - Photo courante

    /// Arbitre les trois sources possibles, dans l'ordre de priorité :
    /// suppression demandée, nouvelle photo choisie, photo déjà persistée.
    private var photoCourante: UIImage? {
        if photoSupprimee { return nil }
        if let image = photoPoissonImage { return image }
        if let data = prise?.photoData { return UIImage(data: data) }
        return nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    sectionEspece
                    sectionMensurations
                    sectionLeurre
                    sectionConditions
                    sectionLocalisation
                    sectionPhoto

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(hex: "F5F5F5"))
            .navigationTitle(modeCreation ? "Nouvelle prise" : "Modifier la prise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") { sauvegarder() }
                        .fontWeight(.semibold)
                        .disabled(especeNom.isEmpty && especeLibre.isEmpty)
                }
            }
            .sheet(isPresented: $afficherLeurrePicker) {
                LeurrePickerView(selectionCourante: leurreID) { leurre in
                    if let leurre {
                        leurreID        = leurre.id
                        leurrePhotoData = leurre.photoData
                    } else {
                        leurreID        = nil
                        leurrePhotoData = nil
                    }
                }
            }
            .fullScreenCover(item: $presentationPhoto) { presentation in
                switch presentation {

                case .visualiseur:
                    if let image = photoCourante {
                        PhotoViewerView(
                            image: image,
                            titre: "Photo du poisson",
                            onRemplacer: { afficherChoixPhoto = true },
                            onSupprimer: { supprimerPhoto() }
                        )
                    }

                case .appareil:
                    AppareilPhotoPicker { image in
                        if let image {
                            photoPoissonImage = image
                            photoSupprimee    = false
                        }
                    }
                    .ignoresSafeArea()
                }
            }
            .photosPicker(
                isPresented: $afficherBibliotheque,
                selection: $photoItem,
                matching: .images
            )
            .confirmationDialog(
                "Photo du poisson",
                isPresented: $afficherChoixPhoto,
                titleVisibility: .visible
            ) {
                Button("Prendre une photo") { presentationPhoto = .appareil }
                Button("Choisir dans la bibliothèque") { afficherBibliotheque = true }
                Button("Annuler", role: .cancel) { }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photoPoissonImage = uiImage
                        photoSupprimee    = false
                    }
                }
            }
            .onChange(of: photoItem) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photoPoissonImage = uiImage
                        photoSupprimee    = false
                    }
                }
            }
            .onAppear {
                print("▶︎ \(NouvelleSortieView.horodatage()) PFV APPEAR — sortie supprimée \(sortie.isDeleted)")
            }
            .onDisappear {
                print("◀︎ \(NouvelleSortieView.horodatage()) PFV DISAPPEAR — sortie supprimée \(sortie.isDeleted)")
            }
        }
    }

    // MARK: - Section espèce

    private var sectionEspece: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Picker espèce depuis enum
            VStack(alignment: .leading, spacing: 6) {
                Text("Espèce")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Picker("Espèce", selection: $especeNom) {
                    Text("Sélectionner…").tag("")
                    ForEach(Espece.allCases, id: \.self) { espece in
                        Text(espece.displayName).tag(espece.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: especeNom) { _, _ in
                    afficherEspeceLibre = false
                    especeLibre = ""
                }
            }

            // Option espèce libre
            Toggle(isOn: $afficherEspeceLibre) {
                Text("Espèce hors liste")
                    .font(.subheadline)
            }
            .tint(Color(hex: "0277BD"))
            .onChange(of: afficherEspeceLibre) { _, val in
                if val { especeNom = "" }
            }

            if afficherEspeceLibre {
                TextField("Nom de l'espèce", text: $especeLibre)
                    .textFieldStyle(.roundedBorder)
            }

            // Relâché
            Toggle(isOn: $relache) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.left.circle")
                        .foregroundColor(.green)
                    Text("Poisson relâché")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .tint(.green)
        }
        .carteJournal(titre: "Espèce", icone: "fish.fill")
    }

    // MARK: - Section mensurations

    private var sectionMensurations: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Taille (cm)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Ex : 65", text: $tailleCm)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Poids (kg)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Ex : 2.4", text: $poidsKg)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.decimalPad)
            }
        }
        .carteJournal(titre: "Mensurations", icone: "ruler")
    }

    // MARK: - Section leurre

    /// Leurre de la boîte correspondant à leurreID, s'il existe encore.
    private var leurreResolu: Leurre? {
        guard let id = leurreID else { return nil }
        return tousLesLeurres.first { $0.id == id }
    }

    private var sectionLeurre: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Sélecteur de mode
            Picker("Mode leurre", selection: $modeLeurre) {
                Text("Aucun").tag(ModeLeurre.aucun)
                Text("Depuis la boîte").tag(ModeLeurre.boite)
                Text("Saisie libre").tag(ModeLeurre.libre)
            }
            .pickerStyle(.segmented)

            switch modeLeurre {

            case .aucun:
                Text("Aucun leurre associé à cette prise.")
                    .font(.caption)
                    .foregroundColor(.secondary)

            case .boite:
                VStack(alignment: .leading, spacing: 10) {

                    if let leurre = leurreResolu {
                        carteLeurre(leurre)
                    } else if let data = leurrePhotoData, let uiImage = UIImage(data: data) {
                        // Leurre retiré de la boîte : la photo copiée dans la prise subsiste
                        carteLeurreOrphelin(image: uiImage)
                    }

                    Button {
                        afficherLeurrePicker = true
                    } label: {
                        Label(
                            leurreID == nil ? "Choisir un leurre" : "Changer de leurre",
                            systemImage: "square.grid.2x2"
                        )
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0277BD").opacity(0.12))
                        .foregroundColor(Color(hex: "0277BD"))
                        .cornerRadius(10)
                    }
                }

            case .libre:
                VStack(alignment: .leading, spacing: 6) {
                    Text("Nom du leurre")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    TextField("Ex : Rapala CD11 Mackerel", text: $leurreLibre)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .carteJournal(titre: "Leurre utilisé", icone: "lasso")
    }

    // MARK: - Carte du leurre sélectionné

    private func carteLeurre(_ leurre: Leurre) -> some View {
        HStack(spacing: 12) {
            if let data = leurre.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "fish")
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(leurre.nom)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(leurre.marque)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(leurre.descriptionCouleurs) · \(Int(leurre.longueur)) cm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(10)
    }

    private func carteLeurreOrphelin(image: UIImage) -> some View {
        HStack(spacing: 12) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text("Leurre n° \(leurreID ?? 0)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("Retiré de la boîte")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(10)
    }

    // MARK: - Section conditions

    private var sectionConditions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let c = conditions {
                ConditionsResumeBadges(conditions: c)
            } else {
                Text("Aucune condition disponible.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button {
                conditions = viewModel.dernieresConditions()
            } label: {
                Label("Actualiser depuis Suggestion IA", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .carteJournal(titre: "Conditions au moment de la prise", icone: "cloud.sun")
    }

    // MARK: - Section localisation

    private var sectionLocalisation: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let lat = latitude, let lon = longitude {
                HStack(spacing: 6) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(String(format: "%.5f, %.5f", lat, lon))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "location.slash")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    Text("Position GPS non disponible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Button {
                latitude  = viewModel.traceGPS.dernierPoint?.latitude
                longitude = viewModel.traceGPS.dernierPoint?.longitude
            } label: {
                Label("Utiliser la position actuelle", systemImage: "location.circle")
                    .font(.caption)
                    .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .carteJournal(titre: "Localisation", icone: "location.fill")
    }

    // MARK: - Section photo poisson

    /// Le geste change de sens selon l'état : sans photo, le bouton ouvre le
    /// menu de saisie ; avec photo, il ouvre le visualiseur, d'où partent le
    /// remplacement et la suppression.
    private var sectionPhoto: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                if photoCourante != nil {
                    presentationPhoto = .visualiseur
                } else {
                    afficherChoixPhoto = true
                }
            } label: {
                if let image = photoCourante {
                    ZStack(alignment: .bottomTrailing) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 160)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.45))
                            .clipShape(Circle())
                            .padding(8)
                    }
                } else {
                    HStack {
                        Image(systemName: "camera")
                        Text("Ajouter une photo du poisson")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(hex: "F5F5F5"))
                    .foregroundColor(.secondary)
                    .cornerRadius(10)
                }
            }

            if photoCourante != nil {
                Text("Appuyez sur la photo pour l'agrandir.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .carteJournal(titre: "Photo du poisson", icone: "camera.fill")
    }

    // MARK: - Actions photo

    /// La suppression n'atteint l'objet persisté qu'à la validation : tant que
    /// le formulaire n'est pas enregistré, un abandon laisse la photo intacte.
    private func supprimerPhoto() {
        photoPoissonImage = nil
        photoItem         = nil
        photoSupprimee    = true
    }

    // MARK: - Sauvegarde

    private func sauvegarder() {
        let nomEspece = afficherEspeceLibre ? "" : especeNom
        let libre     = afficherEspeceLibre ? especeLibre : nil

        let taille = Double(tailleCm.replacingOccurrences(of: ",", with: "."))
        let poids  = Double(poidsKg.replacingOccurrences(of: ",", with: "."))

        let leurreIDFinal     = modeLeurre == .boite ? leurreID : nil
        let leurreLibreFinal  = modeLeurre == .libre ? (leurreLibre.isEmpty ? nil : leurreLibre) : nil
        let leurrePhotoFinale = modeLeurre == .boite ? leurrePhotoData : nil

        if modeCreation {
            let nouvelle = viewModel.ajouterPrise(
                a:               sortie,
                especeNom:       nomEspece,
                especeLibre:     libre,
                tailleCm:        taille,
                poidsKg:         poids,
                relache:         relache,
                leurreID:        leurreIDFinal,
                leurreLibre:     leurreLibreFinal,
                leurrePhotoData: leurrePhotoFinale,
                latitude:        latitude,
                longitude:       longitude,
                photoData:       nil
            )

            if let image = photoPoissonImage, !photoSupprimee {
                viewModel.sauvegarderPhotoPrise(image: image, pourPrise: nouvelle)
            }

        } else if let p = prise {
            p.especeNom       = nomEspece
            p.especeLibre     = libre
            p.tailleCm        = taille
            p.poidsKg         = poids
            p.relache         = relache
            p.leurreID        = leurreIDFinal
            p.leurreLibre     = leurreLibreFinal
            p.leurrePhotoData = leurrePhotoFinale
            p.latitude        = latitude
            p.longitude       = longitude
            p.conditions      = conditions

            // La suppression précède l'éventuel remplacement : une photo
            // supprimée puis reprise ne doit pas laisser l'ancienne en place.
            if photoSupprimee {
                p.photoData = nil
            }

            viewModel.modifierPrise(p)

            if let image = photoPoissonImage, !photoSupprimee {
                viewModel.sauvegarderPhotoPrise(image: image, pourPrise: p)
            }
        }

        dismiss()
    }
}
