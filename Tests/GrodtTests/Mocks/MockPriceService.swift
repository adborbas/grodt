@testable import Grodt
import Foundation

final class MockPriceService: PriceService {
    var pricesByTicker: [String: [DatedQuote]] = [:]
    private(set) var historicalPriceCallCount: [String: Int] = [:]
    private(set) var spotPriceCallCount: [String: Int] = [:]

    func price(for ticker: String) async throws -> Decimal {
        spotPriceCallCount[ticker, default: 0] += 1
        return pricesByTicker[ticker]?.last?.price ?? 0
    }

    func historicalPrice(for ticker: String) async throws -> [DatedQuote] {
        historicalPriceCallCount[ticker, default: 0] += 1
        return pricesByTicker[ticker] ?? []
    }
}
