import Fluent
import SQLKit

struct DropOldHistoricalPortfolioPerformance: AsyncMigration {
    let name = "DropOldHistoricalPortfolioPerformance"

    func prepare(on db: Database) async throws {
        if let sql = db as? SQLDatabase {
            try await sql.raw(#"DROP TABLE IF EXISTS "historical_portfolio_performance""#).run()
        } else {
            // Best-effort (will throw if table doesn't exist)
            try? await db.schema("historical_portfolio_performance").delete()
        }
    }
    func revert(on db: Database) async throws { /* no-op */ }
}
