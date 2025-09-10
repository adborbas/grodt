import Vapor
import Fluent

protocol BrokerageRepository: Sendable {
    func list(for userID: User.IDValue, on db: Database) async throws -> [Brokerage]
    func find(_ id: Brokerage.IDValue, for userID: User.IDValue, on db: Database) async throws -> Brokerage?
    func create(_ brokerage: Brokerage, on db: Database) async throws
    func update(_ brokerage: Brokerage, on db: Database) async throws
    func delete(_ brokerage: Brokerage, on db: Database) async throws
    func accountsCount(for brokerageID: Brokerage.IDValue, on db: Database) async throws -> Int
    func totals(for brokerageID: Brokerage.IDValue, on db: Database) async throws -> PerformanceTotalsDTO?
}

struct PostgresBrokerageRepository: BrokerageRepository {
    func list(for userID: User.IDValue, on db: Database) async throws -> [Brokerage] {
        try await Brokerage.query(on: db).filter(\.$user.$id == userID).all()
    }
    
    func find(_ id: Brokerage.IDValue, for userID: User.IDValue, on db: Database) async throws -> Brokerage? {
        try await Brokerage.query(on: db)
            .filter(\.$id == id)
            .filter(\.$user.$id == userID)
            .with(\.$accounts)
            .first()
    }
    
    func create(_ brokerage: Brokerage, on db: Database) async throws {
        try await brokerage.save(on: db)
    }
    
    func update(_ brokerage: Brokerage, on db: Database) async throws {
        try await brokerage.update(on: db)
    }
    
    func delete(_ brokerage: Brokerage, on db: Database) async throws {
        let accounts = try await BrokerageAccount.query(on: db).filter(\.$brokerage.$id == brokerage.requireID()).count()
        guard accounts == 0 else { throw Abort(.conflict, reason: "Brokerage has accounts.") }
        try await brokerage.delete(on: db)
    }
    
    func accountsCount(for brokerageID: Brokerage.IDValue, on db: Database) async throws -> Int {
        try await BrokerageAccount.query(on: db).filter(\.$brokerage.$id == brokerageID).count()
    }
    
    func totals(for brokerageID: Brokerage.IDValue, on db: Database) async throws -> PerformanceTotalsDTO? {
        guard let last = try await HistoricalBrokeragePerformanceDaily.query(on: db)
            .filter(\.$brokerage.$id == brokerageID)
            .sort(\.$date, .descending)
            .first()
        else { return nil }
        return .init(value: last.value, moneyIn: last.moneyIn)
    }
}
