import Foundation

protocol PortfolioPerformanceUpdating {
    func recalculatePerformance(of portfolio: Portfolio) async throws
    func updateAllPortfolioPerformance() async throws
}

class PortfolioPerformanceUpdater: PortfolioPerformanceUpdating {
    private let userRepository: UserRepository
    private let portfolioRepository: PortfolioRepository
    private let tickerRepository: TickerRepository
    private let quoteCache: QuoteCache
    private let priceService: PriceService
    private let performanceCalculator: HoldingsPerformanceCalculating
    
    private let rateLimiter = RateLimiter(maxRequestsPerMinute: 5)

    init(userRepository: UserRepository,
         portfolioRepository: PortfolioRepository,
         tickerRepository: TickerRepository,
         quoteCache: QuoteCache,
         priceService: PriceService,
         performanceCalculator: HoldingsPerformanceCalculating) {
        self.userRepository = userRepository
        self.portfolioRepository = portfolioRepository
        self.tickerRepository = tickerRepository
        self.quoteCache = quoteCache
        self.priceService = priceService
        self.performanceCalculator = performanceCalculator
    }

    func updateAllPortfolioPerformance() async throws {
        let users = try await userRepository.allUsers()
        for user in users {
            let allPortfolios = try await portfolioRepository.allPortfolios(for: user.id!)
            for portfolio in allPortfolios {
                try await recalculatePerformance(of: portfolio)
            }
        }
    }

    func recalculatePerformance(of portfolio: Portfolio) async throws {
        // If there are no transactions, clear out any existing history and exit.
        let transactions = portfolio.transactions
        guard !transactions.isEmpty else {
            if let existing = portfolio.historicalPerformance {
                existing.datedPerformance = []
                try await portfolioRepository.updateHistoricalPerformance(existing)
            }
            return
        }

        // Determine inclusive date window: earliest purchase date ... today
        let earliestDate = transactions.min(by: { $0.purchaseDate < $1.purchaseDate })!.purchaseDate
        let start = YearMonthDayDate(earliestDate)
        let end = YearMonthDayDate(Date())

        // Use the calculator to build the full daily series
        let datedPerformance = try await performanceCalculator.performanceSeries(
            for: transactions,
            from: start,
            to: end
        )

        // Persist
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
