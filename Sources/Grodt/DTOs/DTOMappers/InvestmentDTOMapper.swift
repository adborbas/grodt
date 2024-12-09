import Foundation
import CollectionConcurrencyKit

class InvestmentDTOMapper {
    private let currencyDTOMapper: CurrencyDTOMapper
    private let tickerRepository: TickerRepository
    private let priceService: PriceService
    
    init(currencyDTOMapper: CurrencyDTOMapper,
         tickerRepository: TickerRepository,
         priceService: PriceService) {
        self.currencyDTOMapper = currencyDTOMapper
        self.priceService = priceService
        self.tickerRepository = tickerRepository
    }
    
    func investments(from transactions: [Transaction]) async throws -> [InvestmentDTO] {
        let investments: [InvestmentDTO] = try await transactions
            .grouped { $0.ticker }
            .asyncCompactMap { (ticker, transactions) in
                let name = try await tickerRepository.tickers(for: ticker)?.name ?? ""
                let latestPrice = try await priceService.price(for: ticker)
                var pricePerPurchase: [Decimal: Decimal] = [:]
                var numberOfShares: Decimal = 0
                var totalCost: Decimal = 0
                transactions.forEach { transaction in
                    pricePerPurchase[transaction.pricePerShareAtPurchase] = transaction.numberOfShares
                    numberOfShares += transaction.numberOfShares
                    totalCost += (transaction.pricePerShareAtPurchase * transaction.numberOfShares) + transaction.fees
                }
                let currentValue = numberOfShares * latestPrice
                let avgBuyPrice = pricePerPurchase.keys.reduce(0) { $0 + $1 } / Decimal(pricePerPurchase.count)
                let profit = currentValue - totalCost
                let totalReturn = (totalCost == 0 ? 0 : profit / totalCost).ro
                
                return InvestmentDTO(name: name,
                                     shortName: ticker,
                                     avgBuyPrice: avgBuyPrice,
                                     latestPrice: latestPrice,
                                     totalReturn: totalReturn,
                                     profit: profit,
                                     value: currentValue,
                                     numberOfShares: numberOfShares,
                                     currency: currencyDTOMapper.currency(from: transactions.first!.currency))
            }
        
        return investments
    }
}
