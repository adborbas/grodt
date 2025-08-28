import Vapor

func migrations(_ app: Application) throws {
    // 1) New tables
    app.migrations.add(Brokerage.Migration())
    app.migrations.add(BrokerageAccount.Migration())

    // 2) Add nullable FK to transactions
    app.migrations.add(Transaction.Migration_AddBrokerageAccountID())

    // 4) Create historical perf tables
    app.migrations.add(HistoricalBrokerageAccountPerformance.Migration())
    app.migrations.add(HistoricalBrokeragePerformance.Migration())

    // 5) Drop platform/account and make FK required
    app.migrations.add(Transaction.Migration_DropPlatformAccountAndMakeBARequired())
    
    app.migrations.add(User.Migration(preconfigured: app.config.preconfiguredUser, logger: app.logger))
    app.migrations.add(UserToken.Migration())
    app.migrations.add(Portfolio.Migration())
//    app.migrations.add(Transaction.Migration())
    app.migrations.add(Currency.Migration())
    app.migrations.add(Ticker.Migration())
    app.migrations.add(Quote.Migration())
    app.migrations.add(HistoricalPortfolioPerformance.Migration())
    app.migrations.add(HistoricalQuote.Migration())
    
    
}
