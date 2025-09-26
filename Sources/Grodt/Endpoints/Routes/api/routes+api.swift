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

        let investmentsController = InvestmentController(serivce: container.investmentService)

        let protected = api.grouped([
            UserTokenCookieAuthenticator(),
            tokenAuthMiddleware,
            OriginRefererCheckMiddleware(),
            guardAuthMiddleware
        ])
        
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

        try protected.register(collection:BrokerageController(service:container.brokerageService))

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
