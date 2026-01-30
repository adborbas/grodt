@testable import Grodt
import Testing
import Foundation

struct TransactionChangedHandlerTests {

    // MARK: - transactionCreated

    @Test func transactionCreated_updatesPortfolioPerformance() async throws {
        let portfolioID = UUID()
        let portfolio = Portfolio.stub(id: portfolioID)
        let transaction = Transaction.stub(portfolioID: portfolioID)

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.expandPortfolioResult = .success(portfolio)

        let mockBrokerageAccountRepo = MockBrokerageAccountRepository()
        let mockPortfolioUpdater = MockPortfolioPerformanceUpdater()
        let mockAccountUpdater = MockBrokerageAccountPerformanceUpdater()
        let mockBrokerageUpdater = MockBrokeragePerformanceUpdater()

        let handler = TransactionChangedHandler(
            portfolioRepository: mockPortfolioRepo,
            brokerageAccountRepository: mockBrokerageAccountRepo,
            portfolioPerformanceUpdater: mockPortfolioUpdater,
            brokerageAccountPerformanceUpdater: mockAccountUpdater,
            brokeragePerformanceUpdater: mockBrokerageUpdater
        )

        try await handler.transactionCreated(transaction)

        #expect(mockPortfolioUpdater.recalculateFromCalled)
        #expect(mockPortfolioUpdater.recalculatedPortfolio?.id == portfolioID)
        #expect(mockPortfolioUpdater.recalculateFromDate == YearMonthDayDate(transaction.transactionDate))
    }

    @Test func transactionCreated_withBrokerageAccount_cascadesToBrokerageAccountAndBrokerage() async throws {
        let portfolioID = UUID()
        let brokerageID = UUID()
        let accountID = UUID()

        let portfolio = Portfolio.stub(id: portfolioID)
        let account = BrokerageAccount.stub(id: accountID, brokerageID: brokerageID)
        let transaction = Transaction.stub(portfolioID: portfolioID, brokerageAccountID: accountID)

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.expandPortfolioResult = .success(portfolio)

        let mockBrokerageAccountRepo = MockBrokerageAccountRepository()
        mockBrokerageAccountRepo.findResult = .success(account)

        let mockPortfolioUpdater = MockPortfolioPerformanceUpdater()
        let mockAccountUpdater = MockBrokerageAccountPerformanceUpdater()
        let mockBrokerageUpdater = MockBrokeragePerformanceUpdater()

        let handler = TransactionChangedHandler(
            portfolioRepository: mockPortfolioRepo,
            brokerageAccountRepository: mockBrokerageAccountRepo,
            portfolioPerformanceUpdater: mockPortfolioUpdater,
            brokerageAccountPerformanceUpdater: mockAccountUpdater,
            brokeragePerformanceUpdater: mockBrokerageUpdater
        )

        try await handler.transactionCreated(transaction)

        // Portfolio updated
        #expect(mockPortfolioUpdater.recalculateFromCalled)
        #expect(mockPortfolioUpdater.recalculatedPortfolio?.id == portfolioID)

        // BrokerageAccount updated
        #expect(mockAccountUpdater.recalculateCalled)
        #expect(mockAccountUpdater.recalculateAccountID == accountID)
        #expect(mockAccountUpdater.recalculateFromDate == YearMonthDayDate(transaction.transactionDate))

        // Brokerage updated
        #expect(mockBrokerageUpdater.recalculateCalled)
        #expect(mockBrokerageUpdater.recalculateBrokerageID == brokerageID)
        #expect(mockBrokerageUpdater.recalculateFromDate == YearMonthDayDate(transaction.transactionDate))
    }

    @Test func transactionCreated_withoutBrokerageAccount_onlyUpdatesPortfolio() async throws {
        let portfolioID = UUID()
        let portfolio = Portfolio.stub(id: portfolioID)
        let transaction = Transaction.stub(portfolioID: portfolioID, brokerageAccountID: nil)

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.expandPortfolioResult = .success(portfolio)

        let mockBrokerageAccountRepo = MockBrokerageAccountRepository()
        let mockPortfolioUpdater = MockPortfolioPerformanceUpdater()
        let mockAccountUpdater = MockBrokerageAccountPerformanceUpdater()
        let mockBrokerageUpdater = MockBrokeragePerformanceUpdater()

        let handler = TransactionChangedHandler(
            portfolioRepository: mockPortfolioRepo,
            brokerageAccountRepository: mockBrokerageAccountRepo,
            portfolioPerformanceUpdater: mockPortfolioUpdater,
            brokerageAccountPerformanceUpdater: mockAccountUpdater,
            brokeragePerformanceUpdater: mockBrokerageUpdater
        )

        try await handler.transactionCreated(transaction)

        // Portfolio updated
        #expect(mockPortfolioUpdater.recalculateFromCalled)

        // BrokerageAccount NOT updated
        #expect(!mockAccountUpdater.recalculateCalled)

        // Brokerage NOT updated
        #expect(!mockBrokerageUpdater.recalculateCalled)
    }

    // MARK: - transactionDeleted

    @Test func transactionDeleted_cascadesUpdatesFromTransactionDate() async throws {
        let portfolioID = UUID()
        let brokerageID = UUID()
        let accountID = UUID()
        let transactionDate = Calendar.current.date(byAdding: .month, value: -3, to: Date())!

        let portfolio = Portfolio.stub(id: portfolioID)
        let account = BrokerageAccount.stub(id: accountID, brokerageID: brokerageID)
        let transaction = Transaction.stub(
            portfolioID: portfolioID,
            brokerageAccountID: accountID,
            transactionDate: transactionDate
        )

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.expandPortfolioResult = .success(portfolio)

        let mockBrokerageAccountRepo = MockBrokerageAccountRepository()
        mockBrokerageAccountRepo.findResult = .success(account)

        let mockPortfolioUpdater = MockPortfolioPerformanceUpdater()
        let mockAccountUpdater = MockBrokerageAccountPerformanceUpdater()
        let mockBrokerageUpdater = MockBrokeragePerformanceUpdater()

        let handler = TransactionChangedHandler(
            portfolioRepository: mockPortfolioRepo,
            brokerageAccountRepository: mockBrokerageAccountRepo,
            portfolioPerformanceUpdater: mockPortfolioUpdater,
            brokerageAccountPerformanceUpdater: mockAccountUpdater,
            brokeragePerformanceUpdater: mockBrokerageUpdater
        )

        try await handler.transactionDeleted(transaction)

        let expectedDate = YearMonthDayDate(transactionDate)

        // All updaters called with the transaction's purchase date
        #expect(mockPortfolioUpdater.recalculateFromDate == expectedDate)
        #expect(mockAccountUpdater.recalculateFromDate == expectedDate)
        #expect(mockBrokerageUpdater.recalculateFromDate == expectedDate)
    }
}
