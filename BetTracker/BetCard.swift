//
//  BetCard.swift
//  BetTracker
//

import SwiftUI

struct BetCard: View {
    let bet: Bet
    var onTap: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {

                // Sport + wager + badges
                HStack(spacing: 6) {
                    Text("\(bet.sport) • \(bet.wagerText)")
                        .font(.headline)
                        .foregroundColor(foregroundColor)

                    if bet.isProp {
                        badge("Prop")
                    }
                    if bet.isParlay {
                        badge("Parlay")
                    }
                }

                Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                    .font(.subheadline)
                    .foregroundColor(foregroundColor.opacity(0.85))

                if let settled = bet.settledAtFormatted {
                    Text("Settled: \(settled)")
                        .font(.subheadline)
                        .foregroundColor(foregroundColor.opacity(0.85))
                } else {
                    Text("Event: \(bet.eventDateFormatted)")
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
        .contentShape(Rectangle())
        .onTapGesture { onTap?() }
    }

    // MARK: - Badge

    private func badge(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(foregroundColor.opacity(0.18))
            .foregroundColor(foregroundColor)
            .clipShape(Capsule())
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
}
