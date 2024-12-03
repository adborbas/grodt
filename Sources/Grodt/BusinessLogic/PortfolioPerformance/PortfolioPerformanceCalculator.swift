import Foundation

protocol PortfolioPerformanceCalculating {
    func performance(of portfolio: Portfolio,
                     on date: YearMonthDayDate,
                     using cache: InMemoryTickerPriceCache) async throws -> DatedPortfolioPerformance
}

class PortfolioPerformanceCalculator: PortfolioPerformanceCalculating {
    private let priceService: PriceService
    
    init(priceService: PriceService) {
        self.priceService = priceService
    }
    
    func performance(
        of portfolio: Portfolio,
        on date: YearMonthDayDate,
        using cache: InMemoryTickerPriceCache
    ) async throws -> DatedPortfolioPerformance {
        let transactionsUntilDate = portfolio.transactions.filter { YearMonthDayDate($0.purchaseDate) <= date }
        
        let financialsForDate = Financials()
        
        for transaction in transactionsUntilDate {
            let inAmount = transaction.numberOfShares * transaction.pricePerShareAtPurchase + transaction.fees
            await financialsForDate.addMoneyIn(inAmount)
            let price = try await self.price(for: transaction.ticker, on: date, using: cache)
            let value = transaction.numberOfShares * price
            await financialsForDate.addValue(value)
        }
        
        let performanceForDate = DatedPortfolioPerformance(
            moneyIn: await financialsForDate.moneyIn,
            value: await financialsForDate.value,
            date: date
        )
        return performanceForDate
    }
    
    private func price(for ticker: String,
                       on date: YearMonthDayDate,
                       using cache: InMemoryTickerPriceCache) async throws -> Decimal {
        if let cachedPrice = cache.price(for: ticker, on: date) {
            return cachedPrice
        }
        let price = try await computePrice(for: ticker, on: date, using: cache)
        cache.setPrice(price, for: ticker, on: date)
        return price
    }
    
    private func computePrice(for ticker: String,
                              on date: YearMonthDayDate,
                              using cache: InMemoryTickerPriceCache) async throws -> Decimal {
        if date == YearMonthDayDate(Date()) {
            return try await priceService.price(for: ticker)
        }
        
        var calendar = Calendar.current
        calendar.timeZone = TimeZone.universalGMT
        var quote: Decimal?
        var dateToCheck = date
        
        for _ in 0..<7 {
            if quote != nil {
                break
            }
            dateToCheck = YearMonthDayDate(calendar.date(byAdding: .day, value: -1, to: dateToCheck.date)!)
            quote = cache.price(for: ticker, on: dateToCheck)
        }
        
        // TODO: What to do if no price????
        return quote!
    }
}
