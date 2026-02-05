import Fluent
import FluentSQL

/// Migration to clean up old per-user Mailjet credentials from the database.
/// This removes:
/// - Old nested monthlyEmail structure from user_preferences (keeping only isMonthlyEmailEnabled)
/// - Any mailjetApiSecret from user_secrets
struct CleanupMailjetCredentials: AsyncMigration {
    let name = "CleanupMailjetCredentials"

    func prepare(on db: Database) async throws {
        guard let sql = db as? SQLDatabase else { return }

        // Clean up user_preferences: convert old nested format to flat format
        // Old format: {"monthlyEmail": {"isEnabled": true, "senderEmail": "...", ...}}
        // New format: {"isMonthlyEmailEnabled": true}
        try await sql.raw("""
            UPDATE user_preferences
            SET data = jsonb_build_object(
                'isMonthlyEmailEnabled',
                COALESCE(
                    (data->'monthlyEmail'->>'isEnabled')::boolean,
                    (data->>'isMonthlyEmailEnabled')::boolean,
                    false
                )
            )
            """).run()

        // Clean up user_secrets: remove mailjetApiSecret if present
        // This leaves only other secrets (if any) in the data column
        try await sql.raw("""
            UPDATE user_secrets
            SET data = data - 'mailjetApiSecret'
            WHERE data ? 'mailjetApiSecret'
            """).run()
    }

    func revert(on db: Database) async throws {
        // Cannot restore old credentials - they're gone for security reasons
        // This is intentionally a one-way migration
    }
}
