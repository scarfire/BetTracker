//
//  BetTrackerApp.swift
//  BetTracker
//

import SwiftUI

@main
struct BetTrackerApp: App {

    @StateObject private var betService = BetService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(betService)
        }
    }
}
