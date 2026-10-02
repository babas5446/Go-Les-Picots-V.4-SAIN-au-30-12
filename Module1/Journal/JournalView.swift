//
//  JournalView.swift
//  Go les Picots V.4 — Journal de sorties
//
//  Liste des sorties de pêche.
//
//  V4.2 :
//  - Le bouton « + » ne présente plus une vue qui fabrique sa propre Sortie :
//    il appelle JournalViewModel.creerSortie(), qui insère l'objet, puis présente
//    le formulaire dessus. Un seul chemin de présentation, une seule feuille.
//    C'est ce qui rend l'identité de la Sortie stable d'une recomposition à
//    l'autre — cause commune des symptômes des sessions 3 et 4.
//  - La cellule affiche « Nom de la sortie à Spot », la date, puis les trois
//    indicateurs de synthèse : navigation, distance, consommation. Les valeurs
//    absentes sont omises, la ligne se réduit d'elle-même.
//  - Le badge distingue « EN COURS » (vert) et « EN PAUSE » (orange).
//  - Une sortie active, en cours comme en pause, n'expose aucune action de
//    swipe : la trace GPS écrirait des points rattachés à un objet supprimé.
//
//  Session 8 — bandeau d'état de sortie active :
//  - La sortie affichée dans le bandeau est tirée du @Query, non de
//    viewModel.sortieEnCours. La garde de restaurerSortieOuverte() fait sortir
//    la fonction sans rien affecter lorsque le service de trace tourne déjà :
//    au retour d'un autre module, sortieEnCours est nil alors qu'une sortie est
//    bien active. Le @Query, lui, reflète la base et survit à la recréation du
//    ViewModel.
//  - Le compteur de points lit sortie.pointsGPS.count, non
//    traceGPS.nombrePointsSession. Après relancement de l'application, le
//    service est vierge et afficherait zéro alors que la trace est en base.
//  - La santé de la trace est lue directement sur TraceGPSService.shared :
//    viewModel.traceGPS est un `let` et ne republie rien vers la vue.
//  - Le bouton d'arrêt clôture après confirmation, sans détour par le
//    formulaire : le plein de carburant n'est pas fait au retour au port.
//

import SwiftUI
import SwiftData

