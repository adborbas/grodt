@testable import Grodt
import Foundation

final class MockBrokerageAccountDailyPerformanceReading: BrokerageAccountDailyPerformanceReading, @unchecked Sendable {
    var readSeriesResult: Result<[DatedPerformance], Error> = .success([])

    func readSeries(for accountID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance] {
        try readSeriesResult.get()
    }
}
