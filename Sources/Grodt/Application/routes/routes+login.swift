import Vapor

func registerLoginRoutes(_ app: Application, _ container: AppContainer) throws {
    let loginRateLimiter = RateLimiterMiddleware(maxRequests: 3, perSeconds: 60)
    try app
        .grouped(loginRateLimiter)
        .register(collection: UserController(dtoMapper: container.loginResponseDTOMapper))
}
