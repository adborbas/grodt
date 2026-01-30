import Foundation
import CollectionConcurrencyKit

class InvestmentDTOMapper: InvestmentDTOMapping {
    enum InvestmentError: Error {
        case invalidPrice(for: String)
    }

    private let currencyDTOMapper: CurrencyDTOMapper
    private let transactionDTOMapper: TransactionDTOMapping
    private let tickerRepository: TickerRepository
    private let priceService: PriceService

    init(currencyDTOMapper: CurrencyDTOMapper,
         transactionDTOMapper: TransactionDTOMapping,
         tickerRepository: TickerRepository,
         priceService: PriceService) {
        self.currencyDTOMapper = currencyDTOMapper
        self.transactionDTOMapper = transactionDTOMapper
        self.priceService = priceService
        self.tickerRepository = tickerRepository
    }
    
    func investments(from transactions: [Transaction]) async throws -> [InvestmentDTO] {
        let groupedTransactions = transactions.grouped { $0.ticker }
        
        let investments: [InvestmentDTO] = try await groupedTransactions.asyncCompactMap { ticker, transactions in
            guard let firstTransaction = transactions.first else { return nil }
            
            async let name = tickerRepository.tickers(for: ticker)?.name ?? ""
            async let latestPrice = priceService.price(for: ticker)
            let aggregates = calculateTransactionAggregates(transactions)
            
            let fetchedLatestPrice = try await latestPrice
            guard fetchedLatestPrice > 0 else {
                throw InvestmentError.invalidPrice(for: ticker)
            }
            
            let currentValue = aggregates.numberOfShares * fetchedLatestPrice
            let profit = currentValue - aggregates.totalCost
            let totalReturn = calculateTotalReturn(profit: profit, cost: aggregates.totalCost)
            
            return InvestmentDTO(
                name: try await name,
                shortName: ticker,
                avgBuyPrice: aggregates.avgBuyPrice,
                latestPrice: fetchedLatestPrice,
                totalReturn: totalReturn,
                profit: profit,
                value: currentValue,
                numberOfShares: aggregates.numberOfShares,
                currency: currencyDTOMapper.currency(from: firstTransaction.currency)
            )
        }
        
        return investments.sorted { lft, rgh in
            lft.totalReturn > rgh.totalReturn
        }
    }
    
    func investmentDetail(from transactions: [Transaction]) async throws -> InvestmentDetailDTO {
        let investmentDTO = try await investments(from: transactions).first!
        let transactions = try await transactions.asyncCompactMap { try await transactionDTOMapper.transaction(from: $0) }
        return InvestmentDetailDTO(name: investmentDTO.name,
                                   shortName: investmentDTO.shortName,
                                   avgBuyPrice: investmentDTO.avgBuyPrice,
                                   latestPrice: investmentDTO.latestPrice,
                                   totalReturn: investmentDTO.totalReturn,
                                   profit: investmentDTO.profit,
                                   value: investmentDTO.value,
                                   numberOfShares: investmentDTO.numberOfShares,
                                   currency: investmentDTO.currency,
                                   transactions: transactions)
    }
    
    private func calculateTransactionAggregates(_ transactions: [Transaction]) -> (avgBuyPrice: Decimal, totalCost: Decimal, numberOfShares: Decimal) {
        var totalCost: Decimal = 0
        var numberOfShares: Decimal = 0
        var pricePerPurchase: [Decimal: Decimal] = [:]
        
        transactions.forEach { transaction in
            pricePerPurchase[transaction.pricePerShareAtPurchase] = transaction.numberOfShares
            totalCost += (transaction.pricePerShareAtPurchase * transaction.numberOfShares) + transaction.fees
            numberOfShares += transaction.numberOfShares
        }
        
        let avgBuyPrice = pricePerPurchase.keys.reduce(0) { $0 + $1 } / Decimal(pricePerPurchase.count)
        return (avgBuyPrice: avgBuyPrice, totalCost: totalCost, numberOfShares: numberOfShares)
    }

    private func calculateTotalReturn(profit: Decimal, cost: Decimal) -> Decimal {
        guard cost > 0 else { return 0 }
        return (profit / cost).rounded(to: 2)
    }
}
