import Foundation

class TransactionChangedHandler: TransactionsControllerDelegate {
    private let portfolioRepository: PortfolioRepository
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let portfolioPerformanceUpdater: PortfolioPerformanceUpdating
    private let brokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating
    private let brokeragePerformanceUpdater: BrokeragePerformanceUpdating

    init(portfolioRepository: PortfolioRepository,
         brokerageAccountRepository: BrokerageAccountRepository,
         portfolioPerformanceUpdater: PortfolioPerformanceUpdating,
         brokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating,
         brokeragePerformanceUpdater: BrokeragePerformanceUpdating) {
        self.portfolioRepository = portfolioRepository
        self.brokerageAccountRepository = brokerageAccountRepository
        self.portfolioPerformanceUpdater = portfolioPerformanceUpdater
        self.brokerageAccountPerformanceUpdater = brokerageAccountPerformanceUpdater
        self.brokeragePerformanceUpdater = brokeragePerformanceUpdater
    }

    func transactionCreated(_ transaction: Transaction) async throws {
        let changeDate = YearMonthDayDate(transaction.purchaseDate)
        try await cascadeUpdate(for: transaction, from: changeDate)
    }

    func transactionDeleted(_ transaction: Transaction) async throws {
        let changeDate = YearMonthDayDate(transaction.purchaseDate)
        try await cascadeUpdate(for: transaction, from: changeDate)
    }

    private func cascadeUpdate(for transaction: Transaction, from date: YearMonthDayDate) async throws {
        // 1. Update Portfolio
        let portfolio = try await portfolioRepository.expandPortfolio(on: transaction)
        try await portfolioPerformanceUpdater.recalculatePerformance(of: portfolio, from: date)

        // 2. Update BrokerageAccount (if linked)
        guard let accountID = transaction.$brokerageAccount.id else { return }
        try await brokerageAccountPerformanceUpdater.recalculatePerformance(for: accountID, from: date)

        // 3. Update parent Brokerage
        guard let account = try await brokerageAccountRepository.account(for: accountID) else { return }
        try await brokeragePerformanceUpdater.recalculatePerformance(for: account.$brokerage.id, from: date)
    }
}
