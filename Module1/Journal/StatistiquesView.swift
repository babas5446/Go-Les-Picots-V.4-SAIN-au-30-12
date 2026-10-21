//
//  StatistiquesView.swift
//  Go Les Picots V.4
//
//  MODULE 5 — Statistiques
//
//  Module strictement en lecture. Aucune écriture, aucune création d'objet
//  SwiftData : le risque de recomposition en boucle identifié en session 6 ne
//  se présente donc pas ici, et le calcul peut rester dans la vue.
//
//  Trois contraintes ont dicté la forme de ce fichier.
//
//  1. Le filtrage sur EtatSortie.terminee ne peut pas passer par un #Predicate.
//     Sortie.etat est une propriété calculée adossée à etatRaw, qui est privée :
//     ni l'une ni l'autre n'est visible d'une requête SwiftData. Le filtrage se
//     fait donc en mémoire, sur une @Query non filtrée. Sans conséquence aux
//     volumes concernés.
//
//  2. Sortie.conditions décode du JSON à chaque lecture. Toute l'agrégation
//     tient dans un passage unique, un décodage par sortie.
//
//  3. Sortie.duree se replie sur Date() quand heureRetour est nil. Juste pour
//     une sortie en cours, faux pour une sortie clôturée dont l'heure de retour
//     manquerait : la durée grandirait à chaque affichage. Les moyennes de
//     durée ne retiennent donc que les sorties portant départ ET retour.
//
//  Octobre 2026 : rendement des leurres (prises par heure à l'eau), prises
//  selon les conditions, contrôle du spread et bilan par espèce. Les calculs
//  sont dans StatistiquesCalcul.swift. Aucun malus : un leurre sans prise
//  n'apparaît dans aucun classement.
//

import SwiftUI
import SwiftData

// MARK: - Regroupement de zones

/// Regroupement des sept zones de pêche en deux familles.
/// Le troisième cas ne vient pas d'une zone absente — Zone n'est pas
/// optionnelle dans ConditionsPeche — mais d'une sortie sans conditions saisies.
enum SecteurPeche: String, CaseIterable {
    case lagon
    case exterieur
    case nonRenseigne

    var displayName: String {
        switch self {
        case .lagon:        return "Lagon"
        case .exterieur:    return "Extérieur"
        case .nonRenseigne: return "Non renseigné"
        }
    }

    var icon: String {
        switch self {
        case .lagon:        return "beach.umbrella"
        case .exterieur:    return "ferry"
        case .nonRenseigne: return "questionmark.circle"
        }
    }

    /// Rattachement d'une zone à son secteur.
    /// Le switch est exhaustif à dessein : l'ajout d'un cas à Zone provoquera
    /// une erreur de compilation ici, plutôt qu'un classement silencieux.
    static func depuis(_ zone: Zone) -> SecteurPeche {
        switch zone {
        case .lagon, .recif, .passe, .tombant: return .lagon
        case .large, .profond, .dcp:           return .exterieur
        }
    }
}

// MARK: - Lignes de classement

struct LigneEspece: Identifiable {
    var id: String { nom }
    let nom: String
    let nombre: Int
}

struct LigneLeurre: Identifiable {
    let id: String
    let nom: String
    let marque: String
    let nombre: Int
}

// MARK: - Agrégat

/// Résultat complet de l'agrégation, construit en un seul passage.
struct StatistiquesAgregat {

    // Sorties
    var nombreSorties: Int = 0
    var nombreSortiesChronometrees: Int = 0
    var dureeCumulee: TimeInterval = 0
    var dureeMoyenne: TimeInterval = 0
    var derniereSortie: Date?
    var distanceCumuleeMN: Double = 0
    var distanceMoyenneMN: Double = 0
    var repartition: [SecteurPeche: Int] = [:]

    // Prises
    var nombrePrises: Int = 0
    var nombreRelachees: Int = 0
    var moyennePrisesParSortie: Double = 0
    var classementEspeces: [LigneEspece] = []

    // Leurres
    var classementLeurres: [LigneLeurre] = []

    var estVide: Bool { nombreSorties == 0 }
}

// MARK: - Vue principale

struct StatistiquesView: View {

    @Environment(\.dismiss) private var dismiss

    @Query private var sorties: [Sortie]
    @Query private var leurres: [Leurre]

