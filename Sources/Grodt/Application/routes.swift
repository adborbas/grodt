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
    let portfolioPerformanceUpdater = PortfolioPerformanceUpdater(
        userRepository: PostgresUserRepository(database: app.db),
        portfolioRepository: PostgresPortfolioRepository(database: app.db),
        tickerRepository: PostgresTickerRepository(database: app.db),
        quoteRepository: PostgresQuoteRepository(database: app.db),
        priceService: priceService,
        performanceCalculator: portfolioPerformanceCalculator,
        dataMapper: portfolioDTOMapper)
    let transactionChangedHandler = TransactionChangedHandler(portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                                              historicalPerformanceUpdater: portfolioPerformanceUpdater)
    
    let globalRateLimiter = RateLimiterMiddleware(maxRequests: 100, perSeconds: 60)
    let loginRateLimiter = RateLimiterMiddleware(maxRequests: 3, perSeconds: 60)
    
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(globalRateLimiter)
    
    try app.group("") { routeBuilder in
        try routeBuilder
            .grouped(loginRateLimiter)
            .register(collection: UserController(dtoMapper: loginResponseDTOMapper))
    }
    
    let tokenAuthMiddleware = UserToken.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    let protected = app.grouped([tokenAuthMiddleware, guardAuthMiddleware])
    try protected.group("api") { routeBuilder in
        try routeBuilder.register(collection:
                                    PortfoliosController(
                                        portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                        currencyRepository: PostgresCurrencyRepository(database: app.db),
                                        historicalPortfolioPerformanceUpdater: portfolioPerformanceUpdater,
                                        dataMapper: portfolioDTOMapper)
        )
        
        let transactionController = TransactionsController(transactionsRepository: PostgresTransactionRepository(database: app.db),
                               currencyRepository: PostgresCurrencyRepository(database: app.db),
                               dataMapper: transactionDTOMapper)
        
        transactionController.delegate = transactionChangedHandler
        try routeBuilder.register(collection: transactionController)
        
        try routeBuilder.register(collection: TickersController(tickerRepository: PostgresTickerRepository(database: app.db),
                                                                dataMapper: tickerDTOMapper,
                                                                tickerService: alphavantage)
        )
    }
    
    
    app.queues.schedule(PortfolioPerformanceUpdaterJob(performanceUpdater: portfolioPerformanceUpdater))
        .daily()
        .at(9, 0)
    app.queues.add(LoggingJobEventDelegate(logger: app.logger))
}
