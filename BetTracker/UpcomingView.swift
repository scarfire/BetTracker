import SwiftUI
import SwiftData

struct UpcomingView: View {
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

                    if upcomingBets.isEmpty {
                        Text("No upcoming bets.")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(upcomingBets) { bet in
                                upcomingCard(bet)
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

    // MARK: Header

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

            Text("Upcoming")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
                .padding(.leading, 16)
                .padding(.bottom, 14)
        }
        .frame(height: headerHeight)
    }

    // MARK: Filter

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

    // MARK: Data

    private var upcomingBets: [Bet] {
        let now = Date()
        let filtered = bets.filter { $0.eventDate > now && $0.net == nil }

        if sportFilter == "All" { return filtered.sorted { $0.eventDate < $1.eventDate } }
        return filtered
            .filter { $0.sport == sportFilter }
            .sorted { $0.eventDate < $1.eventDate }
    }

    // MARK: Card

    private func upcomingCard(_ bet: Bet) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(bet.sport) • \(bet.wagerText)")
                .font(.headline)

            Text("Event: \(shortDate(bet.eventDate))")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text("Bet \(money(bet.betAmount)) → Win \(money(bet.payoutAmount))")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 6)
    }

    private func money(_ value: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "USD"
        return f.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    private func shortDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f.string(from: date)
    }
}

