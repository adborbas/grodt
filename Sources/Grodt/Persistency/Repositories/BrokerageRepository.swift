import Vapor
import Fluent

protocol BrokerageRepository: Sendable {
    func list(for userID: User.IDValue) async throws -> [Brokerage]
    func find(_ id: Brokerage.IDValue, for userID: User.IDValue) async throws -> Brokerage?
    func create(_ brokerage: Brokerage) async throws
    func update(_ brokerage: Brokerage) async throws
    func delete(_ brokerage: Brokerage) async throws
    func accountsCount(for brokerageID: Brokerage.IDValue) async throws -> Int
    func performance(for brokerageID: Brokerage.IDValue) async throws -> PerformanceDTO
}

struct PostgresBrokerageRepository: BrokerageRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func list(for userID: User.IDValue) async throws -> [Brokerage] {
        try await Brokerage.query(on: database)
            .filter(\.$user.$id == userID)
            .with(\.$accounts)
            .all()
    }
    
    func find(_ id: Brokerage.IDValue, for userID: User.IDValue) async throws -> Brokerage? {
        try await Brokerage.query(on: database)
            .filter(\.$id == id)
            .filter(\.$user.$id == userID)
            .with(\.$accounts)
            .first()
    }
    
    func create(_ brokerage: Brokerage) async throws {
        try await brokerage.save(on: database)
    }
    
    func update(_ brokerage: Brokerage) async throws {
        try await brokerage.update(on: database)
    }
    
    func delete(_ brokerage: Brokerage) async throws {
        let accounts = try await BrokerageAccount.query(on: database).filter(\.$brokerage.$id == brokerage.requireID()).count()
        guard accounts == 0 else { throw Abort(.conflict, reason: "Brokerage has accounts.") }
        try await brokerage.delete(on: database)
    }
    
    func accountsCount(for brokerageID: Brokerage.IDValue) async throws -> Int {
        try await BrokerageAccount.query(on: database).filter(\.$brokerage.$id == brokerageID).count()
    }
    
    func performance(for brokerageID: Brokerage.IDValue) async throws -> PerformanceDTO {
        guard let last = try await HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == brokerageID)
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
