import Vapor
import Fluent

struct UserController: RouteCollection {
    private let dtoMapper: LoginResponseDTOMapper
    
    init(dtoMapper: LoginResponseDTOMapper) {
        self.dtoMapper = dtoMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let passwordProtected = routes.grouped(User.authenticator())
        passwordProtected.post("login") { req async throws -> LoginResponseDTO in
            let user = try req.auth.require(User.self)
            let token = try user.generateToken()
            try await token.save(on: req.db)
            return dtoMapper.response(from: token)
        }
    }
}

extension LoginResponseDTO: Content { }
