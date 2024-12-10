import Vapor
import AlphaSwiftage

func routes(_ app: Application) async throws {
    
    let alphavantage = try await AlphaVantageService(serviceType: .rapidAPI(apiKey: app.config.alphavantageAPIKey()) )
    
    let currencyDTOMapper = CurrencyDTOMapper()
    let tickerDTOMapper = TickerDTOMapper()
    let loginResponseDTOMapper = LoginResponseDTOMapper()
    let transactionDTOMapper = TransactionDTOMapper(currencyDTOMapper: currencyDTOMapper)
    let tickerRepository = PostgresTickerRepository(database: app.db)
    let livePriceService = LivePriceService(alphavantage: alphavantage)
    let quoteCache = PostgresQuoteRepository(database: app.db)
    let priceService = CachedPriceService(priceService: livePriceService, cache: quoteCache)
    let investmentDTOMapper = InvestmentDTOMapper(currencyDTOMapper: currencyDTOMapper,
                                                  transactionDTOMapper: transactionDTOMapper,
                                                  tickerRepository: tickerRepository,
                                                  priceService: priceService)
    let portfolioRepository = PostgresPortfolioRepository(database: app.db)
    let portfolioPerformanceCalculator = PortfolioPerformanceCalculator(priceService: priceService)
    let portfolioDTOMapper = PortfolioDTOMapper(investmentDTOMapper: investmentDTOMapper,
                                                currencyDTOMapper: currencyDTOMapper,
                                                performanceCalculator: portfolioPerformanceCalculator)
    let portfolioPerformanceUpdater = PortfolioPerformanceUpdater(
        userRepository: PostgresUserRepository(database: app.db),
        portfolioRepository: portfolioRepository,
        tickerRepository: PostgresTickerRepository(database: app.db),
        quoteCache: quoteCache,
        priceService: priceService,
        performanceCalculator: portfolioPerformanceCalculator)
    let transactionChangedHandler = TransactionChangedHandler(portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                                              historicalPerformanceUpdater: portfolioPerformanceUpdater)
    
    var tickersController = TickersController(tickerRepository: tickerRepository,
                                              dataMapper: tickerDTOMapper,
                                              tickerService: alphavantage)
    let tickerChangeHandler = TickerChangeHandler(priceService: priceService)
    tickersController.delegate = tickerChangeHandler
    
    let investmentsController = InvestmentController(portfolioRepository: portfolioRepository,
                                                     dataMapper: investmentDTOMapper)
    
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
        
        try routeBuilder.register(collection: tickersController)
        try routeBuilder.register(collection: investmentsController)
    }
    
    
    app.queues.schedule(PortfolioPerformanceUpdaterJob(performanceUpdater: portfolioPerformanceUpdater))
        .daily()
        .at(1, 0)
    app.queues.add(LoggingJobEventDelegate(logger: app.logger))
}
