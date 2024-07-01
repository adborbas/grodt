import Foundation
import Fluent

final class Quote: Model {
    static let schema = Keys.schema
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: Keys.symbol)
    var symbol: String
    
    @Field(key: Keys.price)
    var price: Decimal
    
    @Field(key: Keys.lastUpdate)
    var lastUpdate: Date
    
    required init() { }
    
    init(id: UUID? = nil, symbol: String, price: Decimal, lastUpdate: Date) {
        self.id = id
        self.symbol = symbol
        self.price = price
        self.lastUpdate = lastUpdate
    }
}

fileprivate extension Quote {
    enum Keys {
        static let schema = "quotes"
        
        static let symbol: FieldKey = "symbol"
        static let price: FieldKey = "price"
        static let lastUpdate: FieldKey = "lastUpdate"
        static let date: FieldKey = "date"
    }
}

extension Quote {
    struct Migration: AsyncMigration {
        var name: String { "CreateQuote" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(Quote.schema)
                .id()
                .field(Quote.Keys.symbol, .string, .required)
                .field(Quote.Keys.price, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Quote.Keys.lastUpdate, .datetime, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Quote.schema).delete()
        }
    }

}
