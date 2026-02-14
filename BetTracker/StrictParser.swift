//
//  StrictParser.swift
//  BetTracker
//
//  Created by Todd Stevens on 2/14/26.
//


import Foundation

struct StrictParser {
    struct Parsed {
        let bet: Double
        let payout: Double
        let wager: String
    }

    static func parse(_ text: String) -> Parsed? {
        let pattern = #"(?i)\bbet\s*\$?([0-9]+(?:\.[0-9]+)?)\s*to\s*win\s*\$?([0-9]+(?:\.[0-9]+)?)\b"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)

        guard let match = regex.firstMatch(in: text, range: range),
              let betRange = Range(match.range(at: 1), in: text),
              let payoutRange = Range(match.range(at: 2), in: text)
        else { return nil }

        let bet = Double(text[betRange]) ?? 0
        let payout = Double(text[payoutRange]) ?? 0

        if bet <= 0 || payout <= 0 { return nil }

        let cleaned = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
            .trimmingCharacters(in: .whitespaces)

        return Parsed(bet: bet, payout: payout, wager: cleaned.isEmpty ? "Bet" : cleaned)
    }
}
