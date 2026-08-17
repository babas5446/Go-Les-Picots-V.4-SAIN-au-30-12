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
    @State private var notes: String

    // MARK: - Mode saisie leurre

    enum ModeLeurre { case boite, libre, aucun }
    @State private var modeLeurre: ModeLeurre

    // MARK: - Photos

    @State private var photoPoisson: PhotosPickerItem?
    @State private var photoAffichee: Image?
    @State private var leurrePhotoData: Data?

    // MARK: - Localisation

    @State private var latitude: Double?
    @State private var longitude: Double?

    // MARK: - Conditions

    @State private var conditions: ConditionsPeche?

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
        _notes            = State(initialValue: "")
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
        _notes            = State(initialValue: "")
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
                .onChange(of: especeNom) { _ in
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
            .onChange(of: afficherEspeceLibre) { val in
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
                // Picker depuis la boîte à leurres
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Leurre", selection: $leurreID) {
                        Text("Sélectionner…").tag(nil as Int?)
                        ForEach(tousLesLeurres.sorted { $0.nom < $1.nom }) { leurre in
                            Text("\(leurre.nom) — \(leurre.marque)").tag(leurre.id as Int?)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: leurreID) { id in
                        if let id = id,
                           let leurre = tousLesLeurres.first(where: { $0.id == id }) {
                            leurrePhotoData = leurre.photoData
                        } else {
                            leurrePhotoData = nil
                        }
                    }

                    // Aperçu photo leurre
                    if let data = leurrePhotoData, let uiImage = UIImage(data: data) {
                        HStack(spacing: 10) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            if let id = leurreID,
                               let leurre = tousLesLeurres.first(where: { $0.id == id }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(leurre.nom)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                    Text(leurre.marque)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(Int(leurre.longueur)) cm")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(8)
                        .background(Color(hex: "F5F5F5"))
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

    private var sectionPhoto: some View {
        VStack(alignment: .leading, spacing: 8) {
            PhotosPicker(selection: $photoPoisson, matching: .images) {
                if let photo = photoAffichee {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let data = prise?.photoData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
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
            .onChange(of: photoPoisson) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photoAffichee = Image(uiImage: uiImage)
                        if let p = prise {
                            viewModel.sauvegarderPhotoPrise(image: uiImage, pourPrise: p)
                        }
                    }
                }
            }
        }
        .carteJournal(titre: "Photo du poisson", icone: "camera.fill")
    }

    // MARK: - Sauvegarde

    private func sauvegarder() {
        let nomEspece = afficherEspeceLibre ? "" : especeNom
        let libre     = afficherEspeceLibre ? especeLibre : nil

        let taille = Double(tailleCm)
        let poids  = Double(poidsKg.replacingOccurrences(of: ",", with: "."))

        let leurreIDFinal    = modeLeurre == .boite ? leurreID : nil
        let leurreLibreFinal = modeLeurre == .libre ? (leurreLibre.isEmpty ? nil : leurreLibre) : nil
        let photoDonnees: Data? = {
            if let item = photoPoisson,
               let data = try? Data(contentsOf: URL(string: "")!) {
                return data
            }
            return prise?.photoData
        }()

        if modeCreation {
            viewModel.ajouterPrise(
                a:               sortie,
                especeNom:       nomEspece,
                especeLibre:     libre,
                tailleCm:        taille,
                poidsKg:         poids,
                relache:         relache,
                leurreID:        leurreIDFinal,
                leurreLibre:     leurreLibreFinal,
                leurrePhotoData: leurrePhotoData,
                latitude:        latitude,
                longitude:       longitude,
                photoData:       nil
            )
        } else if let p = prise {
            p.especeNom       = nomEspece
            p.especeLibre     = libre
            p.tailleCm        = taille
            p.poidsKg         = poids
            p.relache         = relache
            p.leurreID        = leurreIDFinal
            p.leurreLibre     = leurreLibreFinal
            p.leurrePhotoData = leurrePhotoData
            p.latitude        = latitude
            p.longitude       = longitude
            p.conditions      = conditions
            viewModel.modifierPrise(p)
        }

        dismiss()
    }
}
