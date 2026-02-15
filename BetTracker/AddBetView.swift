//
//  AddBetView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import SwiftUI
import SwiftData

struct AddBetView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("lastSport") private var lastSport: String = Sport.nhl.rawValue

    @State private var whatText: String = ""
    @State private var amountText: String = ""   // format: 5/9.32
    @State private var errorMessage: String?

    @FocusState private var focusedField: Field?
    enum Field { case what, amount }

    @Query private var bets: [Bet]

    var body: some View {
        NavigationStack {
            ZStack {
                // Tap anywhere to dismiss keyboard
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { focusedField = nil }

                VStack(spacing: 16) {

                    // Sport Picker (remembers last)
                    Picker("Sport", selection: $lastSport) {
                        ForEach(Sport.allCases) { sport in
                            Text(sport.rawValue).tag(sport.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    // What box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What")
                            .font(.headline)

                        TextField("BOS ML", text: $whatText)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .onChange(of: whatText) { _, newValue in
                                let upper = newValue.uppercased()
                                if upper != newValue { whatText = upper }
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .what)
                    }

                    // Amounts box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Bet / Payout")
                            .font(.headline)

                        TextField("5/9.32", text: $amountText)
                            .keyboardType(.numbersAndPunctuation)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .focused($focusedField, equals: .amount)

                        HStack(spacing: 12) {
                            Button("Save") {
                                saveBet()
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)

                            Button("Done") {
                                focusedField = nil
                            }
                            .buttonStyle(.bordered)
                            .frame(width: 90)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }

                    // Recent bets today (confirmation) + swipe to delete
                    List {
                        ForEach(recentBetsForList) { bet in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(bet.sport) • \(bet.wagerText)")
                                    .font(.body)

                                Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteRecentBets)
                    }
                }
                .padding()
            }
            .navigationTitle("BetTracker")
            .onAppear {
                focusedField = .what
            }
        }
    }

    // Full list of today's bets (newest first)
    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        return bets
            .filter { $0.createdAt >= start }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // IMPORTANT: For swipe-to-delete offsets to match, use a concrete Array here.
    private var recentBetsForList: [Bet] {
        Array(todayBets.prefix(15))
    }

    private func deleteRecentBets(at offsets: IndexSet) {
        for index in offsets {
            context.delete(recentBetsForList[index])
        }
    }

    private func saveBet() {
        errorMessage = nil

        let what = whatText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !what.isEmpty else {
            errorMessage = "Enter what you bet on (e.g. BOS ML)."
            focusedField = .what
            return
        }

        guard let parsed = SlashAmountParser.parse(amountText) else {
            errorMessage = "Enter amounts like 5/9.32 (bet/payout)."
            focusedField = .amount
            return
        }

        let bet = Bet(
            sport: lastSport,
            wagerText: what,
            betAmount: parsed.bet,
            payoutAmount: parsed.payout,
            originalPayoutAmount: parsed.payout
        )
        context.insert(bet)

        // Auto-clear and keep you in the fast loop
        whatText = ""
        amountText = ""
        focusedField = .what
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

// Strict parser: "bet/payout" with decimals allowed, optional $ and spaces
struct SlashAmountParser {
    struct Parsed { let bet: Double; let payout: Double }

    static func parse(_ input: String) -> Parsed? {
        // Accept: 5/9.32, $5/$9.32, $5 / $9.32, 5.00/9.32
        let cleaned = input
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let parts = cleaned.split(separator: "/")
        guard parts.count == 2 else { return nil }

        guard let bet = Double(parts[0]),
              let payout = Double(parts[1]),
              bet > 0, payout > 0 else { return nil }

        return Parsed(bet: bet, payout: payout)
    }
}

