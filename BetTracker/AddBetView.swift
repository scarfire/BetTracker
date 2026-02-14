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

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    @State private var errorMessage: String?

    @Query private var bets: [Bet]

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {

                // Sport Picker
                Picker("Sport", selection: $lastSport) {
                    ForEach(Sport.allCases) { sport in
                        Text(sport.rawValue).tag(sport.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                // Quick Add Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("Quick Add")
                        .font(.headline)

                    TextField("Bet 3 to win 5.80 Boston ML", text: $inputText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .focused($isFocused)

                    Button("Save Bet") {
                        saveBet()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }

                // Recent Bets Today (confirmation)
                List {
                    ForEach(todayBets.prefix(10)) { bet in
                        VStack(alignment: .leading) {
                            Text("\(bet.sport) • \(bet.wagerText)")
                                .font(.body)

                            Text("Bet $\(bet.betAmount, specifier: "%.2f") → Win $\(bet.payoutAmount, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .navigationTitle("BetTracker")
            .onAppear {
                isFocused = true
            }
        }
    }

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        return bets.filter { $0.createdAt >= start }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func saveBet() {
        guard let parsed = StrictParser.parse(inputText) else {
            errorMessage = "Use format: Bet X to win Y"
            return
        }

        let bet = Bet(
            sport: lastSport,
            wagerText: parsed.wager,
            betAmount: parsed.bet,
            payoutAmount: parsed.payout
        )

        context.insert(bet)

        inputText = "" // AUTO CLEAR (your preference)
        errorMessage = nil
        isFocused = true
    }
}
