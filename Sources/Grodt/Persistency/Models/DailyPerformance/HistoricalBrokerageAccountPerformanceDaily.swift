import Foundation
import Fluent

final class HistoricalBrokerageAccountPerformanceDaily: Model, @unchecked Sendable {
    static let schema = "historical_brokerage_account_performance_daily"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.accountID)
    var account: BrokerageAccount

    @Field(key: Keys.date)
    var date: Date

    @Field(key: Keys.invested)
    var invested: Decimal

    @Field(key: Keys.realized)
    var realized: Decimal

    @Field(key: Keys.currentValue)
    var currentValue: Decimal

    required init() {}

    init(id: UUID? = nil,
         accountID: BrokerageAccount.IDValue,
         date: Date,
         invested: Decimal,
         realized: Decimal = 0,
         currentValue: Decimal)
    {
        self.id = id
        self.$account.id = accountID
        self.date = date
        self.invested = invested
        self.realized = realized
        self.currentValue = currentValue
    }
}

extension HistoricalBrokerageAccountPerformanceDaily {
    enum Keys {
        static let accountID: FieldKey = "brokerage_account_id"
        static let date: FieldKey = "date"
        static let invested: FieldKey = "invested"
        static let realized: FieldKey = "realized"
        static let currentValue: FieldKey = "current_value"

        // Deprecated keys for migration
        static let moneyIn: FieldKey = "money_in"
        static let value: FieldKey = "value"
    }

    struct Migration: AsyncMigration {
        let name = "CreateHistoricalBrokerageAccountPerformanceDaily"

        func prepare(on db: Database) async throws {
            try await db.schema(HistoricalBrokerageAccountPerformanceDaily.schema)
                .id()
                .field(Keys.accountID, .uuid, .required, .references(BrokerageAccount.schema, "id", onDelete: .cascade))
                .field(Keys.date, .date, .required)
                .field(Keys.invested, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.realized, .sql(unsafeRaw: "NUMERIC(64,4)"), .required, .sql(.default(0)))
                .field(Keys.currentValue, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .unique(on: Keys.accountID, Keys.date)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(HistoricalBrokerageAccountPerformanceDaily.schema).delete()
        }
    }
}