struct JournalView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel = JournalViewModel()

    /// Service de trace, observé directement : viewModel.traceGPS est un `let`
    /// et ne relaie aucun changement à la vue.
    @ObservedObject private var traceGPS = TraceGPSService.shared

    // MARK: - SwiftData

    @Query(sort: \Sortie.date, order: .reverse)
    private var sorties: [Sortie]

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // MARK: - Navigation

    /// Feuille unique : création et édition passent par le même chemin.
    @State private var sortieSelectionnee: Sortie?

    // MARK: - Suppression

    /// Sortie en attente de confirmation de suppression.
    @State private var sortieASupprimer: Sortie?

    // MARK: - Clôture

    /// Sortie en attente de confirmation d'arrêt depuis le bandeau.
    @State private var sortieAArreter: Sortie?

    // MARK: - Sortie active

    /// Sortie en cours ou en pause, s'il en existe une.
    /// Source volontairement prise sur le @Query : voir l'en-tête de fichier.
    private var sortieActive: Sortie? {
        sorties.first { $0.etat == .enCours || $0.etat == .enPause }
    }

    // MARK: - Body

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        NavigationStack {
            VStack(spacing: 0) {

                if let active = sortieActive {
                    BandeauSortieActive(
                        sortie: active,
                        sante: traceGPS.sante,
                        onOuvrir:  { sortieSelectionnee = active },
                        onPause:   { viewModel.mettreEnPause(active) },
                        onReprise: { viewModel.reprendreSortie(active) },
                        onArret:   { sortieAArreter = active }
                    )
                }

                Group {
                    if sorties.isEmpty {
                        vueVide
                    } else {
                        listeSorties
                    }
                }
            }
            .navigationTitle("Journal de pêche")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        nouvelleSortie()
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                }
            }
            .fullScreenCover(item: $sortieSelectionnee) { sortie in
                NouvelleSortieView(viewModel: viewModel, sortie: sortie)
            }
            .alert(
                "Arrêter la sortie ?",
                isPresented: alerteArretPresentee,
                presenting: sortieAArreter
            ) { sortie in
                Button("Arrêter", role: .destructive) {
                    confirmerArret(de: sortie)
                }
                Button("Annuler", role: .cancel) {
                    sortieAArreter = nil
                }
            } message: { sortie in
                Text(messageArret(pour: sortie))
            }
            .alert("Erreur", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Erreur inconnue")
            }
        }
    }

    // MARK: - Création

    /// Crée et insère la sortie, puis présente le formulaire dessus.
    private func nouvelleSortie() {
        let sortie = viewModel.creerSortie()
        Task { @MainActor in
            sortieSelectionnee = sortie
        }
    }

    // MARK: - Clôture : état et actions

    private var alerteArretPresentee: Binding<Bool> {
        Binding(
            get: { sortieAArreter != nil },
            set: { presente in
                if !presente { sortieAArreter = nil }
            }
        )
    }

    private func confirmerArret(de sortie: Sortie) {
        defer { sortieAArreter = nil }
        viewModel.terminerSortie(sortie)
    }

    /// Message de confirmation : chiffre ce qui sera figé, sans dramatiser.
    /// La clôture n'est pas destructrice, elle est simplement irréversible
    /// quant à l'enregistrement de la trace.
    private func messageArret(pour sortie: Sortie) -> String {
        var segments: [String] = []

        let nbPoints = sortie.pointsGPS.count
        if nbPoints > 0 {
            segments.append("\(nbPoints) point\(nbPoints > 1 ? "s" : "") GPS")
        }

        let nbPrises = sortie.prises.count
        if nbPrises > 0 {
            segments.append("\(nbPrises) prise\(nbPrises > 1 ? "s" : "")")
        }

        if segments.isEmpty {
            return "L'enregistrement de la trace sera arrêté définitivement."
        }

        let liste = segments.joined(separator: " et ")
        return "\(liste) seront conservés. L'enregistrement de la trace sera arrêté définitivement."
    }

    // MARK: - Liste

    private var listeSorties: some View {
        List {
            ForEach(sorties) { sortie in
                let active = sortie.etat == .enCours || sortie.etat == .enPause

                SortieCellule(sortie: sortie)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sortieSelectionnee = sortie
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Aucune action tant que la sortie est active :
                        // la trace GPS écrirait sur un objet supprimé.
                        if !active {
                            Button(role: .destructive) {
                                sortieASupprimer = sortie
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }
                        }
                    }
            }
        }
        .listStyle(.plain)
        .background(Color(hex: "F5F5F5"))
        .alert(
            "Supprimer cette sortie ?",
            isPresented: alerteSuppressionPresentee,
            presenting: sortieASupprimer
        ) { sortie in
            Button("Supprimer", role: .destructive) {
                confirmerSuppression(de: sortie)
            }
            Button("Annuler", role: .cancel) {
                sortieASupprimer = nil
            }
        } message: { sortie in
            Text(messageSuppression(pour: sortie))
        }
    }

    // MARK: - Suppression : état et actions

    /// Présentation de l'alerte pilotée par la présence d'une sortie en attente.
    private var alerteSuppressionPresentee: Binding<Bool> {
        Binding(
            get: { sortieASupprimer != nil },
            set: { presente in
                if !presente { sortieASupprimer = nil }
            }
        )
    }

    private func confirmerSuppression(de sortie: Sortie) {
        defer { sortieASupprimer = nil }
        viewModel.supprimerSortie(sortie)
    }

    /// Message de l'alerte : nomme la sortie et chiffre ce qui disparaît.
    /// Les segments vides sont omis, singulier et pluriel sont accordés.
    private func messageSuppression(pour sortie: Sortie) -> String {
        let nom = sortie.titreAffiche

        var segments: [String] = []

        let nbPrises = sortie.prises.count
        if nbPrises > 0 {
            segments.append("\(nbPrises) prise\(nbPrises > 1 ? "s" : "")")
        }

        let nbPoints = sortie.pointsGPS.count
        if nbPoints > 0 {
            segments.append("\(nbPoints) point\(nbPoints > 1 ? "s" : "") GPS")
        }

        if segments.isEmpty {
            return "« \(nom) » sera définitivement supprimée. Cette action est irréversible."
        }

        let liste = segments.joined(separator: " et ")
        return "« \(nom) » ainsi que \(liste) seront définitivement supprimés. Cette action est irréversible."
    }

    // MARK: - Vue vide

    private var vueVide: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Color(hex: "0277BD").opacity(0.4))

            VStack(spacing: 8) {
                Text("Aucune sortie enregistrée")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Appuyez sur + pour créer votre première sortie.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                nouvelleSortie()
            } label: {
                Label("Nouvelle sortie", systemImage: "plus")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color(hex: "0277BD"))
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "F5F5F5"))
    }
}

