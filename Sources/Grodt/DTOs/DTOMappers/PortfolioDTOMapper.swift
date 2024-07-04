import Foundation
import CollectionConcurrencyKit

class PortfolioDTOMapper {
    private let transactionDTOMapper: TransactionDTOMapper
    private let currencyDTOMapper: CurrencyDTOMapper
    private let priceService: PriceService
    
    init(transactionDTOMapper: TransactionDTOMapper,
         currencyDTOMapper: CurrencyDTOMapper,
         quoteService: PriceService) {
        self.transactionDTOMapper = transactionDTOMapper
        self.currencyDTOMapper = currencyDTOMapper
        self.priceService = quoteService
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
        let financials = Financials()
        try await portfolio.transactions.concurrentForEach { transaction in
            let inAmount = transaction.numberOfShares * transaction.pricePerShareAtPurchase + transaction.fees
            await financials.addMoneyIn(inAmount)
            
            let outAmount = try await transaction.numberOfShares * self.priceService.price(for: transaction.ticker)
            await financials.addValue(outAmount)
        }
        
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
