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
            
            return response
        }
    }
}
