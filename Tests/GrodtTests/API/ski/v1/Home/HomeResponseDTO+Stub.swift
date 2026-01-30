@testable import Grodt
import Foundation

extension HomeResponseDTO {
    static func stub(
        user: UserInfoDTO = .stub(),
        networth: PerformanceDTO = .zero,
        portfolios: [PortfolioInfoDTO] = [],
        brokerages: [BrokerageInfoDTO] = [],
        investments: [InvestmentDTO] = []
    ) -> HomeResponseDTO {
        HomeResponseDTO(
            user: user,
            networth: networth,
            portfolios: portfolios,
            brokerages: brokerages,
            investments: investments
        )
    }
}

extension PortfolioInfoDTO {
    static func stub(
        id: String = UUID().uuidString,
        name: String = "Test Portfolio",
        currency: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€"),
        performance: PerformanceDTO = .zero
    ) -> PortfolioInfoDTO {
        PortfolioInfoDTO(
            id: id,
            name: name,
            currency: currency,
            performance: performance
        )
    }
}

extension BrokerageInfoDTO {
    static func stub(
        id: UUID = UUID(),
        name: String = "Test Brokerage",
        value: Decimal = 0,
        currency: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€"),
        accountCount: Int = 0
    ) -> BrokerageInfoDTO {
        BrokerageInfoDTO(
            id: id,
            name: name,
            value: value,
            currency: currency,
            accountCount: accountCount
        )
    }
}

extension InvestmentDTO {
    static func stub(
        name: String = "Test Investment",
        shortName: String = "TST",
        avgBuyPrice: Decimal = 100,
        latestPrice: Decimal = 110,
        totalReturn: Decimal = 0.1,
        profit: Decimal = 10,
        currentValue: Decimal = 110,
        numberOfShares: Decimal = 1,
        currency: CurrencyDTO = CurrencyDTO(code: "EUR", symbol: "€")
    ) -> InvestmentDTO {
        InvestmentDTO(
            name: name,
            shortName: shortName,
            avgBuyPrice: avgBuyPrice,
            latestPrice: latestPrice,
            totalReturn: totalReturn,
            profit: profit,
            currentValue: currentValue,
            numberOfShares: numberOfShares,
            currency: currency
        )
    }
}
