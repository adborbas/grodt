import Vapor
import Fluent

struct UserController: RouteCollection {
    private let dtoMapper: LoginResponseDTOMapper
    
    init(dtoMapper: LoginResponseDTOMapper) {
        self.dtoMapper = dtoMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let passwordProtected = routes.grouped(User.authenticator())
        passwordProtected.post("login") { req async throws -> Response in
            let user = try req.auth.require(User.self)
            let token = try user.generateToken()
            try await token.save(on: req.db)
            
            let response = Response(status: .ok)
            response.headers.add(name: .authorization, value: "Bearer \(token.value)")
            let cookieTTL: TimeInterval = UserToken.tokenTTL
            response.cookies[UserTokenCookieAuthenticator.tokenName] = .init(
                string: token.value,
                expires: Date().addingTimeInterval(cookieTTL),
                maxAge: Int(cookieTTL),
                domain: nil,
                path: "/",
                isSecure: req.application.environment == .production,
                isHTTPOnly: true,
                sameSite: .lax
            )
            
            return response
        }
    }
}
