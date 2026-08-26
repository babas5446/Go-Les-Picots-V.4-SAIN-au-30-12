//
//  BoiteLeurresViewModel.swift
//  Go les Picots V.4 — Module 1
//
//  ViewModel principal de la boîte à leurres.
//
//  V4 — Réécriture complète :
//  - Ancien nom : LeureViewModel (faute d'orthographe corrigée)
//  - Persistance JSON → SwiftData (ModelContext injecté à l'init)
//  - leurres: [Leurre] retiré du ViewModel (@Query dans BoiteView)
//  - CRUD via ModelContext.insert / delete / save
//  - Photos stockées dans Leurre.photoData (Data?) — plus de fichiers disque
//  - Export/Import délégués à LeurreExportService
//  - appliquerFiltres(leurres:) reçoit la liste depuis la vue
//

import Foundation
import SwiftUI
import SwiftData
import Combine

@MainActor
class BoiteLeurresViewModel: ObservableObject {

    // MARK: - Contexte SwiftData

    private let context: ModelContext

    // MARK: - État UI

    @Published var leurresFiltres: [Leurre] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false

    // MARK: - Filtres

    @Published var filtreRecherche: String = "" {
        didSet { rafraichirFiltres() }
    }

    @Published var filtreTypePeche: TypePeche? {
        didSet { rafraichirFiltres() }
    }

    @Published var filtreTypeLeurre: TypeLeurre? {
        didSet { rafraichirFiltres() }
    }

    @Published var filtreZone: Zone? {
        didSet { rafraichirFiltres() }
    }

    @Published var filtreContraste: Contraste? {
        didSet { rafraichirFiltres() }
    }

    // MARK: - Tri

    enum TriOption: String, CaseIterable {
        case nom       = "Nom"
        case marque    = "Marque"
        case taille    = "Taille"
        case dateAjout = "Date d'ajout"
        case id        = "ID"

        var displayName: String { rawValue }
    }

    @Published var triActuel: TriOption = .nom {
        didSet { appliquerTri() }
    }

    @Published var triCroissant: Bool = true {
        didSet { appliquerTri() }
    }

    // MARK: - Import/Export

    enum ModeImport {
        case fusionner  // Ajoute les leurres importés — doublons ignorés par id
    }

    enum ImportError: LocalizedError {
        case fichierVide
        case formatInvalide

        var errorDescription: String? {
            switch self {
            case .fichierVide:    return "Le fichier d'import est vide"
            case .formatInvalide: return "Format ZIP ou JSON invalide"
            }
        }
    }

    // MARK: - Initialisation

    init(context: ModelContext) {
        self.context = context
    }

    /// Init sans paramètre — utilise le container SwiftData partagé.
    /// Permet aux vues existantes d'instancier BoiteLeurresViewModel() sans argument.
    @MainActor
    convenience init() {
        self.init(context: LeurreStorageService.shared.mainContext)
    }

    // MARK: - Filtres et tri

    /// Appelé depuis BoiteView à chaque mise à jour de @Query.
    /// Reçoit la liste fraîche depuis SwiftData et applique les filtres actifs.
    func appliquerFiltres(leurres: [Leurre]) {
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

    /// Signal interne — BoiteView re-appelle appliquerFiltres(leurres:) via onChange.
    private func rafraichirFiltres() {
        objectWillChange.send()
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
        filtreRecherche  = ""
        filtreTypePeche  = nil
        filtreTypeLeurre = nil
        filtreZone       = nil
        filtreContraste  = nil
        triActuel        = .nom
        triCroissant     = true
    }

    // MARK: - CRUD

    /// Insère un nouveau leurre dans SwiftData après calcul des champs déduits.
    func ajouterLeurre(_ leurre: Leurre) {
        calculerChampsDeduits(leurre)
        context.insert(leurre)
        sauvegarder()
    }

    /// Persiste les modifications d'un leurre existant.
    /// SwiftData tracke les mutations des propriétés @Model automatiquement.
    func modifierLeurre(_ leurre: Leurre) {
        calculerChampsDeduits(leurre)
        sauvegarder()
    }

    /// Supprime un leurre de SwiftData.
    /// photoData est gérée automatiquement via @Attribute(.externalStorage).
    func supprimerLeurre(_ leurre: Leurre) {
        let nom = leurre.nom
        context.delete(leurre)
        sauvegarder()
    }

    /// Supprime les leurres aux indices fournis dans leurresFiltres.
    /// Appelé par .onDelete dans BoiteView.
    func supprimerLeurres(_ indices: IndexSet) {
        for index in indices {
            guard index < leurresFiltres.count else { continue }
            supprimerLeurre(leurresFiltres[index])
        }
    }

    // MARK: - Génération d'ID

    /// Retourne max(id) + 1 parmi tous les leurres SwiftData.
    func genererNouvelID() -> Int {
        let descriptor = FetchDescriptor<Leurre>()
        let tous = (try? context.fetch(descriptor)) ?? []
        return (tous.map { $0.id }.max() ?? 0) + 1
    }

    // MARK: - Photos

    /// Sauvegarde une photo dans photoData de l'entité SwiftData.
    func sauvegarderPhoto(image: UIImage, pourLeurre leurre: Leurre) {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            signalerErreur("Impossible de compresser l'image")
            return
        }
        leurre.photoData = data
        sauvegarder()
    }

