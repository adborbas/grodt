import Vapor

func registerSkiRoutes(_ app: Application, _ container: AppContainer) throws {
    try app.group("ski", "v1") { ski in
        let tokenAuthMiddleware = UserToken.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let protected = ski.grouped([
            UserTokenCookieAuthenticator(),
            tokenAuthMiddleware,
            OriginRefererCheckMiddleware(),
            guardAuthMiddleware
        ])

        try protected.register(collection: HomeRoute(
            service: container.homeService
        ))
        
        try protected.register(collection: PortfolioRoute(
            service: container.portfolioService,
            transactionService: container.transactionService,
            tickersService: container.tickersService,
            brokerageService: container.brokerageService)
        )
        
        let transactionsRoute = TransactionsRoute(
            transactionsRepository: container.transactionRepository,
            currencyRepository: container.currencyRepository,
            dataMapper: container.transactionDTOMapper)
        
        try protected.register(collection: transactionsRoute)
        
        transactionsRoute.delegate = TransactionChangedHandler(
            portfolioRepository: container.portfolioRepository,
            historicalPerformanceUpdater: container.portfolioPerformanceUpdater
        )
        
        try protected.register(collection: TickersRoute(
            service: container.tickersService)
        )
        
        try protected.register(collection: BrokeragesRoute(
            service: container.brokerageService,
            accountsService: container.brokerageAccountsService)
        )
        
        try protected.register(collection: BrokerageAccountsRoute(
            service: container.brokerageAccountsService
        ))
        
        try protected.register(collection: InvestmentRoute(
            service: container.investmentService
        ))
        
        try protected.register(collection: AccountRoute(
            service: container.accountService)
        )
    }
}
