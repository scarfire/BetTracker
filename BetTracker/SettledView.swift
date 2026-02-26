import SwiftUI
import SwiftData

// MARK: - Swipeable Card

private struct SwipeToDeleteCard<Content: View>: View {
    let content: Content
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0

    private let deleteWidth: CGFloat = 80

    init(onDelete: @escaping () -> Void, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Red delete button behind the card
            Button(action: triggerDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.white)
                    .frame(width: deleteWidth)
                    .frame(maxHeight: .infinity)
                    .background(Color.red)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .opacity(offset < 0 ? 1 : 0)

            content
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 20, coordinateSpace: .local)
                        .onChanged { value in
                            let x = value.translation.width
                            let y = value.translation.height
                            // Only hijack clearly horizontal swipes
                            guard abs(x) > abs(y) else { return }
                            if x < 0 {
                                offset = max(x, -deleteWidth * 1.5)
                            } else if offset < 0 {
                                offset = min(x + offset, 0)
                            }
                        }
                        .onEnded { value in
                            let x = value.translation.width
                            let y = value.translation.height
                            guard abs(x) > abs(y) else { return }
                            if x < -deleteWidth {
                                withAnimation(.easeOut(duration: 0.2)) { offset = -deleteWidth }
                            } else {
                                withAnimation(.spring()) { offset = 0 }
                            }
                        }
                )
        }
        .clipped()
    }

    private func triggerDelete() {
        withAnimation(.easeIn(duration: 0.2)) { offset = -400 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { onDelete() }
    }
}

// MARK: - SettledView

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
                                SwipeToDeleteCard {
                                    modelContext.delete(bet)
                                } content: {
                                    settledCard(bet)
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

            Text("Settled")
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

    private var settledBets: [Bet] {
        let filtered = bets.filter { $0.net != nil }

        if sportFilter == "All" {
            return filtered.sorted { ($0.settledAt ?? Date()) > ($1.settledAt ?? Date()) }
        }

        return filtered
            .filter { $0.sport == sportFilter }
            .sorted { ($0.settledAt ?? Date()) > ($1.settledAt ?? Date()) }
    }

    // MARK: Card

    private func settledCard(_ bet: Bet) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(bet.sport) • \(bet.wagerText)")
                .font(.headline)

            if let settledAt = bet.settledAt {
                Text("Settled: \(shortDate(settledAt))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Text("Net: \(money(bet.net ?? 0))")
                .font(.headline)
                .foregroundColor((bet.net ?? 0) > 0 ? .blue :
                                 (bet.net ?? 0) < 0 ? .red : .gray)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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