// MARK: - Bandeau de sortie active

/// Bandeau permanent affiché tant qu'une sortie est en cours ou en pause.
///
/// Trois fonctions, dans cet ordre de priorité : dire que l'enregistrement
/// tourne, dire s'il tourne réellement, et permettre de l'arrêter sans avoir à
/// retrouver la sortie dans la liste. Le troisième point compte : au retour au
/// port, la sortie du jour n'est pas nécessairement en tête de liste si une
/// autre porte une date postérieure.
struct BandeauSortieActive: View {

    let sortie: Sortie
    let sante: SanteTrace

    let onOuvrir:  () -> Void
    let onPause:   () -> Void
    let onReprise: () -> Void
    let onArret:   () -> Void

    // MARK: - État dérivé

    private var enPause: Bool {
        sortie.etat == .enPause
    }

    private var couleurEtat: Color {
        enPause ? .orange : .green
    }

    /// Horodatage du point le plus récent, s'il en existe un.
    private var dernierReleve: Date? {
        sortie.pointsGPS.map(\.timestamp).max()
    }

    /// Diagnostic à afficher.
    ///
    /// La pause neutralise toute alerte : aucun point n'est attendu, un
    /// avertissement de silence n'aurait aucun sens. Le service peut par ailleurs
    /// conserver un diagnostic hérité de la période active.
    private var diagnostic: SanteTrace {
        enPause ? .normale : sante
    }

    private var alerte: Bool {
        diagnostic != .normale
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            HStack(spacing: 10) {

                Circle()
                    .fill(couleurEtat)
                    .frame(width: 10, height: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sortie.libelleJournal)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    chronometre
                }

                Spacer(minLength: 8)

                boutonPauseReprise
                boutonArret
            }

