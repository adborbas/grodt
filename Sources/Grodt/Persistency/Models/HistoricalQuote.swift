import Foundation
import Fluent

final class HistoricalQuote: Model, @unchecked Sendable {
    static let schema = Keys.schema
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: Keys.symbol)
    var symbol: String
    
    @Field(key: Keys.datedQuotes)
    var datedQuotes: [DatedQuote]
    
    required init() { }
    
    init(id: UUID? = nil, symbol: String, datedQuotes: [DatedQuote]) {
        self.id = id
        self.symbol = symbol
        self.datedQuotes = datedQuotes
    }
}

fileprivate extension HistoricalQuote {
    enum Keys {
        static let schema = "historical_quotes"
        
        static let symbol: FieldKey = "symbol"
        static let datedQuotes: FieldKey = "dated_quotes"
    }
}

extension HistoricalQuote {
    struct Migration: AsyncMigration {
        var name: String { "CreateHistoricalQuote" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(HistoricalQuote.schema)
                .id()
                .field(HistoricalQuote.Keys.symbol, .string, .required)
                .field(Keys.datedQuotes, .array(of: .json), .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Quote.schema).delete()
        }
    }

}
