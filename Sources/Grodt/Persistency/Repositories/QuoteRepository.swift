import Foundation
import Fluent

protocol QuoteRepository {
    func quote(for ticker: String) async throws -> Quote?
    
    func create(_ quote: Quote) async throws
    
    func update(_ quote: Quote) async throws
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
}
