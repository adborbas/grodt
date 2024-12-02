import Foundation

protocol QuoteCache {
    func quote(for ticker: String) async throws -> Quote?
    func storeQuote(_ quote: Quote) async throws
    func clearQuote(for ticker: String) async throws
    
    func historicalQuote(for ticker: String) async throws -> HistoricalQuote?
    func storeHistoricalQuote(_ quote: HistoricalQuote) async throws
    func clearHistoricalQuote(for ticker: String) async throws
}
