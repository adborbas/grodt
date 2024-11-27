import Foundation
import AlphaSwiftage

protocol PriceService {
    func price(for ticker: String) async throws -> Decimal
    func price(for ticker: String, on date: YearMonthDayDate) async throws -> Decimal
    func fetchAndCreateHistoricalPrices(for ticker: String) async throws -> HistoricalQuote
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
    
    func price(for ticker: String, on date: YearMonthDayDate) async throws -> Decimal {
        if date == YearMonthDayDate(Date()) {
            return try await price(for: ticker)
        }
    
        // Ensure the `await` is properly handled
        let quotes: HistoricalQuote
        if let storedQuotes = try await quoteRepository.historicalQuote(for: ticker) {
            quotes = storedQuotes
        } else {
            quotes = try await fetchAndCreateHistoricalPrices(for: ticker)
        }
        
        var quote = quotes.datedQuotes.first(where: { $0.date == date })
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.universalGMT
        var dateToCheck = date

        for _ in 0..<7 {
            if quote != nil {
                break
            }
            dateToCheck = YearMonthDayDate(calendar.date(byAdding: .day, value: -1, to: dateToCheck.date)!)
            quote = quotes.datedQuotes.first(where: { $0.date == dateToCheck })
        }
        return quote!.price
    }
    
    private func liveHistoricalPrices(for ticker: String) async throws -> [DatedQuote] {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.universalGMT
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let result = await alphavantage.dailyAdjustedTimeSeries(for: ticker, outputSize: .full)
        switch result {
        case .success(let quotes):
            return quotes.compactMap { dateString, equityDailyData in
                guard let date = dateFormatter.date(from: dateString) else { return nil}
                return DatedQuote(price: equityDailyData.adjustedClose, date: YearMonthDayDate(date))
            }
        case .failure(let error):
            throw error
        }
    }
    
    private func fetchAndCreatePrice(for ticker: String) async throws -> Decimal {
        let quote = try await latestQuote(for: ticker)
        let newQuote = Quote(symbol: ticker,
                             price: quote.price,
                             lastUpdate: Date())
        
        try await quoteRepository.create(newQuote)
        return newQuote.price
    }
    
    func fetchAndCreateHistoricalPrices(for ticker: String) async throws -> HistoricalQuote {
        let quotes = try await liveHistoricalPrices(for: ticker)
        let historicalQuote = HistoricalQuote(symbol: ticker, datedQuotes: quotes)
        try await quoteRepository.create(historicalQuote)
        
        if let previousQuote = try await quoteRepository.historicalQuote(for: ticker) {
            try await quoteRepository.delete(previousQuote)
        }
        
        return historicalQuote
    }
    
    private func fetchAndUpdatePrice(for outdatedQuote: Quote) async throws -> Decimal {
        let quote = try await latestQuote(for: outdatedQuote.symbol)
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
    
    private func latestQuote(for ticker: String) async throws -> AlphaSwiftage.Quote {
        let result = await alphavantage.quote(for: ticker)
        switch result {
        case .success(let quote):
            return quote
        case .failure(let error):
            throw error
        }
    }
}
