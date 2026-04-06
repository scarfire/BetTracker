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
    @State private var dayRange: Int = 30
    @State private var searchText: String = ""

    private let headerHeight: CGFloat = 140
    private let ranges = [7, 30, 90, 365]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView

                    dateRangePicker
                        .padding(.horizontal)

                    filterBar
                        .padding(.horizontal)

                    searchBar
                        .padding(.horizontal)

                    if !settledBets.isEmpty {
                        totalBar
                            .padding(.horizontal)
                    }

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

    // MARK: - Date Range Picker

    private var dateRangePicker: some View {
        Picker("Date Range", selection: $dayRange) {
            ForEach(ranges, id: \.self) { days in
                Text(label(for: days)).tag(days)
            }
        }
        .pickerStyle(.segmented)
    }

    private func label(for days: Int) -> String {
        switch days {
        case 7:   return "7 Days"
        case 30:  return "30 Days"
        case 90:  return "90 Days"
        default:  return "Year"
        }
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
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search bets...", text: $searchText)
                .autocorrectionDisabled(true)
                .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
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
        let total = settledBets.reduce(0) { $0 + ($1.net ?? 0) }
        return HStack {
            Text("Net")
                .font(.headline)
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
        .animation(.easeInOut(duration: 0.25), value: total)
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

    // MARK: - Data

    private var settledBets: [Bet] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -dayRange, to: Date()) ?? Date()
        let filtered = bets.filter { $0.net != nil && $0.eventDate >= cutoff }
        let sportFiltered = sportFilter == "All" ? filtered : filtered.filter { $0.sport == sportFilter }
        let sorted = sportFiltered.sorted { ($0.settledAt ?? Date()) > ($1.settledAt ?? Date()) }
        guard !searchText.isEmpty else { return sorted }
        let query = searchText.lowercased()
        return sorted.filter {
            $0.wagerText.lowercased().contains(query) || $0.sport.lowercased().contains(query)
        }
    }
}