    var body: some View {
        let stats = agreger()

        Group {
            if stats.estVide {
                EtatVideStatistiques()
            } else {
                let analyse = Self.analyse(sorties: sorties, leurres: leurres)
                List {
                    BlocSorties(stats: stats)
                    BlocPrises(stats: stats)
                    BlocRendementLeurres(analyse: analyse)
                    BlocAnalyses(analyse: analyse)
                    BlocEspeces(analyse: analyse)
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Statistiques")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Fermer") { dismiss() }
            }
        }
    }

    // MARK: - Agrégation

    /// Passage unique sur les sorties terminées.
    /// conditions n'est lu qu'une fois par sortie : chaque accès décode du JSON.
    private func agreger() -> StatistiquesAgregat {

        var agregat = StatistiquesAgregat()

        let terminees = sorties.filter { $0.etat == .terminee }
        guard !terminees.isEmpty else { return agregat }

        agregat.nombreSorties = terminees.count

        var compteursEspeces: [String: Int] = [:]
        var compteursLeurres: [Int: Int]    = [:]
        var prisesHorsBoite: Int            = 0

        for sortie in terminees {

            // Durées — sorties chronométrées de bout en bout uniquement
            if sortie.heureDepart != nil, sortie.heureRetour != nil,
               let duree = sortie.duree, duree > 0 {
                agregat.dureeCumulee += duree
                agregat.nombreSortiesChronometrees += 1
            }

            // Date de la dernière sortie
            if let derniere = agregat.derniereSortie {
                if sortie.date > derniere { agregat.derniereSortie = sortie.date }
            } else {
                agregat.derniereSortie = sortie.date
            }

            // Distance
            agregat.distanceCumuleeMN += sortie.distanceMillesNautiques

            // Secteur — un seul décodage de conditions
            let secteur: SecteurPeche
            if let conditions = sortie.conditions {
                secteur = SecteurPeche.depuis(conditions.zone)
            } else {
                secteur = .nonRenseigne
            }
            agregat.repartition[secteur, default: 0] += 1

            // Prises
            for prise in sortie.prises {
                agregat.nombrePrises += 1
                if prise.relache { agregat.nombreRelachees += 1 }

                compteursEspeces[prise.especeAffichee, default: 0] += 1

                if let identifiant = prise.leurreID {
                    compteursLeurres[identifiant, default: 0] += 1
                } else if let libre = prise.leurreLibre, !libre.isEmpty {
                    prisesHorsBoite += 1
                }
            }
        }

        // Moyennes
        if agregat.nombreSortiesChronometrees > 0 {
            agregat.dureeMoyenne = agregat.dureeCumulee / Double(agregat.nombreSortiesChronometrees)
        }
        agregat.distanceMoyenneMN = agregat.distanceCumuleeMN / Double(agregat.nombreSorties)
        agregat.moyennePrisesParSortie = Double(agregat.nombrePrises) / Double(agregat.nombreSorties)

        // Classement des espèces, décroissant, nom en départage
        agregat.classementEspeces = compteursEspeces
            .map { LigneEspece(nom: $0.key, nombre: $0.value) }
            .sorted { $0.nombre == $1.nombre ? $0.nom < $1.nom : $0.nombre > $1.nombre }

        // Classement des leurres — croisement avec le Module 1
        var lignesLeurres: [LigneLeurre] = compteursLeurres.compactMap { identifiant, nombre in
            guard let leurre = leurres.first(where: { $0.id == identifiant }) else { return nil }
            return LigneLeurre(
                id: String(identifiant),
                nom: leurre.nom,
                marque: leurre.marque,
                nombre: nombre
            )
        }

        if prisesHorsBoite > 0 {
            lignesLeurres.append(
                LigneLeurre(id: "horsBoite", nom: "Hors boîte", marque: "", nombre: prisesHorsBoite)
            )
        }

        agregat.classementLeurres = lignesLeurres
            .sorted { $0.nombre == $1.nombre ? $0.nom < $1.nom : $0.nombre > $1.nombre }

        return agregat
    }
}

// MARK: - Bloc Sorties

private struct BlocSorties: View {
    let stats: StatistiquesAgregat

