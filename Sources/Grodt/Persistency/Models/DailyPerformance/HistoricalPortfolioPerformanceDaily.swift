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

    @Field(key: Keys.moneyIn)
    var moneyIn: Decimal

    @Field(key: Keys.value)
    var value: Decimal

    required init() {}

    init(id: UUID? = nil,
         portfolioID: Portfolio.IDValue,
         date: Date,
         moneyIn: Decimal,
         value: Decimal)
    {
        self.id = id
        self.$portfolio.id = portfolioID
        self.date = date
        self.moneyIn = moneyIn
        self.value = value
    }
}

extension HistoricalPortfolioPerformanceDaily {
    enum Keys {
        static let portfolioID: FieldKey = "portfolio_id"
        static let date: FieldKey = "date"
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
                .field(Keys.moneyIn, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .field(Keys.value, .sql(unsafeRaw: "NUMERIC(64,4)"), .required)
                .unique(on: Keys.portfolioID, Keys.date)
                .create()
        }

        func revert(on db: Database) async throws {
            try await db.schema(HistoricalPortfolioPerformanceDaily.schema).delete()
        }
    }
}
