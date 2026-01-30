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
    _ body: (Application, String) async throws -> Void
) async throws {
    let app = try await makeApp(
        portfolioService: portfolioService,
        transactionService: transactionService,
        tickersService: tickersService,
        brokerageService: brokerageService,
        accountService: accountService
    )
    defer { Task { try? await app.asyncShutdown() } }

    try await XCTVaporContext.$emitWarningIfCurrentTestInfoIsAvailable.withValue(false) {
        try await body(app, testToken)
    }
}

func withTestAppNoAuth(_ body: (Application) async throws -> Void) async throws {
    let app = try await makeApp()
    defer { Task { try? await app.asyncShutdown() } }

    try await XCTVaporContext.$emitWarningIfCurrentTestInfoIsAvailable.withValue(false) {
        try await body(app)
    }
}

func makeApp(
    portfolioService: PortfolioServicing = MockPortfolioService(),
    transactionService: TransactionServicing = MockTransactionService(),
    tickersService: TickersServicing = MockTickersService(),
    brokerageService: BrokerageServicing = MockBrokerageService(),
    accountService: AccountServicing = MockAccountService()
) async throws -> Application {
    let app = try await Application.make(.testing)

    try app.group("ski", "v1") { ski in
        let protected = ski.grouped([
            TestAuthenticator(),
            User.guardMiddleware()
        ])

        try protected.register(collection: PortfolioRoute(
            service: portfolioService,
            transactionService: transactionService,
            tickersService: tickersService,
            brokerageService: brokerageService
        ))

        try protected.register(collection: AccountRoute(
            service: accountService
        ))
    }

    return app
}
