import Vapor
import Fluent

class PortfolioRoute: RouteCollection {
    private let service: PortfolioService
    
    init(service: PortfolioService) {
        self.service = service
    }
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolio")
        portfolios.post(use: create)
        
        portfolios.group(":id") { portfolio in
            portfolio.get(use: `get`)
            portfolio.patch(use: updateName)
            portfolio.delete(use: delete)
        }
    }
    
    private func get(req: Request) async throws -> PortfolioResponseDTO {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let portfolio = try await service.portfolioDetail(for: id,
                                                          userID: userID)
        let performance = try await service.historicalPerformance(for: id,
                                                                  userID: userID)
        
        return PortfolioResponseDTO(portfolio: portfolio,
                                    historicalPerformance: performance)
    }
    
    private func create(req: Request) async throws -> PortfolioDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let postPortfolio = try req.content.decode(CreatePortfolioRequestDTO.self)
        
        return try await service.create(request: postPortfolio, userID: userID)
    }
    
    private func updateName(req: Request) async throws -> PortfolioDTO {
        let id = try req.requiredID()
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let request = try req.content.decode(RenamePortfolioRequestDTO.self)
        
        return try await service.updateName(with: id,
                                            forUser: userID,
                                            newName: request.name)
    }
    
    private func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await service.delete(for: id, userID: userID)
    }
    
}
