import Foundation

class TransactionChangedHandler: TransactionsControllerDelegate {
    private let portfolioRepository: PortfolioRepository
    private let historicalPerformanceUpdater: PortfolioHistoricalPerformanceUpdater
    
    init(portfolioRepository: PortfolioRepository,
         historicalPerformanceUpdater: PortfolioHistoricalPerformanceUpdater) {
        self.portfolioRepository = portfolioRepository
        self.historicalPerformanceUpdater = historicalPerformanceUpdater
    }
    
    func transactionCreated(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await historicalPerformanceUpdater.recalculateHistoricalPerformance(of: portfolio, since: startDateToUpdateTransactions(transaction))
    }
    
    func transactionDeleted(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await historicalPerformanceUpdater.recalculateHistoricalPerformance(of: portfolio, since: startDateToUpdateTransactions(transaction))
    }
    
    private func startDateToUpdateTransactions(_ transaction: Transaction) -> Date {
        let calender = Calendar.current
        return calender.date(byAdding: .day, value: -1, to: transaction.purchaseDate) ?? transaction.purchaseDate
    }
}
