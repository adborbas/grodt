import Foundation
import Fluent

final class HistoricalBrokerageAccountPerformance: Model, @unchecked Sendable {
    static let schema = "historical_brokerage_account_performance"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.accountID)
    var account: BrokerageAccount

    @Field(key: Keys.date)
    var date: Date // store midnight UTC for that Y-M-D

    @Field(key: Keys.moneyIn)
    var moneyIn: Decimal

    @Field(key: Keys.value)
    var value: Decimal

    required init() {}

    init(id: UUID? = nil,
         accountID: BrokerageAccount.IDValue,
         date: Date,
         moneyIn: Decimal,
         value: Decimal)
    {
        self.id = id
        self.$account.id = accountID
        self.date = date
        self.moneyIn = moneyIn
        self.value = value
    }
}

extension HistoricalBrokerageAccountPerformance {
    enum Keys {
        static let accountID: FieldKey = "brokerage_account_id"
        static let date: FieldKey = "date"
        static let moneyIn: FieldKey = "money_in"
        static let value: FieldKey = "value"
    }

    struct Migration: AsyncMigration {
        let name = "CreateHistoricalBrokerageAccountPerformance"

        func prepare(on db: Database) async throws {
            try await db.schema(HistoricalBrokerageAccountPerformance.schema)
                .id()
                .field(Keys.accountID, .uuid, .required, .references(BrokerageAccount.schema, "id", onDelete: .cascade))
                .field(Keys.date, .date, .required)
                .field(Keys.moneyIn, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.value, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .unique(on: Keys.accountID, Keys.date)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(HistoricalBrokerageAccountPerformance.schema).delete()
        }
    }
}
