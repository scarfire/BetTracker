//
//  Bet.swift
//  BetTracker
//

import Foundation

struct Bet: Identifiable, Codable {
    let id: Int
    let sport: String
    let wagerText: String
    let isProp: Bool
    let isParlay: Bool
    let eventDate: String       // "YYYY-MM-DD" from MySQL DATE
    let betAmount: Double
    let payoutAmount: Double
    let originalPayoutAmount: Double
    let net: Double?             // nil = pending
    let settledAt: String?       // "YYYY-MM-DD HH:MM:SS" or nil
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case sport
        case wagerText          = "wager_text"
        case isProp             = "is_prop"
        case isParlay           = "is_parlay"
        case eventDate          = "event_date"
        case betAmount          = "bet_amount"
        case payoutAmount       = "payout_amount"
        case originalPayoutAmount = "original_payout_amount"
        case net
        case settledAt          = "settled_at"
        case createdAt          = "created_at"
    }

    // MARK: - Derived display values

    var eventDateFormatted: String { formatDate(eventDate) }
    var settledAtFormatted: String? { settledAt.map { formatDateTime($0) } }

    var isPending: Bool { net == nil }
    var isWin:     Bool { (net ?? 0) > 0 }
    var isLoss:    Bool { (net ?? 0) < 0 }
    var isPush:    Bool { net != nil && net == 0 }

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
