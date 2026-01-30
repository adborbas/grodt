@testable import Grodt
import Testing
import Foundation

struct HoldingsPerformanceCalculatorTests {

    @Test func series_SingleTicker_CarryForwardAndCumulativeMoneyIn() async throws {
        // Given
        let mockPriceService = MockPriceService()
        let calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)

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
        let expected: [DatedPerformance] = [
            DatedPerformance(moneyIn: 51, value: 60, date: YearMonthDayDate(2024, 1, 10)),
            DatedPerformance(moneyIn: 51, value: 60, date: YearMonthDayDate(2024, 1, 11)),
            DatedPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 12)),
            DatedPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 13)),
            DatedPerformance(moneyIn: 51, value: 70, date: YearMonthDayDate(2024, 1, 14)),
            DatedPerformance(moneyIn: 51, value: 90, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected)
        #expect(mockPriceService.historicalPriceCallCount[ticker] ?? 0 == 1)
    }

    @Test func series_MultiTicker_AggregationAndCarryForward() async throws {
        // Given
        let mockPriceService = MockPriceService()
        let calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)

        // MSFT buys on 10 (3 sh @10) and 12 (2 sh @12), AAPL buy on 14 (1 sh @100 + 2 fees)
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
        let expected: [DatedPerformance] = [
            DatedPerformance(moneyIn: 30,  value: 60,  date: YearMonthDayDate(2024, 1, 10)),
            DatedPerformance(moneyIn: 30,  value: 60,  date: YearMonthDayDate(2024, 1, 11)),
            DatedPerformance(moneyIn: 54,  value: 100, date: YearMonthDayDate(2024, 1, 12)),
            DatedPerformance(moneyIn: 54,  value: 100, date: YearMonthDayDate(2024, 1, 13)),
            DatedPerformance(moneyIn: 156, value: 107, date: YearMonthDayDate(2024, 1, 14)),
            DatedPerformance(moneyIn: 156, value: 132, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected)
        // One historical fetch per ticker during prefetch
        #expect(mockPriceService.historicalPriceCallCount["MSFT"] ?? 0 == 1)
        #expect(mockPriceService.historicalPriceCallCount["AAPL"] ?? 0 == 1)
    }

    @Test func series_EmptyTransactions_ReturnsEmpty() async throws {
        let mockPriceService = MockPriceService()
        let calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)

        let start = YearMonthDayDate(2024, 1, 10)
        let end   = YearMonthDayDate(2024, 1, 15)
        let series = try await calculator.performanceSeries(for: [], from: start, to: end)

        // Then
        let expected: [DatedPerformance] = []
        #expect(series == expected)
    }

    @Test func series_TransactionsInFuture_BeforeStartIgnored() async throws {
        let mockPriceService = MockPriceService()
        let calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)

        // Given a purchase after the range end – should have no effect
        let future = givenTransaction(purchasedOn: YearMonthDayDate(2024, 1, 20), ticker: "NVDA", shares: 1, pricePerShare: 100)
        let start = YearMonthDayDate(2024, 1, 10)
        let end   = YearMonthDayDate(2024, 1, 15)

        mockPriceService.pricesByTicker = [ "NVDA": [ DatedQuote(price: 500, date: end) ] ]

        // When
        let series = try await calculator.performanceSeries(for: [future], from: start, to: end)

        // Then: no contribution
        let expected: [DatedPerformance] = [
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 10)),
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 11)),
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 12)),
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 13)),
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 14)),
            DatedPerformance(moneyIn: 0, value: 0, date: YearMonthDayDate(2024, 1, 15))
        ]
        #expect(series == expected)
        // Prefetch may still fetch NVDA once
        #expect(mockPriceService.historicalPriceCallCount["NVDA"] ?? 0 == 1)
    }

    @Test func performance_40Years_10Tickers() async throws {
        let mockPriceService = MockPriceService()
        let calculator = HoldingsPerformanceCalculator(priceService: mockPriceService)

        // Local helper to add years to a YearMonthDayDate
        func addYears(_ years: Int, to day: YearMonthDayDate) -> YearMonthDayDate {
            var calendar = Calendar.current
            calendar.timeZone = TimeZone(secondsFromGMT: 0)!
            let newDate = calendar.date(byAdding: .year, value: years, to: day.date)!
            return YearMonthDayDate(newDate)
        }

        // 40-year inclusive span
        let start = YearMonthDayDate(1985, 1, 1)
        let end   = YearMonthDayDate(2024, 12, 31)
        let allDays = YearMonthDayDate.days(from: start, to: end)

        // 10 synthetic tickers
        let tickers = (0..<10).map { "T\($0)" }

        // Build deterministic quotes: one quote per day per ticker
        mockPriceService.pricesByTicker.removeAll(keepingCapacity: true)
        for (idx, ticker) in tickers.enumerated() {
            var quotes: [DatedQuote] = []
            quotes.reserveCapacity(allDays.count)
            let base = Decimal(100 + idx * 3)
            for (dayIndex, day) in allDays.enumerated() {
                // Sawtooth pattern ensures variation while staying deterministic
                let bump = Decimal(dayIndex % 200) / 10 // 0.0 ... 19.9 then repeat
                quotes.append(DatedQuote(price: base + bump, date: day))
            }
            mockPriceService.pricesByTicker[ticker] = quotes
        }

        // Transactions: 4 buys per ticker at 0, 10, 20, 30 years from start
        var transactions: [Transaction] = []
        transactions.reserveCapacity(tickers.count * 4)
        for (idx, ticker) in tickers.enumerated() {
            for offset in [0, 10, 20, 30] {
                let buyDay = addYears(offset, to: start)
                let shares = Decimal(5 + (idx % 5))            // 5...9 shares
                let purchasePrice = Decimal(100 + idx * 3 + offset)
                transactions.append(
                    givenTransaction(
                        purchasedOn: buyDay,
                        ticker: ticker,
                        fees: 1,                                  // small fee to exercise moneyIn
                        shares: shares,
                        pricePerShare: purchasePrice
                    )
                )
            }
        }

        // Measure using a monotonic clock
        let clock = ContinuousClock()
        let t0 = clock.now
        let series = try await calculator.performanceSeries(for: transactions, from: start, to: end)
        let duration = t0.duration(to: clock.now)

        // Sanity
        #expect(series.count == allDays.count)
        #expect(!series.isEmpty)

        // Convert Duration to seconds (lenient threshold; tune for CI hardware)
        let comps = duration.components
        let seconds = Double(comps.seconds) + Double(comps.attoseconds) / 1_000_000_000_000_000_000.0
        #expect(seconds < 10.0)
    }
}

// MARK: - Test Helpers

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

extension YearMonthDayDate {
    init(_ y: Int, _ m: Int, _ d: Int) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(timeZone: calendar.timeZone, year: y, month: m, day: d))!
        self.init(date)
    }
}
