import Vapor

func registerApiRoutes(_ app: Application, _ container: AppContainer) throws {
    try app.group("api") { api in
        let tokenAuthMiddleware = UserToken.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()

        var tickersController = TickersController(
            tickerRepository: container.tickerRepository,
            dataMapper: container.tickerDTOMapper,
            tickerService: container.alphavantage
        )
        let tickerChangeHandler = TickerChangeHandler(priceService: container.priceService)
        tickersController.delegate = tickerChangeHandler

        let investmentsController = InvestmentController(
            portfolioRepository: container.portfolioRepository,
            dataMapper: InvestmentDTOMapper(
                currencyDTOMapper: container.currencyDTOMapper,
                transactionDTOMapper: container.transactionDTOMapper,
                tickerRepository: container.tickerRepository,
                priceService: container.priceService
            )
        )

        let accountController = AccountController(
            userRepository: container.userRepository,
            dataMapper: UserDTOMapper()
        )

        let protected = api.grouped([
            UserTokenCookieAuthenticator(),
            tokenAuthMiddleware,
            OriginRefererCheckMiddleware(),
            guardAuthMiddleware
        ])

        try protected.register(collection:
            PortfoliosController(
                portfolioRepository: container.portfolioRepository,
                currencyRepository: container.currencyRepository,
                historicalPortfolioPerformanceUpdater: container.portfolioPerformanceUpdater,
                portfolioDailyRepo: PostgresPortfolioDailyPerformanceRepository(db: app.db),
                dataMapper: container.portfolioDTOMapper
            )
        )

        let transactionController = TransactionsController(
            transactionsRepository: container.transactionRepository,
            currencyRepository: container.currencyRepository,
            dataMapper: container.transactionDTOMapper
        )
        transactionController.delegate = TransactionChangedHandler(
            portfolioRepository: container.portfolioRepository,
            historicalPerformanceUpdater: container.portfolioPerformanceUpdater
        )

        try protected.register(collection: transactionController)
        try protected.register(collection: tickersController)
        try protected.register(collection: investmentsController)
        try protected.register(collection: accountController)

        try protected.register(collection:
            BrokerageController(
                brokerageRepository: container.brokerageRepository,
                dtoMapper: BrokerageDTOMapper(
                    brokerageRepository: container.brokerageRepository,
                    accountDTOMapper: BrokerageAccountDTOMapper(
                        brokerageAccountRepository: container.brokerageAccountRepository,
                        currencyMapper: container.currencyDTOMapper,
                        database: app.db
                    ),
                    database: app.db
                ),
                accounts: container.brokerageAccountRepository,
                currencyMapper: container.currencyDTOMapper,
                performanceRepository: container.brokerageDailyPerformanceRepository,
                performanceDTOMapper: container.performanceDTOMapper
            )
        )

        try protected.register(collection:
            BrokerageAccountController(
                brokerageAccountRepository: container.brokerageAccountRepository,
                performanceRepository: container.brokerageAccountDailyPerformanceRepository,
                performanceDTOMapper: container.performanceDTOMapper,
                currencyMapper: container.currencyDTOMapper,
                transactionDTOMapper: container.transactionDTOMapper,
                currencyRepository: container.currencyRepository
            )
        )
    }
}
