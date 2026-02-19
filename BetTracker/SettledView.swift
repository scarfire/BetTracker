//
//  SettledView.swift
//  BetTracker
//

import SwiftUI
import SwiftData

struct SettledView: View {
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"

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

            Text("Settled")
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
                if settledBets.isEmpty {
                    Text("No settled bets.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(settledBets) { bet in
                        settledRow(bet)
                    }
                }
            }
        }
    }

    // MARK: Data

    private var settledBets: [Bet] {
        let filtered = bets.filter { $0.net != nil }

        let sportFiltered = sportFilter == "All"
            ? filtered
            : filtered.filter { $0.sport == sportFilter }

        return sportFiltered.sorted {
            $0.settledAt ?? $0.createdAt >
            $1.settledAt ?? $1.createdAt
        }
    }

    @ViewBuilder
    private func settledRow(_ bet: Bet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(bet.sport) • \(bet.wagerText)")
                .fontWeight(.semibold)

            Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                .font(.caption)
                .foregroundColor(.secondary)

            if let net = bet.net {
                Text(money(net))
                    .fontWeight(.bold)
                    .foregroundColor(net > 0 ? .blue : (net < 0 ? .red : .gray))
            }
        }
        .padding(.vertical, 6)
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

