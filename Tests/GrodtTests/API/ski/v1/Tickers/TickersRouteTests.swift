@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct TickersRouteTests: RouteTestable {

    let basePath = "ski/v1/tickers"

    // MARK: - POST /tickers

    @Test func create_validTicker_returnsTicker() async throws {
        let expectedTicker = TickerDTO.stub(
            symbol: "AAPL",
            region: "United States",
            name: "Apple Inc",
            currency: "USD"
        )

        let mockService = MockTickersService()
        mockService.createResult = .success(expectedTicker)

        try await withTestApp(tickersService: mockService) { app, token in
            let requestBody = TickerDTO(
                symbol: "AAPL",
                region: "United States",
                name: "Apple Inc",
                currency: "USD"
            )

            try await app.test(.POST, basePath, beforeRequest: { req in
                try req.content.encode(requestBody)
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let ticker = try res.content.decode(TickerDTO.self)
                #expect(ticker.symbol == "AAPL")
                #expect(ticker.name == "Apple Inc")
            })
        }
    }

    // MARK: - GET /tickers/search/:keyword

    @Test func search_validKeyword_returnsTickers() async throws {
        let expectedTickers = [
            TickerDTO.stub(symbol: "AAPL", name: "Apple Inc"),
            TickerDTO.stub(symbol: "AMZN", name: "Amazon.com Inc")
        ]

        let mockService = MockTickersService()
        mockService.searchResult = .success(expectedTickers)

        try await withTestApp(tickersService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/search/apple", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let tickers = try res.content.decode([TickerDTO].self)
                #expect(tickers.count == 2)
            })
        }
    }

    @Test func search_noResults_returnsEmptyArray() async throws {
        let mockService = MockTickersService()
        mockService.searchResult = .success([])

        try await withTestApp(tickersService: mockService) { app, token in
            try await app.test(.GET, "\(basePath)/search/nonexistent", beforeRequest: { req in
                req.headers.bearerAuthorization = BearerAuthorization(token: token)
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
                let tickers = try res.content.decode([TickerDTO].self)
                #expect(tickers.isEmpty)
            })
        }
    }

}
