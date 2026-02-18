//
//  Bet.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//

import Foundation
import SwiftData

@Model
final class Bet {
    var id: UUID

    /// When you entered the bet in the app (placedAt)
    var createdAt: Date

    /// The date the event resolves (game day / last leg date for multi-day parlay)
    /// Store as a Date, but treat it as "day-level" in filtering.
    var eventDate: Date

    /// When you recorded the result (WIN/LOSS/PUSH/CASHOUT). Nil means pending.
    var settledAt: Date?

    var sport: String
    var wagerText: String

    var betAmount: Double
    var payoutAmount: Double

    /// Keeps the original payout so Reset can restore after Cash Out edits payoutAmount
    var originalPayoutAmount: Double

    /// nil = pending, >0 win, <0 loss, 0 push
    var net: Double?

    init(
        createdAt: Date = Date(),
        eventDate: Date = Date(),
        settledAt: Date? = nil,
        sport: String,
        wagerText: String,
        betAmount: Double,
        payoutAmount: Double,
        originalPayoutAmount: Double? = nil,
        net: Double? = nil
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.eventDate = eventDate
        self.settledAt = settledAt
        self.sport = sport
        self.wagerText = wagerText
        self.betAmount = betAmount
        self.payoutAmount = payoutAmount
        self.originalPayoutAmount = originalPayoutAmount ?? payoutAmount
        self.net = net
    }
}

