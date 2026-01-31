import Foundation
import Fluent
import FluentSQL

enum TransactionType: String, Codable, Sendable {
    case buy
    case sell
}

class Transaction: Model, @unchecked Sendable {
    static let schema = "transactions"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.portfolioID)
    var portfolio: Portfolio

    @OptionalParent(key: Keys.brokerageAccountID)
    var brokerageAccount: BrokerageAccount?

    @Field(key: Keys.type)
    var type: TransactionType

    @Field(key: Keys.transactionDate)
    var transactionDate: Date

    @Field(key: Keys.ticker)
    var ticker: String

    @Field(key: Keys.currency)
    var currency: Currency

    @Field(key: Keys.fees)
    var fees: Decimal

    @Field(key: Keys.numberOfShares)
    var numberOfShares: Decimal

    @Field(key: Keys.pricePerShare)
    var pricePerShare: Decimal

    /// Signed number of shares (positive for buys, negative for sells)
    var signedShares: Decimal {
        type == .buy ? numberOfShares : -numberOfShares
    }

    /// Total cost for buys, total proceeds for sells (always positive)
    var totalAmount: Decimal {
        return pricePerShare * numberOfShares + fees
    }

    // MARK: - Deprecated (for backwards compatibility during migration)

    @available(*, deprecated, renamed: "transactionDate")
    var purchaseDate: Date {
        get { transactionDate }
        set { transactionDate = newValue }
    }

    @available(*, deprecated, renamed: "pricePerShare")
    var pricePerShareAtPurchase: Decimal {
        get { pricePerShare }
        set { pricePerShare = newValue }
    }

    required init() { }

    init(id: UUID? = nil,
         portfolioID: Portfolio.IDValue,
         brokerageAccountID: BrokerageAccount.IDValue?,
         type: TransactionType = .buy,
         transactionDate: Date,
         ticker: String,
         currency: Currency,
         fees: Decimal,
         numberOfShares: Decimal,
         pricePerShare: Decimal)
    {
        self.id = id
        self.$portfolio.id = portfolioID
        self.$brokerageAccount.id = brokerageAccountID
        self.type = type
        self.transactionDate = transactionDate
        self.ticker = ticker
        self.currency = currency
        self.fees = fees
        self.numberOfShares = numberOfShares
        self.pricePerShare = pricePerShare
    }
}

fileprivate extension Transaction {
    enum Keys {
        static let portfolioID: FieldKey = "portfolio_id"
        static let brokerageAccountID: FieldKey = "brokerage_account_id"
        static let type: FieldKey = "type"
        static let transactionDate: FieldKey = "transaction_date"
        static let ticker: FieldKey = "ticker"
        static let currency: FieldKey = "currency"
        static let fees: FieldKey = "fees"
        static let numberOfShares: FieldKey = "number_of_shares"
        static let pricePerShare: FieldKey = "price_per_share"

        // Deprecated keys for migration
        static let purchaseDate: FieldKey = "purchase_date"
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
                // Check if columns exist before dropping (for backwards compatibility with fresh databases)
                guard let sql = db as? SQLDatabase else {
                    return
                }

                // Query to check if columns exist
                let columnsExist = try await sql.raw("""
                    SELECT column_name
                    FROM information_schema.columns
                    WHERE table_name = 'transactions'
                    AND column_name IN ('platform', 'account')
                    """).all()

                // Only drop columns if they exist
                if !columnsExist.isEmpty {
                    try await db.schema(Transaction.schema)
                        .deleteField("platform")
                        .deleteField("account")
                        .update()
                }
            }

            func revert(on db: Database) async throws {
                // No-op (we intentionally don't recreate dropped columns)
            }
        }

    struct Migration_AddTypeAndRenameColumns: AsyncMigration {
        let name = "AddTransactionTypeAndRenameColumns"

        func prepare(on db: Database) async throws {
            guard let sql = db as? SQLDatabase else { return }

            // 1. Add type column with default 'buy' for existing transactions
            try await sql.raw("""
                ALTER TABLE transactions
                ADD COLUMN IF NOT EXISTS type VARCHAR(10) NOT NULL DEFAULT 'buy'
                """).run()

            // 2. Rename purchase_date to transaction_date
            try await sql.raw("""
                ALTER TABLE transactions
                RENAME COLUMN purchase_date TO transaction_date
                """).run()

            // 3. Rename price_per_share_at_purchase to price_per_share
            try await sql.raw("""
                ALTER TABLE transactions
                RENAME COLUMN price_per_share_at_purchase TO price_per_share
                """).run()
        }

        func revert(on db: Database) async throws {
            guard let sql = db as? SQLDatabase else { return }

            try await sql.raw("""
                ALTER TABLE transactions
                RENAME COLUMN transaction_date TO purchase_date
                """).run()

            try await sql.raw("""
                ALTER TABLE transactions
                RENAME COLUMN price_per_share TO price_per_share_at_purchase
                """).run()

            try await sql.raw("""
                ALTER TABLE transactions
                DROP COLUMN IF EXISTS type
                """).run()
        }
    }
}
