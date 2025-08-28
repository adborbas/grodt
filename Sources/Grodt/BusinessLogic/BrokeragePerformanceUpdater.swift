import Vapor
import Fluent

struct BrokeragePerformanceUpdater {
    let db: Database

    func recomputeAll(for date: YearMonthDayDate) async throws {
        // Sum across accounts using precomputed account rows for the same date
        let brokerages = try await Brokerage.query(on: db).all()
        for brokerage in brokerages {
            let accountIDs = try await BrokerageAccount.query(on: db)
                .filter(\.$brokerage.$id == brokerage.requireID())
                .all()
                .map { try $0.requireID() }

            guard !accountIDs.isEmpty else { continue }

            let rows = try await HistoricalBrokerageAccountPerformance.query(on: db)
                .filter(\.$account.$id ~~ accountIDs)
                .filter(\.$date == date.date)
                .all()

            let moneyIn = rows.reduce(Decimal(0)) { $0 + $1.moneyIn }
            let value = rows.reduce(Decimal(0)) { $0 + $1.value }

            // upsert
            try await HistoricalBrokeragePerformance.query(on: db)
                .filter(\.$brokerage.$id == brokerage.requireID())
                .filter(\.$date == date.date)
                .delete()

            let row = HistoricalBrokeragePerformance(brokerageID: try brokerage.requireID(),
                                                     date: date.date,
                                                     moneyIn: moneyIn,
                                                     value: value)
            try await row.save(on: db)
        }
    }
}


import Queues

struct BrokeragePerformanceUpdaterJob: AsyncScheduledJob, @unchecked Sendable {
    private let performanceUpdater: BrokeragePerformanceUpdater
    
    init(performanceUpdater: BrokeragePerformanceUpdater) {
        self.performanceUpdater = performanceUpdater
    }
    
    func run(context: Queues.QueueContext) async throws {
        try await performanceUpdater.recomputeAll(for: YearMonthDayDate(Date()))
    }
}