    /// Supprime la photo d'un leurre.
    func supprimerPhoto(pourLeurre leurre: Leurre) {
        leurre.photoData = nil
        sauvegarder()
    }

    // MARK: - Recalcul forcé

    /// Recalcule les champs déduits de tous les leurres existants.
    func recalculerTousLesChampsDeduits() {
        isLoading = true
        let descriptor = FetchDescriptor<Leurre>()
        let tous = (try? context.fetch(descriptor)) ?? []
        for leurre in tous { calculerChampsDeduits(leurre) }
        sauvegarder()
        isLoading = false
    }

    // MARK: - Calcul des champs déduits

    /// Calcule et assigne les champs déduits directement sur l'entité @Model.
    @discardableResult
    func calculerChampsDeduits(_ leurre: Leurre) -> Leurre {
        leurre.contraste = determinerContraste(
            principale: leurre.couleurPrincipale,
            secondaire: leurre.couleurSecondaire
        )
        leurre.zonesAdaptees  = determinerZones(leurre)
        leurre.especesCibles  = determinerEspeces(zones: leurre.zonesAdaptees ?? [])

        if leurre.typePeche == .traine {
            leurre.positionsSpread = determinerPositionsSpread(
                typeLeurre: leurre.typeLeurre,
                contraste:  leurre.contraste ?? .naturel,
                longueur:   leurre.longueur
            )
        }

        leurre.conditionsOptimales = determinerConditionsOptimales(
            contraste:  leurre.contraste ?? .naturel,
            typeLeurre: leurre.typeLeurre
        )
        leurre.isComputed = true
        return leurre
    }

    private func determinerContraste(principale: Couleur, secondaire: Couleur?) -> Contraste {
        if let sec = secondaire {
            let cp = principale.contrasteNaturel
            let cs = sec.contrasteNaturel
            if (cp == .sombre && cs == .flashy) || (cp == .flashy && cs == .sombre) {
                return .contraste
            }
        }
        return principale.contrasteNaturel
    }

    private func determinerZones(_ leurre: Leurre) -> [Zone] {
        var zones: [Zone] = []
        if let profMax = leurre.profondeurNageMax {
            if profMax <= 5  { zones.append(contentsOf: [.lagon, .recif]) }
            if profMax >= 3 && profMax <= 10 { zones.append(.passe) }
            if profMax >= 5  { zones.append(contentsOf: [.large, .dcp]) }
        }
        if leurre.longueur <= 15 {
            if !zones.contains(.lagon) { zones.append(.lagon) }
            if !zones.contains(.recif) { zones.append(.recif) }
        } else if leurre.longueur >= 18 {
            if !zones.contains(.large) { zones.append(.large) }
            if !zones.contains(.passe) { zones.append(.passe) }
        }
        if zones.isEmpty { zones = [.lagon, .passe] }
        return Array(Set(zones)).sorted { $0.rawValue < $1.rawValue }
    }

    private func determinerEspeces(zones: [Zone]) -> [String] {
        var especes = Set<String>()
        for zone in zones { especes.formUnion(zone.especesTypiques) }
        return Array(especes).sorted()
    }

