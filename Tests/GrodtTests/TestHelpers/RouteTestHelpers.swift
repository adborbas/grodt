@testable import Grodt
import Vapor
import XCTVapor

let testToken = "test-token"

func withTestApp(
    portfolioService: PortfolioServicing = MockPortfolioService(),
    transactionService: TransactionServicing = MockTransactionService(),
    tickersService: TickersServicing = MockTickersService(),
    brokerageService: BrokerageServicing = MockBrokerageService(),
    accountService: AccountServicing = MockAccountService(),
    brokerageAccountsService: BrokerageAccountsServicing = MockBrokerageAccountsService(),
    homeService: HomeServicing = MockHomeService(),
    investmentService: InvestmentServicing = MockInvestmentService(),
    _ body: (Application, String) async throws -> Void
) async throws {
    let app = try await makeApp(
        portfolioService: portfolioService,
        transactionService: transactionService,
        tickersService: tickersService,
        brokerageService: brokerageService,
        accountService: accountService,
        brokerageAccountsService: brokerageAccountsService,
        homeService: homeService,
        investmentService: investmentService
    )
    defer { Task { try? await app.asyncShutdown() } }

    try await XCTVaporContext.$emitWarningIfCurrentTestInfoIsAvailable.withValue(false) {
        try await body(app, testToken)
    }
}

func makeApp(
    portfolioService: PortfolioServicing = MockPortfolioService(),
    transactionService: TransactionServicing = MockTransactionService(),
    tickersService: TickersServicing = MockTickersService(),
    brokerageService: BrokerageServicing = MockBrokerageService(),
    accountService: AccountServicing = MockAccountService(),
    brokerageAccountsService: BrokerageAccountsServicing = MockBrokerageAccountsService(),
    homeService: HomeServicing = MockHomeService(),
    investmentService: InvestmentServicing = MockInvestmentService()
) async throws -> Application {
    let app = try await Application.make(.testing)
    app.logger.logLevel = .critical

    try app.group("ski", "v1") { ski in
        let protected = ski.grouped([
            TestAuthenticator(),
            User.guardMiddleware()
        ])

        try protected.register(collection: HomeRoute(
            service: homeService
        ))

        try protected.register(collection: PortfolioRoute(
            service: portfolioService,
            transactionService: transactionService,
            tickersService: tickersService,
            brokerageService: brokerageService
        ))

        try protected.register(collection: AccountRoute(
            service: accountService
        ))

        try protected.register(collection: BrokerageAccountsRoute(
            service: brokerageAccountsService
        ))

        try protected.register(collection: InvestmentRoute(
            service: investmentService
        ))

        try protected.register(collection: TickersRoute(
            service: tickersService
        ))

        try protected.register(collection: TransactionsRoute(
            service: transactionService
        ))

        try protected.register(collection: BrokeragesRoute(
            service: brokerageService,
            accountsService: brokerageAccountsService
        ))
    }

    return app
}
