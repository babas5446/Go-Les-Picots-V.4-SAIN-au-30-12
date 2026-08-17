//
//  NouvelleSortieView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Formulaire de création et d'édition d'une sortie de pêche.
//
//  Modes :
//  - Création : init(viewModel:) — crée une Sortie vide pré-remplie
//  - Édition  : init(viewModel:sortie:) — édite une Sortie existante
//
//  Pré-remplissage :
//  - Conditions depuis UserDefaults (dernière suggestion SuggestionIA)
//  - Heure de départ = maintenant
//

import SwiftUI
import SwiftData
import PhotosUI
import Combine

struct NouvelleSortieView: View {

    // MARK: - ViewModel

    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Sortie en cours d'édition

    private let sortie: Sortie
    private let modeCreation: Bool

    // MARK: - Champs du formulaire

    @State private var nomSpot: String
    @State private var notes: String
    @State private var heureDepart: Date
    @State private var heureRetour: Date
    @State private var heureRetourActive: Bool
    @State private var conditions: ConditionsPeche?
    @State private var leurresSessionIDs: [Int]

    // MARK: - Photos

    @State private var photoItem: PhotosPickerItem?
    @State private var photoSpot: Image?

    // MARK: - Navigation

    @State private var afficherPriseForm: Bool = false
    @State private var afficherLeurresPicker: Bool = false
    @State private var priseAEditer: Prise?

    // MARK: - Chronomètre

    @State private var timerDisplay: String = "00:00:00"
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Init création

    init(viewModel: JournalViewModel) {
        self.viewModel    = viewModel
        self.modeCreation = true

        let nouvelleSortie = Sortie(
            date:       Date(),
            heureDepart: Date(),
            nomSpot:    ""
        )
        self.sortie = nouvelleSortie

        _nomSpot           = State(initialValue: "")
        _notes             = State(initialValue: "")
        _heureDepart       = State(initialValue: Date())
        _heureRetour       = State(initialValue: Date())
        _heureRetourActive = State(initialValue: false)
        _conditions        = State(initialValue: viewModel.dernieresConditions())
        _leurresSessionIDs = State(initialValue: [])
    }

    // MARK: - Init édition

