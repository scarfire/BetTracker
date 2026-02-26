//
//  SettledView.swift
//  BetTracker
//

import SwiftUI
import SwiftData

struct SettledView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var bets: [Bet]
    @State private var sportFilter: String = "All"

    private let headerHeight: CGFloat = 140

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView

                    filterBar
                        .padding(.horizontal)

                    if settledBets.isEmpty {
                        Text("No settled bets.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(settledBets) { bet in
                                BetCard(bet: bet)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(bet)
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
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
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

    // MARK: - Data

    private var settledBets: [Bet] {
        let filtered = bets.filter { $0.net != nil }
        if sportFilter == "All" {
            return filtered.sorted { ($0.settledAt ?? Date()) > ($1.settledAt ?? Date()) }
        }
        return filtered
            .filter { $0.sport == sportFilter }
            .sorted { ($0.settledAt ?? Date()) > ($1.settledAt ?? Date()) }
    }
}
