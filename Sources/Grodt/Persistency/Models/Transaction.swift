import Foundation
import Fluent
import FluentSQL

class Transaction: Model, @unchecked Sendable {
    static let schema = "transactions"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: Keys.portfolioID)
    var portfolio: Portfolio
    
    @OptionalParent(key: Keys.brokerageAccountID)
    var brokerageAccount: BrokerageAccount?
    
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
         brokerageAccountID: BrokerageAccount.IDValue?,
         purchaseDate: Date,
         ticker: String,
         currency: Currency,
         fees: Decimal,
         numberOfShares: Decimal,
         pricePerShareAtPurchase: Decimal)
    {
        self.id = id
        self.$portfolio.id = portfolioID
        self.$brokerageAccount.id = brokerageAccountID
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
        static let brokerageAccountID: FieldKey = "brokerage_account_id"
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
        var name: String { "CreateTransaction" }

        func prepare(on db: Database) async throws {
            try await db.schema(Transaction.schema)
                .id()
                .field(Keys.portfolioID, .uuid, .required, .references(Portfolio.schema, "id", onDelete: .cascade))
                // brokerage_account_id will be added (optionally) by a later migration
                .field(Keys.purchaseDate, .date, .required)
                .field(Keys.ticker, .string, .required)
                .field(Keys.currency, .string, .required)
                .field(Keys.fees, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.numberOfShares, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.pricePerShareAtPurchase, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Transaction.schema).delete()
        }
    }
    
    struct Migration_AddBrokerageAccountID: AsyncMigration {
        let name = "AddBrokerageAccountIDToTransactions"

        func prepare(on db: Database) async throws {
            try await db.schema(Transaction.schema)
                .field(Keys.brokerageAccountID, .uuid, .references(BrokerageAccount.schema, "id"))
                .update()
        }

        func revert(on db: Database) async throws {
            try await db.schema(Transaction.schema)
                .deleteField(Keys.brokerageAccountID)
                .update()
        }
    }

    struct Migration_DropPlatformAccountAndMakeBARequired: AsyncMigration {
            let name = "DropPlatformAccountAndMakeBrokerageAccountRequired"

            func prepare(on db: Database) async throws {
                try await db.schema(Transaction.schema)
                    .deleteField("platform")
                    .deleteField("account")
                    .update()
            }

            func revert(on db: Database) async throws {
                // No-op (we intentionally don't recreate dropped columns)
            }
        }
}
