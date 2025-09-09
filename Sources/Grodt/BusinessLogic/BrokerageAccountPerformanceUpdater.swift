import Queues
import Fluent

struct BrokerageAccountPerformanceUpdater {
    let db: Database
    let priceService: PriceService

    func recomputeAll(for date: YearMonthDayDate) async throws {
        let accounts = try await BrokerageAccount.query(on: db).all()
        let calculator = HoldingsPerformanceCalculator(priceService: priceService)

        for account in accounts {
            let txs = try await account.$transactions.query(on: db).all()
            guard let earliest = txs.map({ $0.purchaseDate }).min().map(YearMonthDayDate.init) else {
                // No transactions: clear existing rows and continue
                try await HistoricalBrokerageAccountPerformance.query(on: db)
                    .filter(\.$account.$id == account.requireID())
                    .delete()
                continue
            }

            let series = try await calculator.performanceSeries(for: txs, from: earliest, to: date)

            // Upsert strategy: replace entire series for this account
            try await HistoricalBrokerageAccountPerformance.query(on: db)
                .filter(\.$account.$id == account.requireID())
                .delete()

            for point in series {
                let row = HistoricalBrokerageAccountPerformance(accountID: try account.requireID(),
                                                                date: point.date.date,
                                                                moneyIn: point.moneyIn,
                                                                value: point.value)
                try await row.save(on: db)
            }
        }
    }
}

struct BrokerageAccountPerformanceUpdaterJob: AsyncScheduledJob, @unchecked Sendable {
    private let performanceUpdater: BrokerageAccountPerformanceUpdater
    
    init(performanceUpdater: BrokerageAccountPerformanceUpdater) {
        self.performanceUpdater = performanceUpdater
    }
    
    func run(context: Queues.QueueContext) async throws {
        try await performanceUpdater.recomputeAll(for: YearMonthDayDate(Date()))
    }
}
