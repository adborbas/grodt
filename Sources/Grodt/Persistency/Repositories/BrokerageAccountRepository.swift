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
    
    init(database: Database) {
        self.database = database
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
        let count = try await Transaction.query(on: database).filter(\.$brokerageAccount.$id == account.requireID()).count()
        guard count == 0 else { throw Abort(.conflict, reason: "BrokerageAccount has transactions.") }
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
