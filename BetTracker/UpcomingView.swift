//
//  UpcomingView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/17/26.
//


//
//  UpcomingView.swift
//  BetTracker
//
//  Upcoming = pending bets whose eventDate is after today.
//

import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"
    @State private var selectedBet: Bet?

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
                .padding(.top, 12)
                .padding(.bottom, 8)

                List {
                    if upcomingBets.isEmpty {
                        Text("No upcoming bets.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(upcomingBets) { bet in
                            upcomingRow(bet)
                        }
                        .onDelete(perform: deleteUpcomingBets)
                    }
                }
            }
            .navigationTitle("Upcoming")
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
    }

    // MARK: - Data

    private var upcomingBets: [Bet] {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let filteredBySport: [Bet] = {
            if sportFilter == "All" { return bets }
            return bets.filter { $0.sport == sportFilter }
        }()

        // Upcoming = eventDate after today AND pending only
        return filteredBySport
            .filter { $0.net == nil && $0.eventDate > startOfToday }
            .sorted {
                if Calendar.current.isDate($0.eventDate, inSameDayAs: $1.eventDate) {
                    return $0.createdAt < $1.createdAt
                }
                return $0.eventDate < $1.eventDate
            }
    }

    // MARK: - Row

    @ViewBuilder
    private func upcomingRow(_ bet: Bet) -> some View {
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

                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("Pending")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Delete

    private func deleteUpcomingBets(at offsets: IndexSet) {
        for index in offsets {
            context.delete(upcomingBets[index])
        }
    }

    // MARK: - Helpers

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
}
