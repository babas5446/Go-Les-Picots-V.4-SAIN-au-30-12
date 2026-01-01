//
//  LeureViewModel.swift
//  Go les Picots - Module 1 Phase 2
//
//  ViewModel principal pour la gestion des leurres
//  - CRUD complet (Create, Read, Update, Delete)
//  - Filtres et recherche
//  - Recalcul automatique des champs déduits
//  - Persistance JSON
//  - Export/Import avec photos (ZIP)
//
//  Created: 2024-12-10
//

import Foundation
import SwiftUI
import Combine
import ZIPFoundation

@MainActor
class LeureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var leurres: [Leurre] = []
    @Published var leurresFiltres: [Leurre] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // MARK: - Enums pour Import/Export
    
    /// Mode d'importation de la base de données
    enum ModeImport {
        case fusionner  // Ajoute les leurres importés aux existants
        case remplacer  // Remplace complètement la base actuelle
    }
    
    /// Erreurs possibles lors de l'import
    enum ImportError: LocalizedError {
        case fichierVide
        case formatInvalide
        
        var errorDescription: String? {
            switch self {
            case .fichierVide:
                return "Le fichier d'import est vide"
            case .formatInvalide:
                return "Format JSON invalide ou incompatible"
            }
        }
    }
    
    // MARK: - Filtres
    
    @Published var filtreRecherche: String = "" {
        didSet { appliquerFiltres() }
    }
    
    @Published var filtreTypePeche: TypePeche? {
        didSet { appliquerFiltres() }
    }
    
    @Published var filtreTypeLeurre: TypeLeurre? {
        didSet { appliquerFiltres() }
    }
    
    @Published var filtreZone: Zone? {
        didSet { appliquerFiltres() }
    }
    
    @Published var filtreContraste: Contraste? {
        didSet { appliquerFiltres() }
    }
    
    // MARK: - Tri
    
    enum TriOption: String, CaseIterable {
        case nom = "Nom"
        case marque = "Marque"
        case taille = "Taille"
        case dateAjout = "Date d'ajout"
        case id = "ID"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    @Published var triActuel: TriOption = .nom {
        didSet { appliquerTri() }
    }
    
    @Published var triCroissant: Bool = true {
        didSet { appliquerTri() }
    }
    
    // MARK: - Services
    
    private let storageService = LeurreStorageService.shared
    
    // MARK: - Initialisation
    
    init() {
        chargerLeurres()
    }
    
    // MARK: - Chargement
    
    func chargerLeurres() {
        isLoading = true
        errorMessage = nil
        
        do {
            leurres = try storageService.chargerLeurres()
            appliquerFiltres()
            print("✅ \(leurres.count) leurres chargés")
            
            if leurres.isEmpty {
                print("⚠️ Base de données vide - aucun leurre disponible")
                errorMessage = "La base de données est vide. Ajoutez des leurres pour commencer."
            }
        } catch let error as StorageError {
            switch error {
            case .decodageEchoue(let detail):
                errorMessage = "❌ Erreur de lecture de la base de données\n\n\(detail)\n\nUne base vide a été créée automatiquement."
                print("❌ Erreur chargement (décodage) : \(detail)")
                
            case .fichierIntrouvable:
                errorMessage = "❌ Fichier de base de données introuvable\n\nUne nouvelle base a été créée."
                print("❌ Erreur chargement : fichier introuvable")
                
            default:
                errorMessage = error.localizedDescription
                print("❌ Erreur chargement : \(error)")
            }
            
            showError = true
            leurres = []
            leurresFiltres = []
            
            print("🔧 Tentative de récupération automatique...")
            do {
                try storageService.reinitialiserBase()
                leurres = try storageService.chargerLeurres()
                appliquerFiltres()
                errorMessage = "✅ Base de données récupérée avec succès.\n\n\(leurres.count) leurres chargés."
                print("✅ Récupération réussie : \(leurres.count) leurres")
            } catch {
                print("❌ Récupération automatique échouée")
            }
            
        } catch {
            errorMessage = "Erreur inattendue : \(error.localizedDescription)"
            showError = true
            leurres = []
            leurresFiltres = []
            print("❌ Erreur chargement (générale) : \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - CRUD
    
    /// Ajoute un nouveau leurre
    func ajouterLeurre(_ leurre: Leurre) {
        var nouveauLeurre = leurre
        nouveauLeurre = calculerChampsDeduits(nouveauLeurre)
        
        do {
            try storageService.ajouterLeurre(nouveauLeurre)
            leurres.append(nouveauLeurre)
            appliquerFiltres()
            print("✅ Leurre ajouté : \(nouveauLeurre.nom)")
        } catch {
            errorMessage = "Erreur lors de l'ajout : \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Crée un nouveau leurre avec un ID auto-généré
    func creerNouveauLeurre(
        nom: String,
        marque: String,
        modele: String? = nil,
        typeLeurre: TypeLeurre,
        typePeche: TypePeche,
        longueur: Double,
        poids: Double? = nil,
        couleurPrincipale: Couleur,
        couleurSecondaire: Couleur? = nil,
        profondeurNageMin: Double? = nil,
        profondeurNageMax: Double? = nil,
        vitesseTraineMin: Double? = nil,
        vitesseTraineMax: Double? = nil,
        notes: String? = nil,
        photoPath: String? = nil
    ) {
        let nouvelID = storageService.genererNouvelID()
        
        let nouveauLeurre = Leurre(
            id: nouvelID,
            nom: nom,
            marque: marque,
            modele: modele,
            typeLeurre: typeLeurre,
            typePeche: typePeche,
            longueur: longueur,
            poids: poids,
            couleurPrincipale: couleurPrincipale,
            couleurSecondaire: couleurSecondaire,
            profondeurNageMin: profondeurNageMin,
            profondeurNageMax: profondeurNageMax,
            vitesseTraineMin: vitesseTraineMin,
            vitesseTraineMax: vitesseTraineMax,
            notes: notes,
            photoPath: photoPath
        )
        
        ajouterLeurre(nouveauLeurre)
    }
    
    /// Modifie un leurre existant
    func modifierLeurre(_ leurre: Leurre) {
        var leurreModifie = leurre
        leurreModifie = calculerChampsDeduits(leurreModifie)
        
        do {
            try storageService.modifierLeurre(leurreModifie)
            
            if let index = leurres.firstIndex(where: { $0.id == leurre.id }) {
                leurres[index] = leurreModifie
            }
            appliquerFiltres()
            print("✅ Leurre modifié : \(leurreModifie.nom)")
        } catch {
            errorMessage = "Erreur lors de la modification : \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Supprime un leurre
    func supprimerLeurre(_ leurre: Leurre) {
        do {
            try storageService.supprimerLeurre(leurre)
            leurres.removeAll { $0.id == leurre.id }
            appliquerFiltres()
            print("🗑️ Leurre supprimé : \(leurre.nom)")
        } catch {
            errorMessage = "Erreur lors de la suppression : \(error.localizedDescription)"
            showError = true
        }
    }
    
    /// Supprime plusieurs leurres
    func supprimerLeurres(_ indices: IndexSet) {
        let leurresToDelete = indices.map { leurresFiltres[$0] }
        
        for leurre in leurresToDelete {
            supprimerLeurre(leurre)
        }
    }
    
    // MARK: - Calcul des champs déduits
    
    /// Calcule les champs déduits à partir des informations saisies
    func calculerChampsDeduits(_ leurre: Leurre) -> Leurre {
        var l = leurre
        
        l.contraste = determinerContraste(
            principale: leurre.couleurPrincipale,
            secondaire: leurre.couleurSecondaire
        )
        
        l.zonesAdaptees = determinerZones(leurre)
        l.especesCibles = determinerEspeces(zones: l.zonesAdaptees ?? [])
        
        if leurre.typePeche == .traine {
            l.positionsSpread = determinerPositionsSpread(
                typeLeurre: leurre.typeLeurre,
                contraste: l.contraste ?? .naturel,
                longueur: leurre.longueur
            )
        }
        
        l.conditionsOptimales = determinerConditionsOptimales(
            contraste: l.contraste ?? .naturel,
            typeLeurre: leurre.typeLeurre
        )
        
        l.isComputed = true
        
        return l
    }
    
    private func determinerContraste(principale: Couleur, secondaire: Couleur?) -> Contraste {
        if let sec = secondaire {
            let contrastePrincipale = principale.contrasteNaturel
            let contrasteSecondaire = sec.contrasteNaturel
            
            if (contrastePrincipale == .sombre && contrasteSecondaire == .flashy) ||
               (contrastePrincipale == .flashy && contrasteSecondaire == .sombre) {
                return .contraste
            }
        }
        
        return principale.contrasteNaturel
    }
    
    private func determinerZones(_ leurre: Leurre) -> [Zone] {
        var zones: [Zone] = []
        
        if let profMax = leurre.profondeurNageMax {
            if profMax <= 5 {
                zones.append(contentsOf: [.lagon, .recif])
            }
            if profMax >= 3 && profMax <= 10 {
                zones.append(.passe)
            }
            if profMax >= 5 {
                zones.append(contentsOf: [.large, .dcp])
            }
        }
        
        if leurre.longueur <= 15 {
            if !zones.contains(.lagon) { zones.append(.lagon) }
            if !zones.contains(.recif) { zones.append(.recif) }
        } else if leurre.longueur >= 18 {
            if !zones.contains(.large) { zones.append(.large) }
            if !zones.contains(.passe) { zones.append(.passe) }
        }
        
        if zones.isEmpty {
            zones = [.lagon, .passe]
        }
        
        return Array(Set(zones)).sorted { $0.rawValue < $1.rawValue }
    }
    
    private func determinerEspeces(zones: [Zone]) -> [String] {
        var especes = Set<String>()
        
        for zone in zones {
            especes.formUnion(zone.especesTypiques)
        }
        
        return Array(especes).sorted()
    }
    
    private func determinerPositionsSpread(typeLeurre: TypeLeurre, contraste: Contraste, longueur: Double) -> [PositionSpread] {
        var positions: [PositionSpread] = []
        
        switch contraste {
        case .naturel:
            positions.append(.longCorner)
        case .flashy:
            positions.append(contentsOf: [.longRigger, .shortRigger])
        case .sombre:
            positions.append(contentsOf: [.longCorner, .shotgun])
        case .contraste:
            positions.append(.shotgun)
        }
        
        if longueur >= 18 {
            if !positions.contains(.shortCorner) {
                positions.append(.shortCorner)
            }
        }
        
        return positions
    }
    
    private func determinerConditionsOptimales(contraste: Contraste, typeLeurre: TypeLeurre) -> ConditionsOptimales {
        var moments: [MomentJournee] = []
        var etatMer: [EtatMer] = []
        var turbidite: [Turbidite] = []
        
        switch contraste {
        case .naturel:
            moments = [.matinee, .midi, .apresMidi]
            etatMer = [.calme, .peuAgitee]
            turbidite = [.claire]
            
        case .flashy:
            moments = [.aube, .matinee, .crepuscule]
            etatMer = [.calme, .peuAgitee, .agitee]
            turbidite = [.claire, .legerementTrouble]
            
        case .sombre:
            moments = [.aube, .crepuscule, .nuit]
            etatMer = [.agitee, .formee]
            turbidite = [.trouble, .tresTrouble]
            
        case .contraste:
            moments = [.aube, .crepuscule]
            etatMer = [.agitee, .formee]
            turbidite = [.legerementTrouble, .trouble]
        }
        
        return ConditionsOptimales(
            moments: moments,
            etatMer: etatMer,
            turbidite: turbidite,
            maree: [.montante, .descendante],
            phasesLunaires: nil
        )
    }
    
    // MARK: - Recalcul forcé
    
    func recalculerTousLesChampsDeduits() {
        isLoading = true
        
        for i in 0..<leurres.count {
            leurres[i] = calculerChampsDeduits(leurres[i])
        }
        
        do {
            try storageService.sauvegarderLeurres(leurres)
            appliquerFiltres()
            print("✅ Tous les champs déduits recalculés")
        } catch {
            errorMessage = "Erreur lors du recalcul : \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Filtres et Tri
    
    func appliquerFiltres() {
        var resultats = leurres
        
        if !filtreRecherche.isEmpty {
            let recherche = filtreRecherche.lowercased()
            resultats = resultats.filter { leurre in
                leurre.nom.lowercased().contains(recherche) ||
                leurre.marque.lowercased().contains(recherche) ||
                leurre.couleurPrincipale.displayName.lowercased().contains(recherche) ||
                (leurre.modele?.lowercased().contains(recherche) ?? false)
            }
        }
        
        if let type = filtreTypePeche {
            resultats = resultats.filter { $0.typePeche == type }
        }
        
        if let type = filtreTypeLeurre {
            resultats = resultats.filter { $0.typeLeurre == type }
        }
        
        if let zone = filtreZone {
            resultats = resultats.filter { leurre in
                leurre.zonesAdaptees?.contains(zone) ?? false
            }
        }
        
        if let contraste = filtreContraste {
            resultats = resultats.filter { $0.contraste == contraste }
        }
        
        leurresFiltres = resultats
        appliquerTri()
    }
    
    func appliquerTri() {
        switch triActuel {
        case .nom:
            leurresFiltres.sort { triCroissant ? $0.nom < $1.nom : $0.nom > $1.nom }
        case .marque:
            leurresFiltres.sort { triCroissant ? $0.marque < $1.marque : $0.marque > $1.marque }
        case .taille:
            leurresFiltres.sort { triCroissant ? $0.longueur < $1.longueur : $0.longueur > $1.longueur }
        case .dateAjout:
            leurresFiltres.sort { (l1, l2) in
                let d1 = l1.dateAjout ?? Date.distantPast
                let d2 = l2.dateAjout ?? Date.distantPast
                return triCroissant ? d1 < d2 : d1 > d2
            }
        case .id:
            leurresFiltres.sort { triCroissant ? $0.id < $1.id : $0.id > $1.id }
        }
    }
    
    func reinitialiserFiltres() {
        filtreRecherche = ""
        filtreTypePeche = nil
        filtreTypeLeurre = nil
        filtreZone = nil
        filtreContraste = nil
        triActuel = .nom
        triCroissant = true
    }
    
    // MARK: - Photos
    
    func sauvegarderPhoto(image: UIImage, pourLeurre leurre: Leurre) {
        do {
            let chemin = try storageService.sauvegarderPhoto(image: image, pourLeurreID: leurre.id)
            
            var leurreModifie = leurre
            leurreModifie.photoPath = chemin
            modifierLeurre(leurreModifie)
        } catch {
            errorMessage = "Erreur sauvegarde photo : \(error.localizedDescription)"
            showError = true
        }
    }
    
    func chargerPhoto(pourLeurre leurre: Leurre) -> UIImage? {
        guard let chemin = leurre.photoPath else { return nil }
        return storageService.chargerPhoto(chemin: chemin)
    }
    
    func telechargerPhoto(url: String, pourLeurre leurre: Leurre) async {
        do {
            let chemin = try await storageService.telechargerPhotoDepuisURL(url, pourLeurreID: leurre.id)
            
            await MainActor.run {
                var leurreModifie = leurre
                leurreModifie.photoPath = chemin
                modifierLeurre(leurreModifie)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Erreur téléchargement photo : \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    // MARK: - Statistiques
    
    var nombreLeuresDeTraîne: Int {
        leurres.filter { $0.typePeche == .traine }.count
    }
    
    var nombreParTypePeche: [TypePeche: Int] {
        Dictionary(grouping: leurres, by: { $0.typePeche })
            .mapValues { $0.count }
    }
    
    var statistiques: (nombreLeurres: Int, nombrePhotos: Int, tailleBase: String) {
        storageService.statistiques()
    }
    
    // MARK: - Utilitaires
    
    func leurre(parID id: Int) -> Leurre? {
        leurres.first { $0.id == id }
    }
    
    func genererNouvelID() -> Int {
        storageService.genererNouvelID()
    }
    
    // MARK: - Export/Import
    
    /// Exporte tous les leurres en JSON + photos dans un ZIP
    func exporterBaseDeDonnees() -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            
            let database = LeureDatabase(
                metadata: LeureDatabase.Metadata(
                    version: "2.0",
                    dateCreation: ISO8601DateFormatter().string(from: Date()),
                    nombreTotal: leurres.count,
                    description: "Export Go Les Picots - Nouvelle-Calédonie",
                    proprietaire: "Utilisateur",
                    source: "Application Go Les Picots V.4"
                ),
                leurres: leurres
            )
            
            let jsonData = try encoder.encode(database)
            
            let timestamp = ISO8601DateFormatter().string(from: Date())
                .replacingOccurrences(of: ":", with: "-")
                .replacingOccurrences(of: ".", with: "-")
            
            let exportFolderName = "go_les_picots_export_\(timestamp)"
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(exportFolderName)
            
            try? FileManager.default.removeItem(at: tempURL)
            try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
            
            let jsonURL = tempURL.appendingPathComponent("leurres.json")
            try jsonData.write(to: jsonURL)
            
            let photosURL = tempURL.appendingPathComponent("photos")
            try FileManager.default.createDirectory(at: photosURL, withIntermediateDirectories: true)
            
            var photosCopiees = 0
            for leurre in leurres {
                if let photoPath = leurre.photoPath,
                   let photoURL = storageService.urlPhoto(chemin: photoPath),
                   FileManager.default.fileExists(atPath: photoURL.path) {
                    
                    let destinationURL = photosURL.appendingPathComponent(photoURL.lastPathComponent)
                    try? FileManager.default.copyItem(at: photoURL, to: destinationURL)
                    photosCopiees += 1
                }
            }
            
            print("📸 \(photosCopiees) photos copiées")
            
            let zipFileName = "go_les_picots_\(timestamp).zip"
            let zipURL = FileManager.default.temporaryDirectory.appendingPathComponent(zipFileName)
            
            try? FileManager.default.removeItem(at: zipURL)
            
            try FileManager.default.zipItem(at: tempURL, to: zipURL)
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let finalURL = documentsURL.appendingPathComponent(zipFileName)
            
            try? FileManager.default.removeItem(at: finalURL)
            try FileManager.default.copyItem(at: zipURL, to: finalURL)
            
            try? FileManager.default.removeItem(at: tempURL)
            
            print("✅ Export ZIP réussi : \(leurres.count) leurres + \(photosCopiees) photos")
            print("📁 Chemin : \(finalURL.path)")
            
            let fileSize = try FileManager.default.attributesOfItem(atPath: finalURL.path)[.size] as? Int64 ?? 0
            print("📄 Taille : \(ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file))")
            
            return finalURL
            
        } catch {
            print("❌ Erreur d'export ZIP : \(error)")
            return nil
        }
    }
    
    /// Importe depuis un ZIP ou JSON
    func importerBaseDeDonnees(depuis url: URL, mode: ModeImport) throws {
        if url.pathExtension.lowercased() == "zip" {
            try importerDepuisZIP(url: url, mode: mode)
        } else {
            try importerDepuisJSON(url: url, mode: mode)
        }
    }
    
    /// Import depuis un fichier ZIP
    private func importerDepuisZIP(url: URL, mode: ModeImport) throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("import_\(UUID().uuidString)")
        
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        
        defer {
            try? FileManager.default.removeItem(at: tempURL)
        }
        
        try FileManager.default.unzipItem(at: url, to: tempURL)
        
        let jsonURL = tempURL.appendingPathComponent("leurres.json")
        try importerDepuisJSON(url: jsonURL, mode: mode)
        
        let photosSourceURL = tempURL.appendingPathComponent("photos")
        if FileManager.default.fileExists(atPath: photosSourceURL.path) {
            let photosDestURL = storageService.documentURL.appendingPathComponent("photos")
            
            try? FileManager.default.createDirectory(at: photosDestURL, withIntermediateDirectories: true)
            
            let photos = try FileManager.default.contentsOfDirectory(at: photosSourceURL, includingPropertiesForKeys: nil)
            
            var photosCopiees = 0
            for photoURL in photos {
                let destURL = photosDestURL.appendingPathComponent(photoURL.lastPathComponent)
                
                if !FileManager.default.fileExists(atPath: destURL.path) {
                    try? FileManager.default.copyItem(at: photoURL, to: destURL)
                    photosCopiees += 1
                }
            }
            
            print("📸 \(photosCopiees) photos importées")
        }
    }
    
    /// Import depuis un fichier JSON pur
    private func importerDepuisJSON(url: URL, mode: ModeImport) throws {
        let jsonData = try Data(contentsOf: url)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var leursImportes: [Leurre]
        
        do {
            let database = try decoder.decode(LeureDatabase.self, from: jsonData)
            leursImportes = database.leurres
            print("✅ Format avec metadata détecté")
        } catch {
            do {
                leursImportes = try decoder.decode([Leurre].self, from: jsonData)
                print("✅ Format array direct détecté")
            } catch {
                print("❌ Erreur décodage : \(error)")
                throw ImportError.formatInvalide
            }
        }
        
        guard !leursImportes.isEmpty else {
            throw ImportError.fichierVide
        }
        
        print("📥 \(leursImportes.count) leurres trouvés dans le fichier")
        
        switch mode {
        case .fusionner:
            let idsExistants = Set(leurres.map { $0.id })
            var nouveauxLeurres = leursImportes
            
            for i in 0..<nouveauxLeurres.count {
                if idsExistants.contains(nouveauxLeurres[i].id) {
                    let leurreModifie = nouveauxLeurres[i]
                    let nouvelID = genererNouvelID()
                    
                    print("⚠️ Conflit ID \(leurreModifie.id) → Nouvel ID \(nouvelID)")
                    
                    nouveauxLeurres[i] = Leurre(
                        id: nouvelID,
                        nom: leurreModifie.nom,
                        marque: leurreModifie.marque,
                        modele: leurreModifie.modele,
                        typeLeurre: leurreModifie.typeLeurre,
                        typePeche: leurreModifie.typePeche,
                        typesPecheCompatibles: leurreModifie.typesPecheCompatibles,
                        longueur: leurreModifie.longueur,
                        poids: leurreModifie.poids,
                        couleurPrincipale: leurreModifie.couleurPrincipale,
                        couleurPrincipaleCustom: leurreModifie.couleurPrincipaleCustom,
                        couleurSecondaire: leurreModifie.couleurSecondaire,
                        couleurSecondaireCustom: leurreModifie.couleurSecondaireCustom,
                        finition: leurreModifie.finition,
                        typesDeNage: leurreModifie.typesDeNage,
                        profondeurNageMin: leurreModifie.profondeurNageMin,
                        profondeurNageMax: leurreModifie.profondeurNageMax,
                        vitesseTraineMin: leurreModifie.vitesseTraineMin,
                        vitesseTraineMax: leurreModifie.vitesseTraineMax,
                        notes: leurreModifie.notes,
                        photoPath: leurreModifie.photoPath,
                        quantite: leurreModifie.quantite
                    )
                }
            }
            
            leurres.append(contentsOf: nouveauxLeurres)
            print("✅ Import fusionné : +\(nouveauxLeurres.count) leurres (total : \(leurres.count))")
            
        case .remplacer:
            leurres = leursImportes
            print("✅ Import remplacé : \(leurres.count) leurres")
        }
        
        try storageService.sauvegarderLeurres(leurres)
        appliquerFiltres()
    }
}
