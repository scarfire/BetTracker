//
//  SummaryView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//


import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var bets: [Bet]
    @State private var selectedSport: Sport = .nhl

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Sport", selection: $selectedSport) {
                    ForEach(Sport.allCases) { sport in
                        Text(sport.rawValue).tag(sport)
                    }
                }
                .pickerStyle(.segmented)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Bets: \(filtered.count)")
                    Text("Wins: \(wins)")
                    Text("Losses: \(losses)")
                    Text("Win %: \(winPercentage, specifier: "%.1f")%")
                    Text("Net: $\(net, specifier: "%.2f")")
                        .foregroundColor(net > 0 ? .blue : (net < 0 ? .red : .primary))
                }
                .font(.title3)

                Spacer()
            }
            .padding()
            .navigationTitle("Summary")
        }
    }

    private var filtered: [Bet] {
        bets.filter { $0.sport == selectedSport.rawValue }
    }

    private var wins: Int {
        filtered.filter { ($0.net ?? 0) > 0 }.count
    }

    private var losses: Int {
        filtered.filter { ($0.net ?? 0) < 0 }.count
    }

    private var winPercentage: Double {
        let total = Double(wins + losses)
        guard total > 0 else { return 0 }
        return (Double(wins) / total) * 100
    }

    private var net: Double {
        filtered.compactMap { $0.net }.reduce(0, +)
    }
}
