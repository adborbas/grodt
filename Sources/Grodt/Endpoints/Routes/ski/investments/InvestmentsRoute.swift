import Vapor
import Fluent

class InvestmentRoute: RouteCollection {
    private let serivce: InvestmentService
    
    init(serivce: InvestmentService) {
        self.serivce = serivce
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let investments = routes.grouped("investments")
        investments.get(use: allInvestments)
        
        investments.group(":ticker") { investment in
            investment.get(use: invesetmentDetail)
        }
    }
    
    func allInvestments(req: Request) async throws -> [InvestmentDTO] {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await serivce.allInvestments(for: userID)
    }
    
    func invesetmentDetail(req: Request) async throws -> InvestmentDetailDTO {
        let ticker: String = try req.requiredParameter(named: "ticker")
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await serivce.investmentDetail(for: ticker, userID: userID)
    }
}

extension InvestmentDetailDTO: Content { }
extension InvestmentDTO: Content { }
