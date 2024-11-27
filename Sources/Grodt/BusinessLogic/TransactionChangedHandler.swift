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
        try await historicalPerformanceUpdater.recalculateHistoricalPerformance(of: portfolio)
    }
    
    func transactionDeleted(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await historicalPerformanceUpdater.recalculateHistoricalPerformance(of: portfolio)
    }
}
