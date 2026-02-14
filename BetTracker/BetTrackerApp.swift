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
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Bet.self)
    }
}
