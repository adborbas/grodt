import Fluent

protocol TickerRepository {
    func allTickers() async throws -> [Ticker]
    func tickers(for symbol: String) async throws -> Ticker?
    func save(_ ticker: Ticker) async throws
}

class PostgresTickerRepository: TickerRepository {
    private let database: Database
    
    init(database: Database) {
        self.database = database
    }
    
    func allTickers() async throws -> [Ticker] {
        return try await Ticker.query(on: database)
            .all()
    }
    
    func tickers(for symbol: String) async throws -> Ticker? {
        return try await Ticker.query(on: database)
            .filter(\Ticker.$symbol == symbol)
            .first()
    }
    
    func save(_ ticker: Ticker) async throws {
        try await ticker.save(on: database)
    }
}
