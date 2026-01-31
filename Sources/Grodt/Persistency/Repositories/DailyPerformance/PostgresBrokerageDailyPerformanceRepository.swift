import Foundation
import Fluent
import SQLKit

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
                invested: point.invested,
                realized: point.realized,
                currentValue: point.currentValue
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
                row.invested = point.invested
                row.realized = point.realized
                row.currentValue = point.currentValue
                try await row.save(on: database)
            } else {
                let newRow = HistoricalBrokeragePerformanceDaily(
                    brokerageID: ownerID,
                    date: point.date.date,
                    invested: point.invested,
                    realized: point.realized,
                    currentValue: point.currentValue
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
        return rows.map {
            DatedPerformance(
                invested: $0.invested,
                realized: $0.realized,
                currentValue: $0.currentValue,
                date: YearMonthDayDate($0.date)
            )
        }
    }

    // Delete all rows for a brokerage.
    func deleteAll(for ownerID: UUID) async throws {
        try await HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == ownerID)
            .delete()
    }

    func batchUpsert(points: [DatedPerformance], for ownerID: UUID) async throws {
        guard !points.isEmpty else { return }
        guard let sql = database as? SQLDatabase else {
            try await upsert(points: points, for: ownerID)
            return
        }

        let batchSize = 100
        for batch in points.chunked(into: batchSize) {
            var values: [SQLQueryString] = []
            for point in batch {
                let dateStr = ISO8601DateFormatter().string(from: point.date.date)
                values.append("\(literal: UUID().uuidString), \(literal: ownerID.uuidString), \(literal: dateStr)::date, \(unsafeRaw: point.invested.description), \(unsafeRaw: point.realized.description), \(unsafeRaw: point.currentValue.description)")
            }

            let valuesList = SQLQueryString(values.map { "(\($0))" }.joined(separator: ", "))

            try await sql.raw("""
                INSERT INTO historical_brokerage_performance_daily (id, brokerage_id, date, invested, realized, current_value)
                VALUES \(valuesList)
                ON CONFLICT (brokerage_id, date)
                DO UPDATE SET invested = EXCLUDED.invested, realized = EXCLUDED.realized, current_value = EXCLUDED.current_value
                """).run()
        }
    }

    func deleteFrom(date: YearMonthDayDate, for ownerID: UUID) async throws {
        try await HistoricalBrokeragePerformanceDaily.query(on: database)
            .filter(\.$brokerage.$id == ownerID)
            .filter(\.$date >= date.date)
            .delete()
    }
}
