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
        LeurreMigrationService.migrerSiNecessaire(
            dans: LeurreStorageService.shared.mainContext
        )
    }

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(LeurreStorageService.shared)
    }
}
