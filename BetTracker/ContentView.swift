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

    var id: String { rawValue }
}

struct ContentView: View {
    var body: some View {
        TabView {
            AddBetView()
                .tabItem {
                    Label("Add Bet", systemImage: "plus.circle.fill")
                }

            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar")
                }

            SummaryView()
                .tabItem {
                    Label("Summary", systemImage: "chart.bar.fill")
                }
        }
    }
}
