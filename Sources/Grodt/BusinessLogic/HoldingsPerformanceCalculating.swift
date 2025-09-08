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
        // Empty or invalid range → nothing to do
        guard !transactions.isEmpty else { return [] }
        if endDate < startDate { return [] }

        // 1) Sort transactions once; we'll consume them with a cursor
        let sortedTx = transactions.sorted { $0.purchaseDate < $1.purchaseDate }

        // 2) Build inclusive day range [startDate ... endDate]
        let days = Self.dates(from: startDate, to: endDate)

        // 3) Prefetch quotes once per ticker and build per-day price update events.
        //    We also establish a baseline price per ticker as the last quote ≤ startDate.
        let tickers = Array(Set(sortedTx.map { $0.ticker }))

        var lastPriceByTicker: [String: Decimal] = [:]                  // baseline/rolling last-known price
        var priceEventsByDay: [Date: [(String, Decimal)]] = [:]         // date → [(ticker, newPrice)]

        for ticker in tickers {
            var quotes = try await priceService.historicalPrice(for: ticker)
            guard !quotes.isEmpty else { continue }
            quotes.sort { $0.date < $1.date }

            // Advance to the last quote on or before the start date to set the baseline
            var i = 0
            var last: Decimal?
            while i < quotes.count, quotes[i].date <= startDate {
                last = quotes[i].price
                i += 1
            }
            if let last { lastPriceByTicker[ticker] = last }

            // Record future quote changes only within the requested window
            while i < quotes.count, quotes[i].date <= endDate {
                priceEventsByDay[quotes[i].date.date, default: []].append((ticker, quotes[i].price))
                i += 1
            }
        }

        // 4) Initialize running portfolio state at startDate
        var runningMoneyIn: Decimal = 0
        var runningValue: Decimal = 0
        var quantityByTicker: [String: Decimal] = [:]

        var txCursor = 0
        // Apply all transactions that occur on or before startDate to establish initial state
        while txCursor < sortedTx.count {
            let tx = sortedTx[txCursor]
            let txDay = YearMonthDayDate(tx.purchaseDate)
            if txDay > startDate { break }
            runningMoneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
            let newQty = (quantityByTicker[tx.ticker] ?? 0) + tx.numberOfShares
            quantityByTicker[tx.ticker] = newQty
            if let px = lastPriceByTicker[tx.ticker] { runningValue += tx.numberOfShares * px }
            txCursor += 1
        }

        // In the rare case no baseline prices were known but quantities exist, compute once from known prices
        if runningValue == 0, !quantityByTicker.isEmpty {
            var v: Decimal = 0
            for (ticker, qty) in quantityByTicker {
                if let px = lastPriceByTicker[ticker], qty != 0 { v += qty * px }
            }
            runningValue = v
        }

        // 5) Sweep through each day; update only when events happen.
        var series: [DatedPortfolioPerformance] = []
        series.reserveCapacity(days.count)

        for day in days {
            // 5a) Apply new transactions effective on this day
            while txCursor < sortedTx.count {
                let tx = sortedTx[txCursor]
                let txDay = YearMonthDayDate(tx.purchaseDate)
                if txDay > day { break }
                runningMoneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
                let prevQty = quantityByTicker[tx.ticker] ?? 0
                let newQty = prevQty + tx.numberOfShares
                quantityByTicker[tx.ticker] = newQty
                if let px = lastPriceByTicker[tx.ticker] { runningValue += tx.numberOfShares * px }
                txCursor += 1
            }

            // 5b) Apply price changes that occur on this day (carry-forward otherwise)
            if let events = priceEventsByDay[day.date] {
                for (ticker, newPx) in events {
                    let oldPx = lastPriceByTicker[ticker]
                    lastPriceByTicker[ticker] = newPx
                    if let qty = quantityByTicker[ticker], qty != 0 {
                        if let oldPx { runningValue += qty * (newPx - oldPx) }
                        else { runningValue += qty * newPx }
                    }
                }
            }

            series.append(DatedPortfolioPerformance(moneyIn: runningMoneyIn, value: runningValue, date: day))
        }

        return series
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
