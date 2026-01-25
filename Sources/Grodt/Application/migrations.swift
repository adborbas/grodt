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
    
    app.migrations.add(Currency.Migration())
    app.migrations.add(Ticker.Migration())
    app.migrations.add(Quote.Migration())
    app.migrations.add(HistoricalQuote.Migration())
    
    app.migrations.add(DropOldHistoricalPortfolioPerformance())

    app.migrations.add(BackfillUserSettings())

    app.databases.middleware.use(UserScaffoldMiddleware())
}
