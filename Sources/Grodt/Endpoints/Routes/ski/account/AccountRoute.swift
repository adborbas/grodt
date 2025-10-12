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

        account.group("detail") { me in
            me.get(use: userDetail)
        }

        account.group("preferences") { preferences in
            preferences.patch(use: updatePreferences)
        }
    }

    func userInfo(req: Request) async throws -> UserInfoDTO {
        let userID = try req.requireUserID()
                
        return try await self.service.userInfo(for: userID)
    }

    func userDetail(req: Request) async throws -> UserDetailDTO {
        let userID = try req.requireUserID()

        return try await self.service.userDetail(for: userID)
    }

    func updatePreferences(req: Request) async throws -> UserPreferencesDTO {
        let userID = try req.requireUserID()
        let patch = try req.content.decode(UpdatePreferencesDTO.self)
        return try await service.updatePreferences(byMerging: patch, for: userID)
    }
}

typealias UpdatePreferencesDTO = UserPreferencesDTO
