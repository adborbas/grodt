protocol TickerPriceUpdating {
    func updateAllTickerPrices() async throws
}

class TickerPriceUpdater: TickerPriceUpdating {
    private let tickerRepository: TickerRepository
    private let priceService: PriceService
    private let quoteCache: QuoteCache
    
    private let rateLimiter = RateLimiter(maxRequestsPerMinute: 5)
    
    init(tickerRepository: TickerRepository,
         quoteCache: QuoteCache,
         priceService: PriceService) {
        self.tickerRepository = tickerRepository
        self.quoteCache = quoteCache
        self.priceService = priceService
    }
    
    func updateAllTickerPrices() async throws {
        let allTickers = try await tickerRepository.allTickers()
        for ticker in allTickers {
            try await clearCache(for: ticker.symbol)
            
            print("\(#function) \(ticker.symbol)")
            await rateLimiter.waitIfNeeded()
            _ = try await priceService.historicalPrice(for: ticker.symbol)
            await rateLimiter.waitIfNeeded()
            _ = try await priceService.price(for: ticker.symbol)
        }
    }
    
    private func clearCache(for ticker: String) async throws {
        try await quoteCache.clearHistoricalQuote(for: ticker)
        try await quoteCache.clearQuote(for: ticker)
    }
}
