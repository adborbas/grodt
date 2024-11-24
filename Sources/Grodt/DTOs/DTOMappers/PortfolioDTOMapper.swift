import Foundation
import CollectionConcurrencyKit

class PortfolioDTOMapper {
    private let transactionDTOMapper: TransactionDTOMapper
    private let currencyDTOMapper: CurrencyDTOMapper
    private let performanceCalculator: PortfolioPerformanceCalculating
    
    init(transactionDTOMapper: TransactionDTOMapper,
         currencyDTOMapper: CurrencyDTOMapper,
         performanceCalculator: PortfolioPerformanceCalculating) {
        self.transactionDTOMapper = transactionDTOMapper
        self.currencyDTOMapper = currencyDTOMapper
        self.performanceCalculator = performanceCalculator
    }
    
    func portfolio(from portfolio: Portfolio) async throws -> PortfolioDTO {
        
        return try await  PortfolioDTO(id: portfolio.id?.uuidString ?? "",
                                       name: portfolio.name,
                                       currency: currencyDTOMapper.currency(from: portfolio.currency),
                                       performance: performance(for: portfolio),
                                       transactions: portfolio.transactions
            .sorted(by: { lhs, rhs in
                return lhs.purchaseDate > rhs.purchaseDate
            })
                .compactMap { transactionDTOMapper.transaction(from: $0) }
        )
    }
    
    func portfolioInfo(from portfolio: Portfolio) async throws -> PortfolioInfoDTO {
        
        return try await PortfolioInfoDTO(id: portfolio.id?.uuidString ?? "",
                                          name: portfolio.name,
                                          currency: currencyDTOMapper.currency(from: portfolio.currency),
                                          performance: performance(for: portfolio),
                                          transactions: portfolio.transactions.compactMap { $0.id?.uuidString }
        )
    }
    
    func performance(for portfolio: Portfolio) async throws -> PortfolioPerformanceDTO {
        guard let performance = portfolio.historicalPerformance?.datedPerformance.last else {
            return PortfolioPerformanceDTO(moneyIn: 0, moneyOut: 0, profit: 0, totalReturn: 0)
        }
        
        let financials = Financials()
        await financials.addMoneyIn(performance.moneyIn)
        await financials.addValue(performance.value)
        
        return await PortfolioPerformanceDTO(moneyIn: financials.moneyIn, moneyOut: financials.value, profit: financials.profit, totalReturn: financials.totalReturn)
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
    var moneyIn: Decimal = 0
    var value: Decimal = 0
    
    func addMoneyIn(_ amount: Decimal) {
        moneyIn += amount
    }
    
    func addValue(_ amount: Decimal) {
        value += amount
    }
    
    var profit: Decimal {
        return value - moneyIn
    }
    
    var totalReturn: Decimal {
        return moneyIn == 0 ? 0 : profit / moneyIn
    }
}
