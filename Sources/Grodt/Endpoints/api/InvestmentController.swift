import Vapor
import Fluent

struct InvestmentController: RouteCollection {
    private let portfolioRepository: PortfolioRepository
    private let dataMapper: InvestmentDTOMapper
    
    init(portfolioRepository: PortfolioRepository,
         dataMapper: InvestmentDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.dataMapper = dataMapper
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
        
        let transactions = try await portfolioRepository.allPortfolios(for: userID)
            .flatMap { $0.transactions }
        
        return try await dataMapper.investments(from: transactions)
    }
    
    func invesetmentDetail(req: Request) async throws -> InvestmentDetailDTO {
        let ticker: String = try req.requiredParameter(named: "ticker")
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let portfolios = try await portfolioRepository.allPortfolios(for: userID)
        let transactions = portfolios
            .flatMap { $0.transactions }
            .filter { $0.ticker == ticker }
        return try await dataMapper.investmentDetail(from: transactions)
    }
}

extension InvestmentDetailDTO: Content { }
extension InvestmentDTO: Content { }
