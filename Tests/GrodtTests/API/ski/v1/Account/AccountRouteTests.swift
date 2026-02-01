@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct AccountRouteTests: RouteTestable {

    let basePath = "ski/v1/account"

    // MARK: - GET /account/me

    @Test func userInfo_withAuth_returnsUserInfo() async throws {
        let expectedUserInfo = UserInfoDTO.stub(name: "John Doe", email: "john@example.com")
        let mockService = MockAccountService()
        mockService.userInfoResult = .success(expectedUserInfo)

        try await withTestApp(accountService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let userInfo = try res.content.decode(UserInfoDTO.self)
                #expect(userInfo.name == "John Doe")
                #expect(userInfo.email == "john@example.com")
            })
        }
    }

    @Test func userInfo_whenServiceThrowsNotFound_returnsNotFound() async throws {
        let mockService = MockAccountService()
        mockService.userInfoResult = .failure(Abort(.notFound))

        try await withTestApp(accountService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/me", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test func userInfo_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            try await app.test(.GET, "\(basePath)/me", afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - GET /account/detail

    @Test func userDetail_withAuth_returnsUserDetail() async throws {
        let expectedDetail = UserDetailDTO.stub(
            name: "Jane Doe",
            email: "jane@example.com",
            preferences: UserPreferencesDTO.stub(
                monthlyEmail: MonthlyEmailConfigDTO.stub(isEnabled: true)
            )
        )
        let mockService = MockAccountService()
        mockService.userDetailResult = .success(expectedDetail)

        try await withTestApp(accountService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/detail", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let detail = try res.content.decode(UserDetailDTO.self)
                #expect(detail.name == "Jane Doe")
                #expect(detail.email == "jane@example.com")
                #expect(detail.preferences.monthlyEmail.isEnabled == true)
            })
        }
    }

    @Test func userDetail_whenServiceThrowsNotFound_returnsNotFound() async throws {
        let mockService = MockAccountService()
        mockService.userDetailResult = .failure(Abort(.notFound))

        try await withTestApp(accountService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/detail", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    @Test func userDetail_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            try await app.test(.GET, "\(basePath)/detail", afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - PATCH /account/preferences/monthly-email

    @Test func updateMonthlyEmail_disableConfig_returnsUpdatedPreferences() async throws {
        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: MonthlyEmailConfigDTO.stub(isEnabled: false)
        )
        let mockService = MockAccountService()
        mockService.updateMonthlyEmailConfigResult = .success(expectedPreferences)

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateMonthlyEmailConfigDTO(
                isEnabled: false,
                senderEmail: nil,
                senderName: nil,
                apiKey: nil,
                apiSecret: nil
            )

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let preferences = try res.content.decode(UserPreferencesDTO.self)
                #expect(preferences.monthlyEmail.isEnabled == false)
            })
        }
    }

    @Test func updateMonthlyEmail_enableConfig_returnsUpdatedPreferences() async throws {
        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: MonthlyEmailConfigDTO.stub(isEnabled: true)
        )
        let mockService = MockAccountService()
        mockService.updateMonthlyEmailConfigResult = .success(expectedPreferences)

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateMonthlyEmailConfigDTO(
                isEnabled: true,
                senderEmail: "sender@example.com",
                senderName: "Sender Name",
                apiKey: "api-key",
                apiSecret: "api-secret"
            )

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let preferences = try res.content.decode(UserPreferencesDTO.self)
                #expect(preferences.monthlyEmail.isEnabled == true)
            })
        }
    }

    @Test func updateMonthlyEmail_whenServiceThrowsBadRequest_returnsBadRequest() async throws {
        let mockService = MockAccountService()
        mockService.updateMonthlyEmailConfigResult = .failure(Abort(.badRequest, reason: "Mailjet configuration missing."))

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateMonthlyEmailConfigDTO(
                isEnabled: true,
                senderEmail: nil,
                senderName: nil,
                apiKey: nil,
                apiSecret: nil
            )

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test func updateMonthlyEmail_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            let requestBody = UpdateMonthlyEmailConfigDTO(
                isEnabled: false,
                senderEmail: nil,
                senderName: nil,
                apiKey: nil,
                apiSecret: nil
            )

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(requestBody)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - PATCH /account/profile/name

    @Test func updateName_withAuth_returnsUpdatedUserInfo() async throws {
        let expectedUserInfo = UserInfoDTO.stub(name: "New Name", email: "test@example.com")
        let mockService = MockAccountService()
        mockService.updateNameResult = .success(expectedUserInfo)

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateNameDTO(name: "New Name")

            try await app.test(.PATCH, "\(basePath)/profile/name", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let userInfo = try res.content.decode(UserInfoDTO.self)
                #expect(userInfo.name == "New Name")
            })
        }
    }

    @Test func updateName_nameTooShort_returnsBadRequest() async throws {
        let mockService = MockAccountService()

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateNameDTO(name: "Hi")

            try await app.test(.PATCH, "\(basePath)/profile/name", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test func updateName_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            let requestBody = UpdateNameDTO(name: "New Name")

            try await app.test(.PATCH, "\(basePath)/profile/name", beforeRequest: { req in
                try req.content.encode(requestBody)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - PATCH /account/profile/email

    @Test func updateEmail_withAuth_returnsUpdatedUserInfo() async throws {
        let expectedUserInfo = UserInfoDTO.stub(name: "Test User", email: "new@example.com")
        let mockService = MockAccountService()
        mockService.updateEmailResult = .success(expectedUserInfo)

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateEmailDTO(email: "new@example.com", currentPassword: "password123")

            try await app.test(.PATCH, "\(basePath)/profile/email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let userInfo = try res.content.decode(UserInfoDTO.self)
                #expect(userInfo.email == "new@example.com")
            })
        }
    }

    @Test func updateEmail_invalidEmailFormat_returnsBadRequest() async throws {
        let mockService = MockAccountService()

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateEmailDTO(email: "not-an-email", currentPassword: "password123")

            try await app.test(.PATCH, "\(basePath)/profile/email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test func updateEmail_wrongPassword_returnsUnauthorized() async throws {
        let mockService = MockAccountService()
        mockService.updateEmailResult = .failure(Abort(.unauthorized, reason: "Current password is incorrect."))

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdateEmailDTO(email: "new@example.com", currentPassword: "wrong_password")

            try await app.test(.PATCH, "\(basePath)/profile/email", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test func updateEmail_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            let requestBody = UpdateEmailDTO(email: "new@example.com", currentPassword: "password123")

            try await app.test(.PATCH, "\(basePath)/profile/email", beforeRequest: { req in
                try req.content.encode(requestBody)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - PATCH /account/profile/password

    @Test func updatePassword_withAuth_returnsNoContent() async throws {
        let mockService = MockAccountService()
        mockService.updatePasswordResult = .success(())

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdatePasswordDTO(currentPassword: "old_password", newPassword: "new_password123")

            try await app.test(.PATCH, "\(basePath)/profile/password", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })
        }
    }

    @Test func updatePassword_passwordTooShort_returnsBadRequest() async throws {
        let mockService = MockAccountService()

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdatePasswordDTO(currentPassword: "old_password", newPassword: "short")

            try await app.test(.PATCH, "\(basePath)/profile/password", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test func updatePassword_wrongCurrentPassword_returnsUnauthorized() async throws {
        let mockService = MockAccountService()
        mockService.updatePasswordResult = .failure(Abort(.unauthorized, reason: "Current password is incorrect."))

        try await withTestApp(accountService: mockService) { app, token in
            let requestBody = UpdatePasswordDTO(currentPassword: "wrong_password", newPassword: "new_password123")

            try await app.test(.PATCH, "\(basePath)/profile/password", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    @Test func updatePassword_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            let requestBody = UpdatePasswordDTO(currentPassword: "old_password", newPassword: "new_password123")

            try await app.test(.PATCH, "\(basePath)/profile/password", beforeRequest: { req in
                try req.content.encode(requestBody)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }
}
