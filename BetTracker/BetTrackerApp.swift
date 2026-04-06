//
//  BetTrackerApp.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import SwiftUI
import SwiftData

@main
struct BetTrackerApp: App {

    private var modelContainer: ModelContainer = {
        do {
            let schema = Schema([Bet.self])

            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.toddlstevens.BetTracker")
            )

            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
//                .onAppear {
//                    try? modelContainer.mainContext.delete(model: Bet.self) // ← REMOVE AFTER RUNNING ONCE
//                }
        }
        .modelContainer(modelContainer)
    }
}
