//
//  Go_Les_Picots_V_4App.swift
//  Go Les Picots V.4
//
//  Point d'entrée de l'application.
//
//  V4 — Migration CoreData → SwiftData :
//  - PersistenceController retiré de l'environnement
//  - ModelContainer fourni par LeurreStorageService.shared
//  - LeurreMigrationService déclenché au premier lancement (one-shot)
//  - Persistence.swift conservé dans le projet mais non utilisé
//

import SwiftUI
import SwiftData

@main
struct Go_Les_Picots_V_4App: App {

    // MARK: - Migration one-shot

    /// Déclenche la migration JSON → SwiftData au premier lancement.
    /// Sans effet les lancements suivants (flag UserDefaults).
    init() {
        // En mode dégradé (base sur disque illisible), aucune migration :
        // elle poserait son flag sur une base temporaire et serait perdue.
        guard !LeurreStorageService.estEnModeDegrade else { return }

        let context = LeurreStorageService.shared.mainContext
        LeurreMigrationService.migrerSiNecessaire(dans: context)

        // Nouvelles règles de déduction : recalcul unique de toute la boîte
        // (versionDeductions). Sinon, leurres migrés, importés ou issus d'une
        // version antérieure : on complète les champs déduits (zones,
        // contraste, positions) dont dépendent les filtres et le moteur.
        let boite = BoiteLeurresViewModel(context: context)
        if !boite.appliquerNouvellesReglesSiNecessaire() {
            boite.completerChampsDeduitsManquants()
        }
    }

    // MARK: - Scene

    @State private var alerteModeDegrade = LeurreStorageService.estEnModeDegrade

    var body: some Scene {
        WindowGroup {
            ContentView()
                .alert("Base de données inaccessible", isPresented: $alerteModeDegrade) {
                    Button("Compris", role: .cancel) { }
                } message: {
                    Text("L'application fonctionne sur une base temporaire : rien de ce que vous saisirez ne sera conservé. Vos données d'origine n'ont pas été modifiées.\n\nDétail : \(LeurreStorageService.erreurOuverture ?? "inconnu")")
                }
        }
        .modelContainer(LeurreStorageService.shared)
    }
}
