import Foundation

struct HomeService: HomeServicing {
    private let portfolioService: PortfolioServicing
    private let accountService: AccountServicing
    private let brokerageService: BrokerageServicing
    private let investmentService: InvestmentServicing

    init(portfolioService: PortfolioServicing,
         accountService: AccountServicing,
         brokerageService: BrokerageServicing,
         investmentService: InvestmentServicing) {
        self.portfolioService = portfolioService
        self.accountService = accountService
        self.brokerageService = brokerageService
        self.investmentService = investmentService
    }

    func home(for userID: User.IDValue) async throws -> HomeResponseDTO {
        let portfolios = try await portfolioService.allPortfolios(userID: userID)
        let userInfo = try await accountService.userInfo(for: userID)
        let networth = totalPerformance(of: portfolios)
        let brokerages = try await brokerageService.allBrokerages(for: userID)
            .compactMap { BrokerageInfoDTO(id: $0.id,
                                           name: $0.name,
                                           value: $0.performance.moneyOut,
                                           currency: CurrencyDTO(code: "EUR", symbol: "€"),
                                           accountCount: $0.accounts.count)
            }
        let investments = try await investmentService.allInvestments(for: userID)

        return HomeResponseDTO(user: userInfo,
                               networth: networth,
                               portfolios: portfolios,
                               brokerages: brokerages,
                               investments: investments)
    }

    private func totalPerformance(of portfolios: [PortfolioInfoDTO]) -> PerformanceDTO {
        let (moneyIn, moneyOut) = portfolios
            .compactMap { $0.performance }
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
