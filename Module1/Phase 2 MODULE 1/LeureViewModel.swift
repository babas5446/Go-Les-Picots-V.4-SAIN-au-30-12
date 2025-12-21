//
//  LeureViewModel.swift
//  Go les Picots - Module 1 Phase 2
//
//  ViewModel principal pour la gestion des leurres
//  - CRUD complet (Create, Read, Update, Delete)
//  - Filtres et recherche
//  - Recalcul automatique des champs déduits
//  - Persistance JSON
//
//  Created: 2024-12-10
//

import Foundation
import SwiftUI
import Combine

@MainActor
class LeureViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var leurres: [Leurre] = []
    @Published var leurresFiltres: [Leurre] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
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
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            leurres = []
            leurresFiltres = []
            print("❌ Erreur chargement : \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - CRUD
    
    /// Ajoute un nouveau leurre
    func ajouterLeurre(_ leurre: Leurre) {
        var nouveauLeurre = leurre
        
        // Calculer les champs déduits
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
        
        // Recalculer les champs déduits
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
    
    // MARK: - Calcul des champs déduits (Moteur simplifié)
    
    /// Calcule les champs déduits à partir des informations saisies
    func calculerChampsDeduits(_ leurre: Leurre) -> Leurre {
        var l = leurre
        
        // 1. Contraste (déduit des couleurs)
        l.contraste = determinerContraste(
            principale: leurre.couleurPrincipale,
            secondaire: leurre.couleurSecondaire
        )
        
        // 2. Zones adaptées (déduit du type de pêche + profondeur)
        l.zonesAdaptees = determinerZones(leurre)
        
        // 3. Espèces cibles (déduit des zones)
        l.especesCibles = determinerEspeces(zones: l.zonesAdaptees ?? [])
        
        // 4. Positions spread (déduit du type + contraste) - uniquement pour traîne
        if leurre.typePeche == .traine {
            l.positionsSpread = determinerPositionsSpread(
                typeLeurre: leurre.typeLeurre,
                contraste: l.contraste ?? .naturel,
                longueur: leurre.longueur
            )
        }
        
        // 5. Conditions optimales (déduit de l'ensemble)
        l.conditionsOptimales = determinerConditionsOptimales(
            contraste: l.contraste ?? .naturel,
            typeLeurre: leurre.typeLeurre
        )
        
        l.isComputed = true
        
        return l
    }
    
    /// Détermine le contraste en fonction des couleurs
    private func determinerContraste(principale: Couleur, secondaire: Couleur?) -> Contraste {
        // Si bicolore avec fort contraste
        if let sec = secondaire {
            let contrastePrincipale = principale.contrasteNaturel
            let contrasteSecondaire = sec.contrasteNaturel
            
            // Combinaisons contrastées
            if (contrastePrincipale == .sombre && contrasteSecondaire == .flashy) ||
               (contrastePrincipale == .flashy && contrasteSecondaire == .sombre) {
                return .contraste
            }
        }
        
        // Sinon, utiliser le contraste naturel de la couleur principale
        return principale.contrasteNaturel
    }
    
    /// Détermine les zones adaptées
    private func determinerZones(_ leurre: Leurre) -> [Zone] {
        var zones: [Zone] = []
        
        // Basé sur la profondeur de nage pour la traîne
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
        
        // Basé sur la taille
        if leurre.longueur <= 15 {
            if !zones.contains(.lagon) { zones.append(.lagon) }
            if !zones.contains(.recif) { zones.append(.recif) }
        } else if leurre.longueur >= 18 {
            if !zones.contains(.large) { zones.append(.large) }
            if !zones.contains(.passe) { zones.append(.passe) }
        }
        
        // Par défaut si rien
        if zones.isEmpty {
            zones = [.lagon, .passe]
        }
        
        return Array(Set(zones)).sorted { $0.rawValue < $1.rawValue }
    }
    
    /// Détermine les espèces cibles en fonction des zones
    private func determinerEspeces(zones: [Zone]) -> [String] {
        var especes = Set<String>()
        
        for zone in zones {
            especes.formUnion(zone.especesTypiques)
        }
        
        return Array(especes).sorted()
    }
    
    /// Détermine les positions spread
    private func determinerPositionsSpread(typeLeurre: TypeLeurre, contraste: Contraste, longueur: Double) -> [PositionSpread] {
        var positions: [PositionSpread] = []
        
        switch contraste {
        case .naturel:
            positions.append(.longCorner)
        case .flashy:
            positions.append(contentsOf: [.shortRigger, .longRigger])
        case .sombre:
            positions.append(contentsOf: [.longCorner, .shotgun])
        case .contraste:
            positions.append(.shotgun)
        }
        
        // Ajustement selon la taille
        if longueur >= 18 {
            if !positions.contains(.shortCorner) {
                positions.append(.shortCorner)
            }
        }
        
        return positions
    }
    
    /// Détermine les conditions optimales
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
    
    /// Recalcule les champs déduits pour tous les leurres
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
        
        // Recherche textuelle
        if !filtreRecherche.isEmpty {
            let recherche = filtreRecherche.lowercased()
            resultats = resultats.filter { leurre in
                leurre.nom.lowercased().contains(recherche) ||
                leurre.marque.lowercased().contains(recherche) ||
                leurre.couleurPrincipale.displayName.lowercased().contains(recherche) ||
                (leurre.modele?.lowercased().contains(recherche) ?? false)
            }
        }
        
        // Filtre type de pêche
        if let type = filtreTypePeche {
            resultats = resultats.filter { $0.typePeche == type }
        }
        
        // Filtre type de leurre
        if let type = filtreTypeLeurre {
            resultats = resultats.filter { $0.typeLeurre == type }
        }
        
        // Filtre zone
        if let zone = filtreZone {
            resultats = resultats.filter { leurre in
                leurre.zonesAdaptees?.contains(zone) ?? false
            }
        }
        
        // Filtre contraste
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
    
    /// Sauvegarde une photo pour un leurre
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
    
    /// Charge une photo pour un leurre
    func chargerPhoto(pourLeurre leurre: Leurre) -> UIImage? {
        guard let chemin = leurre.photoPath else { return nil }
        return storageService.chargerPhoto(chemin: chemin)
    }
    
    /// Télécharge une photo depuis une URL
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
    
    /// Génère un ID pour un nouveau leurre
    func genererNouvelID() -> Int {
        storageService.genererNouvelID()
    }
}
