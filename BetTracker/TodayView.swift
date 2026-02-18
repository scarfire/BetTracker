//
//  TodayView.swift
//  BetTracker
//
//  Updated: Sportsboard pinned header + sections + animations + eventDate + settledAt
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"
    @State private var selectedBet: Bet?

    private let headerHeight: CGFloat = 110

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {

                // Main content pushed below the pinned header
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: headerHeight)

                    contentBody
                }

                // Pinned header (stays at top)
                headerView
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            Image("sportsboard")
                .resizable()
                .scaledToFill()
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .clipped()
                .ignoresSafeArea(edges: .top)

            LinearGradient(
                colors: [Color.black.opacity(0.55), Color.black.opacity(0.15)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea(edges: .top)

            Text("Today")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
        .frame(height: headerHeight)
    }

    // MARK: - Body content

    private var contentBody: some View {
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
                // PENDING
                if !pendingBets.isEmpty {
                    Section("Pending") {
                        ForEach(pendingBets) { bet in
                            betRow(bet)
                        }
                        .onDelete { offsets in
                            deleteFrom(offsets, in: pendingBets)
                        }
                    }
                }

                // WINS
                if !winBets.isEmpty {
                    Section("Wins") {
                        ForEach(winBets) { bet in
                            betRow(bet)
                        }
                        .onDelete { offsets in
                            deleteFrom(offsets, in: winBets)
                        }
                    }
                }

                // LOSSES
                if !lossBets.isEmpty {
                    Section("Losses") {
                        ForEach(lossBets) { bet in
                            betRow(bet)
                        }
                        .onDelete { offsets in
                            deleteFrom(offsets, in: lossBets)
                        }
                    }
                }

                // PUSHES
                if !pushBets.isEmpty {
                    Section("Pushes") {
                        ForEach(pushBets) { bet in
                            betRow(bet)
                        }
                        .onDelete { offsets in
                            deleteFrom(offsets, in: pushBets)
                        }
                    }
                }

                if pendingBets.isEmpty && winBets.isEmpty && lossBets.isEmpty && pushBets.isEmpty {
                    Text("No bets for today.")
                        .foregroundColor(.secondary)
                }
            }
            // Smooth movement between sections when net changes
            .animation(.easeInOut(duration: 0.25), value: animationKey)
        }
    }

    // MARK: - Row

    @ViewBuilder
    private func betRow(_ bet: Bet) -> some View {
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
            // Subtle per-row animation when result is set
            .animation(.easeInOut(duration: 0.25), value: bet.net)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()

        // Today is based on EVENT DATE now (not when you entered it)
        let filtered = bets.filter { $0.eventDate >= start && $0.eventDate < end }

        if sportFilter == "All" { return filtered }
        return filtered.filter { $0.sport == sportFilter }
    }

    // Always oldest -> newest (entry order), within each section
    private var pendingBets: [Bet] {
        todayBets
            .filter { $0.net == nil }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var winBets: [Bet] {
        todayBets
            .filter { ($0.net ?? 0) > 0 }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var lossBets: [Bet] {
        todayBets
            .filter { ($0.net ?? 0) < 0 }
            .sorted { $0.createdAt < $1.createdAt }
    }

    private var pushBets: [Bet] {
        todayBets
            .filter { $0.net == 0 }
            .sorted { $0.createdAt < $1.createdAt }
    }

    // Helps animate movement between sections when results change
    private var animationKey: String {
        let parts = todayBets
            .sorted { $0.createdAt < $1.createdAt }
            .map { bet in
                if let net = bet.net {
                    return net > 0 ? "W" : (net < 0 ? "L" : "P")
                } else {
                    return "N"
                }
            }
        return parts.joined()
    }

    private func deleteFrom(_ offsets: IndexSet, in array: [Bet]) {
        for index in offsets {
            context.delete(array[index])
        }
    }

    // MARK: - UI helpers

    private func backgroundColor(for bet: Bet) -> Color {
        guard let net = bet.net else { return Color.clear }
        if net > 0 { return Color.blue.opacity(0.85) }     // WIN
        if net < 0 { return Color.red.opacity(0.85) }      // LOSS
        return Color.gray.opacity(0.7)                      // PUSH
    }

    private func foregroundColor(for bet: Bet) -> Color {
        guard bet.net != nil else { return .primary }
        return .white
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

// MARK: - Update Result Sheet

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

                // Simple buttons (no "selected" visuals)
                HStack(spacing: 12) {
                    Button("WIN") { applyWin() }
                        .buttonStyle(.bordered)

                    Button("LOSS") { applyLoss() }
                        .buttonStyle(.bordered)

                    Button("PUSH") { applyPush() }
                        .buttonStyle(.bordered)
                }

                Button("Reset to Pending") { resetToPending() }
                    .buttonStyle(.bordered)

                Divider()

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
                            .buttonStyle(.bordered)

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
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func shortDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

