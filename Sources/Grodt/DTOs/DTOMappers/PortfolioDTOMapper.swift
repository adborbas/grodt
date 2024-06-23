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
            await financials.addMoneyOut(outAmount)
        }
        
        let moneyIn = await financials.moneyIn
        let moneyOut = await financials.moneyOut
        let profit: Decimal = moneyOut - moneyIn
        let totalReturn: Decimal = moneyIn == 0 ? 0 : profit / moneyIn
        
        return PortfolioPerformanceDTO(moneyIn: moneyIn, moneyOut: moneyOut, profit: profit, totalReturn: totalReturn)
    }
}

fileprivate actor Financials {
    var moneyIn: Decimal = 0
    var moneyOut: Decimal = 0
    
    func addMoneyIn(_ amount: Decimal) {
        moneyIn += amount
    }
    
    func addMoneyOut(_ amount: Decimal) {
        moneyOut += amount
    }
}
