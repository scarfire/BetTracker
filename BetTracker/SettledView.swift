//
//  SettledView.swift
//  BetTracker
//

import SwiftUI

struct SettledView: View {
    @EnvironmentObject var service: BetService

    @State private var sportFilter: String = "All"
    @State private var searchText: String = ""
    @State private var selectedBet: Bet?
    @State private var useDateFilter: Bool = false
    @State private var filterDate: Date = Date()

    private let headerHeight: CGFloat = 140

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // The API only returns the last 7 days of settled bets
    private var windowStart: Date {
        Calendar.current.date(byAdding: .day, value: -7,
                              to: Calendar.current.startOfDay(for: Date())) ?? Date()
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {

                    headerView
                    filterBar.padding(.horizontal)
                    dateBar.padding(.horizontal)
                    searchBar.padding(.horizontal)

                    if service.isLoading {
                        ProgressView().padding(.horizontal).padding(.top, 8)
                    } else {
                        if !filteredBets.isEmpty {
                            totalBar.padding(.horizontal)
                        }

                        if filteredBets.isEmpty {
                            Text(service.errorMessage != nil ? "Failed to load bets." : "No settled bets.")
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
                    }

                    Spacer(minLength: 20)
                }
            }
            .scrollDismissesKeyboard(.immediately)
            .refreshable { await service.fetchSettled() }
            .ignoresSafeArea(edges: .top)
            .toolbar(.hidden, for: .navigationBar)
            .background(Color(.systemGroupedBackground))
            .sheet(item: $selectedBet) { bet in
                UpdateResultSheet(bet: bet)
            }
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Date Bar

    private var dateBar: some View {
        HStack {
            Text("Date").font(.headline)
            Spacer()
            if useDateFilter {
                DatePicker("Date", selection: $filterDate, in: windowStart..., displayedComponents: .date)
                    .labelsHidden()
                Button {
                    useDateFilter = false
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
            } else {
                Button("All") {
                    filterDate = Date()
                    useDateFilter = true
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.secondarySystemGroupedBackground))
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
        .background(Color(.secondarySystemGroupedBackground))
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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Data

    private var filteredBets: [Bet] {
        var result = service.settledBets

        if useDateFilter {
            let day = Self.dayFormatter.string(from: filterDate)
            result = result.filter { $0.eventDate == day }
        }
        if sportFilter != "All" {
            result = result.filter { $0.sport == sportFilter }
        }
        guard !searchText.isEmpty else { return result }

        let query = searchText.lowercased()
        return result.filter {
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
