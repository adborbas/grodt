import Foundation

protocol HoldingsPerformanceCalculating {
    func performance(for transactions: [Transaction], on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance
    func performanceSeries(for transactions: [Transaction], from startDate: YearMonthDayDate, to endDate: YearMonthDayDate) async throws -> [DatedPortfolioPerformance]
}

struct HoldingsPerformanceCalculator: HoldingsPerformanceCalculating {
    /// External dependency used to resolve prices/quotes.
    let priceService: PriceService

    // MARK: - Public API

    /// Computes a single-day snapshot of performance for the provided transactions on the given date.
    /// - Note: This method requires an exact quote for the date; it mirrors the prior behavior.
    func performance(for transactions: [Transaction], on date: YearMonthDayDate) async throws -> DatedPortfolioPerformance {
        var moneyIn: Decimal = 0
        var value: Decimal = 0

        // Aggregate quantities per ticker up to the requested date
        var quantityByTicker: [_Ticker: Decimal] = [:]
        for tx in transactions where YearMonthDayDate(tx.purchaseDate) <= date {
            moneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
            quantityByTicker[tx.ticker, default: 0] += tx.numberOfShares
        }

        // Resolve price exactly on the date (carry-forward is handled by the series function, not here)
        for (ticker, qty) in quantityByTicker where qty != 0 {
            let quotes = try await priceService.historicalPrice(for: ticker)
            guard let match = quotes.first(where: { $0.date == date }) else {
                // If no exact quote exists, treat as 0 contribution for readability/stability.
                // This preserves method signature while avoiding a crash.
                continue
            }
            value += qty * match.price
        }

        return DatedPortfolioPerformance(moneyIn: moneyIn, value: value, date: date)
    }

    /// Computes an inclusive daily time series from `startDate` to `endDate`.
    /// The implementation is **event-driven**: it updates state only when a transaction occurs
    /// or when a quote changes, and carries prices forward across non-trading days.
    func performanceSeries(
        for transactions: [Transaction],
        from startDate: YearMonthDayDate,
        to endDate: YearMonthDayDate
    ) async throws -> [DatedPortfolioPerformance] {
        guard !transactions.isEmpty else { return [] }
        guard endDate >= startDate else { return [] }

        // 1) Normalize inputs and build the day range.
        let sortedTransactions = transactions.sorted { $0.purchaseDate < $1.purchaseDate }
        let days = YearMonthDayDate.days(from: startDate, to: endDate)
        let tickers = distinctTickers(from: sortedTransactions)

        // 2) Prefetch quotes and build price-change events per day + baselines at start.
        var baselinePrices: [_Ticker: Decimal] = [:]
        let priceEventsByDay = try await buildPriceEvents(
            for: tickers,
            baseline: &baselinePrices,
            startingAt: startDate,
            endingAt: endDate
        )

        // 3) Establish initial running state at start date (moneyIn/qty/value and transaction cursor).
        var state = Self.initialState(at: startDate, with: sortedTransactions, baselinePrices: baselinePrices)

        // 4) Sweep day-by-day, applying new transactions and price-change events.
        var series: [DatedPortfolioPerformance] = []
        series.reserveCapacity(days.count)

        for day in days {
            advanceTransactions(upToAndIncluding: day, transactions: sortedTransactions, state: &state)
            applyPriceEvents(on: day, events: priceEventsByDay[day.date] ?? [], state: &state)
            series.append(.init(moneyIn: state.moneyIn, value: state.value, date: day))
        }

        return series
    }

    // MARK: - Private helpers (domain types)

    private typealias _Ticker = String

    /// Rolling state that evolves over time while we sweep days.
    private struct RunningState {
        var moneyIn: Decimal
        var value: Decimal
        var quantityByTicker: [_Ticker: Decimal]
        var lastPriceByTicker: [_Ticker: Decimal]
        var txCursor: Int
    }

    // MARK: - Private helpers (pure functions)

