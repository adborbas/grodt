@testable import Grodt
import Testing
import Vapor

struct CachedPriceServiceTests {

    // MARK: - price

    @Test func price_cacheHit_returnsCachedPrice() async throws {
        let cachedQuote = Quote(symbol: "AAPL", price: 150, lastUpdate: Date())

        let mockCache = MockQuoteCache()
        mockCache.quoteResult = .success(cachedQuote)

        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 155, date: YearMonthDayDate())]

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        let result = try await service.price(for: "AAPL")

        #expect(result == 150)
        #expect(mockPriceService.spotPriceCallCount["AAPL"] == nil)
    }

    @Test func price_cacheMiss_fetchesFromServiceAndCaches() async throws {
        let mockCache = MockQuoteCache()
        mockCache.quoteResult = .success(nil)

        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 155, date: YearMonthDayDate())]

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        let result = try await service.price(for: "AAPL")

        #expect(result == 155)
        #expect(mockPriceService.spotPriceCallCount["AAPL"] == 1)
        #expect(mockCache.storeQuoteCalled)
        #expect(mockCache.storedQuote?.symbol == "AAPL")
        #expect(mockCache.storedQuote?.price == 155)
    }

    @Test func price_expiredCache_fetchesFromService() async throws {
        let expiredDate = Calendar.current.date(byAdding: .hour, value: -25, to: Date())!
        let expiredQuote = Quote(symbol: "AAPL", price: 140, lastUpdate: expiredDate)

        let mockCache = MockQuoteCache()
        mockCache.quoteResult = .success(expiredQuote)

        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 155, date: YearMonthDayDate())]

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        let result = try await service.price(for: "AAPL")

        #expect(result == 155)
        #expect(mockPriceService.spotPriceCallCount["AAPL"] == 1)
        #expect(mockCache.storeQuoteCalled)
    }

    @Test func price_cacheThrows_throws() async throws {
        let mockCache = MockQuoteCache()
        mockCache.quoteResult = .failure(Abort(.internalServerError))

        let mockPriceService = MockPriceService()

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        await #expect(throws: Abort.self) {
            _ = try await service.price(for: "AAPL")
        }
    }

    @Test func price_priceServiceThrows_throws() async throws {
        let mockCache = MockQuoteCache()
        mockCache.quoteResult = .success(nil)

        let mockPriceService = ThrowingPriceService()

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        await #expect(throws: Error.self) {
            _ = try await service.price(for: "AAPL")
        }
    }

    // MARK: - historicalPrice

    @Test func historicalPrice_cacheHit_returnsCachedData() async throws {
        let today = YearMonthDayDate()
        let yesterday = YearMonthDayDate(Date().addingTimeInterval(-86400))
        let cachedQuotes = [
            DatedQuote(price: 150, date: today),
            DatedQuote(price: 148, date: yesterday)
        ]
        let historicalQuote = HistoricalQuote(symbol: "AAPL", datedQuotes: cachedQuotes)

        let mockCache = MockQuoteCache()
        mockCache.historicalQuoteResult = .success(historicalQuote)

        let mockPriceService = MockPriceService()

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        let result = try await service.historicalPrice(for: "AAPL")

        #expect(result.count == 2)
        #expect(mockPriceService.historicalPriceCallCount["AAPL"] == nil)
    }

    @Test func historicalPrice_cacheMiss_fetchesAndCaches() async throws {
        let mockCache = MockQuoteCache()
        mockCache.historicalQuoteResult = .success(nil)

        let today = YearMonthDayDate()
        let yesterday = YearMonthDayDate(Date().addingTimeInterval(-86400))
        let prices = [
            DatedQuote(price: 155, date: today),
            DatedQuote(price: 153, date: yesterday)
        ]
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = prices

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        let result = try await service.historicalPrice(for: "AAPL")

        #expect(result.count == 2)
        #expect(mockPriceService.historicalPriceCallCount["AAPL"] == 1)
        #expect(mockCache.storedHistoricalQuote?.symbol == "AAPL")
        #expect(mockCache.storedHistoricalQuote?.datedQuotes.count == 2)
    }

    @Test func historicalPrice_cacheThrows_throws() async throws {
        let mockCache = MockQuoteCache()
        mockCache.historicalQuoteResult = .failure(Abort(.internalServerError))

        let mockPriceService = MockPriceService()

        let service = CachedPriceService(priceService: mockPriceService, cache: mockCache)

        await #expect(throws: Abort.self) {
            _ = try await service.historicalPrice(for: "AAPL")
        }
    }
}

// Helper for testing error cases
private final class ThrowingPriceService: PriceService {
    func price(for ticker: String) async throws -> Decimal {
        throw Abort(.serviceUnavailable)
    }

    func historicalPrice(for ticker: String) async throws -> [DatedQuote] {
        throw Abort(.serviceUnavailable)
    }
}
