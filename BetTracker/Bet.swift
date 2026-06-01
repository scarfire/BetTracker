//
//  Bet.swift
//  BetTracker
//

import Foundation

struct Bet: Identifiable {
    let id: Int
    let sport: String
    let wagerText: String
    let isProp: Bool
    let isParlay: Bool
    let eventDate: String
    let betAmount: Double
    let payoutAmount: Double
    let originalPayoutAmount: Double
    let net: Double?
    let settledAt: String?
    let createdAt: String

    // MARK: - Derived display values

    var eventDateFormatted: String { formatDate(eventDate) }
    var settledAtFormatted: String? { settledAt.map { formatDateTime($0) } }

    var isPending: Bool { net == nil }
    var isWin:     Bool { (net ?? 0) > 0 }
    var isLoss:    Bool { (net ?? 0) < 0 }
    var isPush:    Bool { net != nil && net == 0 }

    // MARK: - Manual JSON init

    init?(json: [String: Any]) {
        guard
            let idStr   = json["id"] as? String,
            let id      = Int(idStr),
            let sport   = json["sport"] as? String,
            let wager   = json["wager_text"] as? String,
            let ed      = json["event_date"] as? String,
            let baStr   = json["bet_amount"] as? String,
            let ba      = Double(baStr),
            let paStr   = json["payout_amount"] as? String,
            let pa      = Double(paStr),
            let opaStr  = json["original_payout_amount"] as? String,
            let opa     = Double(opaStr),
            let caStr   = json["created_at"] as? String
        else { return nil }

        self.id                   = id
        self.sport                = sport
        self.wagerText            = wager
        self.eventDate            = ed
        self.betAmount            = ba
        self.payoutAmount         = pa
        self.originalPayoutAmount = opa
        self.createdAt            = caStr

        let propStr   = json["is_prop"] as? String ?? "0"
        let parlayStr = json["is_parlay"] as? String ?? "0"
        self.isProp   = propStr == "1"
        self.isParlay = parlayStr == "1"

        // net: either null or a numeric string
        if let netStr = json["net"] as? String {
            self.net = Double(netStr)
        } else {
            self.net = nil
        }

        // settled_at: either null or a datetime string
        self.settledAt = json["settled_at"] as? String
    }

    // MARK: - Formatters

    private func formatDate(_ str: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        guard let d = f.date(from: str) else { return str }
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: d)
    }

    private func formatDateTime(_ str: String) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let d = f.date(from: str) else { return str }
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}
