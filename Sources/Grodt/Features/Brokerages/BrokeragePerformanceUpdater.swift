import Foundation
import Fluent

protocol BrokeragePerformanceUpdating {
    func updateAllBrokeragePerformance() async throws
    func recalculatePerformance(for brokerageID: UUID, from date: YearMonthDayDate) async throws
}

final class BrokeragePerformanceUpdater: BrokeragePerformanceUpdating {
    // MARK: - Dependencies
    private let userRepository: UserRepository
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let accountDailyRepository: PostgresBrokerageAccountDailyPerformanceRepository
    private let brokerageDailyRepository: PostgresBrokerageDailyPerformanceRepository

    // MARK: - Init
    init(userRepository: UserRepository,
         brokerageAccountRepository: BrokerageAccountRepository,
         accountDailyRepository: PostgresBrokerageAccountDailyPerformanceRepository,
         brokerageDailyRepository: PostgresBrokerageDailyPerformanceRepository) {
        self.userRepository = userRepository
        self.brokerageAccountRepository = brokerageAccountRepository
        self.accountDailyRepository = accountDailyRepository
        self.brokerageDailyRepository = brokerageDailyRepository
    }

    func updateAllBrokeragePerformance() async throws {
        let users = try await userRepository.allUsers()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for user in users {
                group.addTask {
                    try await self.updateAllBrokerages(for: user)
                }
            }
            try await group.waitForAll()
        }
    }

    private func updateAllBrokerages(for user: User) async throws {
        guard let userID = user.id else { return }

        // Load all accounts for the user once (avoid N+1)
        let accounts = try await brokerageAccountRepository.all(for: userID)

        // Group accounts by brokerage id
        var accountsByBrokerage: [UUID: [BrokerageAccount]] = [:]
        accountsByBrokerage.reserveCapacity(accounts.count)
        for account in accounts {
            let brokerageID = account.$brokerage.id
            accountsByBrokerage[brokerageID, default: []].append(account)
        }

        // Update each brokerage
        for (brokerageID, accounts) in accountsByBrokerage {
            try await updateSingleBrokerage(brokerageID, accounts: accounts)
        }
    }

    private func updateSingleBrokerage(_ brokerageID: UUID, accounts: [BrokerageAccount]) async throws {
        guard !accounts.isEmpty else {
            // No accounts → clear any stored series for this brokerage
            try await brokerageDailyRepository.deleteAll(for: brokerageID)
            return
        }

        // Read each account's full series and track the global date window
        var perAccountSeries: [[YearMonthDayDate: DatedPerformance]] = []
        perAccountSeries.reserveCapacity(accounts.count)

        var earliestDate: Date?
        for account in accounts {
            let accountID = try account.requireID()
            let series = try await accountDailyRepository.readSeries(for: accountID, from: nil, to: nil)
            if let firstDate = series.first?.date.date {
                earliestDate = min(earliestDate ?? firstDate, firstDate)
            }
            // Index by date for O(1) lookups during summation
            var map: [YearMonthDayDate: DatedPerformance] = [:]
            map.reserveCapacity(series.count)
            for point in series { map[point.date] = point }
            perAccountSeries.append(map)
        }

        // If no account has any data, clear and return
        guard let startDate = earliestDate else {
            try await brokerageDailyRepository.deleteAll(for: brokerageID)
            return
        }

        let start = YearMonthDayDate(startDate)
        let end = YearMonthDayDate(Date())
        let days = YearMonthDayDate.days(from: start, to: end)

        // Sum across accounts for each day
        var summed: [DatedPerformance] = []
        summed.reserveCapacity(days.count)

        for day in days {
            var invested: Decimal = 0
            var realized: Decimal = 0
            var currentValue: Decimal = 0
            for seriesMap in perAccountSeries {
                if let point = seriesMap[day] {
                    invested += point.invested
                    realized += point.realized
                    currentValue += point.currentValue
                }
            }
            summed.append(DatedPerformance(invested: invested, realized: realized, currentValue: currentValue, date: day))
        }

        // Replace the brokerage's series
        try await brokerageDailyRepository.replaceSeries(for: brokerageID, with: summed)
    }

    func recalculatePerformance(for brokerageID: UUID, from date: YearMonthDayDate) async throws {
        // Get all accounts for this brokerage
        let accounts = try await brokerageAccountRepository.accounts(for: brokerageID)

        guard !accounts.isEmpty else {
            try await brokerageDailyRepository.deleteAll(for: brokerageID)
            return
        }

        // Read each account's series from the specified date
        var perAccountSeries: [[YearMonthDayDate: DatedPerformance]] = []
        perAccountSeries.reserveCapacity(accounts.count)

        for account in accounts {
            let accountID = try account.requireID()
            let series = try await accountDailyRepository.readSeries(for: accountID, from: date, to: nil)
            var map: [YearMonthDayDate: DatedPerformance] = [:]
            map.reserveCapacity(series.count)
            for point in series { map[point.date] = point }
            perAccountSeries.append(map)
        }

        let end = YearMonthDayDate(Date())
        let days = YearMonthDayDate.days(from: date, to: end)

        // Sum across accounts for each day
        var summed: [DatedPerformance] = []
        summed.reserveCapacity(days.count)

        for day in days {
            var invested: Decimal = 0
            var realized: Decimal = 0
            var currentValue: Decimal = 0
            for seriesMap in perAccountSeries {
                if let point = seriesMap[day] {
                    invested += point.invested
                    realized += point.realized
                    currentValue += point.currentValue
                }
            }
            summed.append(DatedPerformance(invested: invested, realized: realized, currentValue: currentValue, date: day))
        }

        // Delete existing data from the date onwards and batch insert new data
        try await brokerageDailyRepository.deleteFrom(date: date, for: brokerageID)
        try await brokerageDailyRepository.batchUpsert(points: summed, for: brokerageID)
    }
}
