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
    ///
    /// Supports both buy and sell transactions using Average Cost method for cost basis.
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
        let sortedTransactions = transactions.sorted { $0.transactionDate < $1.transactionDate }
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

        // 3) Establish initial running state at start date.
        var state = Self.initialState(at: startDate, with: sortedTransactions, baselinePrices: baselinePrices)

        // 4) Sweep day-by-day, applying new transactions and price-change events.
        var series: [DatedPerformance] = []
        series.reserveCapacity(days.count)

        for day in days {
            advanceTransactions(upToAndIncluding: day, transactions: sortedTransactions, state: &state)
            applyPriceEvents(on: day, events: priceEventsByDay[day.date] ?? [], state: &state)
            series.append(.init(invested: state.invested, realized: state.realized, currentValue: state.currentValue, date: day))
        }

        return series
    }

    // MARK: - Private helpers (domain types)

    private typealias Symbol = String

    /// Per-ticker tracking for Average Cost calculation.
    private struct TickerHolding {
        var shares: Decimal = 0
        var costBasis: Decimal = 0  // Total cost of shares currently held

        var averageCostPerShare: Decimal {
            guard shares > 0 else { return 0 }
            return costBasis / shares
        }
    }

    /// Rolling state that evolves over time while we sweep days.
    private struct RunningState {
        var invested: Decimal        // Net invested capital (cost basis of current holdings)
        var realized: Decimal        // Cumulative realized gains/losses from sells
        var currentValue: Decimal    // Current market value of holdings
        var holdingsByTicker: [Symbol: TickerHolding]
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
        var invested: Decimal = 0
        var realized: Decimal = 0
        var currentValue: Decimal = 0
        var holdingsByTicker: [Symbol: TickerHolding] = [:]
        var cursor = 0

        // Apply all transactions up to and including the start day
        while cursor < sortedTransactions.count {
            let tx = sortedTransactions[cursor]
            let txDay = YearMonthDayDate(tx.transactionDate)
            if txDay > startDate { break }

            var holding = holdingsByTicker[tx.ticker] ?? TickerHolding()

            switch tx.type {
            case .buy:
                let cost = tx.totalAmount
                holding.shares += tx.numberOfShares
                holding.costBasis += cost

            case .sell:
                let avgCost = holding.averageCostPerShare
                let costBasisOfSoldShares = avgCost * tx.numberOfShares
                let proceeds = tx.pricePerShare * tx.numberOfShares - tx.fees
                let realizedGain = proceeds - costBasisOfSoldShares

                holding.shares -= tx.numberOfShares
                holding.costBasis -= costBasisOfSoldShares
                realized += realizedGain
            }

            holdingsByTicker[tx.ticker] = holding
            cursor += 1
        }

        // Calculate invested (sum of cost bases) and currentValue from baseline prices
        for (symbol, holding) in holdingsByTicker where holding.shares > 0 {
            invested += holding.costBasis
            if let px = baselinePrices[symbol] {
                currentValue += holding.shares * px
            }
        }

        return RunningState(
            invested: invested,
            realized: realized,
            currentValue: currentValue,
            holdingsByTicker: holdingsByTicker,
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
            let txDay = YearMonthDayDate(tx.transactionDate)
            if txDay > day { break }

            var holding = state.holdingsByTicker[tx.ticker] ?? TickerHolding()

            switch tx.type {
            case .buy:
                let cost = tx.totalAmount
                holding.shares += tx.numberOfShares
                holding.costBasis += cost
                state.invested += cost

                // Update current value if we have a price
                if let px = state.lastPriceByTicker[tx.ticker] {
                    state.currentValue += tx.numberOfShares * px
                }

            case .sell:
                let avgCost = holding.averageCostPerShare
                let costBasisOfSoldShares = avgCost * tx.numberOfShares
                let proceeds = tx.pricePerShare * tx.numberOfShares - tx.fees
                let realizedGain = proceeds - costBasisOfSoldShares

                holding.shares -= tx.numberOfShares
                holding.costBasis -= costBasisOfSoldShares
                state.invested -= costBasisOfSoldShares
                state.realized += realizedGain

                // Update current value if we have a price
                if let px = state.lastPriceByTicker[tx.ticker] {
                    state.currentValue -= tx.numberOfShares * px
                }
            }

            state.holdingsByTicker[tx.ticker] = holding
            state.txCursor += 1
        }
    }

    /// Applies price changes for the given day (if any), adjusting portfolio value using the current quantities.
    private func applyPriceEvents(on day: YearMonthDayDate, events: [(Symbol, Decimal)], state: inout RunningState) {
        guard !events.isEmpty else { return }

        for (symbol, newPx) in events {
            let oldPx = state.lastPriceByTicker[symbol]
            state.lastPriceByTicker[symbol] = newPx

            guard let holding = state.holdingsByTicker[symbol], holding.shares > 0 else { continue }
            if let oldPx {
                state.currentValue += holding.shares * (newPx - oldPx)
            } else {
                state.currentValue += holding.shares * newPx
            }
        }
    }

    private func distinctTickers(from array: [Transaction]) -> [Symbol] {
        Array(Set(array.map { $0.ticker }))
    }
}
