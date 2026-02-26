//
//  TodayView.swift
//  BetTracker
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
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView

                    filterBar
                        .padding(.horizontal)

                    if !pendingBets.isEmpty {
                        sectionHeader("Pending").padding(.horizontal)
                        cards(pendingBets)
                    }
                    if !winBets.isEmpty {
                        sectionHeader("Wins").padding(.horizontal)
                        cards(winBets)
                    }
                    if !lossBets.isEmpty {
                        sectionHeader("Losses").padding(.horizontal)
                        cards(lossBets)
                    }
                    if !pushBets.isEmpty {
                        sectionHeader("Pushes").padding(.horizontal)
                        cards(pushBets)
                    }
                    if pendingBets.isEmpty && winBets.isEmpty && lossBets.isEmpty && pushBets.isEmpty {
                        Text("No bets for today.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 28)
            }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
            .animation(.easeInOut(duration: 0.25), value: animationKey)
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
            Text("Sport").font(.headline)
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
                BetCard(bet: bet) { selectedBet = bet }
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

    // MARK: - Data

    private var todayBets: [Bet] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? Date()
        let dayFiltered = bets.filter { $0.eventDate >= start && $0.eventDate < end }
        if sportFilter == "All" { return dayFiltered }
        return dayFiltered.filter { $0.sport == sportFilter }
    }

    private var pendingBets: [Bet] { todayBets.filter { $0.net == nil }.sorted { $0.createdAt < $1.createdAt } }
    private var winBets:     [Bet] { todayBets.filter { ($0.net ?? 0) > 0 }.sorted { $0.createdAt < $1.createdAt } }
    private var lossBets:    [Bet] { todayBets.filter { ($0.net ?? 0) < 0 }.sorted { $0.createdAt < $1.createdAt } }
    private var pushBets:    [Bet] { todayBets.filter { $0.net == 0 }.sorted { $0.createdAt < $1.createdAt } }

    private var animationKey: String {
        todayBets.sorted { $0.createdAt < $1.createdAt }.map { bet in
            guard let net = bet.net else { return "N" }
            return net > 0 ? "W" : (net < 0 ? "L" : "P")
        }.joined()
    }
}
