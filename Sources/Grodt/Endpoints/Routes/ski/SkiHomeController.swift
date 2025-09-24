import Vapor
import Fluent

class SkiHomeController: RouteCollection {
    private let portfolioService: PortfolioService
    private let accountService: AccountService
    
    init(portfolioService: PortfolioService,
         accountService: AccountService) {
        self.portfolioService = portfolioService
        self.accountService = accountService
    }
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let home = routes.grouped("home")
        home.get(use: getHome)
    }
    
    private func getHome(req: Request) async throws -> SkiHomeDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let portfolios = try await portfolioService.allPortfolios(userID: userID)
        let userInfo = try await accountService.userInfo(for: userID)
        let performance = try await totalPerformance(of: portfolios)
        
        let response = SkiHomeDTO(user: userInfo,
                                  performance: performance,
                                  portfolios: portfolios)
        return response
    }
    
    private func totalPerformance(of portfolios: [PortfolioInfoDTO]) async throws -> PerformanceDTO {
        
        let (moneyIn, moneyOut) = await portfolios
            .concurrentCompactMap {
                $0.performance
            }
            .reduce(into: (Decimal.zero, Decimal.zero)) { acc, p in
                acc.0 += p.moneyIn
                acc.1 += p.moneyOut
            }
        
        let profit = moneyOut - moneyIn
        let totalReturn: Decimal = moneyIn > 0 ? (profit / moneyIn).rounded(to: 2) : .zero
        
        return PerformanceDTO(
            moneyIn: moneyIn,
            moneyOut: moneyOut,
            profit: profit,
            totalReturn: totalReturn
        )
    }
}
