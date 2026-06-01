//
//  ContentView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import SwiftUI

enum Sport: String, CaseIterable, Identifiable {
    case nhl = "NHL"
    case nfl = "NFL"
    case mlb = "MLB"
    case cfb = "NCAAF"
    case cbb = "NCAAB"
    case mix = "MIX"
//    case prop = "Prop"

    var id: String { rawValue }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

            UpcomingView()
                .tabItem {
                    Label("Upcoming", systemImage: "clock")
                }

            SettledView()
                .tabItem {
                    Label("Settled", systemImage: "checkmark.circle")
                }

            AddBetView()
                .tabItem {
                    Label("Add Bet", systemImage: "plus.circle.fill")
                }
        }
    }
}

