//
//  SettledView.swift
//  BetTracker
//

import SwiftUI

struct SettledView: View {
    @EnvironmentObject var service: BetService

    @State private var sportFilter: String = "All"
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
                        ProgressView().padding(.horizontal).padding(.top, 8)
                    } else {
                        if !filteredBets.isEmpty {
                            totalBar.padding(.horizontal)
                        }

                        if filteredBets.isEmpty {
                            Text(service.errorMessage != nil ? "Failed to load bets." : "No settled bets today.")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(filteredBets) { bet in
                                    BetCard(bet: bet)
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
                    }

                    Spacer(minLength: 20)
                }
            }
            .refreshable { await service.fetchSettled() }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
        }
        .task { await service.fetchSettled() }
        .onAppear { Task { await service.fetchSettled() } }
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
            Text("Settled")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 16)
                .padding(.bottom, 14)
        }
        .frame(height: headerHeight)
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

    // MARK: - Total Bar

    private var totalBar: some View {
        let total = filteredBets.reduce(0.0) { $0 + ($1.net ?? 0) }
        return HStack {
            Text("Net").font(.headline)
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

    // MARK: - Data

    private var filteredBets: [Bet] {
        let sportFiltered = sportFilter == "All"
            ? service.settledBets
            : service.settledBets.filter { $0.sport == sportFilter }
        guard !searchText.isEmpty else { return sportFiltered }
        let query = searchText.lowercased()
        return sportFiltered.filter {
            $0.wagerText.lowercased().contains(query) || $0.sport.lowercased().contains(query)
        }
    }

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
