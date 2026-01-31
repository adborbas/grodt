@testable import Grodt
import Foundation

final class MockPortfolioDailyPerformanceReading: PortfolioDailyPerformanceReading, @unchecked Sendable {
    var readSeriesResult: Result<[DatedPerformance], Error> = .success([])

    func readSeries(for portfolioID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance] {
        try readSeriesResult.get()
    }
}
