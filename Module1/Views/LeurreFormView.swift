//
//  LeurreFormView.swift
//  Go les Picots V.4 — Module 1
//
//  Formulaire unifié pour créer ou éditer un leurre.
//
//  V4 — Adaptations SwiftData :
//  - Init : photoPath → photoData (UIImage depuis Data)
//  - sauvegarder() : photoPath/sauvegarderPhoto/supprimerPhoto → leurre.photoData
//  - Finition.description → finition.conditionsIdeales (membre réservé)
//  - telechargerPhotoDepuisURL() : URLSession direct, sans LeurreStorageService
//  - Leurre init : photoPath supprimé, photoData ajouté
//

import SwiftUI
import PhotosUI

struct LeurreFormView: View {

    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BoiteLeurresViewModel

    // MARK: - Mode

    enum Mode {
        case creation
        case edition(Leurre)
        case duplication(Leurre)

        var titre: String {
            switch self {
            case .creation:    return "Nouveau leurre"
            case .edition:     return "Modifier le leurre"
            case .duplication: return "Dupliquer le leurre"
            }
        }

        var boutonAction: String {
            switch self {
            case .creation:    return "Ajouter"
            case .edition:     return "Enregistrer"
            case .duplication: return "Dupliquer"
            }
        }

        var isCreation: Bool { if case .creation = self { return true }; return false }
        var isDuplication: Bool { if case .duplication = self { return true }; return false }

        var leurreSource: Leurre? {
            switch self {
            case .edition(let l), .duplication(let l): return l
            case .creation: return nil
            }
        }
    }

    let mode: Mode

    // MARK: - État

    @State private var nom:    String = ""
    @State private var marque: String = ""
    @State private var modele: String = ""

    @State private var typeLeurre: TypeLeurre = .poissonNageur
    @State private var typePeche:  TypePeche  = .traine

    @State private var typesPecheCompatibles:   Set<TypePeche> = []
    @State private var showTechniquesCompatibles: Bool = false

    @State private var longueur: String = ""
    @State private var poids:    String = ""

    @State private var couleurPrincipale:       Couleur      = .bleuArgente
    @State private var couleurPrincipaleCustom: CouleurCustom? = nil
    @State private var couleurSecondaire:       Couleur?     = nil
    @State private var couleurSecondaireCustom: CouleurCustom? = nil
    @State private var hasCouleurSecondaire:    Bool         = false
    @State private var finitionSelectionnee:    Finition?    = nil

    @State private var typesDeNage:              [TypeDeNage] = []
    @State private var showWobblingChoice        = false
    @State private var showJiggingChoice         = false
    @State private var showTypeDeNagePicker      = false
    @State private var showTypeDeNageDescription: TypeDeNage? = nil

    @State private var profondeurMin: String = ""
    @State private var profondeurMax: String = ""
    @State private var vitesseMin:    String = ""
    @State private var vitesseMax:    String = ""

    @State private var notes:                    String       = ""
    @State private var detectedTypes:            [TypeDeNage] = []
    @State private var showTypeDetectionSuggestion = false
    @State private var hasIgnoredSuggestion        = false

    @State private var selectedImage:     UIImage? = nil
    @State private var photoURL:          String   = ""
    @State private var showImagePicker    = false
    @State private var showCamera         = false
    @State private var showURLInput       = false
    @State private var isDownloadingPhoto = false

    @State private var showImportURL      = false
    @State private var urlProduit:        String              = ""
    @State private var isExtractingInfos  = false
    @State private var infosExtraites:    LeurreInfosExtraites?

    @State private var showValidationError = false
    @State private var validationMessage   = ""

    // MARK: - Init

