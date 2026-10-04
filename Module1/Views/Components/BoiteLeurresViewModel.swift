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
            // Même source que le moteur : zones stockées, sinon déduites.
            resultats = resultats.filter { $0.zonesAdapteesFinales.contains(zone) }
        }

        if let contraste = filtreContraste {
            resultats = resultats.filter { $0.profilVisuel == contraste }
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
        // Retrait immédiat de la liste affichée : la List ne doit plus
        // rendre une instance détruite entre delete() et le prochain @Query.
        let cible = leurre.persistentModelID
        leurresFiltres.removeAll { $0.persistentModelID == cible }
        context.delete(leurre)
        sauvegarder()
    }

    /// Supprime les leurres aux indices fournis dans leurresFiltres.
    /// Appelé par .onDelete dans BoiteView.
    func supprimerLeurres(_ indices: IndexSet) {
        // Les cibles sont figées AVANT toute suppression : supprimerLeurre
        // modifie leurresFiltres, ce qui décalerait les indices suivants.
        let cibles = indices.compactMap { $0 < leurresFiltres.count ? leurresFiltres[$0] : nil }
        for leurre in cibles {
            supprimerLeurre(leurre)
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
    /// Ne touche à aucun champ saisi.
    func recalculerTousLesChampsDeduits() {
        isLoading = true
        let descriptor = FetchDescriptor<Leurre>()
        let tous = (try? context.fetch(descriptor)) ?? []
        for leurre in tous { calculerChampsDeduits(leurre) }
        sauvegarder()
        isLoading = false
    }

    /// Complète les leurres dont les champs déduits manquent
    /// (migration, import ZIP/JSON, ancienne version). Sans effet si tout est à jour.
    /// Retourne le nombre de leurres recalculés.
    @discardableResult
    func completerChampsDeduitsManquants() -> Int {
        let tous = (try? context.fetch(FetchDescriptor<Leurre>())) ?? []
        let aCompleter = tous.filter {
            !$0.isComputed || $0.zonesAdaptees == nil || $0.contraste == nil || $0.positionsSpread == nil
        }
        guard !aCompleter.isEmpty else { return 0 }
        for leurre in aCompleter { calculerChampsDeduits(leurre) }
        sauvegarder()
        print("🧮 Champs déduits complétés pour \(aCompleter.count) leurre(s)")
        return aCompleter.count
    }

    /// Recalcul unique de toute la boîte quand les règles de déduction
    /// changent (réglage « versionDeductions »). Les champs saisis ne sont
    /// pas modifiés. Retourne true si le recalcul a eu lieu.
    @discardableResult
    func appliquerNouvellesReglesSiNecessaire(_ defaults: UserDefaults = .standard) -> Bool {
        let version = defaults.integer(forKey: ReglesDeduction.cleVersion)
        guard version < ReglesDeduction.versionDeductions else { return false }
        recalculerTousLesChampsDeduits()
        guard !showError else { return false }   // échec d'enregistrement : on retentera
        defaults.set(ReglesDeduction.versionDeductions, forKey: ReglesDeduction.cleVersion)
        print("🧮 Règles de déduction v\(ReglesDeduction.versionDeductions) appliquées à toute la boîte")
        return true
    }

    // MARK: - Calcul des champs déduits

    /// Calcule et assigne les champs déduits directement sur l'entité @Model.
    /// Règles v2 (LeurreIntelligenceService.swift) ; les lignes repères des
    /// notes (Espèces, Zones, Postes) priment sur le calcul.
    @discardableResult
    func calculerChampsDeduits(_ leurre: Leurre) -> Leurre {
        let fiche = leurre.ficheDeduction
        let famille = ReglesCouleur.famille(fiche)
        let r = ReglesDeduction.deduire(fiche, famille: famille)

        leurre.contraste     = famille
        leurre.zonesAdaptees = r.zones
        leurre.especesCibles = r.especes
        if leurre.typePeche == .traine {
            leurre.positionsSpread = r.postes
        }

        // Conditions optimales : règle inchangée, sur l'ancien contraste.
        let contrasteHistorique = determinerContraste(
            principale: leurre.couleurPrincipale,
            secondaire: leurre.couleurSecondaire
        )
        leurre.conditionsOptimales = determinerConditionsOptimales(
            contraste:  contrasteHistorique,
            typeLeurre: leurre.typeLeurre
        )
        leurre.isComputed = true
        return leurre
    }

    /// Ancien calcul du contraste, conservé pour les conditions optimales.
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

            // Les champs déduits d'un fichier importé peuvent dater de règles
            // antérieures : toute la boîte est recalculée (champs saisis intacts).
            recalculerTousLesChampsDeduits()

            return .success(nb)

        } catch {
            print("❌ BoiteLeurresViewModel : Import échoué : \(error.localizedDescription)")
            return .failure(error)
        }
    }

    // MARK: - Remplacement de la boîte

    /// Ce que l'utilisateur confirme avant le remplacement.
    struct ApercuRemplacement {
        let nombreFichier: Int
        let photosFichier: Int
        let nombreActuel: Int
        let photosActuelles: Int
        let prisesSansFiche: Int
        let sortiesSansFiche: Int

        var message: String {
            var m = "Ta boîte actuelle (\(nombreActuel) leurres, \(photosActuelles) photos) sera remplacée "
            m += "par celle du fichier (\(nombreFichier) leurres, \(photosFichier) photos). "
            m += "Les numéros du fichier sont conservés. Une sauvegarde ZIP de la boîte actuelle est faite juste avant."
            if prisesSansFiche > 0 || sortiesSansFiche > 0 {
                m += "\n\nJournal : \(prisesSansFiche) prise(s) et \(sortiesSansFiche) sortie(s) citent des numéros "
                m += "absents du fichier ; elles ne seront plus reliées à une fiche de la boîte."
            }
            return m
        }
    }

    struct BilanRemplacement {
        let nombre: Int
        let photos: Int
        let sauvegarde: URL
        let prisesSansFiche: Int
    }

    /// Fichier lu et vérifié, en attente de confirmation.
    private var lotEnAttente: LeurreExportService.LotImport?

    /// Étape 1 : lit tout le fichier sans toucher à la base.
    /// Le fichier local est supprimé en fin de course.
    func preparerRemplacement(depuis url: URL) async -> Result<ApercuRemplacement, Error> {
        isLoading = true
        defer {
            isLoading = false
            try? FileManager.default.removeItem(at: url)
        }
        do {
            let lot = try LeurreExportService.lireLot(depuis: url)
            lotEnAttente = lot
            let actuels = tousLesLeurres
            let journal = referencesJournalSansFiche(Set(lot.dtos.map { $0.id }))
            return .success(ApercuRemplacement(
                nombreFichier: lot.dtos.count,
                photosFichier: lot.nombreAvecPhoto,
                nombreActuel: actuels.count,
                photosActuelles: actuels.filter { $0.photoData != nil }.count,
                prisesSansFiche: journal.prises,
                sortiesSansFiche: journal.sorties
            ))
        } catch {
            lotEnAttente = nil
            return .failure(error)
        }
    }

    func annulerRemplacement() {
        lotEnAttente = nil
    }

    /// Étape 2 (après confirmation) : sauvegarde ZIP, remplacement, recalcul.
    func confirmerRemplacement() async -> Result<BilanRemplacement, Error> {
        guard let lot = lotEnAttente else { return .failure(ImportError.fichierVide) }
        lotEnAttente = nil
        isLoading = true
        defer { isLoading = false }
        do {
            let sauvegarde = try LeurreExportService.sauvegarderBoite(leurres: tousLesLeurres)
            // La liste affichée ne doit plus rendre des fiches supprimées.
            leurresFiltres = []
            let nombre = try LeurreExportService.remplacerBoite(par: lot, dans: context)
            recalculerTousLesChampsDeduits()
            let journal = referencesJournalSansFiche(Set(lot.dtos.map { $0.id }))
            return .success(BilanRemplacement(
                nombre: nombre,
                photos: lot.nombreAvecPhoto,
                sauvegarde: sauvegarde,
                prisesSansFiche: journal.prises
            ))
        } catch {
            return .failure(error)
        }
    }

    /// Prises et sorties du journal qui citent un numéro absent de `ids`.
    private func referencesJournalSansFiche(_ ids: Set<Int>) -> (prises: Int, sorties: Int) {
        let prises = (try? context.fetch(FetchDescriptor<Prise>())) ?? []
        let nbPrises = prises.filter { prise in
            guard let id = prise.leurreID else { return false }
            return !ids.contains(id)
        }.count
        let sorties = (try? context.fetch(FetchDescriptor<Sortie>())) ?? []
        let nbSorties = sorties.filter { !$0.leurresSessionIDs.allSatisfy(ids.contains) }.count
        return (nbPrises, nbSorties)
    }

    // MARK: - Utilitaires

    /// Retourne tous les leurres depuis SwiftData.
    /// Utilisé par SuggestionEngine — remplace l'ancien tableau @Published.
    var tousLesLeurres: [Leurre] {
        let descriptor = FetchDescriptor<Leurre>()
        return (try? context.fetch(descriptor)) ?? []
    }
    
    /// Recherche dans toute la boîte, pas seulement dans la liste filtrée :
    /// un filtre actif ne doit pas masquer un leurre au moteur ou au journal.
    func leurre(parID id: Int) -> Leurre? {
        var descriptor = FetchDescriptor<Leurre>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
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
