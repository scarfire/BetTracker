//
//  AddBetView.swift
//  BetTracker
//
//  Updated: thumb-friendly Save near Bet/Payout + dismiss keyboard on Save + toast confirmation
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

    // Event date (game day / last leg date for parlays)
    @State private var eventDate: Date = Date()
    @State private var showEventDatePicker: Bool = false

    // Toast
    @State private var showToast: Bool = false
    @State private var toastText: String = "Saved"

    @FocusState private var focusedField: Field?
    enum Field { case what, amount }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 14) {

                        // Sport Picker (remembers last)
                        Picker("Sport", selection: $lastSport) {
                            ForEach(Sport.allCases) { sport in
                                Text(sport.rawValue).tag(sport.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)

                        // Event Date row (label + tappable date)
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
                            DatePicker(
                                "",
                                selection: $eventDate,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(.graphical)
                            .labelsHidden()
                            .onChange(of: eventDate) { _, _ in
                                normalizeEventDateToStartOfDay()
                            }
                        }

                        // What box
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What")
                                .font(.headline)

                            // Quick insert buttons
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

                            // Thumb-friendly Save row (right aligned)
                            HStack(alignment: .top) {
                                if let errorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .font(.caption)
                                        .lineLimit(2)
                                } else {
                                    Spacer(minLength: 0)
                                }

                                Spacer()

                                Button {
                                    saveBet()
                                } label: {
                                    Text("Save")
                                        .fontWeight(.semibold)
                                        .frame(minWidth: 110)
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 2)
                        }

                        // Bottom spacer so content can scroll above the keyboard
                        Color.clear
                            .frame(height: 110)
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.interactively)
                .navigationBarHidden(true)
                .toolbar {
                    ToolbarItem(placement: .keyboard) {
                        HStack {
                            Spacer()
                            Button("Done") { focusedField = nil }
                        }
                    }
                }
                .onAppear {
                    focusedField = .what
                    normalizeEventDateToStartOfDay()
                    applyDefaultBetPrefixIfNeeded(force: true)
                }
                .onChange(of: lastSport) { _, _ in
                    applyDefaultBetPrefixIfNeeded(force: true)
                }

                // Toast overlay
                if showToast {
                    toastView(text: toastText)
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Save

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
            createdAt: Date(),
            eventDate: Calendar.current.startOfDay(for: eventDate),
            settledAt: nil,
            sport: lastSport,
            wagerText: what,
            betAmount: parsed.bet,
            payoutAmount: parsed.payout,
            originalPayoutAmount: parsed.payout,
            net: nil
        )

        context.insert(bet)

        // Close keyboard so you can reach the tab bar immediately
        focusedField = nil

        // Toast confirmation
        toastText = "Saved ✓"
        showToastNow()

        // Fast loop reset (keep event date)
        whatText = ""
        amountText = ""
        applyDefaultBetPrefixIfNeeded(force: true)
        useNumericKeyboardForWhat = false
    }

    // MARK: - Toast

    private func showToastNow() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showToast = false
            }
        }
    }

    private func toastView(text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
            .shadow(radius: 6)
            .accessibilityLabel(text)
    }

    // MARK: - What quick buttons

    private func quickAppendButton(label: String, token: String, requiresLeadingSpace: Bool) -> some View {
        Button(label) {
            if token == "ML " {
                useNumericKeyboardForWhat = false
            } else {
                useNumericKeyboardForWhat = true
            }

            appendToken(token, requiresLeadingSpace: requiresLeadingSpace)

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
        var text = whatText
        if requiresLeadingSpace, !text.isEmpty, !text.hasSuffix(" ") {
            text += " "
        }
        text += token
        whatText = text.uppercased()
    }

    // MARK: - Amount quick buttons + defaults per sport

    private func amountButton(_ value: Double) -> some View {
        Button {
            setLastBetAmount(value, for: lastSport)
            amountText = betPrefix(value)

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
        if force || amountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amountText = betPrefix(last)
        }
    }

    // MARK: - Formatting helpers

    private func normalizeEventDateToStartOfDay() {
        eventDate = Calendar.current.startOfDay(for: eventDate)
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// Strict parser: "bet/payout" with decimals allowed, optional $ and spaces
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

