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
            preferences: UserPreferencesDTO.stub(isMonthlyEmailEnabled: true)
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
                #expect(detail.preferences.isMonthlyEmailEnabled == true)
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
        let expectedPreferences = UserPreferencesDTO.stub(isMonthlyEmailEnabled: false)
        let mockService = MockAccountService()
        mockService.setMonthlyEmailEnabledResult = .success(expectedPreferences)

        try await withTestApp(accountService: mockService) { app, token in
            struct RequestBody: Content {
                let isEnabled: Bool
            }

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(RequestBody(isEnabled: false))
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let preferences = try res.content.decode(UserPreferencesDTO.self)
                #expect(preferences.isMonthlyEmailEnabled == false)
            })
        }
    }

    @Test func updateMonthlyEmail_enableConfig_returnsUpdatedPreferences() async throws {
        let expectedPreferences = UserPreferencesDTO.stub(isMonthlyEmailEnabled: true)
        let mockService = MockAccountService()
        mockService.setMonthlyEmailEnabledResult = .success(expectedPreferences)

        try await withTestApp(accountService: mockService) { app, token in
            struct RequestBody: Content {
                let isEnabled: Bool
            }

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(RequestBody(isEnabled: true))
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let preferences = try res.content.decode(UserPreferencesDTO.self)
                #expect(preferences.isMonthlyEmailEnabled == true)
            })
        }
    }

    @Test func updateMonthlyEmail_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            struct RequestBody: Content {
                let isEnabled: Bool
            }

            try await app.test(.PATCH, "\(basePath)/preferences/monthly-email", beforeRequest: { req in
                try req.content.encode(RequestBody(isEnabled: false))
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }
}
