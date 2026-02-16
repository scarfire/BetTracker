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

    @State private var useNumericKeyboardForWhat: Bool = false
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

                        // Quick insert buttons (fast sportsbook-style entry)
                        HStack(spacing: 10) {
                            quickAppendButton(label: "ML", token: "ML ", requiresLeadingSpace: true)
                            quickAppendButton(label: "OVER", token: "OVER ", requiresLeadingSpace: true)
                            quickAppendButton(label: "UNDER", token: "UNDER ", requiresLeadingSpace: true)
                            quickAppendButton(label: "PLUS", token: "+", requiresLeadingSpace: true)
                            quickAppendButton(label: "MINUS", token: "-", requiresLeadingSpace: true)
                            Spacer()
                        }

                        TextField("BOS ML   /   OVER 6.5   /   NYR -1.5", text: $whatText)
                            .keyboardType(useNumericKeyboardForWhat ? .numbersAndPunctuation : .default)
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

                        // Quick bet amount buttons
                        HStack(spacing: 10) {
                            amountButton(1)
                            amountButton(2)
                            amountButton(3)
                            amountButton(5)
                            amountButton(7)
                            amountButton(10)
                        }

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
                applyDefaultBetPrefixIfNeeded(force: true)
            }
            .onChange(of: lastSport) { _, _ in
                applyDefaultBetPrefixIfNeeded(force: true)
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
        setLastBetAmount(parsed.bet, for: lastSport)

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
        applyDefaultBetPrefixIfNeeded(force: true)   // prefill lastBet/
        focusedField = .what
        useNumericKeyboardForWhat = false
    }
    
    private func quickAppendButton(label: String, token: String, requiresLeadingSpace: Bool) -> some View {
        Button(label) {
            // Switch keyboard AFTER tapping, except for ML
            if token == "ML " {
                useNumericKeyboardForWhat = false
            } else {
                useNumericKeyboardForWhat = true
            }

            appendToken(token, requiresLeadingSpace: requiresLeadingSpace)

            // Force keyboard refresh by refocusing
            focusedField = nil
            DispatchQueue.main.async {
                focusedField = .what
            }
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    private func appendToken(_ token: String, requiresLeadingSpace: Bool) {
        // Normalize current text
        var text = whatText

        // If you already typed a team without a trailing space (e.g., "BOS"), and you tap ML/OVER/UNDER,
        // we add a space first.
        if requiresLeadingSpace, !text.isEmpty, !text.hasSuffix(" ") {
            text += " "
        }

        // Append the token
        text += token

        // Force uppercase output
        whatText = text.uppercased()
    }

    private func amountButton(_ value: Double) -> some View {
        Button {
            // Remember default bet amount for current sport
            setLastBetAmount(value, for: lastSport)

            // Replace whatever is there and add "/" immediately
            amountText = betPrefix(value)

            // Jump focus to amount field
            focusedField = nil
            DispatchQueue.main.async {
                focusedField = .amount
            }
        } label: {
            Text(value == floor(value) ? "\(Int(value))" : "\(value)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .cornerRadius(10)
        }
    }

    private func betDefaultsKey(for sport: String) -> String {
        "lastBetAmount_\(sport)"
    }

    private func getLastBetAmount(for sport: String) -> Double? {
        let key = betDefaultsKey(for: sport)
        let v = UserDefaults.standard.double(forKey: key)
        return v > 0 ? v : nil
    }

    private func setLastBetAmount(_ value: Double, for sport: String) {
        let key = betDefaultsKey(for: sport)
        UserDefaults.standard.set(value, forKey: key)
    }

    private func betPrefix(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value))/"
        } else {
            return "\(value)/"
        }
    }

    private func applyDefaultBetPrefixIfNeeded(force: Bool = false) {
        guard let last = getLastBetAmount(for: lastSport) else { return }

        // Only overwrite when asked, or when the field is empty.
        if force || amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amountText = betPrefix(last)
        }
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

