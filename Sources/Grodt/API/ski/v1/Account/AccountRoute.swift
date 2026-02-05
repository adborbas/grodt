import Vapor
import Fluent

class AccountRoute: RouteCollection {
    private let service: AccountServicing

    init(service: AccountServicing) {
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
            preferences.patch("monthly-email", use: updateMonthlyEmail)
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

    func updateMonthlyEmail(req: Request) async throws -> UserPreferencesDTO {
        struct UpdateMonthlyEmailRequest: Content {
            let isEnabled: Bool
        }

        let userID = try req.requireUserID()
        let body = try req.content.decode(UpdateMonthlyEmailRequest.self)
        return try await service.setMonthlyEmailEnabled(body.isEnabled, for: userID)
    }
}
