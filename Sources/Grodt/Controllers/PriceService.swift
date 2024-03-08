import Foundation
import AlphaSwiftage

protocol PriceService {
    func price(for ticker: String) async throws -> Decimal
}

class CachedPriceService: PriceService {
    private enum Constant {
        static let priceTTLInHours: Int = 24
    }
    
    private let quoteRepository: QuoteRepository
    private let alphavantage: AlphaVantageService
    
    init(quoteRepository: QuoteRepository,
         alphavantage: AlphaVantageService) {
        self.quoteRepository = quoteRepository
        self.alphavantage = alphavantage
    }
    
    func price(for ticker: String) async throws -> Decimal {
        let quote = try await quoteRepository.quote(for: ticker)
        if let quote = quote {
            if hasTTLPassed(for: quote) {
                return try await fetchAndUpdatePrice(for: quote)
            } else {
                return quote.price
            }
        }
        
        return try await fetchAndCreatePrice(for: ticker)
    }
    
    private func fetchAndCreatePrice(for ticker: String) async throws -> Decimal {
        let quote = try await quote(for: ticker)
        let newQuote = Quote(symbol: ticker,
                             price: quote.price,
                             lastUpdate: Date())
        
        try await quoteRepository.create(newQuote)
        return newQuote.price
    }
    
    private func fetchAndUpdatePrice(for outdatedQuote: Quote) async throws -> Decimal {
        let quote = try await quote(for: outdatedQuote.symbol)
        outdatedQuote.lastUpdate = Date()
        try await quoteRepository.update(outdatedQuote)
        return quote.price
    }
    
    private func hasTTLPassed(for quote: Quote) -> Bool {
        let currentDate = Date()
        let components = Calendar.current.dateComponents([.hour], from: quote.lastUpdate, to: currentDate)
        
        if let hours = components.hour, hours >= Constant.priceTTLInHours {
            return true
        }
        
        return false
    }
    
    private func quote(for ticker: String) async throws -> AlphaSwiftage.Quote {
        let result = await alphavantage.quote(for: ticker)
        switch result {
        case .success(let quote):
            return quote
        case .failure(let error):
            throw error
        }
    }
}
