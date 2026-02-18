//
//  SettledView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/17/26.
//


//
//  SettledView.swift
//  BetTracker
//
//  Shows recently settled bets (default: last 10 days), newest settled first.
//  Tap a row to edit/adjust results.
//

import SwiftUI
import SwiftData

struct SettledView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"
    @State private var daysBack: Int = 10
    @State private var selectedBet: Bet?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Filters
                VStack(spacing: 10) {
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

                    HStack {
                        Text("Range")
                            .font(.headline)

                        Spacer()

                        Picker("Days", selection: $daysBack) {
                            Text("10 days").tag(10)
                            Text("30 days").tag(30)
                            Text("90 days").tag(90)
                            Text("All").tag(-1)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                List {
                    if settledBets.isEmpty {
                        Text("No settled bets in this range.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settledBets) { bet in
                            settledRow(bet)
                        }
                        .onDelete(perform: deleteSettledBets)
                    }
                }
            }
            .navigationTitle("Settled")
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
    }

    // MARK: - Data

    private var settledBets: [Bet] {
        let filteredBySport: [Bet] = {
            if sportFilter == "All" { return bets }
            return bets.filter { $0.sport == sportFilter }
        }()

        let onlySettled = filteredBySport.filter { $0.settledAt != nil && $0.net != nil }

        let cut: Date? = {
            guard daysBack > 0 else { return nil } // -1 = all
            return Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())
        }()

        let filteredByDate: [Bet] = {
            guard let cut else { return onlySettled }
            return onlySettled.filter { ($0.settledAt ?? .distantPast) >= cut }
        }()

        // Most recently settled first
        return filteredByDate.sorted { ($0.settledAt ?? .distantPast) > ($1.settledAt ?? .distantPast) }
    }

    // MARK: - Row

    @ViewBuilder
    private func settledRow(_ bet: Bet) -> some View {
        Button {
            selectedBet = bet
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(bet.sport) • \(bet.wagerText)")
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Event: \(shortDate(bet.eventDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let settledAt = bet.settledAt {
                        Text("Settled: \(shortDateTime(settledAt))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let net = bet.net {
                    Text(money(net))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(resultColor(net))
                        .cornerRadius(10)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete

    private func deleteSettledBets(at offsets: IndexSet) {
        for index in offsets {
            context.delete(settledBets[index])
        }
    }

    // MARK: - Helpers

    private func resultColor(_ net: Double) -> Color {
        if net > 0 { return Color.blue.opacity(0.85) }
        if net < 0 { return Color.red.opacity(0.85) }
        return Color.gray.opacity(0.7)
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
