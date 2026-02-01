@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct HomeRouteTests: RouteTestable {

    let basePath = "ski/v1/home"

    // MARK: - GET /home

    @Test func get_returnsHomeResponse() async throws {
        let expectedUser = UserInfoDTO.stub(name: "Test User", email: "test@example.com")
        let expectedPortfolio = PortfolioInfoDTO.stub(name: "My Portfolio")
        let expectedBrokerage = BrokerageInfoDTO.stub(name: "My Brokerage")
        let expectedInvestment = InvestmentDTO.stub(name: "Apple Inc", shortName: "AAPL")
        let expectedNetworth = PerformanceDTO(invested: 1000, currentValue: 1100, profit: 100, totalReturn: 0.1)

        let expectedResponse = HomeResponseDTO.stub(
            user: expectedUser,
            networth: expectedNetworth,
            portfolios: [expectedPortfolio],
            brokerages: [expectedBrokerage],
            investments: [expectedInvestment]
        )

        let mockService = MockHomeService()
        mockService.homeResult = .success(expectedResponse)

        try await withTestApp(homeService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(HomeResponseDTO.self)
                #expect(response.user.name == "Test User")
                #expect(response.user.email == "test@example.com")
                #expect(response.portfolios.count == 1)
                #expect(response.portfolios.first?.name == "My Portfolio")
                #expect(response.brokerages.count == 1)
                #expect(response.brokerages.first?.name == "My Brokerage")
                #expect(response.investments.count == 1)
                #expect(response.investments.first?.shortName == "AAPL")
                #expect(response.networth.profit == 100)
            })
        }
    }

    @Test func get_emptyData_returnsEmptyArrays() async throws {
        let expectedResponse = HomeResponseDTO.stub()

        let mockService = MockHomeService()
        mockService.homeResult = .success(expectedResponse)

        try await withTestApp(homeService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let response = try res.content.decode(HomeResponseDTO.self)
                #expect(response.portfolios.isEmpty)
                #expect(response.brokerages.isEmpty)
                #expect(response.investments.isEmpty)
            })
        }
    }

}
