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
    var createdAt: Date

    var sport: String
    var wagerText: String

    var betAmount: Double
    var payoutAmount: Double

    // NEW: keeps the original payout so Reset can restore after Cash Out edits payoutAmount
    var originalPayoutAmount: Double

    var net: Double?

    init(
        createdAt: Date = Date(),
        sport: String,
        wagerText: String,
        betAmount: Double,
        payoutAmount: Double,
        originalPayoutAmount: Double? = nil,
        net: Double? = nil
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.sport = sport
        self.wagerText = wagerText
        self.betAmount = betAmount
        self.payoutAmount = payoutAmount
        self.originalPayoutAmount = originalPayoutAmount ?? payoutAmount
        self.net = net
    }
}
