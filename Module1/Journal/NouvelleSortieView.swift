//
//  NouvelleSortieView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Formulaire d'édition d'une sortie de pêche.
//
//  V4.2 — refonte du cycle de vie :
//  - Un seul initialiseur. La Sortie est créée et insérée par
//    JournalViewModel.creerSortie() avant présentation. L'objet reçu est donc
//    déjà persisté et son identité ne change plus d'une recomposition à l'autre.
//    C'est la correction de la cause commune des symptômes des sessions 3 et 4 :
//    bouton sans effet, saisie impossible, garde-fou inerte, perte de saisie.
//  - Bandeau à quatre états : non démarrée, en cours, en pause, terminée.
//  - Chronomètre par TimelineView(.periodic) : le rafraîchissement reste confiné
//    au bandeau. L'ancien Timer.publish écrivait dans un @State et recomposait
//    tout le corps de la vue chaque seconde, ce qui aggravait l'instabilité.
//  - Toggle « Heure de retour » supprimé : l'heure est posée par « Terminer la
//    sortie ». Elle reste modifiable, mais seulement après clôture.
//  - Bilan de fin de sortie : horaires, durées, distance, vitesses, consommation,
//    export GPX vers Boating.
//  - Photo : menu « Prendre une photo » / « Choisir dans la bibliothèque ».
//    Requiert NSCameraUsageDescription dans les réglages du projet.
//  - Les leurres des spreads sont résolus par FetchDescriptor ciblé au lieu d'un
//    @Query chargeant les 75 leurres de la boîte, qui provoquait l'écran blanc
//    à l'ouverture.
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

    // MARK: - Sortie éditée

    /// Objet déjà inséré dans le contexte par le ViewModel.
    let sortie: Sortie

    // MARK: - Champs du formulaire

    @State private var nomSortie: String
    @State private var nomSpot: String
    @State private var notes: String
    @State private var heureDepart: Date
    @State private var heureRetour: Date
    @State private var conditions: ConditionsPeche?
    @State private var spreads: [SpreadSnapshot]
    @State private var carburantTexte: String

    // MARK: - Leurres des spreads (résolution ciblée)

    @State private var leurresSpread: [Int: Leurre] = [:]

    

    // MARK: - Navigation

    /// Feuille unique, arbitrée par une seule énumération : plusieurs
    /// .sheet sur un même nœud de vue peuvent se neutraliser, la seconde
    /// refermant aussitôt la première (symptôme : fiche de prise qui s'ouvre
    /// et se referme immédiatement).
    @State private var feuille: FeuilleSortie?

    // MARK: - Export GPX


    // MARK: - Alertes

    @State private var afficherAucunSpread: Bool = false
    @State private var afficherConfirmationFin: Bool = false
    @State private var afficherRestauration: Bool = false

    // MARK: - Initialisation

    init(viewModel: JournalViewModel, sortie: Sortie) {
        self.viewModel = viewModel
        self.sortie    = sortie

        _nomSortie      = State(initialValue: sortie.nomSortie)
        _nomSpot        = State(initialValue: sortie.nomSpot)
        _notes          = State(initialValue: sortie.notes)
        _heureDepart    = State(initialValue: sortie.heureDepart ?? sortie.date)
        _heureRetour    = State(initialValue: sortie.heureRetour ?? Date())
        _conditions     = State(initialValue: sortie.conditions)
        _spreads        = State(initialValue: sortie.spreads)
        _carburantTexte = State(
            initialValue: sortie.carburantLitres.map { String(format: "%.1f", $0) } ?? ""
        )
    }

    // MARK: - État courant

    private var etat: EtatSortie { sortie.etat }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    sectionCycleVie

                    if etat == .terminee {
                        sectionBilan
                    }

                    sectionInfos
                    sectionConditions
                    sectionSpreads
                    sectionPrises
                    sectionNotes

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(hex: "F5F5F5"))
            .navigationTitle(etat == .nonDemarree ? "Nouvelle sortie" : "Sortie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        sauvegarder(fermer: true)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
                        sauvegarder(fermer: true)
                    }
                    .fontWeight(.semibold)
                }
            }
            .sheet(item: $feuille) { feuille in
                switch feuille {
                case .nouvellePrise:
                    PriseFormView(viewModel: viewModel, sortie: sortie)
                case .editionPrise(let prise):
                    PriseFormView(viewModel: viewModel, sortie: sortie, prise: prise)
                case .partage(let fichier):
                    PartageActivite(url: fichier.url)
                }
            }
            .alert("Aucun spread disponible", isPresented: $afficherAucunSpread) {
                Button("Compris", role: .cancel) { }
            } message: {
                Text("Lancez d'abord une suggestion dans le module IA : le spread proposé pourra ensuite être reporté ici.")
            }
            .alert("Terminer la sortie ?", isPresented: $afficherConfirmationFin) {
                Button("Terminer", role: .destructive) {
                    sauvegarderChamps()
                    viewModel.terminerSortie(sortie)
                    heureRetour = sortie.heureRetour ?? Date()
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("La trace GPS sera arrêtée et l'heure de retour enregistrée. La sortie restera modifiable.")
            }
            .alert("Action impossible", isPresented: $viewModel.showError) {
                Button("Compris", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Sortie interrompue", isPresented: $afficherRestauration) {
                Button("Compris", role: .cancel) { }
            } message: {
                Text("Cette sortie était encore ouverte lors de la dernière fermeture de l'application. Elle a été mise en pause au dernier point enregistré. Appuyez sur « Reprendre » pour continuer.")
            }
            .task {
                await chargerLeurresSpread()
                if viewModel.sortieRestauree?.id == sortie.id {
                    afficherRestauration = true
                    viewModel.sortieRestauree = nil
                }
            }
            .onChange(of: spreads.count) { _, _ in
                // Report immédiat : un spread ajouté ou retiré ne doit pas
                // attendre « Enregistrer » pour exister sur l'objet persisté.
                sortie.spreads = spreads
                viewModel.modifierSortie(sortie)

                Task { await chargerLeurresSpread() }
            }
            .onAppear {
                print("▶︎ \(Self.horodatage()) NSV APPEAR — supprimée \(sortie.isDeleted)")
            }
            .onDisappear {
                // Plus aucune suppression ici : onDisappear se déclenche aussi
                // à l'ouverture d'une feuille ou de l'appareil photo, alors que
                // la saisie en cours n'est pas encore reportée sur l'objet.
                // Le test du brouillon vide est fait à la fermeture explicite.
                print("◀︎ \(Self.horodatage()) NSV DISAPPEAR — supprimée \(sortie.isDeleted)")
            }
        }
    }

    // MARK: - Section cycle de vie

    private var sectionCycleVie: some View {
        VStack(spacing: 12) {

            bandeauEtat

            switch etat {
            case .nonDemarree:
                boutonCycle(
                    titre: "Démarrer la sortie",
                    icone: "play.circle.fill",
                    couleur: .green
                ) {
                    sauvegarderChamps()
                    viewModel.demarrerSortie(sortie)
                    heureDepart = sortie.heureDepart ?? Date()
                }

            case .enCours:
                HStack(spacing: 10) {
                    boutonCycle(
                        titre: "Pause",
                        icone: "pause.circle.fill",
                        couleur: .orange
                    ) {
                        viewModel.mettreEnPause(sortie)
                    }
                    boutonCycle(
                        titre: "Terminer",
                        icone: "stop.circle.fill",
                        couleur: .red
                    ) {
                        afficherConfirmationFin = true
                    }
                }

            case .enPause:
                HStack(spacing: 10) {
                    boutonCycle(
                        titre: "Reprendre",
                        icone: "play.circle.fill",
                        couleur: .orange
                    ) {
                        viewModel.reprendreSortie(sortie)
                    }
                    boutonCycle(
                        titre: "Terminer",
                        icone: "stop.circle.fill",
                        couleur: .red
                    ) {
                        afficherConfirmationFin = true
                    }
                }

            case .terminee:
                EmptyView()
            }
        }
        .carteJournal(titre: "Sortie", icone: "ferry.fill")
    }

    private func boutonCycle(
        titre: String,
        icone: String,
        couleur: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icone)
                    .font(.title3)
                Text(titre)
                    .fontWeight(.bold)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(couleur)
            .foregroundColor(.white)
            .cornerRadius(14)
        }
    }

    // MARK: - Bandeau d'état

    /// Le chronomètre est confiné dans un TimelineView : lui seul se rafraîchit
    /// chaque seconde, le reste du formulaire n'est pas recomposé.
    private var bandeauEtat: some View {
        Group {
            switch etat {
            case .nonDemarree:
                bandeau(
                    couleur: Color(hex: "0277BD"),
                    icone: "clock",
                    texte: "Sortie non démarrée"
                )

            case .enCours:
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    bandeauActif(
                        couleur: .green,
                        libelle: "En cours",
                        chrono: Self.chrono(sortie.dureeNavigation)
                    )
                }

            case .enPause:
                // Figé : en pause, dureeNavigation ne progresse plus.
                bandeauActif(
                    couleur: .orange,
                    libelle: "En pause",
                    chrono: Self.chrono(sortie.dureeNavigation)
                )

            case .terminee:
                bandeau(
                    couleur: .secondary,
                    icone: "checkmark.circle.fill",
                    texte: "Sortie terminée"
                )
            }
        }
    }

    private func bandeau(couleur: Color, icone: String, texte: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icone)
            Text(texte)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
        }
        .foregroundColor(couleur)
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(couleur.opacity(0.12))
        .cornerRadius(10)
    }

    private func bandeauActif(couleur: Color, libelle: String, chrono: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(couleur)
                    .frame(width: 10, height: 10)
                Text(libelle.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("\(viewModel.traceGPS.nombrePointsSession) pts GPS")
                    .font(.caption)
            }

            HStack {
                Image(systemName: "timer")
                Text(chrono)
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.semibold)
                Spacer()
            }
        }
        .foregroundColor(couleur)
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(couleur.opacity(0.12))
        .cornerRadius(10)
    }

    // MARK: - Section bilan (sortie terminée)

    private var sectionBilan: some View {
        VStack(alignment: .leading, spacing: 14) {

            // Horaires
            HStack {
                bilanValeur("Départ", Self.heure(sortie.heureDepart))
                Spacer()
                bilanValeur("Retour", Self.heure(sortie.heureRetour))
            }

            Divider()

            // Durées
            HStack(alignment: .top) {
                bilanValeur("Durée totale", sortie.dureeFormatee ?? "—")
                Spacer()
                bilanValeur("Navigation", sortie.dureeNavigationFormatee ?? "—")
                Spacer()
                bilanValeur("Pauses", sortie.dureePausesFormatee ?? "—")
            }

            Divider()

            // Trajet
            HStack(alignment: .top) {
                bilanValeur("Distance", sortie.distanceFormatee ?? "—")
                Spacer()
                bilanValeur("Moyenne", sortie.vitesseMoyenneFormatee ?? "—")
                Spacer()
                bilanValeur("Maxi", sortie.vitesseMaxFormatee ?? "—")
            }

            Divider()

            // Carburant
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Plein au retour")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 6) {
                        TextField("0", text: $carburantTexte)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 90)
                            .onChange(of: carburantTexte) { _, _ in
                                enregistrerCarburant()
                            }
                        Text("L")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                bilanValeur("Consommation", sortie.consommationHoraireFormatee ?? "—")
                Spacer()
                bilanValeur("Au mille", sortie.consommationParMilleFormatee ?? "—")
            }

            // Export
            if sortie.exportGPXPossible {
                Button {
                    if let url = viewModel.exporterGPX(sortie: sortie) {
                        feuille = .partage(FichierPartage(url: url))
                    }
                } label: {
                    Label("Exporter la trace (GPX)", systemImage: "square.and.arrow.up")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "0277BD").opacity(0.12))
                        .foregroundColor(Color(hex: "0277BD"))
                        .cornerRadius(10)
                }
                .padding(.top, 4)

                Text("Ouvrez le fichier dans Boating pour visualiser le tracé et les prises.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .carteJournal(titre: "Bilan de la sortie", icone: "chart.bar.fill")
    }

    private func bilanValeur(_ titre: String, _ valeur: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(titre)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(valeur)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }

    // MARK: - Section informations

    private var sectionInfos: some View {
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 6) {
                Text("Nom de la sortie")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                TextField("Sortie du …", text: $nomSortie)
                    .textFieldStyle(.roundedBorder)
            }

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
                    .environment(\.locale, Locale(identifier: "fr_FR"))
            }

            // L'heure de retour n'est modifiable qu'une fois la sortie close :
            // avant, elle est posée par « Terminer la sortie ».
            if etat == .terminee {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Heure de retour")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    DatePicker(
                        "",
                        selection: $heureRetour,
                        in: heureDepart...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "fr_FR"))
                }
            }
        }
        .carteJournal(titre: "Informations", icone: "info.circle.fill")
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

    // MARK: - Section spreads

    private var sectionSpreads: some View {
        VStack(alignment: .leading, spacing: 12) {

            if spreads.isEmpty {
                Text("Aucune configuration enregistrée pour cette sortie.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 4)
            } else {
                ForEach(Array(spreads.enumerated()), id: \.element.id) { index, spread in
                    carteSpread(spread, numero: index + 1)
                }
            }

            Button {
                ajouterSpreadSuggere()
            } label: {
                Label("Ajouter le spread suggéré", systemImage: "plus")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(hex: "0277BD").opacity(0.12))
                    .foregroundColor(Color(hex: "0277BD"))
                    .cornerRadius(10)
            }
        }
        .carteJournal(titre: "Spreads de la sortie", icone: "arrow.triangle.branch")
    }

    private func carteSpread(_ spread: SpreadSnapshot, numero: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack(spacing: 8) {
                Text("Spread \(numero)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "0277BD"))

                Text("· \(spread.heureFormatee)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Button {
                    spreads.removeAll { $0.id == spread.id }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(spread.descriptionCourte)
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach(spread.lignes) { ligne in
                    ligneSpreadView(ligne)
                }
            }
        }
        .padding(10)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(10)
    }

    private func ligneSpreadView(_ ligne: LigneSpread) -> some View {
        HStack(spacing: 10) {
            if let leurre = leurresSpread[ligne.leurreID],
               let data = leurre.photoData,
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "fish")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(ligne.descriptionPosition)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "0277BD"))
                Text("\(ligne.nom) — \(ligne.marque)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
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
                        .onTapGesture { feuille = .editionPrise(prise) }
                }
            }

            Button {
                feuille = .nouvellePrise
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

    /// Reporte dans la sortie le dernier spread produit par le module de suggestion.
    /// L'heure est celle du report, pas celle du calcul : c'est le moment de la
    /// mise à l'eau.
    private func ajouterSpreadSuggere() {
        guard var snapshot = SpreadSnapshotService.dernierSpread() else {
            afficherAucunSpread = true
            return
        }
        snapshot.id   = UUID()
        snapshot.date = Date()
        spreads.append(snapshot)
    }

    /// Reporte les champs du formulaire sur l'objet persisté.
    private func sauvegarderChamps() {
        sortie.nomSortie = nomSortie
        sortie.nomSpot   = nomSpot
        sortie.notes     = notes
        sortie.conditions = conditions
        sortie.spreads    = spreads

        // Les horaires ne sont repris du formulaire que là où ils sont saisissables.
        if sortie.etat == .nonDemarree || sortie.etat == .terminee {
            sortie.heureDepart = heureDepart
        }
        if sortie.etat == .terminee {
            sortie.heureRetour = heureRetour
        }
    }

    private func sauvegarder(fermer: Bool) {
        // Les champs du formulaire sont d'abord reportés : le test du brouillon
        // vide porte ainsi sur ce que l'utilisateur a réellement saisi.
        sauvegarderChamps()
        // Brouillon vide : on ferme d'abord, on supprime ensuite, pour que la
        // vue ne relise pas une sortie déjà détruite pendant l'animation.
        if fermer, viewModel.estBrouillonVide(sortie) {
            let brouillon = sortie
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                viewModel.supprimerSiBrouillonVide(brouillon)
            }
            return
        }
        viewModel.modifierSortie(sortie)
        if fermer { dismiss() }
    }

    private func enregistrerCarburant() {
        let normalise = carburantTexte.replacingOccurrences(of: ",", with: ".")
        viewModel.enregistrerCarburant(Double(normalise), pour: sortie)
    }

    /// Résout les seuls leurres présents dans les spreads de la sortie.
    /// Un @Query sur la boîte entière chargeait 75 objets et leurs photos à
    /// l'ouverture, d'où l'écran blanc.
    private func chargerLeurresSpread() async {
        let ids = Array(Set(spreads.flatMap(\.leurreIDs)))
        guard !ids.isEmpty else {
            leurresSpread = [:]
            return
        }

        var descriptor = FetchDescriptor<Leurre>(
            predicate: #Predicate { ids.contains($0.id) }
        )
        descriptor.fetchLimit = ids.count

        let resultats = (try? context.fetch(descriptor)) ?? []
        leurresSpread = Dictionary(uniqueKeysWithValues: resultats.map { ($0.id, $0) })
    }

    // MARK: - Formatage

    private static func chrono(_ intervalle: TimeInterval?) -> String {
        let total = Int(max(0, intervalle ?? 0))
        return String(format: "%02d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }

    private static func heure(_ date: Date?) -> String {
        guard let date else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "HH'h'mm"
        f.locale     = Locale(identifier: "fr_FR")
        return f.string(from: date)
    }
}

// MARK: - Partage de fichier

/// Les trois feuilles que présente le formulaire de sortie.
enum FeuilleSortie: Identifiable {
    case nouvellePrise
    case editionPrise(Prise)
    case partage(FichierPartage)

    var id: String {
        switch self {
        case .nouvellePrise:          return "nouvelle-prise"
        case .editionPrise(let p):    return "prise-\(p.id.uuidString)"
        case .partage(let f):         return "partage-\(f.id.uuidString)"
        }
    }
}

/// URL rendue identifiable pour la présentation par .sheet(item:).
struct FichierPartage: Identifiable {
    let id = UUID()
    let url: URL
}

/// Feuille de partage système, pour envoyer le GPX vers Boating.
struct PartageActivite: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// MARK: - Appareil photo

/// Prise de vue directe. Requiert NSCameraUsageDescription dans les réglages
/// du projet, sans quoi l'application est interrompue à l'ouverture.
struct AppareilPhotoPicker: UIViewControllerRepresentable {

    let completion: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: AppareilPhotoPicker

        init(_ parent: AppareilPhotoPicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            parent.completion(info[.originalImage] as? UIImage)
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.completion(nil)
            parent.dismiss()
        }
    }
}

// MARK: - Résumé des conditions (badges)

struct ConditionsResumeBadges: View {
    let conditions: ConditionsPeche

    var body: some View {
        FlowLayout(spacing: 6) {
            BadgeCondition(texte: conditions.zone.displayName,          icone: "map")
            BadgeCondition(texte: conditions.etatMer.displayName,       icone: "water.waves")
            BadgeCondition(texte: conditions.typeMaree.displayName,     icone: "arrow.up.arrow.down")
            BadgeCondition(texte: conditions.turbiditeEau.displayName,  icone: "eye")
            BadgeCondition(texte: conditions.momentJournee.displayName, icone: "sun.max")
            BadgeCondition(texte: conditions.phaseLunaire.displayName,  icone: "moon")
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
                HStack(spacing: 4) {
                    if prise.estGeolocalisee {
                        Image(systemName: "mappin.circle.fill")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "0277BD"))
                    }
                    if prise.relache {
                        Text("Relâché")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
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
    static func horodatage() -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f.string(from: Date())
    }
}
