import SwiftUI
import SwiftData

struct BetsGridView: View {
    @Query(sort: \Bet.eventDate) private var bets: [Bet]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Bet Tracker - Data Grid")
                .font(.title2)
                .padding(.horizontal)
                .padding(.top, 8)

            Table(bets) {
                TableColumn("Event Date") { bet in
                    Text(bet.eventDate, format: .dateTime.month().day().year())
                }

                TableColumn("Sport") { bet in
                    Text(bet.sport)
                }

                TableColumn("Wager") { bet in
                    Text(bet.wagerText).lineLimit(1)
                }

                TableColumn("Bet Amount") { bet in
                    Text(bet.betAmount, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }

                TableColumn("Payout") { bet in
                    Text(bet.payoutAmount, format: .number.precision(.fractionLength(2)))
                        .monospacedDigit()
                }

                TableColumn("Net") { bet in
                    if let net = bet.net {
                        Text(net, format: .number.precision(.fractionLength(2)))
                            .monospacedDigit()
                    } else {
                        Text("Pending").foregroundStyle(.secondary)
                    }
                }

                TableColumn("Created") { bet in
                    Text(bet.createdAt, format: .dateTime.month().day().year())
                }
            }
            .padding()
        }
        .frame(minWidth: 1000, minHeight: 600)
    }
}

