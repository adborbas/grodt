import Foundation
import Fluent

struct PostgresBrokerageDailyPerformanceRepository: DailyPerformanceRepository {
    typealias OwnerID = UUID
    
    let database: Database

    func replaceSeries(for ownerID: UUID, with points: [DatedPerformance]) async throws {
        try await deleteAll(for: ownerID)
        guard !points.isEmpty else { return }

        for point in points {
            let row = HistoricalBrokeragePerformanceDaily(
                brokerageID: ownerID,
                date: point.date.date,
                moneyIn: point.moneyIn,
                value: point.value
            )
            try await row.save(on: database)
        }
    }

    func upsert(points: [DatedPerformance], for ownerID: UUID) async throws {
        guard !points.isEmpty else { return }

        // Bound the lookup to a compact date range for efficiency
        let minDate = points.map { $0.date.date }.min()!
        let maxDate = points.map { $0.date.date }.max()!

        let existing = try await HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == ownerID)
            .filter(\.$date >= minDate)
            .filter(\.$date <= maxDate)
            .all()

        var existingByDate: [Date: HistoricalBrokeragePerformanceDaily] = [:]
        existingByDate.reserveCapacity(existing.count)
        for row in existing { existingByDate[row.date] = row }

        for point in points {
            if let row = existingByDate[point.date.date] {
                row.moneyIn = point.moneyIn
                row.value = point.value
                try await row.save(on: database)
            } else {
                let newRow = HistoricalBrokeragePerformanceDaily(
                    brokerageID: ownerID,
                    date: point.date.date,
                    moneyIn: point.moneyIn,
                    value: point.value
                )
                try await newRow.save(on: database)
            }
        }
    }

    func readSeries(for ownerID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance] {
        var query = HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == ownerID)
            .sort(HistoricalBrokeragePerformanceDaily.Keys.date, .ascending)

        if let from { query = query.filter(\.$date >= from.date) }
        if let to { query = query.filter(\.$date <= to.date) }

        let rows = try await query.all()
        return rows.map { DatedPerformance(moneyIn: $0.moneyIn, value: $0.value, date: YearMonthDayDate($0.date)) }
    }

    // Delete all rows for a brokerage.
    func deleteAll(for ownerID: UUID) async throws {
        try await HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == ownerID)
            .delete()
    }
}
