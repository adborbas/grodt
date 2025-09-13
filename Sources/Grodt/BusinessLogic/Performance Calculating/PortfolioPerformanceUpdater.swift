import Foundation
import Fluent

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
    private let portfolioDailyRepo: PostgresPortfolioDailyPerformanceRepository

    init(userRepository: UserRepository,
         portfolioRepository: PortfolioRepository,
         tickerRepository: TickerRepository,
         quoteCache: QuoteCache,
         priceService: PriceService,
         performanceCalculator: HoldingsPerformanceCalculating,
         portfolioDailyRepo: PostgresPortfolioDailyPerformanceRepository) {
        self.userRepository = userRepository
        self.portfolioRepository = portfolioRepository
        self.tickerRepository = tickerRepository
        self.quoteCache = quoteCache
        self.priceService = priceService
        self.performanceCalculator = performanceCalculator
        self.portfolioDailyRepo = portfolioDailyRepo
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
        let transactions = portfolio.transactions

        // No transactions: clear daily rows and return
        guard !transactions.isEmpty else {
            try await portfolioDailyRepo.deleteAll(for: try portfolio.requireID())
            return
        }

        let earliestDate = transactions.min(by: { $0.purchaseDate < $1.purchaseDate })!.purchaseDate
        let start = YearMonthDayDate(earliestDate)
        let end = YearMonthDayDate(Date())

        let datedPerformance = try await performanceCalculator.performanceSeries(
            for: transactions,
            from: start,
            to: end
        )

        try await portfolioDailyRepo.replaceSeries(for: try portfolio.requireID(), with: datedPerformance)
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
