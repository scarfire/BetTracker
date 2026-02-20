import SwiftUI
import SwiftData

@main
struct BetTrackerMacApp: App {
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
            BetsGridView()
        }
        .modelContainer(modelContainer)
    }
}

