//
//  UpdateResultSheet.swift
//  BetTracker
//

import SwiftUI

struct UpdateResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var service: BetService

    let bet: Bet

    @State private var cashoutOn: Bool = false
    @State private var cashoutText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Bet summary
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("\(bet.sport) • \(bet.wagerText)")
                            .font(.headline)
                        if bet.isProp    { badge("Prop") }
                        if bet.isParlay  { badge("Parlay") }
                    }
                    Text("Event: \(bet.eventDateFormatted)")
                        .foregroundColor(.secondary).font(.subheadline)
                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                        .foregroundColor(.secondary).font(.subheadline)

                    if let net = bet.net {
                        Text("Current Net: \(money(net))")
                            .foregroundColor(net > 0 ? .blue : net < 0 ? .red : .gray)
                            .fontWeight(.semibold)
                        if let settled = bet.settledAtFormatted {
                            Text("Settled: \(settled)")
                                .foregroundColor(.secondary).font(.caption)
                        }
                    } else {
                        Text("Current: Pending")
                            .foregroundColor(.orange).fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Action buttons
                HStack(spacing: 12) {
                    actionButton("WIN")   { await settle("win") }
                    actionButton("LOSS")  { await settle("loss") }
                    actionButton("PUSH")  { await settle("push") }
                }

                actionButton("Reset to Pending") { await settle("reset") }

                Divider()

                // Cashout
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Cash Out", isOn: $cashoutOn)
                        .onChange(of: cashoutOn) { _, val in
                            if !val { cashoutText = ""; errorMessage = nil }
                        }

                    if cashoutOn {
                        TextField("Amount received (e.g. 3.80)", text: $cashoutText)
                            .keyboardType(.decimalPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)

                        actionButton("Apply Cash Out") {
                            guard let amount = Double(cashoutText.trimmingCharacters(in: .whitespaces)),
                                  amount >= 0 else {
                                errorMessage = "Enter a valid amount (like 3.80)."
                                return
                            }
                            await settleCashout(amount: amount)
                        }

                        if let errorMessage {
                            Text(errorMessage).foregroundColor(.red).font(.caption)
                        }
                    }
                }

                if isLoading { ProgressView() }

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

    // MARK: - Helpers

    private func badge(_ label: String) -> some View {
        Text(label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.15))
            .foregroundColor(.secondary)
            .clipShape(Capsule())
    }

    private func actionButton(_ title: String, action: @escaping () async -> Void) -> some View {
        Button(title) { Task { await action() } }
            .buttonStyle(.bordered)
    }

    private func settle(_ action: String) async {
        isLoading = true
        do {
            try await service.settle(id: bet.id, action: action)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func settleCashout(amount: Double) async {
        isLoading = true
        do {
            try await service.settle(id: bet.id, action: "cashout", cashoutAmount: amount)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
