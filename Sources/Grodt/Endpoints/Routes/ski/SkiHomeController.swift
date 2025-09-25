import Vapor
import Fluent

class SkiHomeController: RouteCollection {
    private let portfolioService: PortfolioService
    private let accountService: AccountService
    private let brokerageService: BrokerageService
    private let investmentService: InvestmentService
    
    init(portfolioService: PortfolioService,
         accountService: AccountService,
         brokeragesService: BrokerageService,
         investmentService: InvestmentService) {
        self.portfolioService = portfolioService
        self.accountService = accountService
        self.brokerageService = brokeragesService
        self.investmentService = investmentService
    }
    
    func boot(routes: any Vapor.RoutesBuilder) throws {
        let home = routes.grouped("home")
        home.get(use: getHome)
    }
    
    private func getHome(req: Request) async throws -> SkiHomeResponseDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let portfolios = try await portfolioService.allPortfolios(userID: userID)
        let userInfo = try await accountService.userInfo(for: userID)
        let networth = try await totalPerformance(of: portfolios)
        let brokerages = try await brokerageService.allBrokerages(for: userID)
            .compactMap { BrokerageInfoDTO(id: $0.id,
                                           name: $0.name,
                                           value: $0.performance.moneyOut,
                                           currency: CurrencyDTO(code: "EUR", symbol: "€"),
                                           accountCount: $0.accounts.count)
            }
        let investments = try await investmentService.allInvestments(for: userID)
        
        let response = SkiHomeResponseDTO(user: userInfo,
                                          networth: networth,
                                          portfolios: portfolios,
                                          brokerages: brokerages,
                                          investments: investments)
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
