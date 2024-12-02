import Foundation
import Fluent

class PostgresQuoteRepository: QuoteCache {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func quote(for ticker: String) async throws -> Quote? {
        return try await Quote.query(on: database)
            .filter(\Quote.$symbol == ticker)
            .first()
    }
    
    func storeQuote(_ quote: Quote) async throws {
        if quote.$id.exists {
            try await quote.update(on: database)
        } else {
            try await quote.create(on: database)
        }
    }
    
    func clearQuote(for ticker: String) async throws {
        try await quote(for: ticker)?.delete(on: database)
    }
    
    
    func historicalQuote(for ticker: String) async throws -> HistoricalQuote? {
        return try await HistoricalQuote.query(on: database)
            .filter(\HistoricalQuote.$symbol == ticker)
            .first()
    }
    
    func storeHistoricalQuote(_ quote: HistoricalQuote) async throws {
        if quote.$id.exists {
            try await quote.update(on: database)
        } else {
            try await quote.create(on: database)
        }
    }
    
    func clearHistoricalQuote(for ticker: String) async throws {
        try await historicalQuote(for: ticker)?.delete(on: database)
    }
}
