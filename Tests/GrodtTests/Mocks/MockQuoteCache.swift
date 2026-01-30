@testable import Grodt
import Foundation

final class MockQuoteCache: QuoteCache, @unchecked Sendable {
    var quoteResult: Result<Quote?, Error> = .success(nil)
    var storeQuoteResult: Result<Void, Error> = .success(())
    var clearQuoteResult: Result<Void, Error> = .success(())
    var historicalQuoteResult: Result<HistoricalQuote?, Error> = .success(nil)
    var storeHistoricalQuoteResult: Result<Void, Error> = .success(())
    var clearHistoricalQuoteResult: Result<Void, Error> = .success(())

    private(set) var quoteCalledWith: String?
    private(set) var storeQuoteCalled = false
    private(set) var storedQuote: Quote?
    private(set) var storedHistoricalQuote: HistoricalQuote?

    func quote(for ticker: String) async throws -> Quote? {
        quoteCalledWith = ticker
        return try quoteResult.get()
    }

    func storeQuote(_ quote: Quote) async throws {
        storeQuoteCalled = true
        storedQuote = quote
        try storeQuoteResult.get()
    }

    func clearQuote(for ticker: String) async throws {
        try clearQuoteResult.get()
    }

    func historicalQuote(for ticker: String) async throws -> HistoricalQuote? {
        try historicalQuoteResult.get()
    }

    func storeHistoricalQuote(_ quote: HistoricalQuote) async throws {
        storedHistoricalQuote = quote
        try storeHistoricalQuoteResult.get()
    }

    func clearHistoricalQuote(for ticker: String) async throws {
        try clearHistoricalQuoteResult.get()
    }
}
