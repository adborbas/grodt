@testable import Grodt
import Foundation

final class MockPortfolioDTOMapper: PortfolioDTOMapping, @unchecked Sendable {
    var portfolioResult: Result<PortfolioDTO, Error> = .success(PortfolioDTO.stub())
    var portfolioInfoResult: Result<PortfolioInfoDTO, Error> = .success(PortfolioInfoDTO.stub())
    var timeSeriesPerformanceResult: PerformanceTimeSeriesDTO = PerformanceTimeSeriesDTO(values: [])

    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO {
        try portfolioResult.get()
    }

    func portfolioInfo(from portfolio: Portfolio) async throws -> PortfolioInfoDTO {
        try portfolioInfoResult.get()
    }

    func timeSeriesPerformance(from series: [DatedPerformance]) async -> PerformanceTimeSeriesDTO {
        timeSeriesPerformanceResult
    }
}
