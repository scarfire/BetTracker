//
//  UpcomingView.swift
//  BetTracker
//

import SwiftUI

struct UpcomingView: View {
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
                        ProgressView().padding(.horizontal).padding(.top, 8)
                    } else if filteredBets.isEmpty {
                        Text(service.errorMessage != nil ? "Failed to load bets." : "No upcoming bets.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(filteredBets) { bet in
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

                    Spacer(minLength: 20)
                }
            }
            .refreshable { await service.fetchUpcoming() }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
        }
        .task { await service.fetchUpcoming() }
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
            Text("Upcoming")
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

    // MARK: - Data

    private var filteredBets: [Bet] {
        let sportFiltered = sportFilter == "All"
            ? service.upcomingBets
            : service.upcomingBets.filter { $0.sport == sportFilter }
        guard !searchText.isEmpty else { return sportFiltered }
        let query = searchText.lowercased()
        return sportFiltered.filter {
            $0.wagerText.lowercased().contains(query) || $0.sport.lowercased().contains(query)
        }
    }
}
