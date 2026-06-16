//
//  UpdateResultSheet.swift
//  BetTracker
//

import SwiftUI

struct UpdateResultSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var service: BetService

    let bet: Bet

    @State private var mode: Mode = .settle
    @State private var cashoutOn: Bool = false
    @State private var cashoutText: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading = false

    // Edit fields
    @State private var editSport: String = ""
    @State private var editWagerText: String = ""
    @State private var editEventDate: String = ""
    @State private var editBetAmount: String = ""
    @State private var editPayoutAmount: String = ""
    @State private var editIsProp: Bool = false
    @State private var editIsParlay: Bool = false

    enum Mode { case settle, edit }

    var body: some View {
        NavigationStack {
            Group {
                if mode == .settle {
                    settleView
                } else {
                    editView
                }
            }
            .navigationTitle(mode == .settle ? "Update Result" : "Edit Bet")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(mode == .settle ? "Edit Bet" : "Cancel") {
                        if mode == .settle {
                            loadEditFields()
                            withAnimation { mode = .edit }
                        } else {
                            withAnimation { mode = .settle }
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if mode == .edit {
                        Button("Save") { Task { await saveEdit() } }
                    } else {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Settle View

    private var settleView: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text("\(bet.sport) • \(bet.wagerText)").font(.headline)
                    if bet.isProp   { badge("Prop") }
                    if bet.isParlay { badge("Parlay") }
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

            HStack(spacing: 12) {
                actionButton("WIN")  { await settle("win") }
                actionButton("LOSS") { await settle("loss") }
                actionButton("PUSH") { await settle("push") }
            }

            actionButton("Reset to Pending") { await settle("reset") }

            Divider()

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
    }

    // MARK: - Edit View

    private var editView: some View {
        Form {
            Section("Sport") {
                Picker("Sport", selection: $editSport) {
                    ForEach(Sport.allCases) { sport in
                        Text(sport.rawValue).tag(sport.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Flags") {
                Toggle("Prop Bet", isOn: $editIsProp)
                Toggle("Parlay", isOn: $editIsParlay)
            }

            Section("Event Date") {
                TextField("YYYY-MM-DD", text: $editEventDate)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled(true)
            }

            Section("Wager") {
                TextField("e.g. TBL ML", text: $editWagerText)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.characters)
            }

            Section("Amounts") {
                HStack {
                    Text("Bet")
                    Spacer()
                    TextField("5.00", text: $editBetAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
                HStack {
                    Text("Payout")
                    Spacer()
                    TextField("9.45", text: $editPayoutAmount)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundColor(.red).font(.caption)
                }
            }

            Section {
                Button("Save Changes") { Task { await saveEdit() } }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .disabled(isLoading)
            }
        }
    }

    // MARK: - Edit logic

    private func loadEditFields() {
        editSport        = bet.sport
        editWagerText    = bet.wagerText
        editEventDate    = bet.eventDate
        editBetAmount    = String(format: "%.2f", bet.betAmount)
        editPayoutAmount = String(format: "%.2f", bet.payoutAmount)
        editIsProp       = bet.isProp
        editIsParlay     = bet.isParlay
    }

    private func saveEdit() async {
        errorMessage = nil
        guard let betAmt = Double(editBetAmount), betAmt >= 0,
              let payAmt = Double(editPayoutAmount), payAmt > 0 else {
            errorMessage = "Check amounts — payout must be greater than 0."
            return
        }
        guard !editWagerText.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Wager text is required."
            return
        }

        isLoading = true
        do {
            let body: [String: Any] = [
                "action":         "edit",
                "sport":          editSport,
                "wager_text":     editWagerText.uppercased(),
                "is_prop":        editIsProp ? 1 : 0,
                "is_parlay":      editIsParlay ? 1 : 0,
                "event_date":     editEventDate,
                "bet_amount":     betAmt,
                "payout_amount":  payAmt
            ]
            try await service.editBet(id: bet.id, body: body)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
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
