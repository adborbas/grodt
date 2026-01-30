@testable import Grodt
import Testing
import Foundation

struct InvestmentDTOMapperTests {

    // MARK: - investments

    @Test func investments_singleTransaction_calculatesCorrectly() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub(symbol: "AAPL", name: "Apple Inc"))

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        let transaction = Transaction.stub(
            ticker: "AAPL",
            fees: 5,
            numberOfShares: 10,
            pricePerShareAtPurchase: 100
        )

        let investments = try await mapper.investments(from: [transaction])

        #expect(investments.count == 1)
        let investment = investments[0]
        #expect(investment.shortName == "AAPL")
        #expect(investment.numberOfShares == 10)
        #expect(investment.latestPrice == 150)
        // Current value = 10 shares * $150 = $1500
        #expect(investment.value == 1500)
        // Total cost = 10 * $100 + $5 fees = $1005
        // Profit = $1500 - $1005 = $495
        #expect(investment.profit == 495)
    }

    @Test func investments_multipleTransactionsSameTicker_aggregatesCorrectly() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub(symbol: "AAPL", name: "Apple Inc"))

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        let transaction1 = Transaction.stub(
            ticker: "AAPL",
            fees: 5,
            numberOfShares: 10,
            pricePerShareAtPurchase: 100
        )
        let transaction2 = Transaction.stub(
            ticker: "AAPL",
            fees: 3,
            numberOfShares: 5,
            pricePerShareAtPurchase: 120
        )

        let investments = try await mapper.investments(from: [transaction1, transaction2])

        #expect(investments.count == 1)
        let investment = investments[0]
        #expect(investment.numberOfShares == 15) // 10 + 5
        // Total cost = (10 * 100 + 5) + (5 * 120 + 3) = 1005 + 603 = 1608
        // Current value = 15 * 150 = 2250
        // Profit = 2250 - 1608 = 642
        #expect(investment.profit == 642)
    }

    @Test func investments_multipleTickers_groupsCorrectly() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]
        mockPriceService.pricesByTicker["GOOGL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub())

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        let aaplTransaction = Transaction.stub(ticker: "AAPL", fees: 0, numberOfShares: 10, pricePerShareAtPurchase: 100)
        let googlTransaction = Transaction.stub(ticker: "GOOGL", fees: 0, numberOfShares: 5, pricePerShareAtPurchase: 200)

        let investments = try await mapper.investments(from: [aaplTransaction, googlTransaction])

        #expect(investments.count == 2)
        let tickers = investments.map { $0.shortName }
        #expect(tickers.contains("AAPL"))
        #expect(tickers.contains("GOOGL"))
    }

    @Test func investments_sortedByTotalReturnDescending() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]
        mockPriceService.pricesByTicker["GOOGL"] = [DatedQuote(price: 150, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub())

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        // AAPL: bought at 100, now 150 = 50% return
        let aaplTransaction = Transaction.stub(ticker: "AAPL", fees: 0, numberOfShares: 10, pricePerShareAtPurchase: 100)
        // GOOGL: bought at 140, now 150 = ~7% return
        let googlTransaction = Transaction.stub(ticker: "GOOGL", fees: 0, numberOfShares: 10, pricePerShareAtPurchase: 140)

        let investments = try await mapper.investments(from: [googlTransaction, aaplTransaction])

        // AAPL should be first (higher return)
        #expect(investments[0].shortName == "AAPL")
        #expect(investments[1].shortName == "GOOGL")
    }

    @Test func investments_emptyTransactions_returnsEmptyArray() async throws {
        let mapper = makeMapper()

        let investments = try await mapper.investments(from: [])

        #expect(investments.isEmpty)
    }

    @Test func investments_zeroPrice_throws() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 0, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub())

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        let transaction = Transaction.stub(ticker: "AAPL")

        await #expect(throws: InvestmentDTOMapper.InvestmentError.self) {
            _ = try await mapper.investments(from: [transaction])
        }
    }

    // MARK: - Total Return Calculation

    @Test func investments_totalReturn_calculatesCorrectly() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 110, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub())

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        // Buy 10 shares at $100 = $1000 cost
        // Current value = 10 * $110 = $1100
        // Profit = $100
        // Return = 100 / 1000 = 0.10 (10%)
        let transaction = Transaction.stub(
            ticker: "AAPL",
            fees: 0,
            numberOfShares: 10,
            pricePerShareAtPurchase: 100
        )

        let investments = try await mapper.investments(from: [transaction])

        #expect(investments[0].totalReturn == Decimal(string: "0.1")!)
    }

    @Test func investments_negativeReturn_calculatesCorrectly() async throws {
        let mockPriceService = MockPriceService()
        mockPriceService.pricesByTicker["AAPL"] = [DatedQuote(price: 80, date: YearMonthDayDate())]

        let mockTickerRepo = MockTickerRepository()
        mockTickerRepo.tickersForSymbolResult = .success(Ticker.stub())

        let mapper = makeMapper(priceService: mockPriceService, tickerRepository: mockTickerRepo)

        // Buy 10 shares at $100 = $1000 cost
        // Current value = 10 * $80 = $800
        // Profit = -$200
        // Return = -200 / 1000 = -0.20 (-20%)
        let transaction = Transaction.stub(
            ticker: "AAPL",
            fees: 0,
            numberOfShares: 10,
            pricePerShareAtPurchase: 100
        )

        let investments = try await mapper.investments(from: [transaction])

        #expect(investments[0].totalReturn == Decimal(string: "-0.2")!)
        #expect(investments[0].profit == -200)
    }

    // MARK: - Helper

    private func makeMapper(
        priceService: PriceService = MockPriceService(),
        tickerRepository: TickerRepository = MockTickerRepository(),
        transactionDTOMapper: TransactionDTOMapping = MockTransactionDTOMapper()
    ) -> InvestmentDTOMapper {
        InvestmentDTOMapper(
            currencyDTOMapper: CurrencyDTOMapper(),
            transactionDTOMapper: transactionDTOMapper,
            tickerRepository: tickerRepository,
            priceService: priceService
        )
    }
}
