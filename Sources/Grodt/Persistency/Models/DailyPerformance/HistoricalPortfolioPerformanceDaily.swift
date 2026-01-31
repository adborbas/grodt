import Foundation
import Fluent

final class HistoricalPortfolioPerformanceDaily: Model, @unchecked Sendable {
    static let schema = "historical_portfolio_performance_daily"

    @ID(key: .id)
    var id: UUID?

    @Parent(key: Keys.portfolioID)
    var portfolio: Portfolio

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
         portfolioID: Portfolio.IDValue,
         date: Date,
         invested: Decimal,
         realized: Decimal = 0,
         currentValue: Decimal)
    {
        self.id = id
        self.$portfolio.id = portfolioID
        self.date = date
        self.invested = invested
        self.realized = realized
        self.currentValue = currentValue
    }
}

extension HistoricalPortfolioPerformanceDaily {
    enum Keys {
        static let portfolioID: FieldKey = "portfolio_id"
        static let date: FieldKey = "date"
        static let invested: FieldKey = "invested"
        static let realized: FieldKey = "realized"
        static let currentValue: FieldKey = "current_value"

        // Deprecated keys for migration
        static let moneyIn: FieldKey = "money_in"
        static let value: FieldKey = "value"
    }

    struct Migration: AsyncMigration {
        let name = "CreateHistoricalPortfolioPerformanceDaily"

        func prepare(on db: Database) async throws {
            try await db.schema(HistoricalPortfolioPerformanceDaily.schema)
                .id()
                .field(Keys.portfolioID, .uuid, .required, .references(Portfolio.schema, "id", onDelete: .cascade))
                .field(Keys.date, .date, .required)
                .field(Keys.invested, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.realized, .sql(unsafeRaw: "NUMERIC(64,4)"), .required, .sql(.default(0)))
                .field(Keys.currentValue, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .unique(on: Keys.portfolioID, Keys.date)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(HistoricalPortfolioPerformanceDaily.schema).delete()
        }
    }
}
