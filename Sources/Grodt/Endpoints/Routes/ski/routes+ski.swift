import Vapor

func registerSkiRoutes(_ app: Application, _ container: AppContainer) throws {
    try app.group("ski") { ski in
        let tokenAuthMiddleware = UserToken.authenticator()
        let guardAuthMiddleware = User.guardMiddleware()
        let protected = ski.grouped([
            UserTokenCookieAuthenticator(),
            tokenAuthMiddleware,
            OriginRefererCheckMiddleware(),
            guardAuthMiddleware
        ])

        try protected.register(collection: SkiHomeController(
            portfolioService: container.portfolioService,
            accountService: container.accountService,
            brokeragesService: container.brokerageService,
            investmentService: container.investmentService))
    }
}
