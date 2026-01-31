@testable import Grodt
import Vapor

final class MockPortfolioService: PortfolioServicing, @unchecked Sendable {
    var allPortfoliosResult: Result<[PortfolioInfoDTO], Error> = .success([])
    var createResult: Result<PortfolioDTO, Error> = .success(PortfolioDTO.stub())
    var portfolioDetailResult: Result<PortfolioDTO, Error> = .success(PortfolioDTO.stub())
    var updateNameResult: Result<PortfolioDTO, Error> = .success(PortfolioDTO.stub())
    var deleteResult: Result<HTTPStatus, Error> = .success(.ok)
    var historicalPerformanceResult: Result<PerformanceTimeSeriesDTO, Error> = .success(PerformanceTimeSeriesDTO(values: []))

    func allPortfolios(userID: User.IDValue) async throws -> [PortfolioInfoDTO] {
        try allPortfoliosResult.get()
    }

    func create(request: CreatePortfolioRequestDTO, userID: User.IDValue) async throws -> PortfolioDTO {
        try createResult.get()
    }

    func portfolioDetail(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> PortfolioDTO {
        try portfolioDetailResult.get()
    }

    func updateName(with id: Portfolio.IDValue, forUser userID: User.IDValue, newName: String) async throws -> PortfolioDTO {
        try updateNameResult.get()
    }

    func delete(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> HTTPStatus {
        try deleteResult.get()
    }

    func historicalPerformance(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> PerformanceTimeSeriesDTO {
        try historicalPerformanceResult.get()
    }
}
