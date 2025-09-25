import Vapor
import Fluent

class PortfolioRoute: RouteCollection {
    private let service: PortfolioService
    
    init(service: PortfolioService,) {
        self.service = service
    }
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolio")
        portfolios.group(":id") { portfolio in
            portfolio.get(use: `get`)
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
        
        return PortfolioResponseDTO(id: portfolio.id,
                                    name: portfolio.name,
                                    currency: portfolio.currency,
                                    performance: portfolio.performance,
                                    investments: portfolio.investments,
                                    historicalPerformance: performance)
    }
}
