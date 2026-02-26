//
//  BetCard.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/26/26.
//


import SwiftUI

/// A reusable card for displaying a bet. Pass an optional `onTap` to make it tappable.
struct BetCard: View {
    let bet: Bet
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(bet.sport) • \(bet.wagerText)")
                    .font(.headline)
                    .foregroundColor(foregroundColor)

                Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                    .font(.subheadline)
                    .foregroundColor(foregroundColor.opacity(0.85))

                if bet.net == nil {
                    // Show event date on Upcoming / Settled where there's no tap to see details
                    Text("Event: \(shortDate(bet.eventDate))")
                        .font(.subheadline)
                        .foregroundColor(foregroundColor.opacity(0.85))
                }
            }

            Spacer()

            if let net = bet.net {
                Text(money(net))
                    .font(.headline.weight(.bold))
                    .foregroundColor(foregroundColor)
            } else {
                Text("Pending")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.orange)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
        .animation(.easeInOut(duration: 0.25), value: bet.net)
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    // MARK: - Styling

    private var background: Color {
        guard let net = bet.net else { return .white }
        if net > 0 { return Color.blue.opacity(0.85) }
        if net < 0 { return Color.red.opacity(0.85) }
        return Color.gray.opacity(0.70)
    }

    private var foregroundColor: Color {
        guard bet.net != nil else { return .primary }
        return .white
    }

    private func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}