//
//  BetService.swift
//  BetTracker
//

import Foundation
import Combine

class BetService: ObservableObject {

    @Published var todayBets:    [Bet] = []
    @Published var upcomingBets: [Bet] = []
    @Published var settledBets:  [Bet] = []

    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    // MARK: - Fetch

    func fetchToday() async {
        await fetch(scope: "today") { [weak self] bets in
            self?.todayBets = bets
        }
    }

    func fetchUpcoming() async {
        await fetch(scope: "upcoming") { [weak self] bets in
            self?.upcomingBets = bets
        }
    }

    func fetchSettled() async {
        await fetch(scope: "settled") { [weak self] bets in
            self?.settledBets = bets
        }
    }

    private func fetch(scope: String, assign: @escaping ([Bet]) -> Void) async {
        await MainActor.run { isLoading = true; errorMessage = nil }
        defer { Task { await MainActor.run { self.isLoading = false } } }

        guard var components = URLComponents(string: APIConfig.baseURL) else { return }
        components.queryItems = [URLQueryItem(name: "scope", value: scope)]
        guard let url = components.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(for: request(url))
            let bets = try JSONDecoder().decode([Bet].self, from: data)
            await MainActor.run { assign(bets) }
        } catch {
            await MainActor.run { self.errorMessage = error.localizedDescription }
        }
    }

    // MARK: - Create

    func createBet(
        sport: String,
        wagerText: String,
        isProp: Bool,
        isParlay: Bool,
        eventDate: String,
        betAmount: Double,
        payoutAmount: Double
    ) async throws {
        let body: [String: Any] = [
            "sport":         sport,
            "wager_text":    wagerText,
            "is_prop":       isProp ? 1 : 0,
            "is_parlay":     isParlay ? 1 : 0,
            "event_date":    eventDate,
            "bet_amount":    betAmount,
            "payout_amount": payoutAmount
        ]
        try await mutate(method: "POST", id: nil, body: body)
        await fetchToday()
    }

    // MARK: - Settle

    func settle(id: Int, action: String, cashoutAmount: Double? = nil) async throws {
        var body: [String: Any] = ["action": action]
        if let amount = cashoutAmount { body["amount"] = amount }
        try await mutate(method: "PUT", id: id, body: body)
        await fetchToday()
        await fetchSettled()
    }

    // MARK: - Delete

    func delete(id: Int) async throws {
        try await mutate(method: "DELETE", id: id, body: nil)
        await fetchToday()
        await fetchSettled()
        await fetchUpcoming()
    }

    // MARK: - Shared mutate

    private func mutate(method: String, id: Int?, body: [String: Any]?) async throws {
        var urlString = APIConfig.baseURL
        if let id { urlString += "?id=\(id)" }
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }

        var req = request(url)
        req.httpMethod = method
        if let body {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Server error"
            throw NSError(domain: "BetService", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }

    // MARK: - Request helper

    private func request(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue(APIConfig.apiKey, forHTTPHeaderField: "X-API-Key")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 15
        return req
    }
}
