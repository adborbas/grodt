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

            let aggregates = calculateTransactionAggregates(transactions)

            // Skip investments that have been fully sold
            guard aggregates.numberOfShares > 0 else { return nil }

            async let name = tickerRepository.tickers(for: ticker)?.name ?? ""
            async let latestPrice = priceService.price(for: ticker)

            let fetchedLatestPrice = try await latestPrice
            guard fetchedLatestPrice > 0 else {
                throw InvestmentError.invalidPrice(for: ticker)
            }

            let currentValue = aggregates.numberOfShares * fetchedLatestPrice
            // Unrealized profit = current value - cost basis of remaining shares
            let unrealizedProfit = currentValue - aggregates.costBasis
            // Total profit includes realized gains from sells
            let totalProfit = unrealizedProfit + aggregates.realizedGain
            let totalReturn = calculateTotalReturn(profit: totalProfit, cost: aggregates.totalInvested)

            return InvestmentDTO(
                name: try await name,
                shortName: ticker,
                avgBuyPrice: aggregates.avgBuyPrice,
                latestPrice: fetchedLatestPrice,
                totalReturn: totalReturn,
                profit: totalProfit,
                currentValue: currentValue,
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
                                   currentValue: investmentDTO.currentValue,
                                   numberOfShares: investmentDTO.numberOfShares,
                                   currency: investmentDTO.currency,
                                   transactions: transactions)
    }
    
    private struct TransactionAggregates {
        let avgBuyPrice: Decimal
        let numberOfShares: Decimal
        let costBasis: Decimal       // Cost basis of currently held shares
        let totalInvested: Decimal   // Total money invested through buys
        let realizedGain: Decimal    // Cumulative realized gains/losses from sells
    }

    private func calculateTransactionAggregates(_ transactions: [Transaction]) -> TransactionAggregates {
        // Sort by date to process in order (important for Average Cost)
        let sorted = transactions.sorted { $0.transactionDate < $1.transactionDate }

        var shares: Decimal = 0
        var costBasis: Decimal = 0
        var totalInvested: Decimal = 0
        var realizedGain: Decimal = 0
        var buyPrices: [Decimal] = []

        for tx in sorted {
            switch tx.type {
            case .buy:
                let cost = tx.totalAmount
                shares += tx.numberOfShares
                costBasis += cost
                totalInvested += cost
                buyPrices.append(tx.pricePerShare)

            case .sell:
                // Average Cost method
                let avgCost = shares > 0 ? costBasis / shares : 0
                let costBasisOfSold = avgCost * tx.numberOfShares
                let proceeds = tx.pricePerShare * tx.numberOfShares - tx.fees

                shares -= tx.numberOfShares
                costBasis -= costBasisOfSold
                realizedGain += proceeds - costBasisOfSold
            }
        }

        let avgBuyPrice = buyPrices.isEmpty ? 0 : buyPrices.reduce(0, +) / Decimal(buyPrices.count)

        return TransactionAggregates(
            avgBuyPrice: avgBuyPrice,
            numberOfShares: shares,
            costBasis: costBasis,
            totalInvested: totalInvested,
            realizedGain: realizedGain
        )
    }

    private func calculateTotalReturn(profit: Decimal, cost: Decimal) -> Decimal {
        guard cost > 0 else { return 0 }
        return (profit / cost).rounded(to: 2)
    }
}
