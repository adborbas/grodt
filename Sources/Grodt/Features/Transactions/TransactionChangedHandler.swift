import Foundation

class TransactionChangedHandler: TransactionsControllerDelegate {
    private let portfolioRepository: PortfolioRepository
    private let historicalPerformanceUpdater: PortfolioPerformanceUpdating
    
    init(portfolioRepository: PortfolioRepository,
         historicalPerformanceUpdater: PortfolioPerformanceUpdating) {
        self.portfolioRepository = portfolioRepository
        self.historicalPerformanceUpdater = historicalPerformanceUpdater
    }
    
    func transactionCreated(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await historicalPerformanceUpdater.recalculatePerformance(of: portfolio)
    }
    
    func transactionDeleted(_ transaction: Transaction) async throws {
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await historicalPerformanceUpdater.recalculatePerformance(of: portfolio)
    }
}
