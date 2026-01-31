import Foundation
import Fluent
import SQLKit

struct PostgresPortfolioDailyPerformanceRepository: DailyPerformanceRepository {
    typealias OwnerID = UUID

    let db: Database

    func replaceSeries(for ownerID: UUID, with points: [DatedPerformance]) async throws {
        try await deleteAll(for: ownerID)
        guard !points.isEmpty else { return }

        for point in points {
            let row = HistoricalPortfolioPerformanceDaily(
                portfolioID: ownerID,
                date: point.date.date,
                invested: point.invested,
                realized: point.realized,
                currentValue: point.currentValue
            )
            try await row.save(on: db)
        }
    }

    func upsert(points: [DatedPerformance], for ownerID: UUID) async throws {
        guard !points.isEmpty else { return }

        // Bound the lookup to a compact date range for efficiency
        let minDate = points.map { $0.date.date }.min()!
        let maxDate = points.map { $0.date.date }.max()!

        let existing = try await HistoricalPortfolioPerformanceDaily.query(on: db)
            .filter(\.$portfolio.$id == ownerID)
            .filter(\.$date >= minDate)
            .filter(\.$date <= maxDate)
            .all()

        var existingByDate: [Date: HistoricalPortfolioPerformanceDaily] = [:]
        existingByDate.reserveCapacity(existing.count)
        for row in existing { existingByDate[row.date] = row }

        for point in points {
            if let row = existingByDate[point.date.date] {
                row.invested = point.invested
                row.realized = point.realized
                row.currentValue = point.currentValue
                try await row.save(on: db)
            } else {
                let newRow = HistoricalPortfolioPerformanceDaily(
                    portfolioID: ownerID,
                    date: point.date.date,
                    invested: point.invested,
                    realized: point.realized,
                    currentValue: point.currentValue
                )
                try await newRow.save(on: db)
            }
        }
    }

    func readSeries(for ownerID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance] {
        var query = HistoricalPortfolioPerformanceDaily.query(on: db)
            .filter(\.$portfolio.$id == ownerID)
            .sort(HistoricalPortfolioPerformanceDaily.Keys.date, .ascending)

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

    // Delete all rows for a portfolio.
    func deleteAll(for ownerID: UUID) async throws {
        try await HistoricalPortfolioPerformanceDaily.query(on: db)
            .filter(\.$portfolio.$id == ownerID)
            .delete()
    }

    func batchUpsert(points: [DatedPerformance], for ownerID: UUID) async throws {
        guard !points.isEmpty else { return }
        guard let sql = db as? SQLDatabase else {
            // Fallback to regular upsert if not SQL database
            try await upsert(points: points, for: ownerID)
            return
        }

        // Process in batches of 100 to avoid overly large queries
        let batchSize = 100
        for batch in points.chunked(into: batchSize) {
            var values: [SQLQueryString] = []
            for point in batch {
                let dateStr = ISO8601DateFormatter().string(from: point.date.date)
                values.append("\(literal: UUID().uuidString), \(literal: ownerID.uuidString), \(literal: dateStr)::date, \(unsafeRaw: point.invested.description), \(unsafeRaw: point.realized.description), \(unsafeRaw: point.currentValue.description)")
            }

            let valuesList = SQLQueryString(values.map { "(\($0))" }.joined(separator: ", "))

            try await sql.raw("""
                INSERT INTO historical_portfolio_performance_daily (id, portfolio_id, date, invested, realized, current_value)
                VALUES \(valuesList)
                ON CONFLICT (portfolio_id, date)
                DO UPDATE SET invested = EXCLUDED.invested, realized = EXCLUDED.realized, current_value = EXCLUDED.current_value
                """).run()
        }
    }

    func deleteFrom(date: YearMonthDayDate, for ownerID: UUID) async throws {
        try await HistoricalPortfolioPerformanceDaily.query(on: db)
            .filter(\.$portfolio.$id == ownerID)
            .filter(\.$date >= date.date)
            .delete()
    }
}
