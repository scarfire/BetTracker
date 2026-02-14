//
//  TodayView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var bets: [Bet]

    @Environment(\.modelContext) private var context
    @State private var sportFilter: String = "All"   // "All" or "NHL" etc.

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Filter bar
                HStack {
                    Text("Sport")
                        .font(.headline)

                    Spacer()

                    Picker("Sport Filter", selection: $sportFilter) {
                        Text("All").tag("All")
                        ForEach(Sport.allCases) { sport in
                            Text(sport.rawValue).tag(sport.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

                List {
                    ForEach(filteredTodayBetsChronological) { bet in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(bet.sport) • \(bet.wagerText)")
                                    .foregroundColor(colorForBetTitle(bet))

                                Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if let net = bet.net {
                                Text(money(net))
                                    .foregroundColor(net > 0 ? .blue : (net < 0 ? .red : .gray))
                                    .fontWeight(.semibold)
                            } else {
                                Text("Pending")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteBets)
                }
            }
            .navigationTitle("Today")
        }
    }

    // MARK: - Data

    private func deleteBets(at offsets: IndexSet) {
        let items = filteredTodayBetsChronological
        for index in offsets {
            context.delete(items[index])
        }
    }

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        return bets.filter { $0.createdAt >= start }
    }

    // Always oldest -> newest (chronological), regardless of filter
    private var filteredTodayBetsChronological: [Bet] {
        let filtered: [Bet]
        if sportFilter == "All" {
            filtered = todayBets
        } else {
            filtered = todayBets.filter { $0.sport == sportFilter }
        }

        return filtered.sorted { $0.createdAt < $1.createdAt }
    }

    // MARK: - UI helpers

    private func colorForBetTitle(_ bet: Bet) -> Color {
        guard let net = bet.net else { return .primary }
        if net > 0 { return .blue }
        if net < 0 { return .red }
        return .primary
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

