@testable import Grodt
import Foundation

enum TestConstant {
    enum PortfolioInfoDTOs {
        static let new = PortfolioInfoDTO(id: UUID().uuidString,
                                          name: "New",
                                          currency: Currencies.eur.dto,
                                          performance: PerformanceDTOs.zero,
                                          transactions: [])
    }
    
    enum PortfolioDTOs {
        static let new = PortfolioDTO(id: UUID().uuidString,
                               name: "New",
                               currency: Currencies.eur.dto,
                               performance: PerformanceDTOs.zero,
                               transactions: [])
    }
    
    enum PerformanceDTOs {
        static let zero = PerformanceDTO(moneyIn: 0, moneyOut: 0, profit: 0, totalReturn: 0)
    }
    
    enum Currencies {
        static let eur = Currency(code: "EUR", symbol: "€")
    }
}

extension Currency {
    var dto: CurrencyDTO {
        return CurrencyDTO(code: code, symbol: symbol)
    }
}

extension CurrencyDTO {
    var model: Currency {
        return Currency(code: code, symbol: symbol)
    }
}
