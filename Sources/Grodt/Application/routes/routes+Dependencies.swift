import Vapor
import AlphaSwiftage

struct AppContainer {
    // External services
    let alphavantage: AlphaVantageService

    // Mappers
    let currencyDTOMapper: CurrencyDTOMapper
    let tickerDTOMapper: TickerDTOMapper
    let loginResponseDTOMapper: LoginResponseDTOMapper
    let transactionDTOMapper: TransactionDTOMapper
    let portfolioDTOMapper: PortfolioDTOMapper
    let performanceDTOMapper: DatedPerformanceDTOMapper

    // Core repos/services
    let tickerRepository: PostgresTickerRepository
    let livePriceService: LivePriceService
    let quoteCache: PostgresQuoteRepository
    let priceService: CachedPriceService

    let userRepository: PostgresUserRepository
    let portfolioRepository: PostgresPortfolioRepository
    let transactionRepository: PostgresTransactionRepository
    let brokerageRepository: PostgresBrokerageRepository
    let brokerageAccountRepository: PostgresBrokerageAccountRepository
    let brokerageAccountDailyPerformanceRepository: PostgresBrokerageAccountDailyPerformanceRepository
    let brokerageDailyPerformanceRepository: PostgresBrokerageDailyPerformanceRepository

    let currencyRepository: PostgresCurrencyRepository

    // Calculators / updaters
    let performanceCalculator: HoldingsPerformanceCalculating
    let portfolioPerformanceUpdater: PortfolioPerformanceUpdater
    
    let portfolioService: PortfolioService
    let accountService: AccountService
    let brokerageService: BrokerageService
    let investmentService: InvestmentService
    let transactionService: TransactionService
    let tickersService: TickersService
    let brokerageAccountsService: BrokerageAccountsService
}

func buildAppContainer(_ app: Application) async throws -> AppContainer {
    let alphavantage = try await AlphaVantageService(
        serviceType: .rapidAPI(apiKey: app.config.alphavantageAPIKey())
    )

    let currencyDTOMapper = CurrencyDTOMapper()
    let tickerDTOMapper = TickerDTOMapper()
    let loginResponseDTOMapper = LoginResponseDTOMapper()

    let tickerRepository = PostgresTickerRepository(database: app.db)
    let livePriceService = LivePriceService(alphavantage: alphavantage)
    let quoteCache = PostgresQuoteRepository(database: app.db)
    let priceService = CachedPriceService(priceService: livePriceService, cache: quoteCache)

    let transactionDTOMapper = TransactionDTOMapper(
        currencyDTOMapper: currencyDTOMapper,
        database: app.db
    )

    let investmentDTOMapper = InvestmentDTOMapper(
        currencyDTOMapper: currencyDTOMapper,
        transactionDTOMapper: transactionDTOMapper,
        tickerRepository: tickerRepository,
        priceService: priceService
    )

    let secretsEncryptor = try SecretsEncryptor.loadOrCreate(from: ".secrets-key")
    let userRepository = PostgresUserRepository(database: app.db, secretsEncryptor: secretsEncryptor)
    let portfolioRepository = PostgresPortfolioRepository(database: app.db)
    let transactionRepository = PostgresTransactionRepository(database: app.db)
    let brokerageRepository = PostgresBrokerageRepository(database: app.db)
    let brokerageAccountRepository = PostgresBrokerageAccountRepository(database: app.db)

    let brokerageAccountDailyPerformanceRepository = PostgresBrokerageAccountDailyPerformanceRepository(database: app.db)
    let brokerageDailyPerformanceRepository = PostgresBrokerageDailyPerformanceRepository(database: app.db)

    let performanceDTOMapper = DatedPerformanceDTOMapper()

    let portfolioDTOMapper = PortfolioDTOMapper(
        investmentDTOMapper: investmentDTOMapper,
        transactionDTOMapper: transactionDTOMapper,
        performanceDTOMapper: performanceDTOMapper,
        currencyDTOMapper: currencyDTOMapper
    )

    let currencyRepository = PostgresCurrencyRepository(database: app.db)

    let performanceCalculator = HoldingsPerformanceCalculator(priceService: priceService)

    let portfolioPerformanceUpdater = PortfolioPerformanceUpdater(
        userRepository: userRepository,
        portfolioRepository: portfolioRepository,
        tickerRepository: PostgresTickerRepository(database: app.db),
        quoteCache: quoteCache,
        priceService: priceService,
        performanceCalculator: performanceCalculator,
        portfolioDailyRepo: PostgresPortfolioDailyPerformanceRepository(db: app.db)
    )
    
    let portfolioService = PortfolioService(portfolioRepository: portfolioRepository,
                                            currencyRepository: currencyRepository,
                                            historicalPortfolioPerformanceUpdater: portfolioPerformanceUpdater,
                                            portfolioDailyRepo: PostgresPortfolioDailyPerformanceRepository(db: app.db),
                                            dataMapper: portfolioDTOMapper)
    
    let accountService = AccountService(userRepository: userRepository,
                                        userDataMapper: UserDTOMapper(
                                            preferencesMapper: UserPreferencesDTOMapper(userRepository: userRepository)
                                        )
    )

    let brokerageService = BrokerageService(
        brokerageRepository: brokerageRepository,
        dtoMapper: BrokerageDTOMapper(
            brokerageRepository: brokerageRepository,
            accountDTOMapper: BrokerageAccountDTOMapper(
                brokerageAccountRepository: brokerageAccountRepository,
                currencyMapper: currencyDTOMapper,
                database: app.db
            ),
            performanceRepository: brokerageDailyPerformanceRepository,
            performanceDTOMapper: performanceDTOMapper,
            database: app.db
        ),
        accounts: brokerageAccountRepository,
        currencyMapper: currencyDTOMapper
    )
    
    let investmentService = InvestmentService(
        portfolioRepository: portfolioRepository,
        dataMapper: InvestmentDTOMapper(
            currencyDTOMapper: currencyDTOMapper,
            transactionDTOMapper: transactionDTOMapper,
            tickerRepository: tickerRepository,
            priceService: priceService
        )
    )
    
    let transactionService = TransactionService(transactionsRepository: transactionRepository,
                                                currencyRepository: currencyRepository,
                                                dataMapper: transactionDTOMapper)
    
    let tickersService = TickersService(
        tickerRepository: tickerRepository,
        dataMapper: tickerDTOMapper,
        tickerService: alphavantage
    )
    
    let tickerChangeHandler = TickerChangeHandler(priceService: priceService)
    tickersService.delegate = tickerChangeHandler
    
    let brokerageAccountsService = BrokerageAccountsService(
        brokerageRepository: brokerageRepository,
        brokerageAccountRepository: brokerageAccountRepository,
        performanceRepository: brokerageAccountDailyPerformanceRepository,
        performanceDTOMapper: performanceDTOMapper,
        currencyMapper: currencyDTOMapper,
        transactionDTOMapper: transactionDTOMapper,
        currencyRepository: currencyRepository
    )
        

    return AppContainer(
        alphavantage: alphavantage,
        currencyDTOMapper: currencyDTOMapper,
        tickerDTOMapper: tickerDTOMapper,
        loginResponseDTOMapper: loginResponseDTOMapper,
        transactionDTOMapper: transactionDTOMapper,
        portfolioDTOMapper: portfolioDTOMapper,
        performanceDTOMapper: performanceDTOMapper,
        tickerRepository: tickerRepository,
        livePriceService: livePriceService,
        quoteCache: quoteCache,
        priceService: priceService,
        userRepository: userRepository,
        portfolioRepository: portfolioRepository,
        transactionRepository: transactionRepository,
        brokerageRepository: brokerageRepository,
        brokerageAccountRepository: brokerageAccountRepository,
        brokerageAccountDailyPerformanceRepository: brokerageAccountDailyPerformanceRepository,
        brokerageDailyPerformanceRepository: brokerageDailyPerformanceRepository,
        currencyRepository: currencyRepository,
        performanceCalculator: performanceCalculator,
        portfolioPerformanceUpdater: portfolioPerformanceUpdater,
        portfolioService: portfolioService,
        accountService: accountService,
        brokerageService: brokerageService,
        investmentService: investmentService,
        transactionService: transactionService,
        tickersService: tickersService,
        brokerageAccountsService: brokerageAccountsService
    )
}

