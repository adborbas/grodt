import Vapor

func migrations(_ app: Application) throws {
    app.migrations.add(User.Migration(preconfigured: app.config.preconfiguredUser, logger: app.logger))
    app.migrations.add(UserToken.Migration())
    app.migrations.add(Portfolio.Migration())
    app.migrations.add(Transaction.Migration())
    app.migrations.add(Currency.Migration())
    app.migrations.add(Ticker.Migration())
    app.migrations.add(Quote.Migration())
    app.migrations.add(HistoricalPortfolioPerformance.Migration())
    app.migrations.add(HistoricalQuote.Migration())
}
