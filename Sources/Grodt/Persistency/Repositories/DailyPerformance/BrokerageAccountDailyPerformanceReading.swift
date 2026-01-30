import Foundation

protocol BrokerageAccountDailyPerformanceReading: Sendable {
    func readSeries(for accountID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance]
}

extension PostgresBrokerageAccountDailyPerformanceRepository: BrokerageAccountDailyPerformanceReading { }
