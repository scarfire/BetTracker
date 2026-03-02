//
//  TotalsView.swift
//  BetTracker
//
//  Created by Todd Stevens on 3/1/26.
//


//
//  TotalsView.swift
//  BetTracker
//

import SwiftUI
import SwiftData

struct TotalsView: View {
    @Query private var bets: [Bet]
    @State private var dayRange: Int = 30

    private let headerHeight: CGFloat = 140
    private let ranges = [7, 30, 90, 365]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView

                    dateRangePicker
                        .padding(.horizontal)

                    if sportTotals.isEmpty {
                        Text("No settled bets in this period.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(sportTotals, id: \.sport) { row in
                                totalsRow(sport: row.sport, net: row.net, count: row.count)
                            }

                            Divider()
                                .padding(.horizontal)

                            // Grand total
                            let grandTotal = sportTotals.reduce(0) { $0 + $1.net }
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(formatted(grandTotal))
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(color(for: grandTotal))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                        .padding(.horizontal)
                    }

                    Spacer(minLength: 20)
                }
            }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            Image("sportsboard")
                .resizable()
                .scaledToFill()
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.60), Color.black.opacity(0.10)],
                startPoint: .bottom,
                endPoint: .top
            )

            Text("Totals")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 16)
                .padding(.bottom, 14)
        }
        .frame(height: headerHeight)
    }

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        Picker("Date Range", selection: $dayRange) {
            ForEach(ranges, id: \.self) { days in
                Text(label(for: days)).tag(days)
            }
        }
        .pickerStyle(.segmented)
    }

    private func label(for days: Int) -> String {
        switch days {
        case 7:   return "7 Days"
        case 30:  return "30 Days"
        case 90:  return "90 Days"
        default:  return "Year"
        }
    }

    // MARK: - Row

    private func totalsRow(sport: String, net: Double, count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(sport)
                    .font(.headline)
                Text("\(count) bet\(count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(formatted(net))
                .font(.headline.weight(.bold))
                .foregroundColor(color(for: net))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Data

    private struct SportTotal {
        let sport: String
        let net: Double
        let count: Int
    }

    private var settledBets: [Bet] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
        return bets.filter { $0.net != nil && $0.eventDate >= cutoff }
    }

    private var sportTotals: [SportTotal] {
        var grouped: [String: [Bet]] = [:]
        for bet in settledBets {
            grouped[bet.sport, default: []].append(bet)
        }
        return grouped
            .map { sport, bets in
                SportTotal(
                    sport: sport,
                    net: bets.reduce(0) { $0 + ($1.net ?? 0) },
                    count: bets.count
                )
            }
            .sorted { $0.sport < $1.sport }
    }

    // MARK: - Helpers

    private func formatted(_ value: Double) -> String {
        let abs = Swift.abs(value)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let str = f.string(from: NSNumber(value: abs)) ?? "$0.00"
        return value >= 0 ? "+\(str)" : "-\(str)"
    }

    private func color(for value: Double) -> Color {
        if value > 0 { return .blue }
        if value < 0 { return .red }
        return .secondary
    }
}