    /// Prefetches quotes once per ticker and returns (a) a day-indexed map of price-change events and
    /// (b) the baseline price for each ticker as of `startDate` (last quote on or before start).
    private func buildPriceEvents(
        for tickers: [_Ticker],
        baseline: inout [_Ticker: Decimal],
        startingAt startDate: YearMonthDayDate,
        endingAt endDate: YearMonthDayDate
    ) async throws -> [Date: [(_Ticker, Decimal)]] {
        var eventsByDay: [Date: [(_Ticker, Decimal)]] = [:]

        for ticker in tickers {
            var quotes = try await priceService.historicalPrice(for: ticker)
            guard !quotes.isEmpty else { continue }
            quotes.sort { $0.date < $1.date }

            // Establish baseline ≤ startDate
            var i = 0
            var last: Decimal?
            while i < quotes.count, quotes[i].date <= startDate {
                last = quotes[i].price
                i += 1
            }
            if let last { baseline[ticker] = last }

            // Record future quote changes only within the window
            while i < quotes.count, quotes[i].date <= endDate {
                eventsByDay[quotes[i].date.date, default: []].append((ticker, quotes[i].price))
                i += 1
            }
        }

        return eventsByDay
    }

    /// Computes the initial running state at `startDate` by applying all transactions up to that day.
    private static func initialState(
        at startDate: YearMonthDayDate,
        with sortedTransactions: [Transaction],
        baselinePrices: [_Ticker: Decimal]
    ) -> RunningState {
        var moneyIn: Decimal = 0
        var value: Decimal = 0
        var quantityByTicker: [_Ticker: Decimal] = [:]
        var cursor = 0

        // Apply all transactions up to and including the start day
        while cursor < sortedTransactions.count {
            let tx = sortedTransactions[cursor]
            let txDay = YearMonthDayDate(tx.purchaseDate)
            if txDay > startDate { break }

            moneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees
            let newQty = (quantityByTicker[tx.ticker] ?? 0) + tx.numberOfShares
            quantityByTicker[tx.ticker] = newQty

            if let px = baselinePrices[tx.ticker] {
                // Adjust value by the contribution of this delta quantity at baseline price
                value += tx.numberOfShares * px
            }

            cursor += 1
        }

        // If we have quantities but no baseline prices yet, compute value from whatever baselines exist
        if value == 0, !quantityByTicker.isEmpty {
            var v: Decimal = 0
            for (ticker, qty) in quantityByTicker where qty != 0 {
                if let px = baselinePrices[ticker] { v += qty * px }
            }
            value = v
        }

        return RunningState(
            moneyIn: moneyIn,
            value: value,
            quantityByTicker: quantityByTicker,
            lastPriceByTicker: baselinePrices,
            txCursor: cursor
        )
    }

    /// Applies all transactions whose date is ≤ `day`, advancing the transaction cursor and updating state.
    private func advanceTransactions(
        upToAndIncluding day: YearMonthDayDate,
        transactions: [Transaction],
        state: inout RunningState
    ) {
        while state.txCursor < transactions.count {
            let tx = transactions[state.txCursor]
            let txDay = YearMonthDayDate(tx.purchaseDate)
            if txDay > day { break }

            state.moneyIn += (tx.numberOfShares * tx.pricePerShareAtPurchase) + tx.fees

            let prevQty = state.quantityByTicker[tx.ticker] ?? 0
            let newQty = prevQty + tx.numberOfShares
            state.quantityByTicker[tx.ticker] = newQty

            if let px = state.lastPriceByTicker[tx.ticker] {
                // Adjust current value by the contribution of the delta quantity at current price
                state.value += tx.numberOfShares * px
            }

            state.txCursor += 1
        }
    }

    /// Applies price changes for the given day (if any), adjusting portfolio value using the current quantities.
    private func applyPriceEvents(on day: YearMonthDayDate, events: [(_Ticker, Decimal)], state: inout RunningState) {
        guard !events.isEmpty else { return }

        for (ticker, newPx) in events {
            let oldPx = state.lastPriceByTicker[ticker]
            state.lastPriceByTicker[ticker] = newPx

            guard let qty = state.quantityByTicker[ticker], qty != 0 else { continue }
            if let oldPx {
                state.value += qty * (newPx - oldPx)
            } else {
                state.value += qty * newPx
            }
        }
    }
    
    private func distinctTickers(from array: [Transaction]) -> [_Ticker] {
        Array(Set(array.map { $0.ticker }))
    }
}

fileprivate extension YearMonthDayDate {
    static func days(from start: YearMonthDayDate, to end: YearMonthDayDate) -> [YearMonthDayDate] {
        guard end >= start else { return [] }

        var result: [YearMonthDayDate] = []
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone.universalGMT

        var cursor = start.date
        let endDate = end.date

        while cursor <= endDate {
            result.append(YearMonthDayDate(cursor))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor)!
        }

        return result
    }
}
