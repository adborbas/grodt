import Foundation

protocol PortfolioHistoricalPerformanceUpdater {
    func recalculatePerformance(of portfolio: Portfolio) async throws
    func updatePerformanceOfAllPortfolios() async throws
}

class PortfolioPerformanceUpdater: PortfolioHistoricalPerformanceUpdater {
    private let userRepository: UserRepository
    private let portfolioRepository: PortfolioRepository
    private let tickerRepository: TickerRepository
    private let quoteCache: QuoteCache
    private let priceService: PriceService
    private let performanceCalculator: PortfolioPerformanceCalculating
    
    private let rateLimiter = RateLimiter(maxRequestsPerMinute: 5)

    init(userRepository: UserRepository,
         portfolioRepository: PortfolioRepository,
         tickerRepository: TickerRepository,
         quoteCache: QuoteCache,
         priceService: PriceService,
         performanceCalculator: PortfolioPerformanceCalculating) {
        self.userRepository = userRepository
        self.portfolioRepository = portfolioRepository
        self.tickerRepository = tickerRepository
        self.quoteCache = quoteCache
        self.priceService = priceService
        self.performanceCalculator = performanceCalculator
    }

    func updatePerformanceOfAllPortfolios() async throws {
        try await updateAllTickerPrices()
        try await updateHistotrycalPerformances()
    }

    func recalculatePerformance(of portfolio: Portfolio) async throws {
        var datedPerformance = [DatedPortfolioPerformance]()
        let startDate: Date = {
            guard let earliestTransaction = portfolio.earliestTransaction else { return Date() }
            return earliestTransaction.purchaseDate
        }()
        
        let dictCache = DictionaryInMemoryTickerPriceCache()
        for transaction in portfolio.transactions {
            if let storedQuotes = try await quoteCache.historicalQuote(for: transaction.ticker) {
                storedQuotes.datedQuotes.forEach { datedQuote in
                    dictCache.setPrice(datedQuote.price, for: transaction.ticker, on: datedQuote.date)
                }
            }
        }
        
        let dates = dateRangeUntilToday(from: startDate)
        for date in dates {
            let performanceForDate = try await performanceCalculator.performance(of: portfolio,
                                                                                 on: date,
                                                                                 using: dictCache)
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
    
    private func updateAllTickerPrices() async throws{
        let allTickers = try await tickerRepository.allTickers()
        for ticker in allTickers {
            try await clearCache(for: ticker.symbol)
            
            await rateLimiter.waitIfNeeded()
            _ = try await priceService.historicalPrice(for: ticker.symbol)
            await rateLimiter.waitIfNeeded()
            _ = try await priceService.price(for: ticker.symbol)
        }
    }
    
    private func updateHistotrycalPerformances() async throws {
        let users = try await userRepository.allUsers()
        for user in users {
            let allPortfolios = try await portfolioRepository.allPortfolios(for: user.id!)
            for portfolio in allPortfolios {
                try await recalculatePerformance(of: portfolio)
            }
        }
    }
    
    private func clearCache(for ticker: String) async throws {
        try await quoteCache.clearHistoricalQuote(for: ticker)
        try await quoteCache.clearQuote(for: ticker)
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
