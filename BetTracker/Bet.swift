// Bet.swift
// BetTracker
//
// Updated: added parlaySize (1=straight, 2-10=parlay legs) and isProp flag

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

    var parlaySize: Int = 1       // 1 = straight bet, 2-10 = number of legs
    var isProp: Bool = false      // true if any prop involved

    var betAmount: Double = 0
    var payoutAmount: Double = 0
    var originalPayoutAmount: Double = 0

    var net: Double? = nil        // nil = pending, positive = won, negative = lost, 0 = push

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        eventDate: Date = Date(),
        settledAt: Date? = nil,
        sport: String = "",
        wagerText: String = "",
        parlaySize: Int = 1,
        isProp: Bool = false,
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
        self.parlaySize = parlaySize
        self.isProp = isProp
        self.betAmount = betAmount
        self.payoutAmount = payoutAmount
        self.originalPayoutAmount = originalPayoutAmount
        self.net = net
    }
}
