import Fluent
import FluentSQL

/// Migration to rename performance table columns and add realized column
/// - Renames money_in → invested
/// - Renames value → current_value
/// - Adds realized column (default 0)
struct RenamePerformanceColumns: AsyncMigration {
    let name = "RenamePerformanceColumnsAndAddRealized"

    private let tables = [
        "historical_portfolio_performance_daily",
        "historical_brokerage_account_performance_daily",
        "historical_brokerage_performance_daily"
    ]

    func prepare(on db: Database) async throws {
        guard let sql = db as? SQLDatabase else { return }

        for table in tables {
            // Rename money_in to invested
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                RENAME COLUMN money_in TO invested
                """).run()

            // Rename value to current_value
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                RENAME COLUMN value TO current_value
                """).run()

            // Add realized column with default 0
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                ADD COLUMN IF NOT EXISTS realized NUMERIC(64,4) NOT NULL DEFAULT 0
                """).run()
        }
    }

    func revert(on db: Database) async throws {
        guard let sql = db as? SQLDatabase else { return }

        for table in tables {
            // Remove realized column
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                DROP COLUMN IF EXISTS realized
                """).run()

            // Rename current_value back to value
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                RENAME COLUMN current_value TO value
                """).run()

            // Rename invested back to money_in
            try await sql.raw("""
                ALTER TABLE \(unsafeRaw: table)
                RENAME COLUMN invested TO money_in
                """).run()
        }
    }
}
