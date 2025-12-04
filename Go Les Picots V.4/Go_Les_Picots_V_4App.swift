//
//  Go_Les_Picots_V_4App.swift
//  Go Les Picots V.4
//
//  Created by LANES Sebastien on 04/12/2025.
//

import SwiftUI
import CoreData

@main
struct Go_Les_Picots_V_4App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
