import Foundation

protocol PortfolioDailyPerformanceReading: Sendable {
    func readSeries(for portfolioID: UUID, from: YearMonthDayDate?, to: YearMonthDayDate?) async throws -> [DatedPerformance]
}

extension PostgresPortfolioDailyPerformanceRepository: PortfolioDailyPerformanceReading { }
