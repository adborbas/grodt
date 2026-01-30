import Vapor
import Fluent

protocol BrokerageAccountRepository {
    func all(for userID: User.IDValue) async throws -> [BrokerageAccount]
    func find(_ id: BrokerageAccount.IDValue, for userID: User.IDValue) async throws -> BrokerageAccount?
    func create(_ account: BrokerageAccount) async throws
    func update(_ account: BrokerageAccount) async throws
    func delete(_ account: BrokerageAccount) async throws
    func performance(for accountID: BrokerageAccount.IDValue) async throws -> PerformanceDTO
}

class PostgresBrokerageAccountRepository: BrokerageAccountRepository {
    private let database: Database
    private let transactionsRepository: TransactionsRepository

    init(database: Database, transactionsRepository: TransactionsRepository) {
        self.database = database
        self.transactionsRepository = transactionsRepository
    }
    
    func all(for userID: User.IDValue) async throws -> [BrokerageAccount] {
        let query = BrokerageAccount.query(on: database)
            .join(Brokerage.self, on: \BrokerageAccount.$brokerage.$id == \Brokerage.$id)
            .filter(Brokerage.self, \.$user.$id == userID)
            .with(\.$brokerage)
        return try await query.all()
    }
    
    func find(_ id: BrokerageAccount.IDValue, for userID: User.IDValue) async throws -> BrokerageAccount? {
        try await BrokerageAccount.query(on: database)
            .filter(\.$id == id)
            .join(Brokerage.self, on: \BrokerageAccount.$brokerage.$id == \Brokerage.$id)
            .filter(Brokerage.self, \.$user.$id == userID)
            .with(\.$brokerage)
            .first()
    }
    
    func create(_ account: BrokerageAccount) async throws { try await account.save(on: database) }
    func update(_ account: BrokerageAccount) async throws { try await account.update(on: database) }
    
    func delete(_ account: BrokerageAccount) async throws {
        let hasTransactions = try await transactionsRepository.hasTransactions(for: account.requireID())
        guard !hasTransactions else { throw Abort(.conflict, reason: "BrokerageAccount has transactions.") }
        try await account.delete(on: database)
    }
    
    func performance(for accountID: BrokerageAccount.IDValue) async throws -> PerformanceDTO {
        guard let last = try await HistoricalBrokerageAccountPerformanceDaily.query(on: database)
            .filter(\.$account.$id == accountID)
            .sort(\.$date, .descending)
            .first()
        else { return PerformanceDTO.zero }

        let moneyIn = last.moneyIn
        let moneyOut = last.value
        let profit = moneyOut - moneyIn
        let totalReturn: Decimal = moneyIn > 0 ? (profit / moneyIn).rounded(to: 2) : 0

        return PerformanceDTO(moneyIn: moneyIn,
                              moneyOut: moneyOut,
                              profit: profit,
                              totalReturn: totalReturn)
    }
}
