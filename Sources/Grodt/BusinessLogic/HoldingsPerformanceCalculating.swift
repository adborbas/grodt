import Vapor
import Fluent

protocol HoldingsPerformanceCalculating {
    func performance(for transactions: [Transaction], on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance
}

struct SimpleHoldingsPerformanceCalculator: HoldingsPerformanceCalculating {
    let priceService: PriceService

    func performance(for transactions: [Transaction], on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance {
        var moneyIn: Decimal = 0
        var value: Decimal = 0

        var perTickerQuantity: [String: Decimal] = [:]
        for tx in transactions where YearMonthDayDate(tx.purchaseDate) <= date {
            moneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
            perTickerQuantity[tx.ticker, default: 0] += tx.numberOfShares
        }

        for (ticker, qty) in perTickerQuantity {
            let datedPrice = try await priceService.historicalPrice(for: ticker).first { $0.date == date }!
            value += qty * datedPrice.price
        }
        return DatedPortfolioPerformance(moneyIn: moneyIn, value: value, date: date)
    }
}

struct BrokerageAccountPerformanceUpdater {
    let db: Database
    let priceService: PriceService

    func recomputeAll(for date: YearMonthDayDate) async throws {
        let accounts = try await BrokerageAccount.query(on: db).all()
        let calc = SimpleHoldingsPerformanceCalculator(priceService: priceService)

        for account in accounts {
            let txs = try await account.$transactions.query(on: db).all()
            let perf = try await calc.performance(for: txs, on: date)
            let row = HistoricalBrokerageAccountPerformance(accountID: try account.requireID(),
                                                            date: date.date,
                                                            moneyIn: perf.moneyIn,
                                                            value: perf.value)
            try await HistoricalBrokerageAccountPerformance.query(on: db)
                .filter(\.$account.$id == account.requireID())
                .filter(\.$date == date.date)
                .delete()
            try await row.save(on: db)
        }
    }
}

import Queues

struct BrokerageAccountPerformanceUpdaterJob: AsyncScheduledJob, @unchecked Sendable {
    private let performanceUpdater: BrokerageAccountPerformanceUpdater
    
    init(performanceUpdater: BrokerageAccountPerformanceUpdater) {
        self.performanceUpdater = performanceUpdater
    }
    
    func run(context: Queues.QueueContext) async throws {
        try await performanceUpdater.recomputeAll(for: YearMonthDayDate(Date()))
    }
}
