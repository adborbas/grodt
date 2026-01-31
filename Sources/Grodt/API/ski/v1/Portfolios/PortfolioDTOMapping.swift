import Foundation

protocol PortfolioDTOMapping: Sendable {
    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO
    func portfolioInfo(from portfolio: Portfolio) async throws -> PortfolioInfoDTO
    func timeSeriesPerformance(from series: [DatedPerformance]) async -> PerformanceTimeSeriesDTO
}