    var body: some View {
        Section("Sorties") {

            LigneStat(libelle: "Nombre de sorties", valeur: "\(stats.nombreSorties)")

            if stats.nombreSortiesChronometrees > 0 {
                LigneStat(
                    libelle: "Durée cumulée",
                    valeur: FormatStat.duree(stats.dureeCumulee)
                )
                LigneStat(
                    libelle: "Durée moyenne",
                    valeur: FormatStat.duree(stats.dureeMoyenne),
                    detail: stats.nombreSortiesChronometrees < stats.nombreSorties
                        ? "sur \(stats.nombreSortiesChronometrees) sortie\(stats.nombreSortiesChronometrees > 1 ? "s" : "") chronométrée\(stats.nombreSortiesChronometrees > 1 ? "s" : "")"
                        : nil
                )
            }

            if let derniere = stats.derniereSortie {
                LigneStat(libelle: "Dernière sortie", valeur: FormatStat.date(derniere))
            }

            LigneStat(
                libelle: "Distance cumulée",
                valeur: String(format: "%.1f MN", stats.distanceCumuleeMN)
            )
            LigneStat(
                libelle: "Distance moyenne",
                valeur: String(format: "%.1f MN", stats.distanceMoyenneMN)
            )

            ForEach(SecteurPeche.allCases, id: \.self) { secteur in
                let nombre = stats.repartition[secteur] ?? 0
                if nombre > 0 {
                    LigneStat(
                        libelle: secteur.displayName,
                        valeur: "\(nombre)",
                        icone: secteur.icon
                    )
                }
            }
        }
    }
}

// MARK: - Bloc Prises

private struct BlocPrises: View {
    let stats: StatistiquesAgregat

    var body: some View {
        Section("Prises") {

            if stats.nombrePrises == 0 {
                Text("Aucune prise enregistrée")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))
            } else {
                LigneStat(libelle: "Nombre de prises", valeur: "\(stats.nombrePrises)")

                if stats.nombreRelachees > 0 {
                    LigneStat(libelle: "Dont relâchées", valeur: "\(stats.nombreRelachees)")
                }

                LigneStat(
                    libelle: "Moyenne par sortie",
                    valeur: String(format: "%.1f", stats.moyennePrisesParSortie)
                )
            }
        }
    }
}

// MARK: - Ligne générique

private struct LigneStat: View {
    let libelle: String
    let valeur: String
    var detail: String? = nil
    var icone: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            if let icone {
                Image(systemName: icone)
                    .foregroundColor(Color(hex: "0277BD"))
                    .frame(width: 22)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(libelle)
                    .font(.system(size: 16))
                if let detail {
                    Text(detail)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(valeur)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0277BD"))
        }
    }
}

// MARK: - État vide

private struct EtatVideStatistiques: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 52))
                .foregroundColor(.secondary.opacity(0.5))

            Text("Aucune sortie terminée")
                .font(.system(size: 19, weight: .semibold))

            Text("Les statistiques apparaîtront dès qu'une sortie aura été clôturée dans le journal.")
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F5"))
    }
}

// MARK: - Formatage

private enum FormatStat {

    static func duree(_ intervalle: TimeInterval) -> String {
        guard intervalle > 0 else { return "—" }
        let heures  = Int(intervalle) / 3600
        let minutes = (Int(intervalle) % 3600) / 60
        if heures > 0 { return "\(heures)h \(minutes)min" }
        return "\(minutes)min"
    }

    static func date(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "dd/MM/yyyy"
        f.locale     = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }
}

// MARK: - Analyse du journal (rendement, conditions, spread, espèces)

extension StatistiquesView {

    /// Données du journal pour StatistiquesCalcul (un décodage de conditions par sortie et par prise).
    static func donnees(sorties: [Sortie], leurres: [Leurre]) -> (sorties: [StatSortie], leurres: [StatLeurre]) {
        let terminees = sorties.filter { $0.etat == .terminee }
        let s = terminees.map { sortie in
            StatSortie(
                debut: sortie.heureDepart,
                fin: sortie.heureRetour,
                pauses: sortie.cumulPausesSecondes,
                conditions: sortie.conditions,
                spreads: sortie.spreads,
                prises: sortie.prises.map { p in
                    let cle = Espece.depuis(rawValue: p.especeNom)?.rawValue
                        ?? (p.especeNom.isEmpty ? (p.especeLibre ?? "") : p.especeNom)
                    return StatPrise(heure: p.heure, especeCle: cle, especeNom: p.especeAffichee,
                                     leurreID: p.leurreID, relache: p.relache,
                                     tailleCm: p.tailleCm, poidsKg: p.poidsKg, conditions: p.conditions)
                }
            )
        }
        let l = leurres.map { StatLeurre(id: $0.id, nom: $0.nom, marque: $0.marque, famille: $0.contraste ?? $0.profilVisuel) }
        return (s, l)
    }