    private func determinerPositionsSpread(
        typeLeurre: TypeLeurre,
        contraste: Contraste,
        longueur: Double
    ) -> [PositionSpread] {
        var positions: [PositionSpread] = []
        switch contraste {
        case .naturel:   positions.append(.longCorner)
        case .flashy:    positions.append(contentsOf: [.longRigger, .shortRigger])
        case .sombre:    positions.append(contentsOf: [.longCorner, .shotgun])
        case .contraste: positions.append(.shotgun)
        }
        if longueur >= 18, !positions.contains(.shortCorner) {
            positions.append(.shortCorner)
        }
        return positions
    }

    private func determinerConditionsOptimales(
        contraste: Contraste,
        typeLeurre: TypeLeurre
    ) -> ConditionsOptimales {
        var moments:   [MomentJournee] = []
        var etatMer:   [EtatMer]       = []
        var turbidite: [Turbidite]     = []
        switch contraste {
        case .naturel:
            moments   = [.matinee, .midi, .apresMidi]
            etatMer   = [.calme, .peuAgitee]
            turbidite = [.claire]
        case .flashy:
            moments   = [.aube, .matinee, .crepuscule]
            etatMer   = [.calme, .peuAgitee, .agitee]
            turbidite = [.claire, .legerementTrouble]
        case .sombre:
            moments   = [.aube, .crepuscule, .nuit]
            etatMer   = [.agitee, .formee]
            turbidite = [.trouble, .tresTrouble]
        case .contraste:
            moments   = [.aube, .crepuscule]
            etatMer   = [.agitee, .formee]
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

    // MARK: - Export / Import

    /// Exporte tous les leurres dans un fichier ZIP.
    /// Retourne l'URL du ZIP pour UIActivityViewController.
    func exporterBaseDeDonnees(leurres: [Leurre]) -> URL? {
        do {
            return try LeurreExportService.exporterZIP(leurres: leurres)
        } catch {
            signalerErreur("Export échoué : \(error.localizedDescription)")
            return nil
        }
    }

    /// Importe depuis un fichier ZIP ou JSON — doublons ignorés par id.
    ///
    /// L'URL attendue est **locale** : la vue appelante a déjà copié le fichier
    /// choisi par l'utilisateur dans le bac à sable de l'app. L'accès
    /// security-scoped est donc clos avant l'appel, et l'import ne peut plus
    /// échouer par expiration de permission.
    ///
    /// Le fichier temporaire est supprimé en fin de course, succès ou échec.
    /// Retourne le nombre de leurres créés, ou l'erreur rencontrée.
    func importerBaseDeDonnees(depuis url: URL) async -> Result<Int, Error> {

        isLoading = true
        defer {
            isLoading = false
            try? FileManager.default.removeItem(at: url)
        }

        do {
            // Aiguillage sur l'extension — le fileImporter accepte .zip et .json
            let extensionFichier = url.pathExtension.lowercased()

            let nb: Int
            switch extensionFichier {
            case "zip":
                nb = try LeurreExportService.importerZIP(depuis: url, dans: context)
            case "json":
                nb = try LeurreExportService.importerJSON(depuis: url, dans: context)
            default:
                throw ImportError.formatInvalide
            }

            return .success(nb)

        } catch {
            print("❌ BoiteLeurresViewModel : Import échoué : \(error.localizedDescription)")
            return .failure(error)
        }
    }

    // MARK: - Utilitaires

    /// Retourne tous les leurres depuis SwiftData.
    /// Utilisé par SuggestionEngine — remplace l'ancien tableau @Published.
    var tousLesLeurres: [Leurre] {
        let descriptor = FetchDescriptor<Leurre>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    func leurre(parID id: Int) -> Leurre? {
        leurresFiltres.first { $0.id == id }
    }

    var nombreLeuresDeTraine: Int {
        leurresFiltres.filter { $0.typePeche == .traine }.count
    }

    var nombreParTypePeche: [TypePeche: Int] {
        Dictionary(grouping: leurresFiltres, by: { $0.typePeche })
            .mapValues { $0.count }
    }

    // MARK: - Persistance interne

    private func sauvegarder() {
        do {
            try context.save()
        } catch {
            signalerErreur("Erreur de sauvegarde : \(error.localizedDescription)")
        }
    }

    private func signalerErreur(_ message: String) {
        errorMessage = message
        showError    = true
        print("❌ BoiteLeurresViewModel : \(message)")
    }
}
