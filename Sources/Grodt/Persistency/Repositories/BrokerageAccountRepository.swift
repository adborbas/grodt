import Vapor
import Fluent

protocol BrokerageAccountRepository: Sendable {
    func list(for userID: User.IDValue, brokerageID: Brokerage.IDValue?, on db: Database) async throws -> [BrokerageAccount]
    func find(_ id: BrokerageAccount.IDValue, for userID: User.IDValue, on db: Database) async throws -> BrokerageAccount?
    func create(_ account: BrokerageAccount, on db: Database) async throws
    func update(_ account: BrokerageAccount, on db: Database) async throws
    func delete(_ account: BrokerageAccount, on db: Database) async throws
    func totals(for accountID: BrokerageAccount.IDValue, on db: Database) async throws -> PerformanceTotalsDTO?
}

struct PostgresBrokerageAccountRepository: BrokerageAccountRepository {
    func list(for userID: User.IDValue, brokerageID: Brokerage.IDValue?, on db: Database) async throws -> [BrokerageAccount] {
        var query = BrokerageAccount.query(on: db)
            .join(Brokerage.self, on: \BrokerageAccount.$brokerage.$id == \Brokerage.$id)
            .filter(Brokerage.self, \.$user.$id == userID)
        if let brokerageID {
            query = query.filter(\.$brokerage.$id == brokerageID)
        }
        return try await query.all()
    }
    
    func find(_ id: BrokerageAccount.IDValue, for userID: User.IDValue, on db: Database) async throws -> BrokerageAccount? {
        try await BrokerageAccount.query(on: db)
            .filter(\.$id == id)
            .join(Brokerage.self, on: \BrokerageAccount.$brokerage.$id == \Brokerage.$id)
            .filter(Brokerage.self, \.$user.$id == userID)
            .with(\.$brokerage)
            .first()
    }
    
    func create(_ account: BrokerageAccount, on db: Database) async throws { try await account.save(on: db) }
    func update(_ account: BrokerageAccount, on db: Database) async throws { try await account.update(on: db) }
    
    func delete(_ account: BrokerageAccount, on db: Database) async throws {
        let count = try await Transaction.query(on: db).filter(\.$brokerageAccount.$id == account.requireID()).count()
        guard count == 0 else { throw Abort(.conflict, reason: "BrokerageAccount has transactions.") }
        try await account.delete(on: db)
    }
    
    func totals(for accountID: BrokerageAccount.IDValue, on db: Database) async throws -> PerformanceTotalsDTO? {
        guard let last = try await HistoricalBrokerageAccountPerformance.query(on: db)
            .filter(\.$account.$id == accountID)
            .sort(\.$date, .descending)
            .first()
        else { return nil }
        return .init(value: last.value, moneyIn: last.moneyIn)
    }
}
