
//
//  AddBetView.swift
//  BetTracker
//
//  Final Clean Version:
//  - Separate What + Line/Amount field
//  - No space after + or -
//  - One space after OVER or UNDER
//  - Combine What + Amount on Save
//  - Minimal focus logic (stable on iPhone + Mac)
//

import SwiftUI
import SwiftData

struct AddBetView: View {
    @Environment(\.modelContext) private var context

    @AppStorage("lastSport") private var lastSport: String = Sport.nhl.rawValue

    @State private var whatText: String = ""
    @State private var whatAmountText: String = ""   // e.g. 6 or 6.5
    @State private var amountText: String = ""       // format: 5/9.32
    @State private var errorMessage: String?

    @State private var eventDate: Date = Date()
    @State private var showEventDatePicker: Bool = false

    @State private var showToast: Bool = false
    @State private var toastText: String = "Saved"

    @FocusState private var focusedField: Field?
    enum Field { case what, whatAmount, amount }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {

                        Picker("Sport", selection: $lastSport) {
                            ForEach(Sport.allCases) { sport in
                                Text(sport.rawValue).tag(sport.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack {
                            Text("Event Date")
                                .font(.headline)
                            Spacer()
                            Button {
                                focusedField = nil
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showEventDatePicker.toggle()
                                }
                            } label: {
                                Text(shortDate(eventDate))
                                    .fontWeight(.semibold)
                            }
                            .buttonStyle(.bordered)
                        }

                        if showEventDatePicker {
                            DatePicker("", selection: $eventDate, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                                .onChange(of: eventDate) { _, _ in
                                    eventDate = Calendar.current.startOfDay(for: eventDate)
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("What")
                                .font(.headline)

                            HStack(spacing: 10) {
                                quickAppendButton("ML", "ML ", nextFocus: .amount)
                                quickAppendButton("OVER", "OVER ", nextFocus: .whatAmount)
                                quickAppendButton("UNDER", "UNDER ", nextFocus: .whatAmount)
                                quickAppendButton("PLUS", "+", nextFocus: .whatAmount)
                                quickAppendButton("MINUS", "-", nextFocus: .whatAmount)
                                Spacer()
                            }

                            HStack(spacing: 10) {
                                TextField("BOS OVER", text: $whatText)
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
                                    .layoutPriority(1)

                                TextField("6.5", text: $whatAmountText)
#if os(iOS)
                                    .keyboardType(.decimalPad)
#endif
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled(true)
                                    .onChange(of: whatAmountText) { _, newValue in
                                        whatAmountText = sanitizeOneDecimal(newValue)
                                    }
                                    .padding()
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .frame(width: 110)
                                    .multilineTextAlignment(.center)
                                    .focused($focusedField, equals: .whatAmount)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bet / Payout")
                                .font(.headline)

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

                            HStack {
                                if let errorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                                Spacer()
                                Button("Save") {
                                    saveBet()
                                }
                                .fontWeight(.semibold)
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        Color.clear.frame(height: 110)
                    }
                    .padding()
                }
                .navigationBarHidden(true)
                .onAppear {
                    focusedField = .what
                    eventDate = Calendar.current.startOfDay(for: eventDate)
                    applyDefaultBetPrefixIfNeeded(force: true)
                }
                .onChange(of: lastSport) { _, _ in
                    applyDefaultBetPrefixIfNeeded(force: true)
                }

                if showToast {
                    Text(toastText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .shadow(radius: 6)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    private func saveBet() {
        errorMessage = nil

        let baseWhat = whatText.trimmingCharacters(in: .whitespacesAndNewlines)
        let amt = whatAmountText.trimmingCharacters(in: .whitespacesAndNewlines)

        var combinedWhat = baseWhat
        if !amt.isEmpty {
            // If What ends with OVER/UNDER, we want one space before the amount
            if combinedWhat.hasSuffix("OVER") || combinedWhat.hasSuffix("UNDER") {
                combinedWhat += " "
            }
            combinedWhat += amt
        }

        guard let parsed = SlashAmountParser.parse(amountText) else {
            errorMessage = "Enter amounts like 5/9.32 (bet/payout)."
            focusedField = .amount
            return
        }

        setLastBetAmount(parsed.bet, for: lastSport)

        let bet = Bet(
            createdAt: Date(),
            eventDate: eventDate,
            settledAt: nil,
            sport: lastSport,
            wagerText: combinedWhat,
            betAmount: parsed.bet,
            payoutAmount: parsed.payout,
            originalPayoutAmount: parsed.payout,
            net: nil
        )

        context.insert(bet)

        focusedField = nil
        toastText = "Saved ✓"
        showToast = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            showToast = false
        }

        whatText = ""
        whatAmountText = ""
        amountText = ""
        applyDefaultBetPrefixIfNeeded(force: true)

    }

    private func quickAppendButton(_ label: String, _ token: String, nextFocus: Field) -> some View {
        Button(label) {
            appendToken(token)
            focusedField = nextFocus
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemGray5))
        .cornerRadius(8)
    }

    private func appendToken(_ token: String) {
        var text = whatText

        // Always ensure a single leading space before ANY token (if needed)
        if !text.isEmpty && !text.hasSuffix(" ") {
            text += " "
        }

        text += token
        whatText = text.uppercased()
    }

    private func sanitizeOneDecimal(_ input: String) -> String {
        var filtered = input.filter { "0123456789.".contains($0) }

        if let firstDot = filtered.firstIndex(of: ".") {
            let after = filtered.index(after: firstDot)
            let rest = filtered[after...].replacingOccurrences(of: ".", with: "")
            filtered = String(filtered[..<after]) + rest
        }

        if let dot = filtered.firstIndex(of: ".") {
            let after = filtered.index(after: dot)
            if filtered[after...].count > 1 {
                let end = filtered.index(after: after)
                filtered = String(filtered[..<end])
            }
        }

        if filtered.hasPrefix(".") {
            filtered = "0" + filtered
        }

        return filtered
    }

    private func amountButton(_ value: Double) -> some View {
        Button {
            amountText = value == floor(value) ? "\(Int(value))/" : "\(value)/"
            focusedField = .amount
        } label: {
            Text(value == floor(value) ? "\(Int(value))" : "\(value)")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(.systemGray5))
                .cornerRadius(10)
        }
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func lastBetKey(for sport: String) -> String {
        "lastBetAmount_\(sport)"
    }

    private func getLastBetAmount(for sport: String) -> Double? {
        let v = UserDefaults.standard.double(forKey: lastBetKey(for: sport))
        return v > 0 ? v : nil
    }

    private func setLastBetAmount(_ value: Double, for sport: String) {
        UserDefaults.standard.set(value, forKey: lastBetKey(for: sport))
    }

    private func betPrefix(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))/" : "\(value)/"
    }

    private func applyDefaultBetPrefixIfNeeded(force: Bool = false) {
        guard let last = getLastBetAmount(for: lastSport) else { return }
        if force || amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amountText = betPrefix(last)
        }
    }

}

struct SlashAmountParser {
    struct Parsed { let bet: Double; let payout: Double }

    static func parse(_ input: String) -> Parsed? {
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
