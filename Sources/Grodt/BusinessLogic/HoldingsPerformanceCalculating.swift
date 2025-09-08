import Foundation
import Vapor
import Fluent

protocol HoldingsPerformanceCalculating {
    func performance(for transactions: [Transaction], on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance
    func performanceSeries(for transactions: [Transaction], from startDate: YearMonthDayDate, to endDate: YearMonthDayDate) async throws -> [DatedPortfolioPerformance]
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

    func performanceSeries(for transactions: [Transaction], from startDate: YearMonthDayDate, to endDate: YearMonthDayDate) async throws -> [DatedPortfolioPerformance] {
        guard !transactions.isEmpty else { return [] }

        // Sort transactions by purchase date for efficient accumulation
        let sortedTx = transactions.sorted { $0.purchaseDate < $1.purchaseDate }

        // Build date range [startDate ... endDate]
        let dates = Self.dates(from: startDate, to: endDate)

        // Prefetch all historical quotes per ticker and make an iterator for carry-forward pricing
        let tickers = Array(Set(sortedTx.map { $0.ticker }))
        var quotesByTicker: [String: [DatedQuote]] = [:]
        for ticker in tickers {
            // Expect PriceService to return quotes sorted by date asc; if not, sort below
            let quotes = try await priceService.historicalPrice(for: ticker).sorted { $0.date < $1.date }
            quotesByTicker[ticker] = quotes
        }

        // State that evolves day-by-day
        var runningMoneyIn: Decimal = 0
        var quantityByTicker: [String: Decimal] = [:]

        // For price carry-forward: current index & last known price per ticker
        var priceIndexByTicker: [String: Int] = [:]
        var lastPriceByTicker: [String: Decimal] = [:]

        // Cursor for transactions to add as we progress in time
        var txCursor = 0

        var result: [DatedPortfolioPerformance] = []
        result.reserveCapacity(dates.count)

        for day in dates {
            // 1) Advance transactions up to and including this day
            while txCursor < sortedTx.count {
                let tx = sortedTx[txCursor]
                let txDay = YearMonthDayDate(tx.purchaseDate)
                if txDay > day { break }
                runningMoneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
                quantityByTicker[tx.ticker, default: 0] += tx.numberOfShares
                txCursor += 1
            }

            // 2) Update prices (carry forward last known price if no exact quote for this day)
            for ticker in tickers {
                let quotes = quotesByTicker[ticker] ?? []
                let startIdx = priceIndexByTicker[ticker] ?? 0
                var idx = startIdx
                while idx < quotes.count, quotes[idx].date <= day {
                    lastPriceByTicker[ticker] = quotes[idx].price
                    idx += 1
                }
                priceIndexByTicker[ticker] = idx
            }

            // 3) Compute value using current quantities and last known prices
            var value: Decimal = 0
            for (ticker, qty) in quantityByTicker where qty != 0 {
                if let px = lastPriceByTicker[ticker] {
                    value += qty * px
                }
            }

            result.append(DatedPortfolioPerformance(moneyIn: runningMoneyIn, value: value, date: day))
        }

        return result
    }
    
    private static func dates(from start: YearMonthDayDate, to end: YearMonthDayDate) -> [YearMonthDayDate] {
        var out: [YearMonthDayDate] = []
        var current = start.date
        let endDate = end.date
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.universalGMT
        while current <= endDate {
            out.append(YearMonthDayDate(current))
            current = cal.date(byAdding: .day, value: 1, to: current)!
        }
        return out
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
            guard let earliest = txs.map({ $0.purchaseDate }).min().map(YearMonthDayDate.init) else {
                // No transactions: clear existing rows and continue
                try await HistoricalBrokerageAccountPerformance.query(on: db)
                    .filter(\.$account.$id == account.requireID())
                    .delete()
                continue
            }

            let series = try await calc.performanceSeries(for: txs, from: earliest, to: date)

            // Upsert strategy: replace entire series for this account
            try await HistoricalBrokerageAccountPerformance.query(on: db)
                .filter(\.$account.$id == account.requireID())
                .delete()

            for point in series {
                let row = HistoricalBrokerageAccountPerformance(accountID: try account.requireID(),
                                                                date: point.date.date,
                                                                moneyIn: point.moneyIn,
                                                                value: point.value)
                try await row.save(on: db)
            }
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
