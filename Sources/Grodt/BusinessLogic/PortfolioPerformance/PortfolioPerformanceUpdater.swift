import Foundation

protocol PortfolioHistoricalPerformanceUpdater {
    func recalculateHistoricalPerformance(of portfolio: Portfolio) async throws
    func updatePerformanceOfAllPortfolios() async throws
}

class PortfolioPerformanceUpdater: PortfolioHistoricalPerformanceUpdater {
    private let userRepository: UserRepository
    private let portfolioRepository: PortfolioRepository
    private let tickerRepository: TickerRepository
    private let quoteRepository: QuoteRepository
    private let priceService: PriceService
    private let performanceCalculator: PortfolioPerformanceCalculating
    private let dataMapper: PortfolioDTOMapper
    
    private let rateLimiter = RateLimiter(maxRequestsPerMinute: 5)

    init(userRepository: UserRepository,
         portfolioRepository: PortfolioRepository,
         tickerRepository: TickerRepository,
         quoteRepository: QuoteRepository,
         priceService: PriceService,
         performanceCalculator: PortfolioPerformanceCalculating,
         dataMapper: PortfolioDTOMapper) {
        self.userRepository = userRepository
        self.portfolioRepository = portfolioRepository
        self.tickerRepository = tickerRepository
        self.quoteRepository = quoteRepository
        self.priceService = priceService
        self.performanceCalculator = performanceCalculator
        self.dataMapper = dataMapper
    }

    func updatePerformanceOfAllPortfolios() async throws {
        // Remove all historrical prices
        for quote in try await quoteRepository.allHistoricalQuote() {
            try await quoteRepository.delete(quote)
        }
        
        // Update historical prices and latest prices for all tickers
        let allTickers = try await tickerRepository.allTickers()
        for ticker in allTickers {
            await rateLimiter.waitIfNeeded()
            _ = try await priceService.fetchAndCreateHistoricalPrices(for: ticker.symbol)
            await rateLimiter.waitIfNeeded()
            if let quote = try await quoteRepository.quote(for: ticker.symbol) {
                _ = try await priceService.fetchAndUpdatePrice(for: quote)
            }
        }

        // Update historical performance for all portfolios
        let users = try await userRepository.allUsers()
        for user in users {
            let allPortfolios = try await portfolioRepository.allPortfolios(for: user.id!)
            for portfolio in allPortfolios {
                try await recalculateHistoricalPerformance(of: portfolio)
            }
        }
    }

    func recalculateHistoricalPerformance(of portfolio: Portfolio) async throws {
        var datedPerformance = [DatedPortfolioPerformance]()
        guard let earliestTransaction = portfolio.earliestTransaction else { return }
        let dates = dateRangeUntilToday(from: earliestTransaction.purchaseDate)

        for date in dates {
            let performanceForDate = try await performanceCalculator.performance(of: portfolio, on: date)
            datedPerformance.append(performanceForDate)
        }

        if let perf = portfolio.historicalPerformance {
            perf.datedPerformance = datedPerformance
            try await portfolioRepository.updateHistoricalPerformance(perf)
        } else {
            let historicalPerformance = HistoricalPortfolioPerformance(
                portfolioID: portfolio.id!,
                datedPerformance: datedPerformance
            )
            try await portfolioRepository.createHistoricalPerformance(historicalPerformance)
        }
    }

    private func dateRangeUntilToday(from startDate: Date) -> [YearMonthDayDate] {
        var dates: [YearMonthDayDate] = []
        var currentDate = startDate
        let calendar = Calendar.current
        let today = Date()


        while currentDate <= today {
            let ymdDate = YearMonthDayDate(currentDate)
            dates.append(ymdDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return dates
    }
}
