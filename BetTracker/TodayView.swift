//
//  TodayView.swift
//  BetTracker
//
//  ScrollView header (sportsboard) + sections + animations + eventDate + settledAt
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var bets: [Bet]

    @State private var sportFilter: String = "All"
    @State private var selectedBet: Bet?

    private let headerHeight: CGFloat = 140

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14, pinnedViews: []) {

                    headerView

                    filterBar
                        .padding(.horizontal)

                    // Sections (custom, not List)
                    if !pendingBets.isEmpty {
                        sectionHeader("Pending")
                            .padding(.horizontal)
                        cards(pendingBets)
                    }

                    if !winBets.isEmpty {
                        sectionHeader("Wins")
                            .padding(.horizontal)
                        cards(winBets)
                    }

                    if !lossBets.isEmpty {
                        sectionHeader("Losses")
                            .padding(.horizontal)
                        cards(lossBets)
                    }

                    if !pushBets.isEmpty {
                        sectionHeader("Pushes")
                            .padding(.horizontal)
                        cards(pushBets)
                    }

                    if pendingBets.isEmpty && winBets.isEmpty && lossBets.isEmpty && pushBets.isEmpty {
                        Text("No bets for today.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    } else {
                        Spacer(minLength: 20)
                    }
                }
                .padding(.bottom, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
//            .navigationBarTitleDisplayMode(.inline) // keep nav quiet; title lives in header image
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
            .animation(.easeInOut(duration: 0.25), value: animationKey)
        }
    }

    // MARK: - Header (scrolls away)

    private var headerView: some View {
        ZStack(alignment: .bottomLeading) {
            Image("sportsboard")
                .resizable()
                .scaledToFill()
                .frame(height: headerHeight)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.60), Color.black.opacity(0.10)],
                startPoint: .bottom,
                endPoint: .top
            )

            Text("Today")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 16)
                .padding(.bottom, 14)
        }
        .frame(height: headerHeight)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
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
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Section + Cards

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .foregroundColor(.secondary)
            .padding(.top, 8)
    }

    private func cards(_ array: [Bet]) -> some View {
        VStack(spacing: 10) {
            ForEach(array) { bet in
                betCard(bet)
                    .contextMenu {
                        Button(role: .destructive) {
                            context.delete(bet)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal)
    }

    private func betCard(_ bet: Bet) -> some View {
        Button {
            selectedBet = bet
        } label: {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(bet.sport) • \(bet.wagerText)")
                        .font(.headline)
                        .foregroundColor(foregroundColor(for: bet))

                    Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                        .font(.subheadline)
                        .foregroundColor(foregroundColor(for: bet).opacity(0.85))
                }

                Spacer()

                if let net = bet.net {
                    Text(money(net))
                        .font(.headline.weight(.bold))
                        .foregroundColor(foregroundColor(for: bet))
                } else {
                    Text("Pending")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(14)
            .background(cardBackground(for: bet))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
            .animation(.easeInOut(duration: 0.25), value: bet.net)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data (Today uses eventDate)

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()

        let dayFiltered = bets.filter { $0.eventDate >= start && $0.eventDate < end }
        if sportFilter == "All" { return dayFiltered }
        return dayFiltered.filter { $0.sport == sportFilter }
    }

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

    // MARK: - Styling helpers

    private func cardBackground(for bet: Bet) -> Color {
        guard let net = bet.net else { return .white }
        if net > 0 { return Color.blue.opacity(0.85) }
        if net < 0 { return Color.red.opacity(0.85) }
        return Color.gray.opacity(0.70)
    }

    private func foregroundColor(for bet: Bet) -> Color {
        // Pending cards are white with normal text
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

// MARK: - Update Result Sheet (keep your existing one below this)
// Keep EXACTLY your current UpdateResultSheet block here.


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

