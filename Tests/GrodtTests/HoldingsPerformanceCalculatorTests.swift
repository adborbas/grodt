@testable import Grodt
import Testing
import Foundation

fileprivate final class MockPriceService: PriceService {
    var pricesByTicker: [String: [DatedQuote]] = [:]
    private(set) var historicalPriceCallCount: [String: Int] = [:]
    private(set) var spotPriceCallCount: [String: Int] = [:]
    
    func price(for ticker: String) async throws -> Decimal {
        spotPriceCallCount[ticker, default: 0] += 1
        return pricesByTicker[ticker]?.last?.price ?? 0
    }
    
    func historicalPrice(for ticker: String) async throws -> [DatedQuote] {
        historicalPriceCallCount[ticker, default: 0] += 1
        return pricesByTicker[ticker] ?? []
    }
}

class HoldingsPerformanceCalculatorTests {
    private var mockPriceService = MockPriceService()
    private lazy var calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)
    
    @Test
    func series_SingleTicker_CarryForwardAndCumulativeMoneyIn() async throws {
        // Given
        let ticker = "AAPL"
        let buy = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 10), ticker: ticker, fees: 1, shares: 10, pricePerShare: 5)
        let start = YearMonthDayDate(buy.purchaseDate)
        let end   = YearMonthDayDate(2024, 1, 15)
        
        mockPriceService.pricesByTicker = [
            ticker: [
                DatedQuote(price: 9, date: end),
                DatedQuote(price: 6, date: start),
                DatedQuote(price: 7, date: YearMonthDayDate(2024, 1, 12))
            ]
        ]
        
        // When
        let series = try await calculator.performanceSeries(for: [buy], from: start, to: end)
        
        // Then
        let expected2: [DatedPortfolioPerformance] = [
            DatedPortfolioPerformance(moneyIn: 51, value: 60, date: YearMonthDayDate(2024, 1, 10)),
            DatedPortfolioPerformance(moneyIn: 51, value: 60, date: YearMonthDayDate(2024, 1, 11)),
            DatedPortfolioPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 12)),
            DatedPortfolioPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 13)),
            DatedPortfolioPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 14)),
            DatedPortfolioPerformance(moneyIn: 51, value: 90, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected2)
        #expect(mockPriceService.historicalPriceCallCount[ticker]! == 1)
    }
    
    @Test
    func series_MultiTicker_AggregationAndCarryForward() async throws {
        // Given: MSFT buys on 10 (3 sh @10) and 12 (2 sh @12), AAPL buy on 14 (1 sh @100 + 2 fees)
        let msft1 = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 10), ticker: "MSFT", shares: 3, pricePerShare: 10)
        let msft2 = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 12), ticker: "MSFT", shares: 2, pricePerShare: 12)
        let aapl  = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 14), ticker: "AAPL", fees: 2, shares: 1, pricePerShare: 100)
        let start = YearMonthDayDate(2024, 1, 10)
        let end   = YearMonthDayDate(2024, 1, 15)
        
        let d10 = start
        let d14 = YearMonthDayDate(2024, 1, 14)
        let d15 = end
        
        // MSFT quotes only on 10 and 15; AAPL quote only on 14 to test carry-forward
        mockPriceService.pricesByTicker = [
            "MSFT": [ DatedQuote(price: 20, date: d10), DatedQuote(price: 25, date: d15) ],
            "AAPL": [ DatedQuote(price: 7, date: d14) ]
        ]
        
        // When
        let series = try await calculator.performanceSeries(for: [msft1, msft2, aapl], from: start, to: end)
        
        // Then
        let expected: [DatedPortfolioPerformance] = [
            DatedPortfolioPerformance(moneyIn: 30,  value: 60,  date: YearMonthDayDate(2024, 1, 10)),
            DatedPortfolioPerformance(moneyIn: 30,  value: 60,  date: YearMonthDayDate(2024, 1, 11)),
            DatedPortfolioPerformance(moneyIn: 54,  value: 100, date: YearMonthDayDate(2024, 1, 12)),
            DatedPortfolioPerformance(moneyIn: 54,  value: 100, date: YearMonthDayDate(2024, 1, 13)),
            DatedPortfolioPerformance(moneyIn: 156, value: 107, date: YearMonthDayDate(2024, 1, 14)),
            DatedPortfolioPerformance(moneyIn: 156, value: 132, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected)
        // One historical fetch per ticker during prefetch
        #expect(mockPriceService.historicalPriceCallCount["MSFT"]! == 1)
        #expect(mockPriceService.historicalPriceCallCount["AAPL"]! == 1)
    }
    
    @Test
    func series_EmptyTransactions_ReturnsEmpty() async throws {
        let start = YearMonthDayDate(2024, 1, 10)
        let end   = YearMonthDayDate(2024, 1, 15)
        let series = try await calculator.performanceSeries(for: [], from: start, to: end)
        // Then
        let expected: [DatedPortfolioPerformance] = []
        #expect(series == expected)
    }
    
    @Test
    func series_TransactionsInFuture_BeforeStartIgnored() async throws {
        // Given a purchase after the range end – should have no effect
        let future = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 20), ticker: "NVDA", shares: 1, pricePerShare: 100)
        let start = YearMonthDayDate(2024, 1, 10)
        let end   = YearMonthDayDate(2024, 1, 15)

        mockPriceService.pricesByTicker = [ "NVDA": [ DatedQuote(price: 500, date: end) ] ]
        
        // When
        let series = try await calculator.performanceSeries(for: [future], from: start, to: end)
        
        // Then: no contribution
        let expected: [DatedPortfolioPerformance] = [
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 10)),
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 11)),
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 12)),
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 13)),
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 14)),
            DatedPortfolioPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected)
        // Prefetch may still fetch NVDA once
        #expect(mockPriceService.historicalPriceCallCount["NVDA"]! == 1)
    }
    
    private func givenTransaction(
        portfolioID: UUID = UUID(),
        brokerageAccountID: UUID? = UUID(),
        purchasedOn: YearMonthDayDate,
        ticker: String,
        currency: Currency = TestConstant.Currencies.eur,
        fees: Decimal = 0,
        shares: Decimal,
        pricePerShare: Decimal
    ) -> Transaction {
        Transaction(
            portfolioID: portfolioID,
            brokerageAccountID: brokerageAccountID,
            purchaseDate: purchasedOn.date,
            ticker: ticker,
            currency: currency,
            fees: fees,
            numberOfShares: shares,
            pricePerShareAtPurchase: pricePerShare
        )
    }
}

extension YearMonthDayDate {
    init(_ y: Int, _ m: Int, _ d: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: y, month: m, day: d))!
        self.init(date)
    }
}
