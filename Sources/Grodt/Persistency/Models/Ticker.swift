import Foundation
import Fluent

class Ticker: Model, @unchecked Sendable {
    static let schema = Keys.schema
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: Keys.symbol)
    var symbol: String
    
    @Field(key: Keys.region)
    var region: String
    
    @Field(key: Keys.name)
    var name: String
    
    @Field(key: Keys.currency)
    var currency: String
    
    required init() { }
    
    init(id: UUID? = nil, symbol: String, region: String, name: String, currency: String) {
        self.id = id
        self.symbol = symbol
        self.region = region
        self.name = name
        self.currency = currency
    }
}

fileprivate extension Ticker {
    enum Keys {
        static let schema = "tickers"
        
        
        static let symbol: FieldKey = "symbol"
        static let region: FieldKey = "region"
        static let name: FieldKey = "name"
        static let currency: FieldKey = "currency"
    }
}

extension Ticker {
    struct Migration: AsyncMigration {
        let name = "CreateTicker"
        
        func prepare(on database: Database) async throws {
            try await database.schema(Ticker.schema)
                .id()
                .field(Keys.symbol, .string, .required)
                .field(Keys.region, .string, .required)
                .field(Keys.name, .string, .required)
                .field(Keys.currency, .string, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Ticker.schema).delete()
        }
    }
}