    /// Fiche et taille minimale de chaque espèce de l'énumération.
    static func fiches() -> [String: (fiche: String?, tailleMin: Double?)] {
        var r: [String: (fiche: String?, tailleMin: Double?)] = [:]
        for e in Espece.allCases {
            let f = e.ficheIdentifiant.flatMap { EspecesDatabase.shared.espece(identifiant: $0) }
            r[e.rawValue] = (e.ficheIdentifiant, f?.tailleMinLegale)
        }
        return r
    }

    static func analyse(sorties: [Sortie], leurres: [Leurre]) -> AnalyseJournal {
        let d = donnees(sorties: sorties, leurres: leurres)
        return StatistiquesCalcul.analyser(sorties: d.sorties, leurres: d.leurres,
                                           marees: TideService.joursEnCache(), fiches: fiches())
    }
}

// MARK: - Ligne de rendement

private struct LigneRendementVue: View {
    let ligne: LigneRendement
    /// Rendement le plus élevé de la liste, pour la longueur des barres.
    let maximum: Double
    var afficherDetail = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ligne.libelle).font(.system(size: 16))
                    if afficherDetail && !ligne.detail.isEmpty {
                        Text(ligne.detail).font(.system(size: 13)).foregroundColor(.secondary)
                    }
                }
                Spacer()
                if let r = ligne.rendement {
                    Text("\(StatistiquesCalcul.rendement(r)) /h")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(ligne.echantillonFaible ? .secondary : Color(hex: "0277BD"))
                } else {
                    Text("\(ligne.prises + ligne.horsEffort)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            if let r = ligne.rendement, maximum > 0 {
                GeometryReader { g in
                    Capsule()
                        .fill(Color(hex: "0277BD").opacity(ligne.echantillonFaible ? 0.25 : 0.7))
                        .frame(width: max(4, g.size.width * CGFloat(r / maximum)), height: 5)
                }
                .frame(height: 5)
            }
            Text(legende)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var legende: String {
        var t = "\(ligne.prises) prise\(ligne.prises > 1 ? "s" : "")"
        if ligne.heures > 0 { t += " en \(StatistiquesCalcul.heures(ligne.heures))" } else { t += ", temps à l'eau non relevé" }
        if ligne.horsEffort > 0 { t += " (+\(ligne.horsEffort) hors spread enregistré)" }
        if ligne.rendement != nil && ligne.echantillonFaible { t += " · peu d'heures, tendance à confirmer" }
        return t
    }
}

private func maximum(_ lignes: [LigneRendement]) -> Double {
    lignes.compactMap(\.rendement).max() ?? 0
}

// MARK: - Bloc Rendement des leurres

private struct BlocRendementLeurres: View {
    let analyse: AnalyseJournal

    var body: some View {
        Section {
            if analyse.leurres.isEmpty {
                Text("Aucune prise rattachée à un leurre de la boîte")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))
            } else {
                let m = maximum(analyse.leurres)
                ForEach(analyse.leurres.prefix(8)) { LigneRendementVue(ligne: $0, maximum: m) }
                if analyse.leurres.count > 8 {
                    NavigationLink("Tous les leurres preneurs (\(analyse.leurres.count))") {
                        List {
                            Section {
                                ForEach(analyse.leurres) { LigneRendementVue(ligne: $0, maximum: m) }
                            } footer: {
                                Text(Self.explication)
                            }
                        }
                        .listStyle(.insetGrouped)
                        .navigationTitle("Leurres preneurs")
                    }
                }
            }
        } header: {
            Text("Rendement des leurres")
        } footer: {
            Text(Self.explication)
        }
    }

    static let explication = "Prises par heure à l'eau, d'après les spreads enregistrés pendant les sorties. Seuls les leurres qui ont pris figurent ici. En gris : moins de 3 heures de pêche, tendance à confirmer."
}

// MARK: - Bloc Analyses (conditions, spread, fiabilité)

private struct BlocAnalyses: View {
    let analyse: AnalyseJournal

