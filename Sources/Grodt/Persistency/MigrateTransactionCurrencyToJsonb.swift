import Fluent
import FluentSQL

struct MigrateTransactionCurrencyToJsonb: AsyncMigration {
    var name: String { "MigrateTransactionCurrencyToJsonb" }

    func prepare(on db: Database) async throws {
        guard let sql = db as? SQLDatabase else {
            return
        }

        // Check current column type
        let result = try await sql.raw("""
            SELECT data_type
            FROM information_schema.columns
            WHERE table_name = 'transactions'
            AND column_name = 'currency'
            """).first()

        guard let row = result else {
            // Column doesn't exist, nothing to migrate
            return
        }

        // Decode the data_type field
        let dataType = try row.decode(column: "data_type", as: String.self)

        // Only migrate if it's currently TEXT
        if dataType == "text" {
            try await sql.raw("""
                ALTER TABLE transactions
                ALTER COLUMN currency TYPE jsonb USING currency::jsonb
                """).run()
        }
        // If it's already jsonb, do nothing
    }

    func revert(on db: Database) async throws {
        // We don't revert this migration because converting back would lose data
        // The revert is a no-op
    }
}
