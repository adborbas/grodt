import Vapor
import Fluent

protocol PortfolioServicing: Sendable {
    func allPortfolios(userID: User.IDValue) async throws -> [PortfolioInfoDTO]
    func create(request: CreatePortfolioRequestDTO, userID: User.IDValue) async throws -> PortfolioDTO
    func portfolioDetail(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> PortfolioDTO
    func updateName(with id: Portfolio.IDValue, forUser userID: User.IDValue, newName: String) async throws -> PortfolioDTO
    func delete(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> HTTPStatus
    func historicalPerformance(for id: Portfolio.IDValue, userID: User.IDValue) async throws -> PerformanceTimeSeriesDTO
}

class PortfolioService: PortfolioServicing {
    private let portfolioRepository: PortfolioRepository
    private let portfolioDailyRepo: PortfolioDailyPerformanceReading
    private let currencyRepository: CurrencyRepository
    private let dataMapper: PortfolioDTOMapping

    init(portfolioRepository: PortfolioRepository,
         currencyRepository: CurrencyRepository,
         portfolioDailyRepo: PortfolioDailyPerformanceReading,
         dataMapper: PortfolioDTOMapping) {
        self.portfolioRepository = portfolioRepository
        self.currencyRepository = currencyRepository
        self.portfolioDailyRepo = portfolioDailyRepo
        self.dataMapper = dataMapper
    }
    
    func allPortfolios(userID: User.IDValue) async throws -> [PortfolioInfoDTO] {
        return try await portfolioRepository.allPortfolios(for: userID)
            .concurrentCompactMap { portfolio in
                return try await self.dataMapper.portfolioInfo(from: portfolio)
            }
    }
    
    func create(request: CreatePortfolioRequestDTO,
                userID: User.IDValue) async throws -> PortfolioDTO {
        
        guard let currency = try await currencyRepository.currency(for: request.currency) else {
            throw Abort(.badRequest)
        }
        
        let portfolio = Portfolio(userID: userID,
                                  name: request.name,
                                  currency: currency)
        
        let newPortfolio = try await portfolioRepository.create(portfolio)
        return try await dataMapper.portfolio(from: newPortfolio)
    }
    
    func portfolioDetail(for id: Portfolio.IDValue,
                         userID: User.IDValue) async throws -> PortfolioDTO {
        guard let portfolio = try await portfolioRepository.portfolio(for: userID, with: id) else {
            throw Abort(.notFound)
        }
        
        return try await dataMapper.portfolio(from: portfolio)
    }
    
    func updateName(with id: Portfolio.IDValue,
                    forUser userID: User.IDValue,
                    newName: String) async throws -> PortfolioDTO {
        guard let portfolio = try await portfolioRepository.portfolio(for: userID, with: id) else {
            throw Abort(.notFound)
        }
        
        portfolio.name = newName
        
        let updatedPortfolio = try await portfolioRepository.update(portfolio)
        return try await dataMapper.portfolio(from: updatedPortfolio)
    }
    
    func delete(for id: Portfolio.IDValue,
                userID: User.IDValue) async throws -> HTTPStatus {
        do {
            try await portfolioRepository.delete(for:  userID, with: id)
        } catch FluentError.noResults {
            return .ok
        }
        return .ok
    }
    
    func historicalPerformance(for id: Portfolio.IDValue,
                               userID: User.IDValue) async throws -> PerformanceTimeSeriesDTO {
        guard let _ = try await portfolioRepository.portfolio(for: userID, with: id) else {
            throw Abort(.notFound)
        }
        
        let series = try await portfolioDailyRepo.readSeries(for: id, from: nil, to: nil)
        return await dataMapper.timeSeriesPerformance(from: series)
    }
}

extension PortfolioDTO: ResponseDTO { }
extension PortfolioInfoDTO: ResponseDTO { }
extension PerformanceTimeSeriesDTO: ResponseDTO{ }
