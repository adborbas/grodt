import Vapor
import Fluent

struct AccountController: RouteCollection {
    private let userRepository: UserRepository
    private let dataMapper: UserDTOMapper
    
    init(userRepository: UserRepository,
         dataMapper: UserDTOMapper) {
        self.userRepository = userRepository
        self.dataMapper = dataMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let account = routes.grouped("account")
        account.group("me") { me in
            me.get(use: userInfo)
        }
    }
    
    func userInfo(req: Request) async throws -> UserInfoDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }
        
        return dataMapper.userInfo(from: user)
    }
}

extension UserInfoDTO: Content { }
