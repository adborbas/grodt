import Vapor
import AlphaSwiftage
import Fluent
import CollectionConcurrencyKit

struct PortfoliosController: RouteCollection {
    private let service: PortfolioService
    
    init(service: PortfolioService) {
        self.service = service
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolios")
        portfolios.get(use: allPortfolios)
        portfolios.post(use: create)
        
        portfolios.group(":id") { portfolio in
            portfolio.get(use: portfolioDetail)
            portfolio.put(use: update)
            portfolio.delete(use: delete)
            
            portfolio.group("performance") { pref in
                pref.get(use: historicalPerformance)
            }
        }
    }
    
    func allPortfolios(req: Request) async throws -> [PortfolioInfoDTO] {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await service.allPortfolios(userID: userID)
    }
    
    func create(req: Request) async throws -> PortfolioDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let postPortfolio = try req.content.decode(CreatePortfolioRequestDTO.self)
        
        return try await service.create(request: postPortfolio, userID: userID)
    }
    
    func portfolioDetail(req: Request) async throws -> PortfolioDTO {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await service.portfolioDetail(for: id,
                                                 userID: userID)
    }
    
    func update(req: Request) async throws -> PortfolioDTO {
        let id = try req.requiredID()
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let updateDTO = try req.content.decode(UpdatePortfolioRequestDTO.self)
        
        return try await service.update(for: id,
                                        request: updateDTO,
                                        userID: userID)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await service.delete(for: id, userID: userID)
    }
    
    func historicalPerformance(req: Request) async throws -> PerformanceTimeSeriesDTO {
        let id = try req.requiredID()
        guard let userID = req.auth.get(User.self)?.id else { throw Abort(.badRequest) }
        
        return try await service.historicalPerformance(for: id, userID: userID)
    }
}