    init(viewModel: BoiteLeurresViewModel, mode: Mode) {
        self.viewModel = viewModel
        self.mode      = mode

        guard let leurre = mode.leurreSource else { return }

        let nomModifie = mode.isDuplication ? "\(leurre.nom) (copie)" : leurre.nom
        _nom    = State(initialValue: nomModifie)
        _marque = State(initialValue: leurre.marque)
        _modele = State(initialValue: leurre.modele ?? "")
        _typeLeurre = State(initialValue: leurre.typeLeurre)
        _typePeche  = State(initialValue: leurre.typePeche)

        let compatibles = leurre.typesPecheCompatibles ?? []
        _typesPecheCompatibles    = State(initialValue: Set(compatibles))
        _showTechniquesCompatibles = State(initialValue: !compatibles.isEmpty)

        _longueur = State(initialValue: String(format: "%.1f", leurre.longueur))
        _poids    = State(initialValue: leurre.poids.map { String(format: "%.0f", $0) } ?? "")

        _couleurPrincipale       = State(initialValue: leurre.couleurPrincipale)
        _couleurPrincipaleCustom = State(initialValue: leurre.couleurPrincipaleCustom)
        _couleurSecondaire       = State(initialValue: leurre.couleurSecondaire)
        _couleurSecondaireCustom = State(initialValue: leurre.couleurSecondaireCustom)
        _hasCouleurSecondaire    = State(initialValue: leurre.couleurSecondaire != nil || leurre.couleurSecondaireCustom != nil)
        _finitionSelectionnee    = State(initialValue: leurre.finition)
        _typesDeNage             = State(initialValue: leurre.typesDeNage ?? [])

        _profondeurMin = State(initialValue: leurre.profondeurNageMin.map { String(format: "%.1f", $0) } ?? "")
        _profondeurMax = State(initialValue: leurre.profondeurNageMax.map { String(format: "%.1f", $0) } ?? "")
        _vitesseMin    = State(initialValue: leurre.vitesseTraineMin.map  { String(format: "%.0f", $0) } ?? "")
        _vitesseMax    = State(initialValue: leurre.vitesseTraineMax.map  { String(format: "%.0f", $0) } ?? "")
        _notes         = State(initialValue: leurre.notes ?? "")

        // ✅ V4 : photo depuis photoData — plus de photoPath ni chargerPhoto()
        if let data = leurre.photoData, let image = UIImage(data: data) {
            _selectedImage = State(initialValue: image)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                if mode.isCreation { sectionImportURL }
                sectionPhoto
                sectionIdentification
                sectionType
                sectionTechniquesCompatibles
                sectionCaracteristiques
                sectionCouleurs
                sectionFinition
                if typePeche == .traine { sectionTraine }

                Section(header: Text("Types de nage (optionnel)")) {
                    Button {
                        showTypeDeNagePicker = true
                    } label: {
                        HStack {
                            Text("Types de nage").foregroundColor(.primary)
                            Spacer()
                            HStack(spacing: 4) {
                                Text(typesDeNage.isEmpty ? "Aucun" : "\(typesDeNage.count)/3")
                                    .foregroundColor(typesDeNage.isEmpty ? .secondary : Color(hex: "0277BD"))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2).foregroundColor(.secondary)
                            }
                        }
                    }

                    if !typesDeNage.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(typesDeNage, id: \.self) { type in
                                    typeBadge(for: type)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                sectionNotes
            }
            .navigationTitle(mode.titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.boutonAction) { validerEtSauvegarder() }
                        .disabled(!formulaireValide)
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePickerView(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showCamera) {
                ImagePickerView(image: $selectedImage, sourceType: .camera)
            }
            .alert("Erreur de validation", isPresented: $showValidationError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(validationMessage)
            }
            .alert("URL de l'image", isPresented: $showURLInput) {
                TextField("https://...", text: $photoURL)
                    .textInputAutocapitalization(.never).keyboardType(.URL)
                Button("Télécharger") { telechargerPhotoDepuisURL() }
                Button("Annuler", role: .cancel) { photoURL = "" }
            } message: {
                Text("Collez l'URL d'une image")
            }
            .alert("Importer depuis une page produit", isPresented: $showImportURL) {
                TextField("https://www.rapala.fr/...", text: $urlProduit)
                    .textInputAutocapitalization(.never).keyboardType(.URL)
                Button("Importer") { importerDepuisURL() }
                Button("Annuler", role: .cancel) { urlProduit = "" }
            } message: {
                Text("Collez l'URL de la page du leurre (Rapala, Pêcheur.com, Decathlon...)")
            }
            .sheet(isPresented: $showWobblingChoice) {
                WobblingChoiceSheet(selectedTypes: $typesDeNage)
            }
            .sheet(isPresented: $showTypeDeNagePicker) {
                TypeDeNagePickerSheet(
                    selectedTypes: $typesDeNage,
                    onWobblingTapped: {
                        showTypeDeNagePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showWobblingChoice = true }
                    },
                    onJiggingTapped: {
                        showTypeDeNagePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { showJiggingChoice = true }
                    }
                )
            }
            .sheet(isPresented: $showJiggingChoice) {
                JiggingChoiceSheet(selectedTypes: $typesDeNage)
            }
            .sheet(isPresented: Binding(
                get: { showTypeDeNageDescription != nil },
                set: { if !$0 { showTypeDeNageDescription = nil } }
            )) {
                if let type = showTypeDeNageDescription {
                    TypeDeNageDescriptionModal(typeDeNage: type)
                }
            }
        }
    }

    // MARK: - Type Badge

    private func typeBadge(for type: TypeDeNage) -> some View {
        HStack(spacing: 6) {
            Button { showTypeDeNageDescription = type } label: {
                Text(type.rawValue)
                    .font(.subheadline).foregroundColor(Color(hex: "0277BD"))
                    .padding(.leading, 12).padding(.vertical, 6)
            }
            Button {
                if let index = typesDeNage.firstIndex(of: type) {
                    withAnimation { typesDeNage.remove(at: index) }
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption).foregroundColor(.gray)
            }
            .padding(.trailing, 8)
        }
        .background(Color(hex: "E3F2FD"))
        .cornerRadius(16)
    }

    // MARK: - Section Import URL

    private var sectionImportURL: some View {
        Section {
            if !isExtractingInfos {
                Button { showImportURL = true } label: {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.title2).foregroundColor(Color(hex: "0277BD"))
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Importer depuis une page produit")
                                .font(.headline).foregroundColor(Color(hex: "0277BD"))
                            Text("Rapala, Pêcheur.com, Decathlon...")
                                .font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Extraction des informations...").foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: { Text("Gain de temps") } footer: {
            Text("L'app va extraire la marque, le nom et la description depuis la page produit.")
        }
    }

    // MARK: - Section Photo

    private var sectionPhoto: some View {
        Section {
            VStack(spacing: 12) {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable().scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                selectedImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2).foregroundStyle(.white, .red)
                            }
                            .padding(8)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2)).frame(height: 120)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray)
                                Text("Aucune photo").font(.caption).foregroundColor(.secondary)
                            }
                        }
                }

                if !isDownloadingPhoto {
                    HStack(spacing: 16) {
                        Button { showCamera = true } label: {
                            Label("Caméra", systemImage: "camera")
                        }.buttonStyle(.bordered)
                        Button { showImagePicker = true } label: {
                            Label("Galerie", systemImage: "photo.on.rectangle")
                        }.buttonStyle(.bordered)
                        Button { showURLInput = true } label: {
                            Label("URL", systemImage: "link")
                        }.buttonStyle(.bordered)
                    }
                    .font(.caption)
                } else {
                    ProgressView("Téléchargement...").padding()
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        } header: { Text("Photo") }
    }

    // MARK: - Section Identification

    private var sectionIdentification: some View {
        Section {
            TextField("Nom du leurre", text: $nom).textInputAutocapitalization(.words)
            TextField("Marque", text: $marque).textInputAutocapitalization(.words)
            TextField("Modèle (facultatif)", text: $modele).textInputAutocapitalization(.words)
        } header: { Text("Identification") } footer: {
            Text("Informations visibles sur l'emballage")
        }
    }

    // MARK: - Section Type

    private var sectionType: some View {
        Section {
            Picker("Type de pêche", selection: $typePeche) {
                ForEach(TypePeche.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }
            .onChange(of: typePeche) { newValue in
                if showTechniquesCompatibles { typesPecheCompatibles.insert(newValue) }
            }
            Picker("Type de leurre", selection: $typeLeurre) {
                ForEach(TypeLeurre.allCases, id: \.self) { type in
                    Text("\(type.icon) \(type.displayName)").tag(type)
                }
            }
        } header: { Text("Classification") }
    }

    // MARK: - Section Techniques compatibles

    private var sectionTechniquesCompatibles: some View {
        Section {
            Toggle(isOn: $showTechniquesCompatibles) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.badge.questionmark")
                        .foregroundColor(Color(hex: "FFBC42"))
                    Text("Techniques compatibles").fontWeight(.medium)
                }
            }
            .tint(Color(hex: "FFBC42"))
            .onChange(of: showTechniquesCompatibles) { newValue in
                if !newValue { typesPecheCompatibles.removeAll() }
                else { typesPecheCompatibles.insert(typePeche) }
            }

            if showTechniquesCompatibles {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sélectionnez toutes les techniques utilisables avec ce leurre")
                        .font(.caption).foregroundColor(.secondary)
                    ForEach(TypePeche.allCases, id: \.self) { technique in
                        Toggle(isOn: Binding(
                            get: { typesPecheCompatibles.contains(technique) },
                            set: { isSelected in
                                if isSelected { typesPecheCompatibles.insert(technique) }
                                else if technique != typePeche { typesPecheCompatibles.remove(technique) }
                            }
                        )) {
                            HStack(spacing: 8) {
                                Image(systemName: technique.icon)
                                    .foregroundColor(technique == typePeche ? Color(hex: "0277BD") : .secondary)
                                Text(technique.displayName)
                                    .foregroundColor(technique == typePeche ? Color(hex: "0277BD") : .primary)
                                if technique == typePeche {
                                    Text("(principale)").font(.caption).foregroundColor(Color(hex: "0277BD"))
                                }
                            }
                        }
                        .disabled(technique == typePeche)
                        .tint(Color(hex: "FFBC42"))
                    }
                }
            }
        } header: { Text("🔧 Polyvalence (Facultatif)") } footer: {
            if showTechniquesCompatibles {
                Text("La technique principale (\(typePeche.displayName)) est toujours incluse.")
            } else {
                Text("Activez pour indiquer si ce leurre peut être utilisé avec plusieurs techniques.")
            }
        }
    }

    // MARK: - Section Caractéristiques

    private var sectionCaracteristiques: some View {
        Section {
            HStack {
                Text("Longueur"); Spacer()
                TextField("cm", text: $longueur).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 80)
                Text("cm").foregroundColor(.secondary)
            }
            HStack {
                Text("Poids (facultatif)"); Spacer()
                TextField("g", text: $poids).keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing).frame(width: 80)
                Text("g").foregroundColor(.secondary)
            }
        } header: { Text("Caractéristiques") }
    }

    // MARK: - Section Couleurs

    private var sectionCouleurs: some View {
        Section {
            CouleurSearchField(
                couleurSelectionnee: $couleurPrincipale,
                couleurCustomSelectionnee: $couleurPrincipaleCustom,
                titre: "Couleur principale"
            ).padding(.vertical, 4)

            Toggle("Couleur secondaire", isOn: $hasCouleurSecondaire)

            if hasCouleurSecondaire {
                CouleurSearchField(
                    couleurSelectionnee: Binding(
                        get: { couleurSecondaire ?? .blanc },
                        set: { couleurSecondaire = $0 }
                    ),
                    couleurCustomSelectionnee: $couleurSecondaireCustom,
                    titre: "Couleur secondaire"
                ).padding(.vertical, 4)
            }
        } header: { Text("Couleurs") } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if let secondaire = hasCouleurSecondaire ? couleurSecondaire : nil {
                    Text("Contraste détecté : \(determinerContrastePrevisu(principale: couleurPrincipale, secondaire: secondaire).displayName)")
                } else {
                    Text("Contraste détecté : \(couleurPrincipale.contrasteNaturel.displayName)")
                }
                Text("💡 Tapez pour rechercher rapidement").font(.caption2).foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Section Finition

    private var sectionFinition: some View {
        Section {
            Picker("Finition", selection: $finitionSelectionnee) {
                Text("Non renseignée").tag(nil as Finition?)
                ForEach(Finition.allCases, id: \.self) { finition in
                    Text(finition.displayName).tag(finition as Finition?)
                }
            }

            if let finition = finitionSelectionnee {
                // ✅ V4 : finition.description supprimé (membre réservé NSObject)
                // On affiche uniquement conditionsIdeales
                Label(finition.conditionsIdeales, systemImage: "lightbulb.fill")
                    .font(.caption).foregroundColor(.blue)
                    .padding(.vertical, 4)
            }
        } header: { Text("Finition (optionnel)") } footer: {
            if finitionSelectionnee == nil {
                Text("Ajoutez une finition pour optimiser l'utilisation selon les conditions")
            }
        }
    }

    // MARK: - Section Traîne

    private var sectionTraine: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Profondeur de nage").font(.subheadline).foregroundColor(.secondary)
                HStack {
                    TextField("Min", text: $profondeurMin).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text("à").foregroundColor(.secondary)
                    TextField("Max", text: $profondeurMax).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text("m").foregroundColor(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Vitesse de traîne").font(.subheadline).foregroundColor(.secondary)
                HStack {
                    TextField("Min", text: $vitesseMin).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text("à").foregroundColor(.secondary)
                    TextField("Max", text: $vitesseMax).keyboardType(.decimalPad).textFieldStyle(.roundedBorder)
                    Text("nœuds").foregroundColor(.secondary)
                }
            }
        } header: { Text("Paramètres de traîne") } footer: {
            Text("Informations indiquées sur l'emballage ou dans la documentation du fabricant")
        }
    }

    // MARK: - Section Notes

    private var sectionNotes: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .onChange(of: notes) { _, newValue in detectTypeDeNage(in: newValue) }

            if showTypeDetectionSuggestion, let suggestedType = detectedTypes.first {
                typeDetectionBadge(for: suggestedType)
            }
        } header: { Text("Notes personnelles") } footer: {
            Text("Remarques, retours d'expérience, description fabricant...")
        }
    }

    // MARK: - Validation

    private var formulaireValide: Bool {
        !nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        !marque.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(longueur.replacingOccurrences(of: ",", with: ".")) != nil
    }

    private func validerCoherenceTypePeche() -> Bool {
        let typesLancerSeuls: [TypeLeurre] = [
            .popper, .stickbait, .stickbaitFlottant, .stickbaitCoulant,
            .jigMetallique, .jigStickbait, .jigStickbaitCoulant, .jigVibrant
        ]
        if typesLancerSeuls.contains(typeLeurre) && typePeche == .traine {
            validationMessage = "❌ Un \(typeLeurre.displayName) ne peut être utilisé qu'au lancer, jamais en traîne."
            showValidationError = true
            return false
        }
        return true
    }

    private func validerEtSauvegarder() {
        guard !nom.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Le nom est obligatoire"; showValidationError = true; return
        }
        guard !marque.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "La marque est obligatoire"; showValidationError = true; return
        }
        let longueurNorm = longueur.replacingOccurrences(of: ",", with: ".")
        guard let longueurValue = Double(longueurNorm), longueurValue > 0 else {
            validationMessage = "La longueur doit être un nombre positif"; showValidationError = true; return
        }
        guard validerCoherenceTypePeche() else { return }

        if typePeche.necessiteInfosTraine {
            let minNorm = profondeurMin.replacingOccurrences(of: ",", with: ".")
            let maxNorm = profondeurMax.replacingOccurrences(of: ",", with: ".")
            if let min = Double(minNorm), let max = Double(maxNorm), min > max {
                validationMessage = "La profondeur min doit être inférieure à max"
                showValidationError = true; return
            }
        }

        sauvegarder()
        dismiss()
    }

    // MARK: - Sauvegarde

    private func sauvegarder() {
        let longueurValue = Double(longueur.replacingOccurrences(of: ",", with: ".")) ?? 0
        let poidsValue    = Double(poids.replacingOccurrences(of: ",", with: "."))
        let profMinValue  = Double(profondeurMin.replacingOccurrences(of: ",", with: "."))
        let profMaxValue  = Double(profondeurMax.replacingOccurrences(of: ",", with: "."))
        let vitMinValue   = Double(vitesseMin.replacingOccurrences(of: ",", with: "."))
        let vitMaxValue   = Double(vitesseMax.replacingOccurrences(of: ",", with: "."))
        let couleurSec    = hasCouleurSecondaire ? couleurSecondaire : nil
        let techniquesCompatiblesArray: [TypePeche]? = showTechniquesCompatibles ?
            Array(typesPecheCompatibles).sorted(by: { $0.displayName < $1.displayName }) : nil

        // ✅ V4 : photoData depuis selectedImage — plus de photoPath
        let photoData = selectedImage?.jpegData(compressionQuality: 0.8)

        switch mode {
        case .creation, .duplication:
            let nouvelID = viewModel.genererNouvelID()
            let nouveauLeurre = Leurre(
                id: nouvelID,
                nom: nom.trimmingCharacters(in: .whitespaces),
                marque: marque.trimmingCharacters(in: .whitespaces),
                modele: modele.isEmpty ? nil : modele.trimmingCharacters(in: .whitespaces),
                typeLeurre: typeLeurre,
                typePeche: typePeche,
                typesPecheCompatibles: techniquesCompatiblesArray,
                longueur: longueurValue,
                poids: poidsValue,
                couleurPrincipale: couleurPrincipale,
                couleurPrincipaleCustom: couleurPrincipaleCustom,
                couleurSecondaire: couleurSec,
                couleurSecondaireCustom: hasCouleurSecondaire ? couleurSecondaireCustom : nil,
                finition: finitionSelectionnee,
                typesDeNage: typesDeNage.isEmpty ? nil : typesDeNage,
                profondeurNageMin: profMinValue,
                profondeurNageMax: profMaxValue,
                vitesseTraineMin: vitMinValue,
                vitesseTraineMax: vitMaxValue,
                notes: notes.isEmpty ? nil : notes,
                photoData: photoData
            )
            viewModel.ajouterLeurre(nouveauLeurre)

        case .edition(let leurreOriginal):
            // ✅ V4 : mutation directe sur @Model SwiftData
            leurreOriginal.nom    = nom.trimmingCharacters(in: .whitespaces)
            leurreOriginal.marque = marque.trimmingCharacters(in: .whitespaces)
            leurreOriginal.modele = modele.isEmpty ? nil : modele.trimmingCharacters(in: .whitespaces)
            leurreOriginal.typeLeurre              = typeLeurre
            leurreOriginal.typePeche               = typePeche
            leurreOriginal.typesPecheCompatibles   = techniquesCompatiblesArray
            leurreOriginal.longueur                = longueurValue
            leurreOriginal.poids                   = poidsValue
            leurreOriginal.couleurPrincipale       = couleurPrincipale
            leurreOriginal.couleurPrincipaleCustom = couleurPrincipaleCustom
            leurreOriginal.couleurSecondaire       = couleurSec
            leurreOriginal.couleurSecondaireCustom = hasCouleurSecondaire ? couleurSecondaireCustom : nil
            leurreOriginal.finition                = finitionSelectionnee
            leurreOriginal.typesDeNage             = typesDeNage.isEmpty ? nil : typesDeNage
            leurreOriginal.profondeurNageMin       = profMinValue
            leurreOriginal.profondeurNageMax       = profMaxValue
            leurreOriginal.vitesseTraineMin        = vitMinValue
            leurreOriginal.vitesseTraineMax        = vitMaxValue
            leurreOriginal.notes                   = notes.isEmpty ? nil : notes
            leurreOriginal.photoData               = photoData
            viewModel.modifierLeurre(leurreOriginal)
        }
    }

    // MARK: - Téléchargement photo depuis URL

    private func telechargerPhotoDepuisURL() {
        guard !photoURL.isEmpty, let url = URL(string: photoURL) else { return }
        isDownloadingPhoto = true

        // ✅ V4 : URLSession direct — plus de LeurreStorageService.shared
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    selectedImage      = UIImage(data: data)
                    isDownloadingPhoto = false
                    photoURL           = ""
                }
            } catch {
                await MainActor.run {
                    isDownloadingPhoto = false
                    validationMessage  = "Impossible de télécharger l'image : \(error.localizedDescription)"
                    showValidationError = true
                }
            }
        }
    }

    // MARK: - Import depuis URL produit

    private func importerDepuisURL() {
        guard !urlProduit.isEmpty else { return }
        isExtractingInfos = true

        Task {
            do {
                let infos = try await LeurreWebScraperService.shared.extraireInfosDepuisURL(urlProduit)
                await MainActor.run {
                    infosExtraites = infos
                    if let m = infos.marque          { self.marque = m }
                    if let n = infos.nom             { self.nom = n }
                    if let t = infos.typeLeurre      { self.typeLeurre = t }
                    if let tp = infos.typePeche      { self.typePeche = tp }
                    if let compatibles = infos.typesPecheCompatibles, !compatibles.isEmpty {
                        self.showTechniquesCompatibles = true
                        self.typesPecheCompatibles = Set(compatibles)
                    }
                    if let pMin = infos.profondeurMin { self.profondeurMin = String(format: "%.1f", pMin) }
                    if let pMax = infos.profondeurMax { self.profondeurMax = String(format: "%.1f", pMax) }
                    if let vMin = infos.vitesseTraineMin { self.vitesseMin = String(format: "%.1f", vMin) }
                    if let vMax = infos.vitesseTraineMax { self.vitesseMax = String(format: "%.1f", vMax) }
                    if let desc = infos.descriptionFabricant, !desc.isEmpty { self.notes = desc }

                    isExtractingInfos = false
                    urlProduit = ""

                    if let urlPhoto = infos.urlPhoto { telechargerPhotoDepuisURLString(urlPhoto) }

                    let champsRemplis = [
                        infos.marque != nil ? "marque" : nil,
                        infos.nom != nil ? "nom" : nil,
                        infos.typeLeurre != nil ? "type" : nil,
                        infos.typePeche != nil ? "technique" : nil,
                        infos.typesPecheCompatibles != nil ? "compatibilités" : nil,
                        infos.profondeurMin != nil || infos.profondeurMax != nil ? "profondeur" : nil,
                        infos.vitesseTraineMin != nil || infos.vitesseTraineMax != nil ? "vitesse" : nil,
                        infos.urlPhoto != nil ? "photo" : nil,
                        infos.descriptionFabricant != nil ? "description" : nil
                    ].compactMap { $0 }

                    if !champsRemplis.isEmpty {
                        validationMessage = "✅ Informations extraites : \(champsRemplis.joined(separator: ", "))"
                        showValidationError = true
                    }
                }
            } catch {
                await MainActor.run {
                    isExtractingInfos = false
                    validationMessage = "Erreur d'extraction : \(error.localizedDescription)"
                    showValidationError = true
                }
            }
        }
    }

    private func telechargerPhotoDepuisURLString(_ urlString: String) {
        Task {
            do {
                let image = try await LeurreWebScraperService.shared.telechargerImage(urlString: urlString)
                await MainActor.run { selectedImage = image }
            } catch {
                print("⚠️ Photo non téléchargeable : \(error)")
            }
        }
    }

    // MARK: - Utilitaires

    private func determinerContrastePrevisu(principale: Couleur, secondaire: Couleur?) -> Contraste {
        if let sec = secondaire {
            let cp = principale.contrasteNaturel
            let cs = sec.contrasteNaturel
            if (cp == .sombre && cs == .flashy) || (cp == .flashy && cs == .sombre) { return .contraste }
        }
        return principale.contrasteNaturel
    }

    // MARK: - Détection Type de Nage

    private func detectTypeDeNage(in text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            withAnimation { showTypeDetectionSuggestion = false; detectedTypes = []; hasIgnoredSuggestion = false }
            return
        }
        let allDetected  = TypeDeNageDetector.detect(in: text)
        let newDetections = allDetected.filter { !typesDeNage.contains($0) }

        if !newDetections.isEmpty && typesDeNage.count < 3 && !hasIgnoredSuggestion {
            let available = 3 - typesDeNage.count
            detectedTypes = Array(newDetections.prefix(available))
            withAnimation(.easeInOut(duration: 0.3)) { showTypeDetectionSuggestion = true }
        } else {
            withAnimation(.easeInOut(duration: 0.2)) { showTypeDetectionSuggestion = false }
        }
    }

    private func typeDetectionBadge(for type: TypeDeNage) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(Color(hex: "FFBC42")).font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(detectedTypes.count > 1 ? "Types de nage détectés" : "Type de nage détecté")
                        .font(.caption).foregroundColor(.secondary)
                    if detectedTypes.count > 1 {
                        Text("\(detectedTypes.count) suggestions")
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    } else if let firstType = detectedTypes.first {
                        Text(firstType.rawValue)
                            .font(.subheadline).fontWeight(.semibold).foregroundColor(.primary)
                    }
                }
                Spacer()
                Button {
                    withAnimation { showTypeDetectionSuggestion = false; hasIgnoredSuggestion = true }
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.gray).font(.title3)
                }
            }

            if detectedTypes.count > 1 {
                VStack(spacing: 8) {
                    ForEach(detectedTypes, id: \.self) { detectedType in
                        HStack(spacing: 12) {
                            Text(detectedType.rawValue).font(.subheadline).foregroundColor(.primary)
                            Spacer()
                            Button {
                                if typesDeNage.count < 3 {
                                    typesDeNage.append(detectedType)
                                    if let index = detectedTypes.firstIndex(of: detectedType) { detectedTypes.remove(at: index) }
                                    if detectedTypes.isEmpty { withAnimation { showTypeDetectionSuggestion = false } }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Ajouter")
                                }
                                .font(.caption).fontWeight(.semibold).foregroundColor(.white)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(Color(hex: "0277BD")).cornerRadius(8)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                if (typesDeNage.count + detectedTypes.count) <= 3 {
                    Button {
                        typesDeNage.append(contentsOf: detectedTypes)
                        withAnimation { showTypeDetectionSuggestion = false; detectedTypes = [] }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Tout ajouter (\(detectedTypes.count))").fontWeight(.semibold)
                        }
                        .foregroundColor(.white).frame(maxWidth: .infinity)
                        .padding(.vertical, 10).background(Color(hex: "4CAF50")).cornerRadius(10)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    Button {
                        if let firstType = detectedTypes.first, typesDeNage.count < 3 { typesDeNage.append(firstType) }
                        withAnimation { showTypeDetectionSuggestion = false; hasIgnoredSuggestion = false }
                    } label: {
                        Text("Ajouter").font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(Color(hex: "0277BD")).cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(hex: "FFF9E6"))
        .cornerRadius(12)
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Preview

#Preview("Création") {
    LeurreFormView(viewModel: BoiteLeurresViewModel(), mode: .creation)
}
