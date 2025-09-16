import Foundation
import Fluent

struct PostgresBrokerageAccountDailyPerformanceRepository: DailyPerformanceRepository {
    typealias OwnerID = UUID
    
    let database: Database

    func replaceSeries(for ownerID: UUID, with points: [DatedPerformance]) async throws {
        try await deleteAll(for: ownerID)
        guard !points.isEmpty else { return }

        for point in points {
            let row = HistoricalBrokerageAccountPerformanceDaily(
                accountID: ownerID,
                date: point.date.date,
                moneyIn: point.moneyIn,
                value: point.value
            )
            try await row.save(on: database)
        }
    }

    func upsert(points: [DatedPerformance], for ownerID: UUID) async throws {
        guard !points.isEmpty else { return }

        let minDate = points.map { $0.date.date }.min()!
        let maxDate = points.map { $0.date.date }.max()!

        let existing = try await HistoricalBrokerageAccountPerformanceDaily.query(on: database)
            .filter(\.$account.$id == ownerID)
            .filter(\.$date >= minDate)
            .filter(\.$date <= maxDate)
            .all()

        var existingByDate: [Date: HistoricalBrokerageAccountPerformanceDaily] = [:]
        existingByDate.reserveCapacity(existing.count)
        for row in existing { existingByDate[row.date] = row }

        for point in points {
            if let row = existingByDate[point.date.date] {
                row.moneyIn = point.moneyIn
                row.value = point.value
                try await row.save(on: database)
            } else {
                let newRow = HistoricalBrokerageAccountPerformanceDaily(
                    accountID: ownerID,
                    date: point.date.date,
                    moneyIn: point.moneyIn,
                    value: point.value
                )
                try await newRow.save(on: database)
            }
        }
    }

    func readSeries(for ownerID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance] {
        var query = HistoricalBrokerageAccountPerformanceDaily.query(on: database)
            .filter(\.$account.$id == ownerID)
            .sort(HistoricalBrokerageAccountPerformanceDaily.Keys.date, .ascending)

        if let from { query = query.filter(\.$date >= from.date) }
        if let to { query = query.filter(\.$date <= to.date) }

        let rows = try await query.all()
        return rows.map { DatedPerformance(moneyIn: $0.moneyIn, value: $0.value, date: YearMonthDayDate($0.date)) }
    }

    func deleteAll(for ownerID: UUID) async throws {
        try await HistoricalBrokerageAccountPerformanceDaily.query(on: database)
            .filter(\.$account.$id == ownerID)
            .delete()
    }
}
