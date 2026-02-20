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

    var id: UUID = UUID()
    var createdAt: Date = Date()
    var eventDate: Date = Date()
    var settledAt: Date? = nil

    var sport: String = ""
    var wagerText: String = ""

    var betAmount: Double = 0
    var payoutAmount: Double = 0
    var originalPayoutAmount: Double = 0

    var net: Double? = nil  // nil = pending

    // Keep your custom init if you want, but it's no longer required for CloudKit
    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        eventDate: Date = Date(),
        settledAt: Date? = nil,
        sport: String = "",
        wagerText: String = "",
        betAmount: Double = 0,
        payoutAmount: Double = 0,
        originalPayoutAmount: Double = 0,
        net: Double? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.eventDate = eventDate
        self.settledAt = settledAt
        self.sport = sport
        self.wagerText = wagerText
        self.betAmount = betAmount
        self.payoutAmount = payoutAmount
        self.originalPayoutAmount = originalPayoutAmount
        self.net = net
    }
}

