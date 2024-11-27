import Fluent
import Vapor

final class Portfolio: Model, @unchecked Sendable {
    static let schema = "portfolios"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: Keys.userID)
    var user: User
    
    @Field(key: Keys.name)
    var name: String
    
    @Field(key: Keys.currency)
    var currency: Currency
    
    @Children(for: \.$portfolio)
    var transactions: [Transaction]
    
    @OptionalChild(for: \.$portfolio)
    var historicalPerformance: HistoricalPortfolioPerformance?
    
    required init() { }
    
    init(id: UUID? = nil,
         userID: User.IDValue,
         name: String,
         currency: Currency) {
        self.id = id
        self.$user.id = userID
        self.name = name
        self.currency = currency
    }
}

extension Portfolio {
    var earliestTransaction: Transaction? {
        return transactions.sorted { $0.purchaseDate < $1.purchaseDate }.first
    }
}

fileprivate extension Portfolio {
    enum Keys {
        static let userID: FieldKey = "user_id"
        static let name: FieldKey = "name"
        static let currency: FieldKey = "currency"
    }
}

extension Portfolio {
    struct Migration: AsyncMigration {
        var name: String { "CreatePortfolio" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(Portfolio.schema)
                .id()
                .field(Keys.userID, .uuid, .required, .references(User.schema, "id"))
                .field(Keys.name, .string, .required)
                .field(Keys.currency, .dictionary, .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Portfolio.schema).delete()
        }
    }
}
