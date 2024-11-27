import Foundation

protocol PortfolioPerformanceCalculating {
    func performance(of portfolio: Portfolio, on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance
}

class PortfolioPerformanceCalculator: PortfolioPerformanceCalculating {
    private let priceService: PriceService
    
    init(priceService: PriceService) {
        self.priceService = priceService
    }
    
    func performance(of portfolio: Portfolio, on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance {
        let transactionsUntilDate = portfolio.transactions.filter { YearMonthDayDate($0.purchaseDate) <= date }
        
        let financialsForDate = Financials()
        for transaction in transactionsUntilDate {
            let inAmount = transaction.numberOfShares * transaction.pricePerShareAtPurchase + transaction.fees
            await financialsForDate.addMoneyIn(inAmount)
            
            let value = try await transaction.numberOfShares * self.priceService.price(for: transaction.ticker, on: date)
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
