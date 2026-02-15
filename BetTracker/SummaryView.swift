//
//  SummaryView.swift
//  BetTracker
//

import SwiftUI
import SwiftData

struct SummaryView: View {
    @Query private var bets: [Bet]

    @State private var scope: Scope = .today

    enum Scope: String, CaseIterable, Identifiable {
        case today = "Today"
        case allTime = "All Time"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Scope toggle
                Picker("Scope", selection: $scope) {
                    ForEach(Scope.allCases) { s in
                        Text(s.rawValue).tag(s)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    // Overall totals
                    Section("Totals") {
                        SummaryRow(
                            title: "All Sports",
                            stats: stats(for: filteredBets)
                        )
                    }

                    // Per-sport
                    Section("By Sport") {
                        ForEach(Sport.allCases) { sport in
                            let sportBets = filteredBets.filter { $0.sport == sport.rawValue }
                            SummaryRow(
                                title: sport.rawValue,
                                stats: stats(for: sportBets)
                            )
                        }
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }

    // MARK: - Filtering

    private var filteredBets: [Bet] {
        switch scope {
        case .today:
            let start = Calendar.current.startOfDay(for: Date())
            return bets.filter { $0.createdAt >= start }
        case .allTime:
            return bets
        }
    }

    // MARK: - Stats

    struct Stats {
        var total: Int
        var settled: Int
        var wins: Int
        var losses: Int
        var pushes: Int
        var winPct: Double?   // nil if no wins/losses
        var net: Double
    }

    private func stats(for bets: [Bet]) -> Stats {
        let total = bets.count
        let settledBets = bets.compactMap { $0.net }
        let settled = settledBets.count

        var wins = 0
        var losses = 0
        var pushes = 0
        var net: Double = 0

        for n in settledBets {
            net += n
            if n > 0 { wins += 1 }
            else if n < 0 { losses += 1 }
            else { pushes += 1 }
        }

        let denom = wins + losses
        let winPct: Double? = denom > 0 ? Double(wins) / Double(denom) : nil

        return Stats(
            total: total,
            settled: settled,
            wins: wins,
            losses: losses,
            pushes: pushes,
            winPct: winPct,
            net: net
        )
    }
}

// MARK: - Row UI

private struct SummaryRow: View {
    let title: String
    let stats: SummaryView.Stats

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(money(stats.net))
                    .font(.headline)
                    .foregroundColor(stats.net > 0 ? .blue : (stats.net < 0 ? .red : .primary))
            }

            HStack(spacing: 16) {
                mini("Bets", "\(stats.total)")
                mini("Settled", "\(stats.settled)")
                mini("W", "\(stats.wins)")
                mini("L", "\(stats.losses)")
                mini("P", "\(stats.pushes)")
                mini("Win%", stats.winPct.map { pct($0) } ?? "—")
            }
            .font(.headline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func mini(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
            Text(value).fontWeight(.semibold)
        }
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func pct(_ value: Double) -> String {
        String(format: "%.1f%%", value * 100.0)
    }
}

