import Foundation
import Fluent

final class HistoricalBrokeragePerformanceDaily: Model, @unchecked Sendable {
    static let schema = "historical_brokerage_performance_daily"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.brokerageID)
    var brokerage: Brokerage

    @Field(key: Keys.date)
    var date: Date

    @Field(key: Keys.moneyIn)
    var moneyIn: Decimal

    @Field(key: Keys.value)
    var value: Decimal

    required init() {}

    init(id: UUID? = nil,
         brokerageID: Brokerage.IDValue,
         date: Date,
         moneyIn: Decimal,
         value: Decimal)
    {
        self.id = id
        self.$brokerage.id = brokerageID
        self.date = date
        self.moneyIn = moneyIn
        self.value = value
    }
}

extension HistoricalBrokeragePerformanceDaily {
    enum Keys {
        static let brokerageID: FieldKey = "brokerage_id"
        static let date: FieldKey = "date"
        static let moneyIn: FieldKey = "money_in"
        static let value: FieldKey = "value"
    }

    struct Migration: AsyncMigration {
        let name = "CreateHistoricalBrokeragePerformanceDaily"

        func prepare(on db: Database) async throws {
            try await db.schema(HistoricalBrokeragePerformanceDaily.schema)
                .id()
                .field(Keys.brokerageID, .uuid, .required, .references(Brokerage.schema, "id", onDelete: .cascade))
                .field(Keys.date, .date, .required)
                .field(Keys.moneyIn, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.value, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .unique(on: Keys.brokerageID, Keys.date)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(HistoricalBrokeragePerformanceDaily.schema).delete()
        }
    }
}
