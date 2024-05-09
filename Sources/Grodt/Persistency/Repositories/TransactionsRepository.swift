import Fluent
import Foundation

protocol TransactionsRepository {
    func transaction(for id: UUID) async throws -> Transaction?
}

class PostgresTransactionRepository: TransactionsRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }

    func transaction(for id: UUID) async throws -> Transaction? {
        return try await Transaction.query(on: database)
            .filter(\Transaction.$id == id)
            .first()
    }
}
