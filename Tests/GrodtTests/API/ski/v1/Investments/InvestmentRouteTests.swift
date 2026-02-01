@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct InvestmentRouteTests: RouteTestable {

    let basePath = "ski/v1/investments"

    // MARK: - GET /investments

    @Test func allInvestments_returnsInvestments() async throws {
        let expectedInvestments = [
            InvestmentDTO.stub(name: "Apple Inc", shortName: "AAPL"),
            InvestmentDTO.stub(name: "Microsoft Corp", shortName: "MSFT")
        ]

        let mockService = MockInvestmentService()
        mockService.allInvestmentsResult = .success(expectedInvestments)

        try await withTestApp(investmentService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let investments = try res.content.decode([InvestmentDTO].self)
                #expect(investments.count == 2)
                #expect(investments[0].shortName == "AAPL")
                #expect(investments[1].shortName == "MSFT")
            })
        }
    }

    @Test func allInvestments_emptyList_returnsEmptyArray() async throws {
        let mockService = MockInvestmentService()
        mockService.allInvestmentsResult = .success([])

        try await withTestApp(investmentService: mockService) { app, token in
            try await app.test(.GET, basePath, beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let investments = try res.content.decode([InvestmentDTO].self)
                #expect(investments.isEmpty)
            })
        }
    }

    // MARK: - GET /investments/:ticker

    @Test func investmentDetail_existingTicker_returnsDetail() async throws {
        let expectedDetail = InvestmentDetailDTO.stub(
            name: "Apple Inc",
            shortName: "AAPL",
            avgBuyPrice: 150,
            latestPrice: 175,
            profit: 25
        )

        let mockService = MockInvestmentService()
        mockService.investmentDetailResult = .success(expectedDetail)

        try await withTestApp(investmentService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/AAPL", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let detail = try res.content.decode(InvestmentDetailDTO.self)
                #expect(detail.shortName == "AAPL")
                #expect(detail.avgBuyPrice == 150)
                #expect(detail.latestPrice == 175)
                #expect(detail.profit == 25)
            })
        }
    }

    @Test func investmentDetail_nonExistentTicker_returnsNotFound() async throws {
        let mockService = MockInvestmentService()
        mockService.investmentDetailResult = .failure(Abort(.notFound))

        try await withTestApp(investmentService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/UNKNOWN", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .notFound)
            })
        }
    }

}
