import Queues
import Fluent

protocol BrokerageAccountPerformanceUpdating {
    func updateAllBrokerageAccountPerformance() async throws
}

struct BrokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating {
    let db: Database
    let priceService: PriceService

    func updateAllBrokerageAccountPerformance() async throws {
        let accounts = try await BrokerageAccount.query(on: db).all()
        let calculator = HoldingsPerformanceCalculator(priceService: priceService)

        for account in accounts {
            let transacitons = try await account.$transactions.query(on: db).all()
            guard let earliest = transacitons.map({ $0.purchaseDate }).min().map(YearMonthDayDate.init) else {
                // No transactions: clear existing rows and continue
                try await HistoricalBrokerageAccountPerformance.query(on: db)
                    .filter(\.$account.$id == account.requireID())
                    .delete()
                continue
            }

            let series = try await calculator.performanceSeries(for: transacitons, from: earliest, to: YearMonthDayDate())

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
