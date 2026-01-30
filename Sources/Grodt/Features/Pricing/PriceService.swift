import Foundation

protocol PriceService {
    func price(for ticker: String) async throws -> Decimal
    func historicalPrice(for ticker: String) async throws -> [DatedQuote]
}
