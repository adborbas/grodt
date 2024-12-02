import Foundation
import AlphaSwiftage

class CachedPriceService: PriceService {
    private enum Constant {
        static let priceTTLInHours: Int = 24
    }
    
    private let cache: QuoteCache
    private let priceService: PriceService
    
    init(priceService: PriceService,
         cache: QuoteCache) {
        self.priceService = priceService
        self.cache = cache
    }
    
    func price(for ticker: String) async throws -> Decimal {
        let quoteFromCache = try await cache.quote(for: ticker)
        if let quoteFromCache = quoteFromCache, !hasTTLPassed(for: quoteFromCache) {
            return quoteFromCache.price
        }
        
        let latestPrice = try await priceService.price(for: ticker)
        try await storeCachedPrice(for: quoteFromCache, to: latestPrice, for: ticker)
        return latestPrice
    }
    
    func historicalPrice(for ticker: String) async throws -> [DatedQuote] {
        let quotes: HistoricalQuote
        if let storedQuotes = try await cache.historicalQuote(for: ticker) {
            quotes = storedQuotes
        } else {
            let lastestPrices = try await priceService.historicalPrice(for: ticker)
            let historicalQuote = HistoricalQuote(symbol: ticker, datedQuotes: lastestPrices)
            try await cache.storeHistoricalQuote(historicalQuote)
            quotes = historicalQuote
        }
        return quotes.datedQuotes
        
    }
    
    private func storeCachedPrice(for outdatedQuote: Quote?,
                                           to newPrice: Decimal,
                                           for ticker: String) async throws {
        if let outdatedQuote {
            outdatedQuote.lastUpdate = Date()
            outdatedQuote.price = newPrice
            try await cache.storeQuote(outdatedQuote)
        } else {
            let newQuote = Quote(symbol: ticker,
                                 price: newPrice,
                                 lastUpdate: Date())
            try await cache.storeQuote(newQuote)
        }
    }
    
    private func hasTTLPassed(for quote: Quote) -> Bool {
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.hour], from: quote.lastUpdate, to: currentDate)
        
        if let hours = components.hour, hours >= Constant.priceTTLInHours {
            return true
        }
        
        return false
    }
}
