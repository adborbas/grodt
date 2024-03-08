import Fluent

protocol TickerRepository {
    func allTickers() async throws -> [Ticker]
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
}
