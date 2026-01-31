import Fluent
import Foundation

protocol TransactionsRepository {
    func transaction(for id: UUID) async throws -> Transaction?
    func all(for userID: User.IDValue) async throws -> [Transaction]
    func transactionsForUser(_ userID: User.IDValue, ticker: String) async throws -> [Transaction]
    func transactionsForPortfolio(_ portfolioID: Portfolio.IDValue, ticker: String) async throws -> [Transaction]
    func transactions(for accountID: BrokerageAccount.IDValue) async throws -> [Transaction]
    func hasTransactions(for accountID: BrokerageAccount.IDValue) async throws -> Bool
    func save(_ transaction: Transaction) async throws
    func delete(_ transaction: Transaction) async throws
    func update(_ transaction: Transaction) async throws
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
            .sort(\.$transactionDate, .descending)
            .all()
    }

    func transactionsForUser(_ userID: User.IDValue, ticker: String) async throws -> [Transaction] {
        return try await Transaction.query(on: database)
            .join(parent: \Transaction.$portfolio)
            .filter(Portfolio.self, \.$user.$id == userID)
            .filter(\.$ticker == ticker)
            .with(\.$portfolio)
            .with(\.$brokerageAccount)
            .sort(\.$transactionDate, .descending)
            .all()
    }

    func transactionsForPortfolio(_ portfolioID: Portfolio.IDValue, ticker: String) async throws -> [Transaction] {
        return try await Transaction.query(on: database)
            .filter(\.$portfolio.$id == portfolioID)
            .filter(\.$ticker == ticker)
            .sort(\.$transactionDate, .ascending)
            .all()
    }

    func transactions(for accountID: BrokerageAccount.IDValue) async throws -> [Transaction] {
        try await Transaction.query(on: database)
            .filter(\.$brokerageAccount.$id == accountID)
            .all()
    }

    func hasTransactions(for accountID: BrokerageAccount.IDValue) async throws -> Bool {
        let count = try await Transaction.query(on: database)
            .filter(\.$brokerageAccount.$id == accountID)
            .count()
        return count > 0
    }

    func save(_ transaction: Transaction) async throws {
        _ = try await transaction.save(on: database)
    }

    func delete(_ transaction: Transaction) async throws {
        try await transaction.delete(on: database)
    }

    func update(_ transaction: Transaction) async throws {
        try await transaction.update(on: database)
    }
}
