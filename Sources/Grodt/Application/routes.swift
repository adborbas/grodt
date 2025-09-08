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
                                                transactionDTOMapper: transactionDTOMapper,
                                                currencyDTOMapper: currencyDTOMapper,
                                                performanceCalculator: portfolioPerformanceCalculator)
    let currencyRepository = PostgresCurrencyRepository(database: app.db)
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
    
    let accountController = AccountController(userRepository: PostgresUserRepository(database: app.db), dataMapper: UserDTOMapper())
    
    let globalRateLimiter = RateLimiterMiddleware(maxRequests: 100, perSeconds: 60)
    let loginRateLimiter = RateLimiterMiddleware(maxRequests: 3, perSeconds: 60)
    
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(globalRateLimiter)
    
    let tokenAuthMiddleware = UserToken.authenticator()
    let guardAuthMiddleware = User.guardMiddleware()
    
    try app.group("api") { api in
        // Public routes
        try api
            .grouped(loginRateLimiter)
            .register(collection: UserController(dtoMapper: loginResponseDTOMapper))
        
        // Protected routes
        let protected = api.grouped([tokenAuthMiddleware, guardAuthMiddleware])
        try protected.register(collection:
                                PortfoliosController(
                                    portfolioRepository: PostgresPortfolioRepository(database: app.db),
                                    currencyRepository: currencyRepository,
                                    historicalPortfolioPerformanceUpdater: portfolioPerformanceUpdater,
                                    dataMapper: portfolioDTOMapper)
        )
        
        let transactionController = TransactionsController(transactionsRepository: PostgresTransactionRepository(database: app.db),
                                                           currencyRepository: currencyRepository,
                                                           dataMapper: transactionDTOMapper)
        transactionController.delegate = transactionChangedHandler
        try protected.register(collection: transactionController)
        try protected.register(collection: tickersController)
        try protected.register(collection: investmentsController)
        try protected.register(collection: accountController)
        try protected.register(collection: BrokerageController(brokerages: PostgresBrokerageRepository(),
                                                               accounts: PostgresBrokerageAccountRepository(),
                                                               currencyMapper: currencyDTOMapper))
        try protected.register(collection: BrokerageAccountController(accounts: PostgresBrokerageAccountRepository(),
                                                                      currencyMapper: currencyDTOMapper,
                                                                      currencyRepository: currencyRepository))
    }
    
    if app.environment != .testing {
        let portfolioUpdaterJob = PortfolioPerformanceUpdaterJob(performanceUpdater: portfolioPerformanceUpdater)
        app.queues.schedule(portfolioUpdaterJob)
            .daily()
            .at(3, 0)
        
        app.queues.schedule(BrokerageAccountPerformanceUpdaterJob(performanceUpdater: BrokerageAccountPerformanceUpdater(db: app.db, priceService: priceService)))
            .daily()
            .at(4, 0)
        app.queues.schedule(BrokeragePerformanceUpdaterJob(performanceUpdater: BrokeragePerformanceUpdater(db: app.db)))
            .daily()
            .at(5, 0)
        
        app.queues.add(LoggingJobEventDelegate(logger: app.logger))
        
        let userTokenCleanerJob = UserTokenClearUpJob(userTokenClearing: UserTokenClearer(database: app.db))
        app.queues.schedule(userTokenCleanerJob)
            .hourly()
        
        try app.queues.startScheduledJobs()
        try app.queues.startInProcessJobs()
    }
}
