import Foundation

protocol PortfolioPerformanceCalculating {
    func performance(of portfolio: Portfolio, on date: YearMonthDayDate, priceCache: inout [String: Decimal]) async throws -> DatedPortfolioPerformance
}

class PortfolioPerformanceCalculator: PortfolioPerformanceCalculating {
    private let priceService: PriceService
    
    init(priceService: PriceService) {
        self.priceService = priceService
    }
    
    func performance(
        of portfolio: Portfolio,
        on date: YearMonthDayDate,
        priceCache: inout [String: Decimal]
    ) async throws -> DatedPortfolioPerformance {
        let transactionsUntilDate = portfolio.transactions.filter { YearMonthDayDate($0.purchaseDate) <= date }
        
        let financialsForDate = Financials()
        
        for transaction in transactionsUntilDate {
            let inAmount = transaction.numberOfShares * transaction.pricePerShareAtPurchase + transaction.fees
            await financialsForDate.addMoneyIn(inAmount)
            
            let price: Decimal
            if let cachedPrice = priceCache[transaction.ticker] {
                price = cachedPrice
            } else {
                price = try await self.priceService.price(for: transaction.ticker, on: date)
                priceCache[transaction.ticker] = price
            }
            
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
}
