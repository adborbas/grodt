import Vapor

func migrations(_ app: Application) throws {
    // Create users table first (without creating any users yet)
    app.migrations.add(User.Migration())

    // Create user_preferences and user_secrets (they reference users table)
    app.migrations.add(UserPreferences.CreateMigration())
    app.migrations.add(UserSecret.CreateMigration())

    // Now create the preconfigured user (UserScaffoldMiddleware can now work)
    app.migrations.add(User.CreatePreconfiguredUserMigration(preconfigured: app.config.preconfiguredUser, logger: app.logger))

    // Create other tables that reference users
    app.migrations.add(UserToken.Migration())
    app.migrations.add(Portfolio.Migration())

    app.migrations.add(Brokerage.Migration())
    app.migrations.add(BrokerageAccount.Migration())

    app.migrations.add(HistoricalPortfolioPerformanceDaily.Migration())
    app.migrations.add(HistoricalBrokerageAccountPerformanceDaily.Migration())
    app.migrations.add(HistoricalBrokeragePerformanceDaily.Migration())
    
    app.migrations.add(Transaction.Migration())
    app.migrations.add(Transaction.Migration_AddBrokerageAccountID())
    if app.environment != .testing {
        app.migrations.add(Transaction.Migration_DropPlatformAccountAndMakeBARequired())
    }

    // Migrate currency column from TEXT to JSONB (safe for both fresh and existing databases)
    app.migrations.add(MigrateTransactionCurrencyToJsonb())

    // Add transaction type, rename columns, and update performance tables
    if app.environment != .testing {
        app.migrations.add(Transaction.Migration_AddTypeAndRenameColumns())
        app.migrations.add(RenamePerformanceColumns())
    }

    app.migrations.add(Currency.Migration())
    app.migrations.add(Ticker.Migration())
    app.migrations.add(Quote.Migration())
    app.migrations.add(HistoricalQuote.Migration())
    
    app.migrations.add(DropOldHistoricalPortfolioPerformance())

    app.migrations.add(BackfillUserSettings())

    // Clean up old per-user Mailjet credentials (RFC-02: System Email Service)
    if app.environment != .testing {
        app.migrations.add(CleanupMailjetCredentials())
    }

    // Seed development data (only in development environment)
    if app.environment == .development {
        app.migrations.add(SeedDevelopmentData())
    }

    app.databases.middleware.use(UserScaffoldMiddleware())
}
