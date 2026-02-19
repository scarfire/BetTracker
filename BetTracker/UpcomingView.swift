//
//  UpcomingView.swift
//  BetTracker
//

import SwiftUI
import SwiftData

struct UpcomingView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"
    @State private var selectedBet: Bet?

    private let headerHeight: CGFloat = 110

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {

                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: headerHeight)

                    contentBody
                }

                headerView
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
    }

    // MARK: Header

    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            Image("sportsboard")
                .resizable()
                .scaledToFill()
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .clipped()
                .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.15)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .top)

            Text("Upcoming")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .frame(height: headerHeight)
    }

    // MARK: Body

    private var contentBody: some View {
        VStack(spacing: 0) {

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
                if upcomingBets.isEmpty {
                    Text("No upcoming bets.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(upcomingBets) { bet in
                        upcomingRow(bet)
                    }
                    .onDelete(perform: deleteUpcoming)
                }
            }
        }
    }

    // MARK: Data

    private var upcomingBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())

        let filtered = bets.filter {
            $0.net == nil && $0.eventDate > start
        }

        let sportFiltered = sportFilter == "All"
            ? filtered
            : filtered.filter { $0.sport == sportFilter }

        return sportFiltered.sorted {
            if Calendar.current.isDate($0.eventDate, inSameDayAs: $1.eventDate) {
                return $0.createdAt < $1.createdAt
            }
            return $0.eventDate < $1.eventDate
        }
    }

    private func deleteUpcoming(at offsets: IndexSet) {
        for index in offsets {
            context.delete(upcomingBets[index])
        }
    }

    @ViewBuilder
    private func upcomingRow(_ bet: Bet) -> some View {
        Button {
            selectedBet = bet
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(bet.sport) • \(bet.wagerText)")
                    .fontWeight(.semibold)

                Text("Event: \(shortDate(bet.eventDate))")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

