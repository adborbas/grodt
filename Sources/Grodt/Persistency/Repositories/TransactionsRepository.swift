import Fluent
import Foundation

protocol TransactionsRepository {
    func transaction(for id: UUID) async throws -> Transaction?
    func all(for userID: User.IDValue) async throws -> [Transaction]
    func save(_ transaction: Transaction) async throws
}

class PostgresTransactionRepository: TransactionsRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }

    func transaction(for id: UUID) async throws -> Transaction? {
        return try await Transaction.query(on: database)
            .filter(\Transaction.$id == id)
            .with(\.$portfolio)
            .first()
    }
    
    func all(for userID: User.IDValue) async throws -> [Transaction] {
        return try await Transaction.query(on: database)
            .join(parent: \Transaction.$portfolio)
            .filter(Portfolio.self, \.$user.$id == userID)
            .with(\.$portfolio)
            .with(\.$brokerageAccount)
            .sort(\.$purchaseDate, .descending)
            .all()
    }
    
    func save(_ transaction: Transaction) async throws {
        _ = try await transaction.save(on: database)
    }
}
