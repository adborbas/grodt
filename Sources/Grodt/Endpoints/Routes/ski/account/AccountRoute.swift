import Vapor
import Fluent

class AccountRoute: RouteCollection {
    private let service: AccountService

    init(service: AccountService) {
        self.service = service
    }

    func boot(routes: Vapor.RoutesBuilder) throws {
        let account = routes.grouped("account")
        account.group("me") { me in
            me.get(use: userInfo)
        }
    }

    func userInfo(req: Request) async throws -> UserInfoDTO {
        let userID = try req.requireUserID()
                
        return try await self.service.userInfo(for: userID)
    }
}

extension UserInfoDTO: Content { }
