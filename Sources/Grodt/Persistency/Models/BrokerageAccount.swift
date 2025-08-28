import Foundation
import Fluent

final class BrokerageAccount: Model, @unchecked Sendable {
    static let schema = "brokerage_accounts"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.brokerageID)
    var brokerage: Brokerage

    @Field(key: Keys.displayName)
    var displayName: String

    @Field(key: Keys.baseCurrency)
    var baseCurrency: Currency

    @Timestamp(key: Keys.createdAt, on: .create)
    var createdAt: Date?

    @Timestamp(key: Keys.updatedAt, on: .update)
    var updatedAt: Date?

    @Children(for: \.$brokerageAccount)
    var transactions: [Transaction]

    init() {}

    init(id: UUID? = nil,
         brokerageID: Brokerage.IDValue,
         displayName: String,
         baseCurrency: Currency)
    {
        self.id = id
        self.$brokerage.id = brokerageID
        self.displayName = displayName
        self.baseCurrency = baseCurrency
    }
}

extension BrokerageAccount {
    enum Keys {
        static let brokerageID: FieldKey = "brokerage_id"
        static let displayName: FieldKey = "display_name"
        static let baseCurrency: FieldKey = "base_currency"
        static let createdAt: FieldKey = "created_at"
        static let updatedAt: FieldKey = "updated_at"
    }

    struct Migration: AsyncMigration {
        let name = "CreateBrokerageAccount"

        func prepare(on db: Database) async throws {
            try await db.schema(BrokerageAccount.schema)
                .id()
                .field(Keys.brokerageID, .uuid, .required, .references(Brokerage.schema, "id", onDelete: .cascade))
                .field(Keys.displayName, .string, .required)
                .field(Keys.baseCurrency, .dictionary, .required)
                .field(Keys.createdAt, .datetime)
                .field(Keys.updatedAt, .datetime)
                .unique(on: Keys.brokerageID, Keys.displayName)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(BrokerageAccount.schema).delete()
        }
    }
}
