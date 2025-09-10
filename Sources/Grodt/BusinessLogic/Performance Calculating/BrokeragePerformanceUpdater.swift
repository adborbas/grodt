import Foundation
import Vapor
import Fluent

protocol BrokeragePerformanceUpdating {
    func updateAllBrokeragePerformance() async throws
}

struct BrokeragePerformanceUpdater: BrokeragePerformanceUpdating {
    let db: Database

    func updateAllBrokeragePerformance() async throws {
        let today = YearMonthDayDate()
        
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
                .filter(\.$date == today.date)
                .all()

            let moneyIn = rows.reduce(Decimal(0)) { $0 + $1.moneyIn }
            let value = rows.reduce(Decimal(0)) { $0 + $1.value }

            // upsert
            try await HistoricalBrokeragePerformance.query(on: db)
                .filter(\.$brokerage.$id == brokerage.requireID())
                .filter(\.$date == today.date)
                .delete()

            let row = HistoricalBrokeragePerformance(brokerageID: try brokerage.requireID(),
                                                     date: today.date,
                                                     moneyIn: moneyIn,
                                                     value: value)
            try await row.save(on: db)
        }
    }
}
