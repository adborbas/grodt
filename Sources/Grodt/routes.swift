import Vapor
import AlphaSwiftage

func routes(_ app: Application) async throws {
    
    let alphavantage = try await AlphaVantageService(serviceType: .rapidAPI(apiKey: app.config.alphavantageAPIKey()) )
    
    let currencyDTOMapper = CurrencyDTOMapper()
    let tickerDTOMapper = TickerDTOMapper()
    let loginResponseDTOMapper = LoginResponseDTOMapper()
    let transactionDTOMapper = TransactionDTOMapper(currencyDTOMapper: currencyDTOMapper)
    let priceService = CachedPriceService(quoteRepository: PostgresQuoteRepository(database: app.db),
                                          alphavantage: alphavantage)
    let portfolioPerformanceCalculator = PortfolioPerformanceCalculator(priceService: priceService)
    let portfolioDTOMapper = PortfolioDTOMapper(transactionDTOMapper: transactionDTOMapper,
                                                currencyDTOMapper: currencyDTOMapper,
                                                performanceCalculator: portfolioPerformanceCalculator)
    
    try app.group("") { routeBuilder in
        try routeBuilder.register(collection: UserController(dtoMapper: loginResponseDTOMapper))
    }
    
    let tokenAuthMiddleware = UserToken.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let protected = app.grouped([tokenAuthMiddleware, guardAuthMiddleware])
    try protected.group("api") { routeBuilder in
        try routeBuilder.register(collection:
                                    PortfoliosController(portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                                         currencyRepository: PostgresCurrencyRepository(database: app.db),
                                                         dataMapper: portfolioDTOMapper)
        )
        
        let transactionController = TransactionsController(transactionsRepository: PostgresTransactionRepository(database: app.db),
                               currencyRepository: PostgresCurrencyRepository(database: app.db),
                               dataMapper: transactionDTOMapper)
        
        transactionController.delegate = HistoricalPortfolioPerformanceUpdater(portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                                                               quoteRepository: PostgresQuoteRepository(database: app.db),
                                                                               performanceCalculator: portfolioPerformanceCalculator,
                                                                               dataMapper: portfolioDTOMapper)
        try routeBuilder.register(collection: transactionController)
        
        try routeBuilder.register(collection: TickersController(tickerRepository: PostgresTickerRepository(database: app.db),
                                                                dataMapper: tickerDTOMapper,
                                                                tickerService: alphavantage)
        )
    }
}