func installGlobalMiddleware(_ app: Application) {
    let globalRateLimiter = RateLimiterMiddleware(maxRequests: 100, perSeconds: 60)
    app.middleware.use(app.sessions.middleware)
    app.middleware.use(globalRateLimiter)
    app.middleware.use(AccessLogMiddleware(app: app))
}

func scheduleNightlyJobs(_ app: Application, _ container: AppContainer) throws {
    if app.environment == .testing { return }

    let nightlyUpdaterJob = NightlyUpdaterJob(
        tickerPriceUpdater: TickerPriceUpdater(
            tickerRepository: container.tickerRepository,
            quoteCache: container.quoteCache,
            priceService: container.priceService
        ),
        portfolioPerformanceUpdater: container.portfolioPerformanceUpdater,
        brokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdater(
            transactionRepository: container.transactionRepository,
            brokerageAccountRepository: container.brokerageAccountRepository,
            accountDailyRepository: container.brokerageAccountDailyPerformanceRepository,
            userRepository: container.userRepository,
            calculator: container.performanceCalculator
        ),
        brokeragePerformanceUpdater: BrokeragePerformanceUpdater(
            userRepository: container.userRepository,
            brokerageAccountRepository: container.brokerageAccountRepository,
            accountDailyRepository: container.brokerageAccountDailyPerformanceRepository,
            brokerageDailyRepository: container.brokerageDailyPerformanceRepository
        )
    )

    app.queues.schedule(nightlyUpdaterJob)
        .daily()
        .at(3, 0)

    app.queues.add(LoggingJobEventDelegate(logger: app.logger))

    let userTokenCleanerJob = UserTokenClearUpJob(userTokenClearing: UserTokenClearer(database: app.db))
    app.queues.schedule(userTokenCleanerJob)
        .daily()
}

func scheduleMonthlyEmails(_ app: Application, _ container: AppContainer) throws {
    if app.environment == .testing { return }

    let portfolioPerformanceEmail = PortfolioPerformanceEmail(
        portfolioService: container.portfolioService,
        userRepository: container.userRepository
    )

    let monthlyEmailJob = MonthlyEmailJob(portfolioPerformanceEmail: portfolioPerformanceEmail)

    app.queues.schedule(monthlyEmailJob)
        .monthly()
        .on(1)
        .at(22, 0)
}
