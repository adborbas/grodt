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
}
