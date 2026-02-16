//
//  ContentView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//
import SwiftUI
import SwiftData

enum Sport: String, CaseIterable, Identifiable {
    case nhl = "NHL"
    case nfl = "NFL"
    case mlb = "MLB"
    case cfb = "CFB"
    case cbb = "CBB"
    case prop = "Prop"

    var id: String { rawValue }
}

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

            AddBetView()
                .tabItem {
                    Label("Add Bet", systemImage: "plus.circle.fill")
                }

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
        }
    }
}
