import Foundation
import Fluent

class Transaction: Model {
    static let schema = "transactions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: Keys.portfolioID)
    var portfolio: Portfolio
    
    @Field(key: Keys.platform)
    var platform: String
    
    @OptionalField(key: Keys.account)
    var account: String?
    
    @Field(key: Keys.purchaseDate)
    var purchaseDate: Date
    
    @Field(key: Keys.ticker)
    var ticker: String
    
    @Field(key: Keys.currency)
    var currency: Currency
    
    @Field(key: Keys.fees)
    var fees: Decimal
    
    @Field(key: Keys.numberOfShares)
    var numberOfShares: Decimal
    
    @Field(key: Keys.pricePerShareAtPurchase)
    var pricePerShareAtPurchase: Decimal
    
    var totalCost: Decimal {
        return pricePerShareAtPurchase * numberOfShares + fees
    }
    
    required init() { }
    
    init(id: UUID? = nil,
         portfolioID: Portfolio.IDValue,
         platform: String,
         account: String?,
         purchaseDate: Date,
         ticker: String,
         currency: Currency,
         fees: Decimal,
         numberOfShares: Decimal,
         pricePerShareAtPurchase: Decimal) {
        self.id = id
        self.$portfolio.id = portfolioID
        self.platform = platform
        self.account = account
        self.purchaseDate = purchaseDate
        self.ticker = ticker
        self.currency = currency
        self.fees = fees
        self.numberOfShares = numberOfShares
        self.pricePerShareAtPurchase = pricePerShareAtPurchase
    }
}

fileprivate extension Transaction {
    enum Keys {
        static let portfolioID: FieldKey = "portfolio_id"
        static let platform: FieldKey = "platform"
        static let account: FieldKey = "account"
        static let purchaseDate: FieldKey = "purchase_date"
        static let ticker: FieldKey = "ticker"
        static let currency: FieldKey = "currency"
        static let fees: FieldKey = "fees"
        static let numberOfShares: FieldKey = "number_of_shares"
        static let pricePerShareAtPurchase: FieldKey = "price_per_share_at_purchase"
    }
}

extension Transaction {
    struct Migration: AsyncMigration {
        let name: String = "CreateTransaction"
        
        func prepare(on database: Database) async throws {
            try await database.schema(Transaction.schema)
                .id()
                .field(Keys.portfolioID, .uuid, .required, .references(Portfolio.schema, "id"))
                .field(Keys.platform, .string, .required)
                .field(Keys.account, .string)
                .field(Keys.purchaseDate, .datetime, .required)
                .field(Keys.ticker, .string, .required)
                .field(Keys.currency, .dictionary, .required)
                .field(Keys.fees, .sql(raw: "NUMERIC(7,2)"), .required)
                .field(Keys.numberOfShares, .sql(raw: "NUMERIC(64,6)"), .required)
                .field(Keys.pricePerShareAtPurchase, .sql(raw: "NUMERIC(64,4)"), .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Transaction.schema).delete()
        }
    }
}

