import Foundation
import Queues
import Fluent

protocol BrokerageAccountPerformanceUpdating {
    func updateAllBrokerageAccountPerformance() async throws
    func recalculatePerformance(for accountID: UUID, from date: YearMonthDayDate) async throws
}

class BrokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating {
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let transactionRepository: TransactionsRepository
    private let accountDailyRepository: PostgresBrokerageAccountDailyPerformanceRepository
    private let userRepository: UserRepository
    private let calculator: HoldingsPerformanceCalculating
    
    init(transactionRepository: TransactionsRepository,
         brokerageAccountRepository: BrokerageAccountRepository,
         accountDailyRepository: PostgresBrokerageAccountDailyPerformanceRepository,
         userRepository: UserRepository,
         calculator: HoldingsPerformanceCalculating) {
        self.transactionRepository = transactionRepository
        self.brokerageAccountRepository = brokerageAccountRepository
        self.accountDailyRepository = accountDailyRepository
        self.userRepository = userRepository
        self.calculator = calculator
    }

    func updateAllBrokerageAccountPerformance() async throws {
        let users = try await userRepository.allUsers()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for user in users {
                group.addTask {
                    try await self.updateAllAccounts(for: user)
                }
            }
            try await group.waitForAll()
        }
    }

    private func updateAllAccounts(for user: User) async throws {
        guard let userID = user.id else { return }

        let accounts = try await brokerageAccountRepository.all(for: userID)
        let userTransactions = try await transactionRepository.all(for: userID)

        for account in accounts {
            try await updateSingleAccount(account, with: userTransactions)
        }
    }

    private func updateSingleAccount(_ account: BrokerageAccount, with userTransactions: [Transaction]) async throws {
        let accountID = try account.requireID()

        // Keep only transactions linked to this account (explicit loop avoids any Fluent `filter` ambiguity)
        var accountTransactions: [Transaction] = []
        accountTransactions.reserveCapacity(userTransactions.count)
        for transaction in userTransactions {
            let linkedID = transaction.$brokerageAccount.id ?? transaction.brokerageAccount?.id
            if linkedID == accountID {
                accountTransactions.append(transaction)
            }
        }

        // No transactions → clear any stored series
        guard let earliest = accountTransactions.map(\.purchaseDate).min() else {
            try await accountDailyRepository.deleteAll(for: accountID)
            return
        }

        let start = YearMonthDayDate(earliest)
        let end = YearMonthDayDate(Date())

        let series = try await calculator.performanceSeries(
            for: accountTransactions,
            from: start,
            to: end
        )

        try await accountDailyRepository.replaceSeries(for: accountID, with: series)
    }

    func recalculatePerformance(for accountID: UUID, from date: YearMonthDayDate) async throws {
        let accountTransactions = try await transactionRepository.transactions(for: accountID)

        // No transactions → clear any stored series
        guard !accountTransactions.isEmpty else {
            try await accountDailyRepository.deleteAll(for: accountID)
            return
        }

        let end = YearMonthDayDate(Date())

        let series = try await calculator.performanceSeries(
            for: accountTransactions,
            from: date,
            to: end
        )

        // Delete existing data from the date onwards and batch insert new data
        try await accountDailyRepository.deleteFrom(date: date, for: accountID)
        try await accountDailyRepository.batchUpsert(points: series, for: accountID)
    }
}
