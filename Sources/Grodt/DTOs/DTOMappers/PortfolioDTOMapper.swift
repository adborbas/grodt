import Foundation
import CollectionConcurrencyKit

class PortfolioDTOMapper {
    private let investmentDTOMapper: InvestmentDTOMapper
    private let currencyDTOMapper: CurrencyDTOMapper
    private let transactionDTOMapper: TransactionDTOMapper
    
    init(investmentDTOMapper: InvestmentDTOMapper,
         transactionDTOMapper: TransactionDTOMapper,
         currencyDTOMapper: CurrencyDTOMapper) {
        self.investmentDTOMapper = investmentDTOMapper
        self.transactionDTOMapper = transactionDTOMapper
        self.currencyDTOMapper = currencyDTOMapper
    }
    
    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO {
        
        let investments = try await investmentDTOMapper.investments(from: portfolio.transactions)
        let transactions = try await portfolio.transactions.asyncMap { try await transactionDTOMapper.transaction(from: $0) }
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
    
    func performance(for portfolio: Portfolio) async throws -> PortfolioPerformanceDTO {
        // Expect the daily series to be eager-loaded by the caller. If it's not loaded, fall back to zeros.
        guard portfolio.$historicalDailyPerformance.value != nil,
              let latest = portfolio.historicalDailyPerformance.max(by: { $0.date < $1.date })
        else {
            return PortfolioPerformanceDTO(moneyIn: 0, moneyOut: 0, profit: 0, totalReturn: 0)
        }

        let moneyIn = latest.moneyIn
        let moneyOut = latest.value
        let profit = moneyOut - moneyIn
        let totalReturn: Decimal = moneyIn > 0 ? (profit / moneyIn).rounded(to: 2) : 0

        return PortfolioPerformanceDTO(
            moneyIn: moneyIn,
            moneyOut: moneyOut,
            profit: profit,
            totalReturn: totalReturn
        )
    }
    
    func timeSeriesPerformance(from series: [DatedPortfolioPerformance]) async -> PortfolioPerformanceTimeSeriesDTO {
        let values: [DatedPortfolioPerformanceDTO] = series
            .map { point in
                let moneyIn = point.moneyIn
                let moneyOut = point.value
                let profit = moneyOut - moneyIn
                let totalReturn: Decimal = moneyIn > 0 ? (profit / moneyIn).rounded(to: 2) : 0
                return DatedPortfolioPerformanceDTO(
                    date: point.date.date,
                    moneyIn: moneyIn,
                    moneyOut: moneyOut,
                    profit: profit,
                    totalReturn: totalReturn
                )
            }
            .sorted { $0.date < $1.date }

        return PortfolioPerformanceTimeSeriesDTO(values: values)
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
