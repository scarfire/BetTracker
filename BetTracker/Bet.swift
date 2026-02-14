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

    var status: String   // PENDING, WIN, LOSS, PUSH, CASHOUT
    var net: Double?

    init(
        createdAt: Date = Date(),
        sport: String,
        wagerText: String,
        betAmount: Double,
        payoutAmount: Double,
        status: String = "PENDING",
        net: Double? = nil
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.sport = sport
        self.wagerText = wagerText
        self.betAmount = betAmount
        self.payoutAmount = payoutAmount
        self.status = status
        self.net = net
    }
}
