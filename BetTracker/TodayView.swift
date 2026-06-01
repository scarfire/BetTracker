//
//  TodayView.swift
//  BetTracker
//

import SwiftUI

struct TodayView: View {
    @EnvironmentObject var service: BetService

    @State private var sportFilter: String = "All"
    @State private var selectedBet: Bet?
    @State private var searchText: String = ""

    private let headerHeight: CGFloat = 140

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView

                    filterBar.padding(.horizontal)
                    searchBar.padding(.horizontal)

                    if service.isLoading {
                        ProgressView()
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        if !settledBets.isEmpty {
                            dailyTotalBar.padding(.horizontal)
                        }
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
                        if filteredBets.isEmpty {
                            Text(service.errorMessage != nil ? "Failed to load bets." : "No bets for today.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                    }

                    Spacer(minLength: 20)
                }
                .padding(.bottom, 28)
            }
            .refreshable { await service.fetchToday() }
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea(edges: .top)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
        .task { await service.fetchToday() }
        .onAppear { Task { await service.fetchToday() } }
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
                startPoint: .bottom, endPoint: .top
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

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundColor(.secondary)
            TextField("Search bets...", text: $searchText)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Daily Total Bar

    private var dailyTotalBar: some View {
        let total = settledBets.reduce(0.0) { $0 + ($1.net ?? 0) }
        return HStack {
            Text("Today's Net").font(.headline)
            Spacer()
            Text(formatted(total))
                .font(.headline.weight(.bold))
                .foregroundColor(total > 0 ? .blue : total < 0 ? .red : .secondary)
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
                            Task { try? await service.delete(id: bet.id) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Data

    private var filteredBets: [Bet] {
        let sportFiltered = sportFilter == "All"
            ? service.todayBets
            : service.todayBets.filter { $0.sport == sportFilter }
        guard !searchText.isEmpty else { return sportFiltered }
        let query = searchText.lowercased()
        return sportFiltered.filter {
            $0.wagerText.lowercased().contains(query) || $0.sport.lowercased().contains(query)
        }
    }

    private var settledBets: [Bet] { filteredBets.filter { !$0.isPending } }
    private var pendingBets: [Bet] { filteredBets.filter { $0.isPending }.sorted { $0.eventDate < $1.eventDate } }
    private var winBets:     [Bet] { filteredBets.filter { $0.isWin }.sorted { $0.createdAt < $1.createdAt } }
    private var lossBets:    [Bet] { filteredBets.filter { $0.isLoss }.sorted { $0.createdAt < $1.createdAt } }
    private var pushBets:    [Bet] { filteredBets.filter { $0.isPush }.sorted { $0.createdAt < $1.createdAt } }

    private func formatted(_ value: Double) -> String {
        let abs = Swift.abs(value)
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        let str = f.string(from: NSNumber(value: abs)) ?? "$0.00"
        return value >= 0 ? "+\(str)" : "-\(str)"
    }
}
