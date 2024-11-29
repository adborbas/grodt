import Foundation
import Fluent

protocol QuoteRepository {
    func quote(for ticker: String) async throws -> Quote?
    
    func create(_ quote: Quote) async throws
    
    func update(_ quote: Quote) async throws
    
    func allHistoricalQuote() async throws -> [HistoricalQuote]
    
    func historicalQuote(for ticker: String) async throws -> HistoricalQuote?
    
    func create(_ historicalQuote: HistoricalQuote) async throws
    
    func delete(_ historicalQuote: HistoricalQuote) async throws
    
    func update(_ historicalQuote: HistoricalQuote) async throws
}

class PostgresQuoteRepository: QuoteRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func quote(for ticker: String) async throws -> Quote? {
        return try await Quote.query(on: database)
            .filter(\Quote.$symbol == ticker)
            .first()
    }
    
    func create(_ quote: Quote) async throws {
        try await quote.save(on: database)
    }
    
    func update(_ quote: Quote) async throws {
        try await quote.update(on: database)
    }
    
    func allHistoricalQuote() async throws -> [HistoricalQuote] {
        return try await HistoricalQuote.query(on: database)
            .all()
    }
    
    func historicalQuote(for ticker: String) async throws -> HistoricalQuote? {
        return try await HistoricalQuote.query(on: database)
            .filter(\HistoricalQuote.$symbol == ticker)
            .first()
    }
    
    func create(_ historicalQuote: HistoricalQuote) async throws {
        try await historicalQuote.save(on: database)
    }
    
    func update(_ historicalQuote: HistoricalQuote) async throws {
        try await historicalQuote.update(on: database)
    }
    
    func delete(_ historicalQuote: HistoricalQuote) async throws {
        try await historicalQuote.delete(on: database)
    }
}