            ligneEtat
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(height: 0.5)
        }
        .contentShape(Rectangle())
        .onTapGesture { onOuvrir() }
    }

    // MARK: - Chronomètre

    /// Amplitude totale depuis le départ, pauses comprises — arbitrage retenu
    /// en session 5. La durée de navigation, elle, se lit dans la fiche.
    private var chronometre: some View {
        Group {
            if let depart = sortie.heureDepart {
                TimelineView(.periodic(from: .now, by: 1)) { contexte in
                    Text(Self.duree(depuis: depart, jusqua: contexte.date))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .foregroundColor(couleurEtat)
                }
            } else {
                Text("--:--:--")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
        }
    }

    private static func duree(depuis debut: Date, jusqua fin: Date) -> String {
        let total = max(0, Int(fin.timeIntervalSince(debut)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    // MARK: - Boutons

    private var boutonPauseReprise: some View {
        Button {
            if enPause { onReprise() } else { onPause() }
        } label: {
            Image(systemName: enPause ? "play.fill" : "pause.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 38, height: 34)
                .background(enPause ? Color.green : Color.orange)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var boutonArret: some View {
        Button {
            onArret()
        } label: {
            Image(systemName: "stop.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 38, height: 34)
                .background(Color.red)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Ligne d'état

    private var ligneEtat: some View {
        HStack(spacing: 6) {
            Image(systemName: pictogrammeEtat)
                .font(.caption2)
            Text(texteEtat)
                .font(.caption)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .foregroundColor(alerte ? .red : .secondary)
    }

    private var pictogrammeEtat: String {
        if enPause { return "pause.circle" }
        switch diagnostic {
        case .normale:                  return "dot.radiowaves.up.forward"
        case .silencieuse:              return "exclamationmark.triangle.fill"
        case .autorisationRefusee:      return "location.slash.fill"
        case .autorisationIndeterminee: return "exclamationmark.triangle.fill"
        }
    }

    /// Quatre causes de silence, quatre messages. Confondre une autorisation
    /// défaillante avec une réception dégradée conduirait à chercher le défaut
    /// au mauvais endroit : le premier cas relève des réglages, le second du ciel.
    private var texteEtat: String {
        if enPause {
            return "Enregistrement suspendu · \(compteurPoints)"
        }

        switch diagnostic {
        case .normale:
            return "\(compteurPoints)\(complementDernierPoint)"

        case .silencieuse:
            return "Aucun point depuis plus de 3 minutes · réception dégradée"

        case .autorisationRefusee:
            return "Localisation refusée · autoriser dans les réglages de l'appareil"

        case .autorisationIndeterminee:
            return "Localisation sans réponse · vérifier les réglages de localisation"
        }
    }

    private var compteurPoints: String {
        let n = sortie.pointsGPS.count
        return "\(n) point\(n > 1 ? "s" : "") GPS"
    }

    /// Âge du dernier point, en minutes entières. Sous la minute, l'information
    /// est bruitée et n'apprend rien : elle est omise.
    private var complementDernierPoint: String {
        guard let dernier = dernierReleve else { return "" }
        let minutes = Int(Date().timeIntervalSince(dernier) / 60)
        guard minutes >= 1 else { return " · dernier à l'instant" }
        return " · dernier il y a \(minutes) min"
    }
}

// MARK: - Cellule de sortie

struct SortieCellule: View {

    let sortie: Sortie

    private var dateFormatee: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale    = Locale(identifier: "fr_FR")
        return f.string(from: sortie.date)
    }

    /// Couleur de l'indicateur latéral et du badge.
    private var couleurEtat: Color {
        switch sortie.etat {
        case .enCours:     return .green
        case .enPause:     return .orange
        case .terminee:    return Color(hex: "0277BD")
        case .nonDemarree: return Color.secondary
        }
    }

    private var badgeVisible: Bool {
        sortie.etat == .enCours || sortie.etat == .enPause
    }

    var body: some View {
        HStack(spacing: 12) {

            RoundedRectangle(cornerRadius: 3)
                .fill(couleurEtat)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 6) {

                // Ligne 1 : « Nom de la sortie à Spot » + badge d'état
                HStack {
                    Text(sortie.libelleJournal)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if badgeVisible {
                        Text(sortie.etat.displayName.uppercased())
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(couleurEtat)
                            .cornerRadius(4)
                    }

                    Spacer()

                    if !sortie.prises.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "fish.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: "FFBC42"))
                            Text("\(sortie.prises.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(hex: "FFBC42"))
                        }
                    }
                }

                // Ligne 2 : date
                Text(dateFormatee)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Ligne 3 : navigation, distance, consommation.
                // Les valeurs non disponibles sont omises par le modèle.
                let indicateurs = sortie.indicateursJournal
                if !indicateurs.isEmpty || !sortie.notes.isEmpty {
                    HStack(spacing: 12) {
                        ForEach(Array(indicateurs.enumerated()), id: \.offset) { _, valeur in
                            Text(valeur)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        if !sortie.notes.isEmpty {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
