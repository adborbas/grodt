import Foundation
import CollectionConcurrencyKit

class PortfolioDTOMapper {
    private let investmentDTOMapper: InvestmentDTOMapper
    private let currencyDTOMapper: CurrencyDTOMapper
    private let performanceCalculator: PortfolioPerformanceCalculating
    
    init(investmentDTOMapper: InvestmentDTOMapper,
         currencyDTOMapper: CurrencyDTOMapper,
         performanceCalculator: PortfolioPerformanceCalculating) {
        self.investmentDTOMapper = investmentDTOMapper
        self.currencyDTOMapper = currencyDTOMapper
        self.performanceCalculator = performanceCalculator
    }
    
    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO {
        
        let investments = try await investmentDTOMapper.investments(from: portfolio.transactions)
        return try await  PortfolioDTO(id: portfolio.id?.uuidString ?? "",
                                       name: portfolio.name,
                                       currency: currencyDTOMapper.currency(from: portfolio.currency),
                                       performance: performance(for: portfolio),
                                       investments: investments)
    }
    
    func portfolioInfo(from portfolio: Portfolio) async throws -> PortfolioInfoDTO {
        
        return try await PortfolioInfoDTO(id: portfolio.id?.uuidString ?? "",
                                          name: portfolio.name,
                                          currency: currencyDTOMapper.currency(from: portfolio.currency),
                                          performance: performance(for: portfolio)
        )
    }
    
    func performance(for portfolio: Portfolio) async throws -> PortfolioPerformanceDTO {
        guard portfolio.$historicalPerformance.value != nil,
              let performance = portfolio.historicalPerformance?.datedPerformance.last else {
            return PortfolioPerformanceDTO(moneyIn: 0, moneyOut: 0, profit: 0, totalReturn: 0)
        }
        
        let financials = Financials()
            await financials.addMoneyIn(performance.moneyIn)
            await financials.addValue(performance.value)
            
            return PortfolioPerformanceDTO(
                moneyIn: await financials.moneyIn,
                moneyOut: await financials.value,
                profit: await financials.profit,
                totalReturn: await financials.totalReturn
            )
    }
    
    func timeSeriesPerformance(from historicalPerformance: HistoricalPortfolioPerformance) async -> PortfolioPerformanceTimeSeriesDTO {
        let values: [DatedPortfolioPerformanceDTO] = await historicalPerformance.$datedPerformance.wrappedValue.concurrentMap { datedPerformance in
            let financials = Financials()
            await financials.addMoneyIn(datedPerformance.moneyIn)
            await financials.addValue(datedPerformance.value)
            return await DatedPortfolioPerformanceDTO(date: datedPerformance.date.date,
                                                      moneyIn: financials.moneyIn,
                                                      moneyOut: financials.value,
                                                      profit: financials.profit,
                                                      totalReturn: financials.totalReturn)
            
        }.sorted { lhs, rhs in
            lhs.date < lhs.date
        }
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

fileprivate extension Decimal {
    func rounded(to scale: Int, roundingMode: NSDecimalNumber.RoundingMode = .bankers) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, roundingMode)
        return result
    }
}
