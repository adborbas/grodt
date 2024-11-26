import Fluent
import Vapor

final class HistoricalPortfolioPerformance: Model, @unchecked Sendable {
    static let schema = "historical_portfolio_performance"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: Keys.portfolioID)
    var portfolio: Portfolio
    
    @Field(key: Keys.datedPerformance)
    var datedPerformance: [DatedPortfolioPerformance]
    
    required init() { }
    
    init(id: UUID? = nil,
         portfolioID: Portfolio.IDValue,
         datedPerformance: [DatedPortfolioPerformance]) {
        self.id = id
        self.$portfolio.id = portfolioID
        self.datedPerformance = datedPerformance
    }
}

fileprivate extension HistoricalPortfolioPerformance {
    enum Keys {
        static let portfolioID: FieldKey = "portfolio_id"
        static let datedPerformance: FieldKey = "dated_performance"
    }
}

extension HistoricalPortfolioPerformance {
    struct Migration: AsyncMigration {
        var name: String { "CreateHistoricalPortfolioPerformance" }
        
        func prepare(on database: Database) async throws {
            try await database.schema(HistoricalPortfolioPerformance.schema)
                .id()
                .field(Keys.portfolioID, .uuid, .required, .references(Portfolio.schema, "id"))
                .field(Keys.datedPerformance, .array(of: .json), .required)
                .create()
        }
        
        func revert(on database: Database) async throws {
            try await database.schema(Portfolio.schema).delete()
        }
    }
}
