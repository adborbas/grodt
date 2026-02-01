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

        // Profile update endpoints
        account.group("profile") { profile in
            profile.patch("name", use: updateName)
            profile.patch("email", use: updateEmail)

            // Password change has stricter rate limiting (3 requests/min)
            let passwordRateLimiter = RateLimiterMiddleware(maxRequests: 3, perSeconds: 60)
            profile.grouped(passwordRateLimiter).patch("password", use: updatePassword)
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
        let userID = try req.requireUserID()
        let newConfig = try req.content.decode(UpdateMonthlyEmailConfigDTO.self)
        return try await service.updateMonthlyEmailConfig(newConfig, for: userID)
    }

    // MARK: - Profile Updates

    func updateName(req: Request) async throws -> UserInfoDTO {
        let userID = try req.requireUserID()
        try UpdateNameDTO.validate(content: req)
        let dto = try req.content.decode(UpdateNameDTO.self)
        return try await service.updateName(dto, for: userID)
    }

    func updateEmail(req: Request) async throws -> UserInfoDTO {
        let userID = try req.requireUserID()
        try UpdateEmailDTO.validate(content: req)
        let dto = try req.content.decode(UpdateEmailDTO.self)
        return try await service.updateEmail(dto, for: userID)
    }

    func updatePassword(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        try UpdatePasswordDTO.validate(content: req)
        let dto = try req.content.decode(UpdatePasswordDTO.self)
        try await service.updatePassword(dto, for: userID)
        return .noContent
    }
}

struct UpdateMonthlyEmailConfigDTO: Content {
    let isEnabled: Bool
    let senderEmail: String?
    let senderName: String?
    let apiKey: String?
    let apiSecret: String?
}
