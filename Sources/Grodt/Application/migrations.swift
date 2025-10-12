import Vapor

func migrations(_ app: Application) throws {
    app.migrations.add(Brokerage.Migration())
    app.migrations.add(BrokerageAccount.Migration())

    app.migrations.add(HistoricalPortfolioPerformanceDaily.Migration())
    app.migrations.add(HistoricalBrokerageAccountPerformanceDaily.Migration())
    app.migrations.add(HistoricalBrokeragePerformanceDaily.Migration())
    
    app.migrations.add(User.Migration(preconfigured: app.config.preconfiguredUser, logger: app.logger))
    app.migrations.add(UserToken.Migration())
    app.migrations.add(Portfolio.Migration())
    
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

    app.migrations.add(UserPreference.CreateMigration())
    app.migrations.add(UserSecret.CreateMigration())
    app.migrations.add(BackfillUserSettings())

    app.databases.middleware.use(UserScaffoldMiddleware())
}
