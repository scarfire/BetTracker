//
//  UpdateResultSheet.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/26/26.
//


//
//  UpdateResultSheet.swift
//  BetTracker
//

import SwiftUI

struct UpdateResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    let bet: Bet

    @State private var cashoutOn: Bool = false
    @State private var cashoutText: String = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(bet.sport) • \(bet.wagerText)")
                        .font(.headline)

                    Text("Event: \(shortDate(bet.eventDate))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    if let net = bet.net {
                        Text("Current Net: \(money(net))")
                            .foregroundColor(net > 0 ? .blue : (net < 0 ? .red : .gray))
                            .fontWeight(.semibold)

                        if let settledAt = bet.settledAt {
                            Text("Settled: \(shortDateTime(settledAt))")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    } else {
                        Text("Current: Pending")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 12) {
                    Button("WIN")  { applyWin() }  .buttonStyle(.bordered)
                    Button("LOSS") { applyLoss() } .buttonStyle(.bordered)
                    Button("PUSH") { applyPush() } .buttonStyle(.bordered)
                }

                Button("Reset to Pending") { resetToPending() }
                    .buttonStyle(.bordered)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Cash Out", isOn: $cashoutOn)
                        .onChange(of: cashoutOn) { _, newValue in
                            if !newValue { cashoutText = ""; error = nil }
                        }

                    if cashoutOn {
                        TextField("Amount received (e.g. 3.80)", text: $cashoutText)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        Button("Apply Cash Out") { applyCashout() }
                            .buttonStyle(.bordered)

                        if let error {
                            Text(error).foregroundColor(.red).font(.caption)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Update Result")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func applyWin() {
        withAnimation(.easeInOut(duration: 0.25)) {
            bet.net = bet.payoutAmount - bet.betAmount
            bet.settledAt = Date()
        }
        dismiss()
    }

    private func applyLoss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            bet.net = -bet.betAmount
            bet.settledAt = Date()
        }
        dismiss()
    }

    private func applyPush() {
        withAnimation(.easeInOut(duration: 0.25)) {
            bet.net = 0
            bet.settledAt = Date()
        }
        dismiss()
    }

    private func applyCashout() {
        error = nil
        let trimmed = cashoutText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let received = Double(trimmed), received >= 0 else {
            error = "Enter a valid amount (like 3.80)."
            return
        }
        withAnimation(.easeInOut(duration: 0.25)) {
            bet.payoutAmount = received
            bet.net = received - bet.betAmount
            bet.settledAt = Date()
        }
        dismiss()
    }

    private func resetToPending() {
        withAnimation(.easeInOut(duration: 0.25)) {
            bet.net = nil
            bet.payoutAmount = bet.originalPayoutAmount
            bet.settledAt = nil
        }
        cashoutOn = false
        cashoutText = ""
        error = nil
        dismiss()
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
        f.timeStyle = .none
        return f.string(from: date)
    }

    private func shortDateTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}