    init(viewModel: JournalViewModel, sortie: Sortie) {
        self.viewModel    = viewModel
        self.modeCreation = false
        self.sortie       = sortie

        _nomSpot           = State(initialValue: sortie.nomSpot)
        _notes             = State(initialValue: sortie.notes)
        _heureDepart       = State(initialValue: sortie.heureDepart ?? sortie.date)
        _heureRetour       = State(initialValue: sortie.heureRetour ?? Date())
        _heureRetourActive = State(initialValue: sortie.heureRetour != nil)
        _conditions        = State(initialValue: sortie.conditions)
        _leurresSessionIDs = State(initialValue: sortie.leurresSessionIDs)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // Bouton démarrer / terminer
                    sectionCycleVie

                    // Informations générales
                    sectionInfos

                    // Conditions de pêche
                    sectionConditions

                    // Leurres de la session
                    sectionLeurres

                    // Prises
                    sectionPrises

                    // Notes
                    sectionNotes

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(hex: "F5F5F5"))
            .navigationTitle(modeCreation ? "Nouvelle sortie" : "Modifier la sortie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") { sauvegarder() }
                        .fontWeight(.semibold)
                }
            }
            .onReceive(timer) { _ in
                if viewModel.sortieEnCours?.id == sortie.id {
                    mettreAJourChrono()
                }
            }
            .sheet(isPresented: $afficherPriseForm) {
                PriseFormView(viewModel: viewModel, sortie: sortie)
            }
            .sheet(item: $priseAEditer) { prise in
                PriseFormView(viewModel: viewModel, sortie: sortie, prise: prise)
            }
        }
    }

    // MARK: - Section cycle de vie

    private var sectionCycleVie: some View {
        let enCours = viewModel.sortieEnCours?.id == sortie.id

        return VStack(spacing: 12) {
            Button {
                if enCours {
                    viewModel.terminerSortie(sortie)
                } else {
                    viewModel.demarrerSortie(sortie)
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: enCours ? "stop.circle.fill" : "play.circle.fill")
                        .font(.title2)
                    Text(enCours ? "Terminer la sortie" : "Démarrer la sortie")
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(enCours ? Color.red : Color.green)
                .foregroundColor(.white)
                .cornerRadius(14)
            }

            if enCours {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .foregroundColor(.green)
                    Text(timerDisplay)
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                .padding(.vertical, 4)
            }
        }
        .carteJournal(titre: "Sortie", icone: "boat.fill")
    }

    // MARK: - Section informations

    private var sectionInfos: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Nom du spot")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Ex : Passe de Boulari, DCP Tiaré…", text: $nomSpot)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Heure de départ")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                DatePicker("", selection: $heureDepart, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
            }

            VStack(alignment: .leading, spacing: 6) {
                Toggle(isOn: $heureRetourActive) {
                    Text("Heure de retour")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .tint(Color(hex: "0277BD"))

                if heureRetourActive {
                    DatePicker("", selection: $heureRetour, in: heureDepart..., displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }

            // Photo du spot
            sectionPhotoSpot
        }
        .carteJournal(titre: "Informations", icone: "info.circle.fill")
    }

    // MARK: - Photo spot

    private var sectionPhotoSpot: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo du spot")
                .font(.subheadline)
                .fontWeight(.semibold)

            PhotosPicker(selection: $photoItem, matching: .images) {
                if let photo = photoSpot {
                    photo
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if let data = sortie.photoSpotData,
                          let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    HStack {
                        Image(systemName: "camera")
                        Text("Ajouter une photo")
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(hex: "F5F5F5"))
                    .foregroundColor(.secondary)
                    .cornerRadius(10)
                }
            }
            .onChange(of: photoItem) { item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        photoSpot = Image(uiImage: uiImage)
                        viewModel.sauvegarderPhotoSpot(image: uiImage, pourSortie: sortie)
                    }
                }
            }
        }
    }

    // MARK: - Section conditions

    private var sectionConditions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let c = conditions {
                ConditionsResumeBadges(conditions: c)
            } else {
                Text("Aucune condition renseignée.\nLancez une suggestion dans le Module IA pour pré-remplir.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }

            Button {
                conditions = viewModel.dernieresConditions()
            } label: {
                Label("Actualiser depuis Suggestion IA", systemImage: "arrow.clockwise")
                    .font(.caption)
                    .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .carteJournal(titre: "Conditions", icone: "cloud.sun.fill")
    }

    // MARK: - Section leurres de la session

    private var sectionLeurres: some View {
        VStack(alignment: .leading, spacing: 12) {
            if leurresSessionIDs.isEmpty {
                Text("Aucun leurre sélectionné pour cette session.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(leurresSessionIDs, id: \.self) { id in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "0277BD"))
                        Text("Leurre #\(id)")
                            .font(.subheadline)
                        Spacer()
                        Button {
                            leurresSessionIDs.removeAll { $0 == id }
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Button {
                afficherLeurresPicker = true
            } label: {
                Label("Sélectionner les leurres", systemImage: "plus")
                    .font(.subheadline)
                    .foregroundColor(Color(hex: "0277BD"))
            }
        }
        .carteJournal(titre: "Leurres de la session", icone: "fish")
        // La vue de sélection des leurres sera implémentée avec BoiteView picker
    }

    // MARK: - Section prises

    private var sectionPrises: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sortie.prises.isEmpty {
                Text("Aucune prise enregistrée.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ForEach(sortie.prises.sorted { $0.heure < $1.heure }) { prise in
                    PriseCellule(prise: prise)
                        .onTapGesture { priseAEditer = prise }
                }
            }

            Button {
                afficherPriseForm = true
            } label: {
                Label("Ajouter une prise", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "FFBC42").opacity(0.15))
                    .foregroundColor(Color(hex: "FFBC42"))
                    .cornerRadius(10)
            }
        }
        .carteJournal(titre: "Prises", icone: "fish.fill")
    }

    // MARK: - Section notes

    private var sectionNotes: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $notes)
                .frame(minHeight: 100)
                .padding(6)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(8)
                .font(.body)
        }
        .carteJournal(titre: "Notes libres", icone: "note.text")
    }

    // MARK: - Actions

    private func sauvegarder() {
        sortie.nomSpot          = nomSpot
        sortie.notes            = notes
        sortie.heureDepart      = heureDepart
        sortie.heureRetour      = heureRetourActive ? heureRetour : nil
        sortie.conditions       = conditions
        sortie.leurresSessionIDs = leurresSessionIDs

        if modeCreation {
            context.insert(sortie)
        }

        viewModel.modifierSortie(sortie)
        dismiss()
    }

    private func mettreAJourChrono() {
        guard let depart = sortie.heureDepart else { return }
        let elapsed = Int(Date().timeIntervalSince(depart))
        let h = elapsed / 3600
        let m = (elapsed % 3600) / 60
        let s = elapsed % 60
        timerDisplay = String(format: "%02d:%02d:%02d", h, m, s)
    }
}

// MARK: - Résumé des conditions (badges)

struct ConditionsResumeBadges: View {
    let conditions: ConditionsPeche

    var body: some View {
        FlowLayout(spacing: 6) {
            BadgeCondition(texte: conditions.zone.displayName,       icone: "map")
            BadgeCondition(texte: conditions.etatMer.displayName,    icone: "water.waves")
            BadgeCondition(texte: conditions.typeMaree.displayName,  icone: "arrow.up.arrow.down")
            BadgeCondition(texte: conditions.turbiditeEau.displayName, icone: "eye")
            BadgeCondition(texte: conditions.momentJournee.displayName, icone: "sun.max")
            BadgeCondition(texte: conditions.phaseLunaire.displayName, icone: "moon")
        }
    }
}

struct BadgeCondition: View {
    let texte: String
    let icone: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icone)
                .font(.caption2)
            Text(texte)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(hex: "0277BD").opacity(0.1))
        .foregroundColor(Color(hex: "0277BD"))
        .cornerRadius(8)
    }
}

// MARK: - Cellule prise

struct PriseCellule: View {
    let prise: Prise

    private var heureFormatee: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.locale    = Locale(identifier: "fr_FR")
        return f.string(from: prise.heure)
    }

    var body: some View {
        HStack(spacing: 10) {
            // Photo leurre ou placeholder
            if let data = prise.leurrePhotoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "FFBC42").opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "fish")
                            .foregroundColor(Color(hex: "FFBC42"))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(prise.especeAffichee)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(prise.descriptionCourte)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(heureFormatee)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if prise.relache {
                    Text("Relâché")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
        }
        .padding(8)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(10)
    }
}


// MARK: - ViewModifier carte journal

struct CarteJournalModifier: ViewModifier {
    let titre: String
    let icone: String

    func body(content: Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icone)
                    .foregroundColor(Color(hex: "0277BD"))
                Text(titre)
                    .font(.headline)
                    .foregroundColor(Color(hex: "0277BD"))
            }
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

extension View {
    func carteJournal(titre: String, icone: String) -> some View {
        modifier(CarteJournalModifier(titre: titre, icone: icone))
    }
}
