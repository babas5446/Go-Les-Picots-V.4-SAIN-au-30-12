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
                List {
                    BlocSorties(stats: stats)
                    BlocPrises(stats: stats)
                    BlocLeurres(stats: stats)
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

                ForEach(stats.classementEspeces) { ligne in
                    LigneStat(libelle: ligne.nom, valeur: "\(ligne.nombre)")
                }
            }
        }
    }
}

// MARK: - Bloc Leurres

private struct BlocLeurres: View {
    let stats: StatistiquesAgregat

    var body: some View {
        Section("Leurres les plus productifs") {

            if stats.classementLeurres.isEmpty {
                Text("Aucune prise rattachée à un leurre")
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))
            } else {
                ForEach(stats.classementLeurres.prefix(5)) { ligne in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(ligne.nom)
                                .font(.system(size: 16))
                            if !ligne.marque.isEmpty {
                                Text(ligne.marque)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()
                        Text("\(ligne.nombre)")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                }
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
