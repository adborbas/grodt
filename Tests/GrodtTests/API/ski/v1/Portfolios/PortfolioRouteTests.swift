@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct PortfolioRouteTests: RouteTestable {

    let basePath = "ski/v1/portfolios"

    @Test func createPortfolio_withValidData_returnsCreatedPortfolio() async throws {
        let expectedPortfolio = PortfolioDTO.stub(name: "My Portfolio", currencyCode: "EUR")
        let mockService = MockPortfolioService()
        mockService.createResult = .success(expectedPortfolio)

        try await withTestApp(portfolioService: mockService) { app, token in
            let requestBody = CreatePortfolioRequestDTO(name: "My Portfolio", currency: "EUR")

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let portfolio = try res.content.decode(PortfolioDTO.self)
                #expect(portfolio.name == "My Portfolio")
                #expect(portfolio.currency.code == "EUR")
            })
        }
    }

    @Test func createPortfolio_whenServiceThrowsBadRequest_returnsBadRequest() async throws {
        let mockService = MockPortfolioService()
        mockService.createResult = .failure(Abort(.badRequest))

        try await withTestApp(portfolioService: mockService) { app, token in
            let requestBody = CreatePortfolioRequestDTO(name: "My Portfolio", currency: "INVALID")

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .badRequest)
            })
        }
    }

    @Test func createPortfolio_withoutAuth_returnsUnauthorized() async throws {
        try await withTestAppNoAuth { app in
            let requestBody = CreatePortfolioRequestDTO(name: "My Portfolio", currency: "EUR")

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
            }, afterResponse: { res async throws in
                #expect(res.status == .unauthorized)
            })
        }
    }

    // MARK: - GET /portfolios/:id

    @Test func getPortfolio_existingPortfolio_returnsPortfolioWithHistory() async throws {
        let portfolioID = UUID()
        let expectedPortfolio = PortfolioDTO.stub(id: portfolioID, name: "Test Portfolio")
        let expectedPerformance = PerformanceTimeSeriesDTO(values: [])

        let mockService = MockPortfolioService()
        mockService.portfolioDetailResult = .success(expectedPortfolio)
        mockService.historicalPerformanceResult = .success(expectedPerformance)

        try await withTestApp(portfolioService: mockService) { app, token in
            try await app.test(.GET, path(for: portfolioID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let responseDTO = try res.content.decode(PortfolioResponseDTO.self)
                #expect(responseDTO.portfolio.name == "Test Portfolio")
            })
        }
    }

    @Test func getPortfolio_nonExistentPortfolio_returnsNotFound() async throws {
        let mockService = MockPortfolioService()
        mockService.portfolioDetailResult = .failure(Abort(.notFound))

        try await withTestApp(portfolioService: mockService) { app, token in
            let randomID = UUID()

            try await app.test(.GET, path(for: randomID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    // MARK: - PATCH /portfolios/:id

    @Test func updatePortfolioName_withValidData_returnsUpdatedPortfolio() async throws {
        let portfolioID = UUID()
        let updatedPortfolio = PortfolioDTO.stub(id: portfolioID, name: "New Name")

        let mockService = MockPortfolioService()
        mockService.updateNameResult = .success(updatedPortfolio)

        try await withTestApp(portfolioService: mockService) { app, token in
            let requestBody = RenamePortfolioRequestDTO(name: "New Name")

            try await app.test(.PATCH, path(for: portfolioID), beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let updated = try res.content.decode(PortfolioDTO.self)
                #expect(updated.name == "New Name")
            })
        }
    }

    @Test func updatePortfolioName_nonExistentPortfolio_returnsNotFound() async throws {
        let mockService = MockPortfolioService()
        mockService.updateNameResult = .failure(Abort(.notFound))

        try await withTestApp(portfolioService: mockService) { app, token in
            let randomID = UUID()
            let requestBody = RenamePortfolioRequestDTO(name: "New Name")

            try await app.test(.PATCH, path(for: randomID), beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

    // MARK: - DELETE /portfolios/:id

    @Test func deletePortfolio_existingPortfolio_returnsOk() async throws {
        let portfolioID = UUID()
        let mockService = MockPortfolioService()
        mockService.deleteResult = .success(.ok)

        try await withTestApp(portfolioService: mockService) { app, token in
            try await app.test(.DELETE, path(for: portfolioID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func deletePortfolio_nonExistentPortfolio_returnsOk() async throws {
        let mockService = MockPortfolioService()
        mockService.deleteResult = .success(.ok)

        try await withTestApp(portfolioService: mockService) { app, token in
            let randomID = UUID()

            try await app.test(.DELETE, path(for: randomID), beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }
}
