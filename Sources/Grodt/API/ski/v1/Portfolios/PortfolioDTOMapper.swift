import Foundation
import CollectionConcurrencyKit

class PortfolioDTOMapper: PortfolioDTOMapping {
    private let investmentDTOMapper: InvestmentDTOMapper
    private let currencyDTOMapper: CurrencyDTOMapper
    private let transactionDTOMapper: TransactionDTOMapper
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    
    init(investmentDTOMapper: InvestmentDTOMapper,
         transactionDTOMapper: TransactionDTOMapper,
         performanceDTOMapper: DatedPerformanceDTOMapper,
         currencyDTOMapper: CurrencyDTOMapper) {
        self.investmentDTOMapper = investmentDTOMapper
        self.transactionDTOMapper = transactionDTOMapper
        self.performanceDTOMapper = performanceDTOMapper
        self.currencyDTOMapper = currencyDTOMapper
    }
    
    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO {
        
        let investments = try await investmentDTOMapper.investments(from: portfolio.transactions)
        let transactions = try await portfolio.transactions
            .sorted { $0.transactionDate > $1.transactionDate }
            .asyncMap { try await transactionDTOMapper.transaction(from: $0) }
        return try await  PortfolioDTO(id: portfolio.id?.uuidString ?? "",
                                       name: portfolio.name,
                                       currency: currencyDTOMapper.currency(from: portfolio.currency),
                                       performance: performance(for: portfolio),
                                       investments: investments,
                                       transactions: transactions)
    }
    
    func portfolioInfo(from portfolio: Portfolio) async throws -> PortfolioInfoDTO {
        
        return try await PortfolioInfoDTO(id: portfolio.id?.uuidString ?? "",
                                          name: portfolio.name,
                                          currency: currencyDTOMapper.currency(from: portfolio.currency),
                                          performance: performance(for: portfolio)
        )
    }
    
    func performance(for portfolio: Portfolio) async throws -> PerformanceDTO {
        // Expect the daily series to be eager-loaded by the caller. If it's not loaded, fall back to zeros.
        guard portfolio.$historicalDailyPerformance.value != nil,
              let latest = portfolio.historicalDailyPerformance.max(by: { $0.date < $1.date })
        else {
            return PerformanceDTO.zero
        }

        let invested = latest.invested
        let currentValue = latest.currentValue
        let profit = currentValue + latest.realized - invested
        let totalReturn: Decimal = invested > 0 ? (profit / invested).rounded(to: 2) : 0

        return PerformanceDTO(
            invested: invested,
            currentValue: currentValue,
            profit: profit,
            totalReturn: totalReturn
        )
    }
    
    func timeSeriesPerformance(from series: [DatedPerformance]) async -> PerformanceTimeSeriesDTO {
        let values =  series.map { performanceDTOMapper.performancePoint(from: $0)  }
            .sorted { $0.date < $1.date }
        
        return PerformanceTimeSeriesDTO(values: values)
    }
}

actor Financials {
    private(set) var moneyIn: Decimal = 0
    private(set) var value: Decimal = 0
    
    func addMoneyIn(_ amount: Decimal) async {
        guard amount > 0 else { return }
        moneyIn += amount
    }
    
    func addValue(_ amount: Decimal) async {
        guard amount > 0 else { return }
        value += amount
    }
    
    var profit: Decimal {
        value - moneyIn
    }
    
    var totalReturn: Decimal {
        guard moneyIn > 0 else { return 0 }
        return (profit / moneyIn).rounded(to: 2)
    }
}

extension Decimal {
    func rounded(to scale: Int, roundingMode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, roundingMode)
        return result
    }
}
