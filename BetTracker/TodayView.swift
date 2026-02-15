//
//  TodayView.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"   // "All" or "NHL" etc.
    @State private var selectedBet: Bet?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // Filter bar
                HStack {
                    Text("Sport")
                        .font(.headline)

                    Spacer()

                    Picker("Sport Filter", selection: $sportFilter) {
                        Text("All").tag("All")
                        ForEach(Sport.allCases) { sport in
                            Text(sport.rawValue).tag(sport.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 8)

                List {
                    ForEach(filteredTodayBetsChronological) { bet in
                        Button {
                            selectedBet = bet
                        } label: {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(bet.sport) • \(bet.wagerText)")
                                        .fontWeight(.semibold)
                                    
                                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                                        .font(.caption)
                                        .opacity(0.9)
                                }
                                
                                Spacer()
                                
                                if let net = bet.net {
                                    Text(money(net))
                                        .fontWeight(.bold)
                                } else {
                                    Text("Pending")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }
                            }
                            .padding(10)
                            .background(backgroundColor(for: bet))
                            .foregroundColor(foregroundColor(for: bet))
                            .cornerRadius(10)
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete(perform: deleteBets)
                }
            }
            .navigationTitle("Today")
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
    }

    // MARK: - Data

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        return bets.filter { $0.createdAt >= start }
    }

    // Always oldest -> newest (entry order), regardless of filter
    private var filteredTodayBetsChronological: [Bet] {
        let filtered: [Bet]
        if sportFilter == "All" {
            filtered = todayBets
        } else {
            filtered = todayBets.filter { $0.sport == sportFilter }
        }
        return filtered.sorted { $0.createdAt < $1.createdAt }
    }

    private func deleteBets(at offsets: IndexSet) {
        let items = filteredTodayBetsChronological
        for index in offsets {
            context.delete(items[index])
        }
    }

    // MARK: - UI helpers

    private func colorForBetTitle(_ bet: Bet) -> Color {
        guard let net = bet.net else { return .primary }
        if net > 0 { return .blue }
        if net < 0 { return .red }
        return .primary
    }

    private func money(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
        
    private func backgroundColor(for bet: Bet) -> Color {
        guard let net = bet.net else { return Color.clear }

        if net > 0 {
            return Color.blue.opacity(0.85)   // WIN
        } else if net < 0 {
            return Color.red.opacity(0.85)    // LOSS
        } else {
            return Color.gray.opacity(0.7)    // PUSH
        }
    }

    private func foregroundColor(for bet: Bet) -> Color {
        guard bet.net != nil else { return .primary }
        return .white
    }

}

// MARK: - Update Result Sheet

struct UpdateResultSheet: View {
    @Environment(\.dismiss) private var dismiss

    let bet: Bet

    @State private var cashoutOn: Bool = false
    @State private var cashoutText: String = ""
    @State private var error: String?

    private enum Selection {
        case none, win, loss, push
    }

    // NONE selected while pending
    private var selection: Selection {
        guard let net = bet.net else { return .none }
        if net > 0 { return .win }
        if net < 0 { return .loss }
        return .push
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(bet.sport) • \(bet.wagerText)")
                        .font(.headline)

                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                        .foregroundColor(.secondary)
                        .font(.subheadline)

                    if let net = bet.net {
                        Text("Current Net: \(money(net))")
                            .foregroundColor(net > 0 ? .blue : (net < 0 ? .red : .gray))
                            .fontWeight(.semibold)
                    } else {
                        Text("Current: Pending")
                            .foregroundColor(.orange)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Quick result buttons
                HStack(spacing: 12) {
                    Button("WIN") { applyWin() }
                        .buttonStyle(.bordered)

                    Button("LOSS") { applyLoss() }
                        .buttonStyle(.bordered)

                    Button("PUSH") { applyPush() }
                        .buttonStyle(.bordered)
                }
                
                Divider()

                // Cash Out
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Cash Out", isOn: $cashoutOn)
                        .onChange(of: cashoutOn) { _, newValue in
                            if !newValue {
                                cashoutText = ""
                                error = nil
                            }
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
                            .buttonStyle(.borderedProminent)

                        if let error {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
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
        bet.net = bet.payoutAmount - bet.betAmount
        dismiss()
    }

    private func applyLoss() {
        bet.net = -bet.betAmount
        dismiss()
    }

    private func applyPush() {
        bet.net = 0
        dismiss()
    }

    private func applyCashout() {
        error = nil
        let trimmed = cashoutText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let received = Double(trimmed), received >= 0 else {
            error = "Enter a valid amount (like 3.80)."
            return
        }
        // Record cashout as actual payout received
        bet.payoutAmount = received
        bet.net = received - bet.betAmount
        dismiss()
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

