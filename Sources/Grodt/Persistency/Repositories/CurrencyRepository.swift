import Foundation
import Fluent

protocol CurrencyRepository {
    func currencies() async throws -> [Currency]
    
    func currency(for code: String) async throws -> Currency?
}

class PostgresCurrencyRepository: CurrencyRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func currencies() async throws -> [Currency] {
        return try await Currency.query(on: database)
            .all()
    }
    
    func currency(for code: String) async throws -> Currency? {
        return try await Currency.query(on: database)
            .filter(\Currency.$code == code)
            .first()
    }
}
