@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct BrokerageAccountsRouteTests: RouteTestable {

    let basePath = "ski/v1/brokerage-accounts"

    // MARK: - GET /brokerage-accounts/:id

    @Test func detail_existingAccount_returnsAccountDetails() async throws {
        let accountID = UUID()
        let expectedAccount = BrokerageAccountDTO.stub(
            id: accountID,
            displayName: "My Trading Account"
        )
        let mockService = MockBrokerageAccountsService()
        mockService.detailResult = .success(expectedAccount)

        try await withTestApp(brokerageAccountsService: mockService) { app, token in
            try await app.test(.GET, path(for: accountID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let account = try res.content.decode(BrokerageAccountDTO.self)
                #expect(account.id == accountID)
                #expect(account.displayName == "My Trading Account")
            })
        }
    }

    // MARK: - PUT /brokerage-accounts/:id

    @Test func update_existingAccount_returnsOk() async throws {
        let accountID = UUID()
        let mockService = MockBrokerageAccountsService()
        mockService.updateResult = .success(.ok)

        try await withTestApp(brokerageAccountsService: mockService) { app, token in
            struct UpdateRequest: Content {
                let displayName: String
            }
            let requestBody = UpdateRequest(displayName: "Updated Account Name")

            try await app.test(.PUT, path(for: accountID), beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - DELETE /brokerage-accounts/:id

    @Test func delete_existingAccount_returnsNoContent() async throws {
        let accountID = UUID()
        let mockService = MockBrokerageAccountsService()
        mockService.deleteResult = .success(.noContent)

        try await withTestApp(brokerageAccountsService: mockService) { app, token in
            try await app.test(.DELETE, path(for: accountID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .noContent)
            })
        }
    }

    @Test func delete_accountWithTransactions_returnsConflict() async throws {
        let mockService = MockBrokerageAccountsService()
        mockService.deleteResult = .failure(Abort(.conflict, reason: "BrokerageAccount has transactions."))

        try await withTestApp(brokerageAccountsService: mockService) { app, token in
            let accountID = UUID()

            try await app.test(.DELETE, path(for: accountID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .conflict)
            })
        }
    }

}
