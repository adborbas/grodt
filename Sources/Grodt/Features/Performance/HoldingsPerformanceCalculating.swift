import Foundation

protocol HoldingsPerformanceCalculating {
    func performanceSeries(for transactions: [Transaction], from startDate: YearMonthDayDate, to endDate: YearMonthDayDate) async throws -> [DatedPerformance]

    /// Overload that accepts pre-fetched prices to enable sharing price data between calculations.
    func performanceSeries(
        for transactions: [Transaction],
        from startDate: YearMonthDayDate,
        to endDate: YearMonthDayDate,
        priceCache: [String: [DatedQuote]]
    ) async throws -> [DatedPerformance]
}

struct HoldingsPerformanceCalculator: HoldingsPerformanceCalculating {
    let priceService: PriceService

    /// Computes an inclusive daily time series from `startDate` to `endDate`.
    /// The implementation is **event-driven**: it updates state only when a transaction occurs
    /// or when a quote changes, and carries prices forward across non-trading days.
    func performanceSeries(
        for transactions: [Transaction],
        from startDate: YearMonthDayDate,
        to endDate: YearMonthDayDate
    ) async throws -> [DatedPerformance] {
        guard !transactions.isEmpty else { return [] }
        guard endDate >= startDate else { return [] }

        let symbols = distinctTickers(from: transactions)
        var priceCache: [String: [DatedQuote]] = [:]
        for symbol in symbols {
            priceCache[symbol] = try await priceService.historicalPrice(for: symbol)
        }
        return try await performanceSeries(for: transactions, from: startDate, to: endDate, priceCache: priceCache)
    }

    /// Overload that accepts pre-fetched prices to enable sharing price data between calculations.
    func performanceSeries(
        for transactions: [Transaction],
        from startDate: YearMonthDayDate,
        to endDate: YearMonthDayDate,
        priceCache: [String: [DatedQuote]]
    ) async throws -> [DatedPerformance] {
        guard !transactions.isEmpty else { return [] }
        guard endDate >= startDate else { return [] }

        // 1) Normalize inputs and build the day range.
        let sortedTransactions = transactions.sorted { $0.purchaseDate < $1.purchaseDate }
        let days = YearMonthDayDate.days(from: startDate, to: endDate)
        let symbols = distinctTickers(from: sortedTransactions)

        // 2) Build price-change events per day + baselines at start from the cache.
        var baselinePrices: [Symbol: Decimal] = [:]
        let priceEventsByDay = buildPriceEventsFromCache(
            for: symbols,
            baseline: &baselinePrices,
            startingAt: startDate,
            endingAt: endDate,
            priceCache: priceCache
        )

        // 3) Establish initial running state at start date (moneyIn/qty/value and transaction cursor).
        var state = Self.initialState(at: startDate, with: sortedTransactions, baselinePrices: baselinePrices)

        // 4) Sweep day-by-day, applying new transactions and price-change events.
        var series: [DatedPerformance] = []
        series.reserveCapacity(days.count)

        for day in days {
            advanceTransactions(upToAndIncluding: day, transactions: sortedTransactions, state: &state)
            applyPriceEvents(on: day, events: priceEventsByDay[day.date] ?? [], state: &state)
            series.append(.init(moneyIn: state.moneyIn, value: state.value, date: day))
        }

        return series
    }

    // MARK: - Private helpers (domain types)

    private typealias Symbol = String

    /// Rolling state that evolves over time while we sweep days.
    private struct RunningState {
        var moneyIn: Decimal
        var value: Decimal
        var quantityByTicker: [Symbol: Decimal]
        var lastPriceByTicker: [Symbol: Decimal]
        var txCursor: Int
    }

    // MARK: - Private helpers (pure functions)

    /// Builds price events from a pre-fetched cache of quotes.
    /// Returns (a) a day-indexed map of price-change events and
    /// (b) the baseline price for each symbol as of `startDate` (last quote on or before start).
    private func buildPriceEventsFromCache(
        for symbols: [Symbol],
        baseline: inout [Symbol: Decimal],
        startingAt startDate: YearMonthDayDate,
        endingAt endDate: YearMonthDayDate,
        priceCache: [String: [DatedQuote]]
    ) -> [Date: [(Symbol, Decimal)]] {
        var eventsByDay: [Date: [(Symbol, Decimal)]] = [:]

        for symbol in symbols {
            guard var quotes = priceCache[symbol], !quotes.isEmpty else { continue }
            quotes.sort { $0.date < $1.date }

            // Establish baseline ≤ startDate
            var i = 0
            var last: Decimal?
            while i < quotes.count, quotes[i].date <= startDate {
                last = quotes[i].price
                i += 1
            }
            if let last { baseline[symbol] = last }

            // Record future quote changes only within the window
            while i < quotes.count, quotes[i].date <= endDate {
                eventsByDay[quotes[i].date.date, default: []].append((symbol, quotes[i].price))
                i += 1
            }
        }

        return eventsByDay
    }

    /// Computes the initial running state at `startDate` by applying all transactions up to that day.
    private static func initialState(
        at startDate: YearMonthDayDate,
        with sortedTransactions: [Transaction],
        baselinePrices: [Symbol: Decimal]
    ) -> RunningState {
        var moneyIn: Decimal = 0
        var value: Decimal = 0
        var quantityByTicker: [Symbol: Decimal] = [:]
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
            for (symbol, qty) in quantityByTicker where qty != 0 {
                if let px = baselinePrices[symbol] { v += qty * px }
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
    private func applyPriceEvents(on day: YearMonthDayDate, events: [(Symbol, Decimal)], state: inout RunningState) {
        guard !events.isEmpty else { return }

        for (symbol, newPx) in events {
            let oldPx = state.lastPriceByTicker[symbol]
            state.lastPriceByTicker[symbol] = newPx

            guard let qty = state.quantityByTicker[symbol], qty != 0 else { continue }
            if let oldPx {
                state.value += qty * (newPx - oldPx)
            } else {
                state.value += qty * newPx
            }
        }
    }
    
    private func distinctTickers(from array: [Transaction]) -> [Symbol] {
        Array(Set(array.map { $0.ticker }))
    }
}
