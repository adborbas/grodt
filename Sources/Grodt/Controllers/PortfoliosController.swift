import Vapor
import AlphaSwiftage
import Fluent
import CollectionConcurrencyKit

struct PortfoliosController: RouteCollection {
    private let portfolioRepository: PortfolioRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: PortfolioDTOMapper
    private let portfolioPerformanceUpdater: PortfolioHistoricalPerformanceUpdater
    
    init(portfolioRepository: PortfolioRepository,
         currencyRepository: CurrencyRepository,
         historicalPortfolioPerformanceUpdater: PortfolioHistoricalPerformanceUpdater,
         dataMapper: PortfolioDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.currencyRepository = currencyRepository
        self.portfolioPerformanceUpdater = historicalPortfolioPerformanceUpdater
        self.dataMapper = dataMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolios")
        portfolios.get(use: allPortfolios)
        portfolios.post(use: create)
        portfolios.get("update", use: updateHistorycalPerformance)
        
        portfolios.group(":id") { portfolio in
            portfolio.get(use: portfolioDetail)
            portfolio.delete(use: delete)
            
            portfolio.group("historicalPerformance") { pref in
                pref.get(use: historicalPerformance)
            }
        }
    }
    
    func allPortfolios(req: Request) async throws -> [PortfolioInfoDTO] {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await portfolioRepository.allPortfolios(for: userID)
            .concurrentCompactMap { portfolio in
                return try await dataMapper.portfolioInfo(from: portfolio)
            }
    }
    
    func create(req: Request) async throws -> PortfolioDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let postPortfolio = try req.content.decode(CreatePortfolioRequestDTO.self)
        guard let currency = try await currencyRepository.currency(for: postPortfolio.currency) else {
            throw Abort(.badRequest)
        }
        
        let portfolio = Portfolio(userID: userID,
                                  name: postPortfolio.name,
                                  currency: currency)
        
        let newPortfolio = try await portfolioRepository.create(portfolio)
        return try await dataMapper.portfolio(from: newPortfolio)
    }
    
    func portfolioDetail(req: Request) async throws -> PortfolioDTO {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        guard let portfolio = try await portfolioRepository.portfolio(for: userID, with: id) else {
            throw Abort(.notFound)
        }
        
        return try await dataMapper.portfolio(from: portfolio)
    }
    
    func updateHistorycalPerformance(req: Request) async throws -> HTTPStatus {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        do {
            try await portfolioPerformanceUpdater.updatePerformanceOfAllPortfolios()
        } catch  {
            return .internalServerError
        }
        
        return .ok
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        do {
            try await portfolioRepository.delete(for:  userID, with: id)
        } catch FluentError.noResults {
            return .ok
        }
        return .ok
    }
    
    func historicalPerformance(req: Request) async throws -> PortfolioPerformanceTimeSeriesDTO {
        let id = try req.requiredID()
        guard let _ = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let historicalPerformance = try await portfolioRepository.historicalPerformance(with: id)
        return await dataMapper.timeSeriesPerformance(from: historicalPerformance)
    }
}

extension PortfolioDTO: Content { }
extension PortfolioInfoDTO: Content { }
extension PortfolioPerformanceTimeSeriesDTO: Content { }
