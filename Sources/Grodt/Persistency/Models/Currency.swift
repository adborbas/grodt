import Foundation
import Fluent

class Currency: Model, @unchecked Sendable {
    static let schema = Keys.schema
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: Keys.code)
    var code: String
    
    @Field(key: Keys.symbol)
    var symbol: String
    
    required init() { }
    
    init(id: UUID? = nil, code: String, symbol: String) {
        self.id = id
        self.code = code
        self.symbol = symbol
    }
}

fileprivate extension Currency {
    enum Keys {
        static let schema = "currencies"
        
        static let code: FieldKey = "code"
        static let symbol: FieldKey = "symbol"
    }
}

extension Currency {
    struct Migration: AsyncMigration {
        var name: String { "CreateCurrency" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(Currency.schema)
                .id()
                .field(Currency.Keys.code, .string, .required)
                .field(Currency.Keys.symbol, .string, .required)
                .create()
            
            try await Currency(code: "EUR", symbol: "€").save(on: database)
            try await Currency(code: "USD", symbol: "$").save(on: database)
            try await Currency(code: "HUF", symbol: "Ft").save(on: database)
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Currency.schema).delete()
        }
    }

}
