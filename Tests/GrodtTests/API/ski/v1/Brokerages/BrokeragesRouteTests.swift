@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct BrokeragesRouteTests: RouteTestable {

    let basePath = "ski/v1/brokerages"

    // MARK: - GET /brokerages

    @Test func list_returnsBrokerages() async throws {
        let expectedBrokerages = [
            BrokerageDTO.stub(name: "Interactive Brokers"),
            BrokerageDTO.stub(name: "Fidelity")
        ]

        let mockService = MockBrokerageService()
        mockService.allBrokeragesResult = .success(expectedBrokerages)

        try await withTestApp(brokerageService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let brokerages = try res.content.decode([BrokerageDTO].self)
                #expect(brokerages.count == 2)
                #expect(brokerages[0].name == "Interactive Brokers")
                #expect(brokerages[1].name == "Fidelity")
            })
        }
    }

    @Test func list_emptyList_returnsEmptyArray() async throws {
        let mockService = MockBrokerageService()
        mockService.allBrokeragesResult = .success([])

        try await withTestApp(brokerageService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let brokerages = try res.content.decode([BrokerageDTO].self)
                #expect(brokerages.isEmpty)
            })
        }
    }

    // MARK: - POST /brokerages

    @Test func create_validRequest_returnsBrokerage() async throws {
        let brokerageId = UUID()
        let expectedBrokerage = BrokerageDTO.stub(id: brokerageId, name: "New Brokerage")

        let mockService = MockBrokerageService()
        mockService.createBrokerageResult = .success(expectedBrokerage)

        try await withTestApp(brokerageService: mockService) { app, token in
            struct CreateRequest: Content {
                let name: String
            }
            let requestBody = CreateRequest(name: "New Brokerage")

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let brokerage = try res.content.decode(BrokerageDTO.self)
                #expect(brokerage.id == brokerageId)
                #expect(brokerage.name == "New Brokerage")
            })
        }
    }

    @Test func create_serviceError_returnsError() async throws {
        let mockService = MockBrokerageService()
        mockService.createBrokerageResult = .failure(Abort(.internalServerError))

        try await withTestApp(brokerageService: mockService) { app, token in
            struct CreateRequest: Content {
                let name: String
            }
            let requestBody = CreateRequest(name: "New Brokerage")

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .internalServerError)
            })
        }
    }

    // MARK: - GET /brokerages/:id

    @Test func detail_existingBrokerage_returnsBrokerage() async throws {
        let brokerageId = UUID()
        let expectedBrokerage = BrokerageDTO.stub(id: brokerageId, name: "My Brokerage")

        let mockService = MockBrokerageService()
        mockService.brokerageDetailResult = .success(expectedBrokerage)

        try await withTestApp(brokerageService: mockService) { app, token in
            try await app.test(.GET, path(for: brokerageId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let brokerage = try res.content.decode(BrokerageDTO.self)
                #expect(brokerage.id == brokerageId)
                #expect(brokerage.name == "My Brokerage")
            })
        }
    }

    @Test func detail_nonExistentBrokerage_returnsNotFound() async throws {
        let mockService = MockBrokerageService()
        mockService.brokerageDetailResult = .failure(Abort(.notFound))

        try await withTestApp(brokerageService: mockService) { app, token in
            let randomId = UUID()

            try await app.test(.GET, path(for: randomId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    // MARK: - PUT /brokerages/:id

    @Test func update_validRequest_returnsOk() async throws {
        let brokerageId = UUID()
        let expectedBrokerage = BrokerageDTO.stub(id: brokerageId, name: "Updated Brokerage")

        let mockService = MockBrokerageService()
        mockService.updateBrokerageResult = .success(expectedBrokerage)

        try await withTestApp(brokerageService: mockService) { app, token in
            struct UpdateRequest: Content {
                let name: String
            }
            let requestBody = UpdateRequest(name: "Updated Brokerage")

            try await app.test(.PUT, path(for: brokerageId), beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func update_nonExistentBrokerage_returnsNotFound() async throws {
        let mockService = MockBrokerageService()
        mockService.updateBrokerageResult = .failure(Abort(.notFound))

        try await withTestApp(brokerageService: mockService) { app, token in
            let randomId = UUID()
            struct UpdateRequest: Content {
                let name: String
            }
            let requestBody = UpdateRequest(name: "Updated Brokerage")

            try await app.test(.PUT, path(for: randomId), beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    // MARK: - DELETE /brokerages/:id

    @Test func delete_existingBrokerage_returnsOk() async throws {
        let brokerageId = UUID()
        let mockService = MockBrokerageService()
        mockService.deleteBrokerageResult = .success(())

        try await withTestApp(brokerageService: mockService) { app, token in
            try await app.test(.DELETE, path(for: brokerageId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func delete_nonExistentBrokerage_returnsNotFound() async throws {
        let mockService = MockBrokerageService()
        mockService.deleteBrokerageResult = .failure(Abort(.notFound))

        try await withTestApp(brokerageService: mockService) { app, token in
            let randomId = UUID()

            try await app.test(.DELETE, path(for: randomId), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    // MARK: - POST /brokerages/:id/accounts

    @Test func createAccount_validRequest_returnsAccount() async throws {
        let brokerageId = UUID()
        let accountId = UUID()
        let expectedAccount = BrokerageAccountDTO.stub(
            id: accountId,
            brokerageId: brokerageId,
            displayName: "New Account"
        )

        let mockAccountsService = MockBrokerageAccountsService()
        mockAccountsService.createResult = .success(expectedAccount)

        try await withTestApp(brokerageAccountsService: mockAccountsService) { app, token in
            struct CreateAccountRequest: Content {
                let displayName: String
                let currency: String
            }
            let requestBody = CreateAccountRequest(displayName: "New Account", currency: "EUR")

            try await app.test(.POST, "\(path(for: brokerageId))/accounts", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let account = try res.content.decode(BrokerageAccountDTO.self)
                #expect(account.id == accountId)
                #expect(account.displayName == "New Account")
            })
        }
    }

    @Test func createAccount_serviceError_returnsError() async throws {
        let mockAccountsService = MockBrokerageAccountsService()
        mockAccountsService.createResult = .failure(Abort(.internalServerError))

        try await withTestApp(brokerageAccountsService: mockAccountsService) { app, token in
            let brokerageId = UUID()
            struct CreateAccountRequest: Content {
                let displayName: String
                let currency: String
            }
            let requestBody = CreateAccountRequest(displayName: "New Account", currency: "EUR")

            try await app.test(.POST, "\(path(for: brokerageId))/accounts", beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .internalServerError)
            })
        }
    }

}
