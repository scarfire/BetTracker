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

    var body: some View {
        NavigationStack {
            List {
                ForEach(todayBets) { bet in
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
            }
            .navigationTitle("Today")
        }
    }

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        return bets
            .filter { $0.createdAt >= start }
            .sorted { $0.createdAt > $1.createdAt }
    }

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

