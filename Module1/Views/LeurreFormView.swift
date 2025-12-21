//
//  LeurreFormView.swift
//  Go les Picots - Module 1 Phase 2
//
//  Formulaire unifié pour créer ou éditer un leurre
//  - Mode création (nouveau leurre)
//  - Mode édition (leurre existant)
//  - Champs conditionnels (traîne)
//  - Intégration photo
//
//  Created: 2024-12-10
//

import SwiftUI
import PhotosUI

struct LeurreFormView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: LeureViewModel
    
    // MARK: - Mode du formulaire
    
    enum Mode {
        case creation
        case edition(Leurre)
        
        var titre: String {
            switch self {
            case .creation: return "Nouveau leurre"
            case .edition: return "Modifier le leurre"
            }
        }
        
        var boutonAction: String {
            switch self {
            case .creation: return "Ajouter"
            case .edition: return "Enregistrer"
            }
        }
        
        var isCreation: Bool {
            if case .creation = self { return true }
            return false
        }
    }
    
    let mode: Mode
    
    // MARK: - État du formulaire
    
    // Identification
    @State private var nom: String = ""
    @State private var marque: String = ""
    @State private var modele: String = ""
    
    // Type
    @State private var typeLeurre: TypeLeurre = .poissonNageur
    @State private var typePeche: TypePeche = .traine
    
    // Caractéristiques
    @State private var longueur: String = ""
    @State private var poids: String = ""
    
    // Couleurs
    @State private var couleurPrincipale: Couleur = .bleuArgente
    @State private var couleurSecondaire: Couleur? = nil
    @State private var hasCouleurSecondaire: Bool = false
    
    // Traîne (conditionnel)
    @State private var profondeurMin: String = ""
    @State private var profondeurMax: String = ""
    @State private var vitesseMin: String = ""
    @State private var vitesseMax: String = ""
    
    // Notes
    @State private var notes: String = ""
    
    // Photo
    @State private var selectedImage: UIImage? = nil
    @State private var photoURL: String = ""
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showURLInput = false
    @State private var isDownloadingPhoto = false
    
    // ═══════════════════════════════════════════════════════════
    // PHASE 1 : Import depuis URL produit
    // ═══════════════════════════════════════════════════════════
    @State private var showImportURL = false
    @State private var urlProduit: String = ""
    @State private var isExtractingInfos = false
    @State private var infosExtraites: LeurreInfosExtraites?
    @State private var showVariantSelection = false
    @State private var variantesDisponibles: [VarianteLeurre] = []
    
    // Validation
    @State private var showValidationError = false
    @State private var validationMessage = ""
    
    // MARK: - Initialisation
    
    init(viewModel: LeureViewModel, mode: Mode) {
        self.viewModel = viewModel
        self.mode = mode
        
        // Pré-remplir si édition
        if case .edition(let leurre) = mode {
            _nom = State(initialValue: leurre.nom)
            _marque = State(initialValue: leurre.marque)
            _modele = State(initialValue: leurre.modele ?? "")
            _typeLeurre = State(initialValue: leurre.typeLeurre)
            _typePeche = State(initialValue: leurre.typePeche)
            _longueur = State(initialValue: String(format: "%.1f", leurre.longueur))
            _poids = State(initialValue: leurre.poids.map { String(format: "%.0f", $0) } ?? "")
            _couleurPrincipale = State(initialValue: leurre.couleurPrincipale)
            _couleurSecondaire = State(initialValue: leurre.couleurSecondaire)
            _hasCouleurSecondaire = State(initialValue: leurre.couleurSecondaire != nil)
            _profondeurMin = State(initialValue: leurre.profondeurNageMin.map { String(format: "%.1f", $0) } ?? "")
            _profondeurMax = State(initialValue: leurre.profondeurNageMax.map { String(format: "%.1f", $0) } ?? "")
            _vitesseMin = State(initialValue: leurre.vitesseTraineMin.map { String(format: "%.0f", $0) } ?? "")
            _vitesseMax = State(initialValue: leurre.vitesseTraineMax.map { String(format: "%.0f", $0) } ?? "")
            _notes = State(initialValue: leurre.notes ?? "")
            
            // Charger la photo existante
            if let photoPath = leurre.photoPath,
               let image = LeurreStorageService.shared.chargerPhoto(chemin: photoPath) {
                _selectedImage = State(initialValue: image)
            }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                // ═══════════════════════════════════════════════════════════
                // PHASE 1 : Section Import depuis URL
                // ═══════════════════════════════════════════════════════════
                if mode.isCreation {
                    sectionImportURL
                }
                
                // Section Photo
                sectionPhoto
                
                // Section Identification
                sectionIdentification
                
                // Section Type
                sectionType
                
                // Section Caractéristiques
                sectionCaracteristiques
                
                // Section Couleurs
                sectionCouleurs
                
                // Section Traîne (conditionnel)
                if typePeche.necessiteInfosTraine {
                    sectionTraine
                }
                
                // Section Notes
                sectionNotes
            }
            .navigationTitle(mode.titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.boutonAction) {
                        validerEtSauvegarder()
                    }
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
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                
                Button("Télécharger") {
                    telechargerPhotoDepuisURL()
                }
                Button("Annuler", role: .cancel) {
                    photoURL = ""
                }
            } message: {
                Text("Collez l'URL d'une image")
            }
            // ═══════════════════════════════════════════════════════════
            // PHASE 1 : Alert import URL
            // ═══════════════════════════════════════════════════════════
            .alert("Importer depuis une page produit", isPresented: $showImportURL) {
                TextField("https://www.rapala.fr/...", text: $urlProduit)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                
                Button("Importer") {
                    importerDepuisURL()
                }
                Button("Annuler", role: .cancel) {
                    urlProduit = ""
                }
            } message: {
                Text("Collez l'URL de la page du leurre (Rapala, Pêcheur.com, Decathlon...)")
            }
            .sheet(isPresented: $showVariantSelection) {
                SelectionVarianteView(
                    variantes: variantesDisponibles,
                    onSelection: { variante in
                        appliquerVariante(variante)
                        showVariantSelection = false
                    }
                )
            }
        }
    }
    
    // MARK: - Section Import URL (Phase 1)
    
    private var sectionImportURL: some View {
        Section {
            if !isExtractingInfos {
                Button {
                    showImportURL = true
                } label: {
                    HStack {
                        Image(systemName: "link.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color(hex: "0277BD"))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Importer depuis une page produit")
                                .font(.headline)
                                .foregroundColor(Color(hex: "0277BD"))
                            Text("Rapala, Pêcheur.com, Decathlon...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Extraction des informations...")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text("Gain de temps")
        } footer: {
            Text("L'app va extraire la marque, le nom, les dimensions et la photo depuis la page produit. Vous pourrez ensuite ajuster manuellement.")
        }
    }
    
    // MARK: - Sections du formulaire
    
    private var sectionPhoto: some View {
        Section {
            VStack(spacing: 12) {
                // Aperçu photo
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(alignment: .topTrailing) {
                            Button {
                                selectedImage = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .red)
                            }
                            .padding(8)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .overlay {
                            VStack(spacing: 8) {
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                                Text("Aucune photo")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                }
                
                // Boutons photo
                if !isDownloadingPhoto {
                    HStack(spacing: 16) {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Caméra", systemImage: "camera")
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("Galerie", systemImage: "photo.on.rectangle")
                        }
                        .buttonStyle(.bordered)
                        
                        Button {
                            showURLInput = true
                        } label: {
                            Label("URL", systemImage: "link")
                        }
                        .buttonStyle(.bordered)
                    }
                    .font(.caption)
                } else {
                    ProgressView("Téléchargement...")
                        .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
        } header: {
            Text("Photo")
        }
    }
    
    private var sectionIdentification: some View {
        Section {
            TextField("Nom du leurre", text: $nom)
                .textInputAutocapitalization(.words)
            
            TextField("Marque", text: $marque)
                .textInputAutocapitalization(.words)
            
            TextField("Modèle (facultatif)", text: $modele)
                .textInputAutocapitalization(.words)
        } header: {
            Text("Identification")
        } footer: {
            Text("Informations visibles sur l'emballage")
        }
    }
    
    private var sectionType: some View {
        Section {
            Picker("Type de pêche", selection: $typePeche) {
                ForEach(TypePeche.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon)
                        .tag(type)
                }
            }
            
            Picker("Type de leurre", selection: $typeLeurre) {
                ForEach(TypeLeurre.allCases, id: \.self) { type in
                    Text("\(type.icon) \(type.displayName)")
                        .tag(type)
                }
            }
        } header: {
            Text("Classification")
        }
    }
    
    private var sectionCaracteristiques: some View {
        Section {
            HStack {
                Text("Longueur")
                Spacer()
                TextField("cm", text: $longueur)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("cm")
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Poids (facultatif)")
                Spacer()
                TextField("g", text: $poids)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("g")
                    .foregroundColor(.secondary)
            }
        } header: {
            Text("Caractéristiques")
        }
    }
    
    private var sectionCouleurs: some View {
        Section {
            Picker("Couleur principale", selection: $couleurPrincipale) {
                ForEach(Couleur.allCases, id: \.self) { couleur in
                    HStack {
                        Circle()
                            .fill(couleur.swiftUIColor)
                            .frame(width: 20, height: 20)
                        Text(couleur.displayName)
                    }
                    .tag(couleur)
                }
            }
            
            Toggle("Couleur secondaire", isOn: $hasCouleurSecondaire)
            
            if hasCouleurSecondaire {
                Picker("Couleur secondaire", selection: Binding(
                    get: { couleurSecondaire ?? .blanc },
                    set: { couleurSecondaire = $0 }
                )) {
                    ForEach(Couleur.allCases, id: \.self) { couleur in
                        HStack {
                            Circle()
                                .fill(couleur.swiftUIColor)
                                .frame(width: 20, height: 20)
                            Text(couleur.displayName)
                        }
                        .tag(couleur)
                    }
                }
            }
        } header: {
            Text("Couleurs")
        } footer: {
            if let secondaire = hasCouleurSecondaire ? couleurSecondaire : nil {
                Text("Contraste détecté : \(determinerContrastePrevisu(principale: couleurPrincipale, secondaire: secondaire).displayName)")
            } else {
                Text("Contraste détecté : \(couleurPrincipale.contrasteNaturel.displayName)")
            }
        }
    }
    
    private var sectionTraine: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Profondeur de nage")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Min", text: $profondeurMin)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("à")
                        .foregroundColor(.secondary)
                    
                    TextField("Max", text: $profondeurMax)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("m")
                        .foregroundColor(.secondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Vitesse de traîne")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Min", text: $vitesseMin)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("à")
                        .foregroundColor(.secondary)
                    
                    TextField("Max", text: $vitesseMax)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                    
                    Text("nœuds")
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Paramètres de traîne")
        } footer: {
            Text("Informations indiquées sur l'emballage ou dans la documentation du fabricant")
        }
    }
    
    private var sectionNotes: some View {
        Section {
            TextEditor(text: $notes)
                .frame(minHeight: 80)
        } header: {
            Text("Notes personnelles")
        } footer: {
            Text("Remarques, retours d'expérience, etc.")
        }
    }
    
    // MARK: - Validation
    
    private var formulaireValide: Bool {
        !nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        !marque.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(longueur.replacingOccurrences(of: ",", with: ".")) != nil
    }
    
    private func validerEtSauvegarder() {
        // Validation nom
        guard !nom.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "Le nom est obligatoire"
            showValidationError = true
            return
        }
        
        // Validation marque
        guard !marque.trimmingCharacters(in: .whitespaces).isEmpty else {
            validationMessage = "La marque est obligatoire"
            showValidationError = true
            return
        }
        
        // Validation longueur
        let longueurNormalisee = longueur.replacingOccurrences(of: ",", with: ".")
        guard let longueurValue = Double(longueurNormalisee), longueurValue > 0 else {
            validationMessage = "La longueur doit être un nombre positif"
            showValidationError = true
            return
        }
        
        // Validation traîne (si applicable)
        if typePeche.necessiteInfosTraine {
            if !profondeurMin.isEmpty || !profondeurMax.isEmpty {
                let minNorm = profondeurMin.replacingOccurrences(of: ",", with: ".")
                let maxNorm = profondeurMax.replacingOccurrences(of: ",", with: ".")
                
                if let min = Double(minNorm), let max = Double(maxNorm), min > max {
                    validationMessage = "La profondeur min doit être inférieure à max"
                    showValidationError = true
                    return
                }
            }
        }
        
        // Créer ou modifier le leurre
        sauvegarder()
        dismiss()
    }
    
    private func sauvegarder() {
        // Parser les valeurs numériques
        let longueurValue = Double(longueur.replacingOccurrences(of: ",", with: ".")) ?? 0
        let poidsValue = Double(poids.replacingOccurrences(of: ",", with: "."))
        let profMinValue = Double(profondeurMin.replacingOccurrences(of: ",", with: "."))
        let profMaxValue = Double(profondeurMax.replacingOccurrences(of: ",", with: "."))
        let vitMinValue = Double(vitesseMin.replacingOccurrences(of: ",", with: "."))
        let vitMaxValue = Double(vitesseMax.replacingOccurrences(of: ",", with: "."))
        
        let couleurSec: Couleur? = hasCouleurSecondaire ? couleurSecondaire : nil
        
        switch mode {
        case .creation:
            // Créer nouveau leurre
            let nouvelID = viewModel.genererNouvelID()
            
            var nouveauLeurre = Leurre(
                id: nouvelID,
                nom: nom.trimmingCharacters(in: .whitespaces),
                marque: marque.trimmingCharacters(in: .whitespaces),
                modele: modele.isEmpty ? nil : modele.trimmingCharacters(in: .whitespaces),
                typeLeurre: typeLeurre,
                typePeche: typePeche,
                longueur: longueurValue,
                poids: poidsValue,
                couleurPrincipale: couleurPrincipale,
                couleurSecondaire: couleurSec,
                profondeurNageMin: profMinValue,
                profondeurNageMax: profMaxValue,
                vitesseTraineMin: vitMinValue,
                vitesseTraineMax: vitMaxValue,
                notes: notes.isEmpty ? nil : notes
            )
            
            // Sauvegarder la photo si présente
            if let image = selectedImage {
                if let chemin = try? LeurreStorageService.shared.sauvegarderPhoto(image: image, pourLeurreID: nouvelID) {
                    nouveauLeurre.photoPath = chemin
                }
            }
            
            viewModel.ajouterLeurre(nouveauLeurre)
            
        case .edition(let leurreOriginal):
            // Modifier leurre existant
            var leurreModifie = leurreOriginal
            leurreModifie.nom = nom.trimmingCharacters(in: .whitespaces)
            leurreModifie.marque = marque.trimmingCharacters(in: .whitespaces)
            leurreModifie.modele = modele.isEmpty ? nil : modele.trimmingCharacters(in: .whitespaces)
            leurreModifie.typeLeurre = typeLeurre
            leurreModifie.typePeche = typePeche
            leurreModifie.longueur = longueurValue
            leurreModifie.poids = poidsValue
            leurreModifie.couleurPrincipale = couleurPrincipale
            leurreModifie.couleurSecondaire = couleurSec
            leurreModifie.profondeurNageMin = profMinValue
            leurreModifie.profondeurNageMax = profMaxValue
            leurreModifie.vitesseTraineMin = vitMinValue
            leurreModifie.vitesseTraineMax = vitMaxValue
            leurreModifie.notes = notes.isEmpty ? nil : notes
            
            // Gérer la photo
            if let image = selectedImage {
                // Nouvelle photo ou photo modifiée
                if let chemin = try? LeurreStorageService.shared.sauvegarderPhoto(image: image, pourLeurreID: leurreOriginal.id) {
                    // Supprimer l'ancienne photo si différente
                    if let ancienChemin = leurreOriginal.photoPath, ancienChemin != chemin {
                        LeurreStorageService.shared.supprimerPhoto(chemin: ancienChemin)
                    }
                    leurreModifie.photoPath = chemin
                }
            } else if leurreOriginal.photoPath != nil {
                // Photo supprimée
                if let ancienChemin = leurreOriginal.photoPath {
                    LeurreStorageService.shared.supprimerPhoto(chemin: ancienChemin)
                }
                leurreModifie.photoPath = nil
            }
            
            viewModel.modifierLeurre(leurreModifie)
        }
    }
    
    // MARK: - Photo URL
    
    private func telechargerPhotoDepuisURL() {
        guard !photoURL.isEmpty else { return }
        
        isDownloadingPhoto = true
        
        let leurreID: Int
        switch mode {
        case .creation:
            leurreID = viewModel.genererNouvelID()
        case .edition(let leurre):
            leurreID = leurre.id
        }
        
        Task {
            do {
                let chemin = try await LeurreStorageService.shared.telechargerPhotoDepuisURL(photoURL, pourLeurreID: leurreID)
                
                await MainActor.run {
                    if let image = LeurreStorageService.shared.chargerPhoto(chemin: chemin) {
                        selectedImage = image
                    }
                    isDownloadingPhoto = false
                    photoURL = ""
                }
            } catch {
                await MainActor.run {
                    isDownloadingPhoto = false
                    validationMessage = "Impossible de télécharger l'image : \(error.localizedDescription)"
                    showValidationError = true
                }
            }
        }
    }
    
    // MARK: - Import depuis URL produit (Phase 1)
    
    private func importerDepuisURL() {
        guard !urlProduit.isEmpty else { return }
        
        isExtractingInfos = true
        
        Task {
            do {
                let infos = try await LeurreWebScraperService.shared.extraireInfosDepuisURL(urlProduit)
                
                await MainActor.run {
                    infosExtraites = infos
                    
                    // Pré-remplir les champs
                    if let marque = infos.marque {
                        self.marque = marque
                    }
                    
                    if let nom = infos.nom {
                        self.nom = nom
                    }
                    
                    if let type = infos.typeLeurre {
                        self.typeLeurre = type
                    }
                    
                    // ✅ CORRECTION : Terminer l'extraction AVANT d'afficher la sheet ou le message
                    isExtractingInfos = false
                    urlProduit = ""
                    
                    // Télécharger la photo si disponible
                    if let urlPhoto = infos.urlPhoto {
                        telechargerPhotoDepuisURLString(urlPhoto)
                    }
                    
                    // ✅ CORRECTION : Gérer les variantes avec un délai pour éviter les conflits UI
                    // Si plusieurs variantes, demander à l'utilisateur de choisir
                    if infos.variantes.count > 1 {
                        variantesDisponibles = infos.variantes
                        
                        // Petit délai pour s'assurer que l'UI est stable
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            print("📊 Affichage sélecteur de variantes : \(infos.variantes.count) options")
                            showVariantSelection = true
                        }
                    } else if let variante = infos.variantes.first {
                        // Une seule variante : appliquer directement
                        print("✅ Application automatique de la variante unique")
                        appliquerVariante(variante)
                        
                        // Message de succès après application
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            let champsRemplis = [
                                infos.marque != nil ? "marque" : nil,
                                infos.nom != nil ? "nom" : nil,
                                infos.typeLeurre != nil ? "type" : nil,
                                infos.urlPhoto != nil ? "photo" : nil,
                                "dimensions"
                            ].compactMap { $0 }
                            
                            validationMessage = "✅ Informations extraites : \(champsRemplis.joined(separator: ", "))\n\nVous pouvez maintenant ajuster manuellement les champs."
                            showValidationError = true
                        }
                    } else {
                        // Aucune variante trouvée : afficher message immédiatement
                        let champsRemplis = [
                            infos.marque != nil ? "marque" : nil,
                            infos.nom != nil ? "nom" : nil,
                            infos.typeLeurre != nil ? "type" : nil,
                            infos.urlPhoto != nil ? "photo" : nil
                        ].compactMap { $0 }
                        
                        if !champsRemplis.isEmpty {
                            validationMessage = "✅ Informations extraites : \(champsRemplis.joined(separator: ", "))\n\nVous pouvez maintenant ajuster manuellement les champs."
                            showValidationError = true
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isExtractingInfos = false
                    validationMessage = "Erreur d'extraction : \(error.localizedDescription)\n\nEssayez de remplir les champs manuellement."
                    showValidationError = true
                }
            }
        }
    }
    
    private func telechargerPhotoDepuisURLString(_ urlString: String) {
        Task {
            do {
                let image = try await LeurreWebScraperService.shared.telechargerImage(urlString: urlString)
                
                await MainActor.run {
                    selectedImage = image
                }
            } catch {
                print("⚠️ Impossible de télécharger la photo : \(error)")
            }
        }
    }
    
    private func appliquerVariante(_ variante: VarianteLeurre) {
        if let longueur = variante.longueur {
            self.longueur = String(format: "%.1f", longueur)
        }
        
        if let poids = variante.poids {
            self.poids = String(format: "%.0f", poids)
        }
        
        if let profMin = variante.profondeurMin {
            self.profondeurMin = String(format: "%.1f", profMin)
        }
        
        if let profMax = variante.profondeurMax {
            self.profondeurMax = String(format: "%.1f", profMax)
        }
    }
    
    // MARK: - Utilitaires
    
    private func determinerContrastePrevisu(principale: Couleur, secondaire: Couleur?) -> Contraste {
        if let sec = secondaire {
            let cp = principale.contrasteNaturel
            let cs = sec.contrasteNaturel
            
            if (cp == .sombre && cs == .flashy) || (cp == .flashy && cs == .sombre) {
                return .contraste
            }
        }
        return principale.contrasteNaturel
    }
}

// MARK: - Preview

#Preview("Création") {
    LeurreFormView(viewModel: LeureViewModel(), mode: .creation)
}

// MARK: - Vue de sélection de variante

struct SelectionVarianteView: View {
    let variantes: [VarianteLeurre]
    let onSelection: (VarianteLeurre) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(variantes) { variante in
                        Button {
                            onSelection(variante)
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(variante.description)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let longueur = variante.longueur, let poids = variante.poids {
                                        Text("Longueur: \(Int(longueur)) cm • Poids: \(Int(poids))g")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                } header: {
                    Text("Plusieurs variantes disponibles")
                } footer: {
                    Text("Sélectionnez la taille que vous possédez")
                }
            }
            .navigationTitle("Choisir la variante")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }
}