    var body: some View {
        Section {
            NavigationLink {
                VueConditions(analyse: analyse)
            } label: {
                Label("Prises selon les conditions", systemImage: "cloud.sun")
            }
            NavigationLink {
                VueSpread(analyse: analyse)
            } label: {
                Label("Contrôle du spread", systemImage: "point.3.connected.trianglepath.dotted")
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Temps de pêche relevé : \(StatistiquesCalcul.heures(analyse.heuresPeche)) sur \(analyse.sortiesAvecSpread) sortie\(analyse.sortiesAvecSpread > 1 ? "s" : "")")
                    .font(.system(size: 14))
                if analyse.sortiesSansSpread > 0 || analyse.prisesSansEffort > 0 {
                    Text(fiabilite)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Analyses")
        }
    }

    private var fiabilite: String {
        var morceaux: [String] = []
        if analyse.sortiesSansSpread > 0 {
            morceaux.append("\(analyse.sortiesSansSpread) sortie\(analyse.sortiesSansSpread > 1 ? "s" : "") sans spread enregistré")
        }
        if analyse.prisesSansEffort > 0 {
            morceaux.append("\(analyse.prisesSansEffort) prise\(analyse.prisesSansEffort > 1 ? "s" : "") hors spread enregistré")
        }
        return morceaux.joined(separator: " ; ") + " : ces prises comptent dans les totaux, pas dans les rendements. Enregistrer le spread à chaque changement de leurre rend les chiffres plus sûrs."
    }
}

private struct VueConditions: View {
    let analyse: AnalyseJournal

    var body: some View {
        List {
            Section {
                Text("Pour chaque condition : prises par heure de pêche. Moment, marée et lune sont recalculés quart d'heure par quart d'heure (aube et crépuscule : 45 minutes autour du lever et du coucher) ; zone, eau et courant viennent de la saisie de la sortie.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            ForEach(analyse.facteurs) { f in
                Section(f.titre) {
                    let m = maximum(f.lignes)
                    ForEach(f.lignes) { LigneRendementVue(ligne: $0, maximum: m, afficherDetail: false) }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Selon les conditions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct VueSpread: View {
    let analyse: AnalyseJournal

    var body: some View {
        List {
            Section {
                ForEach(analyse.postes) { LigneRendementVue(ligne: $0, maximum: maximum(analyse.postes), afficherDetail: false) }
            } header: {
                Text("Par poste")
            } footer: {
                Text("Heures : temps passé par une ligne à ce poste. Une prise compte pour le poste où son leurre était monté.")
            }
            ForEach(analyse.couleurs) { f in
                Section {
                    let m = maximum(f.lignes)
                    ForEach(f.lignes) { LigneRendementVue(ligne: $0, maximum: m, afficherDetail: false) }
                } header: {
                    Text("Couleur — contraste \(f.titre.lowercased())")
                }
            }
            if !analyse.couleurs.isEmpty {
                Section {
                    Text("Famille de couleur du leurre selon le besoin de contraste du moment : c'est ce qui permet de vérifier, avec tes propres chiffres, la répartition naturel, sombre, flashy et contrasté proposée par le moteur.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Contrôle du spread")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Bloc Bilan par espèce

private struct BlocEspeces: View {
    let analyse: AnalyseJournal

    var body: some View {
        Section("Bilan par espèce") {
            if analyse.especes.isEmpty {
                Text("Aucune prise enregistrée")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))
            } else {
                ForEach(analyse.especes) { b in
                    NavigationLink {
                        VueBilanEspece(bilan: b)
                    } label: {
                        HStack {
                            Text(b.nom).font(.system(size: 16))
                            if b.gardesSousTaille > 0 {
                                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            }
                            Spacer()
                            Text("\(b.prises)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(hex: "0277BD"))
                        }
                    }
                }
            }
        }
    }
}

struct VueBilanEspece: View {
    let bilan: BilanEspece

    var body: some View {
        List {
            ContenuBilanEspece(bilan: bilan)
            if let id = bilan.ficheIdentifiant, let fiche = EspecesDatabase.shared.espece(identifiant: id) {
                Section {
                    NavigationLink {
                        EspeceDetailView(espece: fiche)
                    } label: {
                        Label("Voir la fiche : \(fiche.nomCommun)", systemImage: "book")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(bilan.nom)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Contenu partagé par le bilan des statistiques et le bloc « Dans mon journal » de la fiche.
struct ContenuBilanEspece: View {
    let bilan: BilanEspece

    var body: some View {
        Section("Prises") {
            ligne("Prises", "\(bilan.prises)")
            if bilan.relachees > 0 { ligne("Dont remises à l'eau", "\(bilan.relachees)") }
            if let t = bilan.tailleMoyenne { ligne("Taille moyenne", String(format: "%.0f cm", t)) }
            if let t = bilan.tailleMax { ligne("Plus grande", String(format: "%.0f cm", t)) }
            if let p = bilan.poidsMoyen { ligne("Poids moyen", poids(p)) }
            if let p = bilan.poidsMax { ligne("Record", poids(p)) }
            if !bilan.secteurs.isEmpty { ligne("Zones", bilan.secteurs.joined(separator: ", ")) }
            if bilan.gardesSousTaille > 0, let min = bilan.tailleMinLegale {
                Label("\(bilan.gardesSousTaille) poisson\(bilan.gardesSousTaille > 1 ? "s" : "") gardé\(bilan.gardesSousTaille > 1 ? "s" : "") sous la taille minimale de la fiche (\(Int(min)) cm). À vérifier dans la réglementation de la province.",
                      systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.orange)
            }
        }
        if bilan.meilleurMoment != nil || bilan.meilleureMaree != nil {
            Section {
                if let m = bilan.meilleurMoment { meilleur("Moment", m) }
                if let m = bilan.meilleureMaree { meilleur("Marée", m) }
            } header: {
                Text("Quand elle se prend le mieux")
            } footer: {
                Text("Prises de l'espèce par heure de pêche, toutes sorties confondues (une heure de pêche au moins).")
            }
        }
        if !bilan.leurres.isEmpty {
            Section("Leurres preneurs") {
                let m = bilan.leurres.compactMap(\.rendement).max() ?? 0
                ForEach(bilan.leurres) { LigneRendementVue(ligne: $0, maximum: m) }
            }
        }
    }

    private func ligne(_ libelle: String, _ valeur: String) -> some View {
        HStack {
            Text(libelle).font(.system(size: 16))
            Spacer()
            Text(valeur).font(.system(size: 16, weight: .semibold)).foregroundColor(Color(hex: "0277BD"))
        }
    }

    private func meilleur(_ titre: String, _ l: LigneRendement) -> some View {
        HStack {
            Text(titre).font(.system(size: 16))
            Spacer()
            Text("\(l.libelle) · \(StatistiquesCalcul.rendement(l.rendement ?? 0)) /h")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(hex: "0277BD"))
        }
    }

    private func poids(_ kg: Double) -> String {
        String(format: "%.1f kg", kg).replacingOccurrences(of: ".", with: ",")
    }
}

// MARK: - Bloc « Dans mon journal » de la fiche espèce

/// Résumé du journal pour une fiche de la Bibliothèque (affiché seulement s'il y a des prises).
struct BlocJournalEspece: View {
    let bilan: BilanEspece

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "book.closed")
                    .foregroundColor(Color(hex: "0277BD"))
                Text("DANS MON JOURNAL")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            ligne("Prises", "\(bilan.prises)" + (bilan.relachees > 0 ? " (\(bilan.relachees) remises à l'eau)" : ""))
            if let p = bilan.poidsMax {
                ligne("Record", String(format: "%.1f kg", p).replacingOccurrences(of: ".", with: ","))
            } else if let t = bilan.tailleMax {
                ligne("Plus grande", String(format: "%.0f cm", t))
            }
            if let l = bilan.leurres.first { ligne("Meilleur leurre", l.libelle) }
            if let m = bilan.meilleurMoment { ligne("Meilleur moment", m.libelle) }
            if let m = bilan.meilleureMaree { ligne("Meilleure marée", m.libelle) }
            if bilan.gardesSousTaille > 0 {
                Text("\(bilan.gardesSousTaille) poisson\(bilan.gardesSousTaille > 1 ? "s" : "") gardé\(bilan.gardesSousTaille > 1 ? "s" : "") sous la taille minimale indiquée.")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func ligne(_ libelle: String, _ valeur: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(libelle).font(.subheadline).foregroundColor(.secondary)
            Spacer()
            Text(valeur).font(.subheadline).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
    }
}
