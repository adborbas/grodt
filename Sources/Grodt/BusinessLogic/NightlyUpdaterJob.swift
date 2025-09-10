import Vapor
import Queues
import Foundation

struct NightlyUpdaterJob: AsyncScheduledJob, @unchecked Sendable {
    private let tickerPriceUpdater: TickerPriceUpdating
    private let portfolioPerformanceUpdater: PortfolioPerformanceUpdating
    private let brokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating
    private let brokeragePerformanceUpdater: BrokeragePerformanceUpdating
    
    init(
        tickerPriceUpdater: TickerPriceUpdating,
        portfolioPerformanceUpdater: PortfolioPerformanceUpdating,
        brokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating,
        brokeragePerformanceUpdater: BrokeragePerformanceUpdating
    ) {
        self.tickerPriceUpdater = tickerPriceUpdater
        self.portfolioPerformanceUpdater = portfolioPerformanceUpdater
        self.brokerageAccountPerformanceUpdater = brokerageAccountPerformanceUpdater
        self.brokeragePerformanceUpdater = brokeragePerformanceUpdater
    }
    
    @discardableResult
    private func logStep<T>(_ name: String, context: Queues.QueueContext, _ work: () async throws -> T) async throws -> T {
        context.logger.info("NightlyUpdaterJob – START: \(name)")
        let clock = ContinuousClock()
        let t0 = clock.now
        do {
            let value = try await work()
            let duration = t0.duration(to: clock.now)
            let comps = duration.components
            let seconds = Double(comps.seconds) + Double(comps.attoseconds) / 1_000_000_000_000_000_000.0
            context.logger.info("NightlyUpdaterJob – END: \(name) in \(String(format: "%.3f", seconds))s")
            return value
        } catch {
            let duration = t0.duration(to: clock.now)
            let comps = duration.components
            let seconds = Double(comps.seconds) + Double(comps.attoseconds) / 1_000_000_000_000_000_000.0
            context.logger.error("NightlyUpdaterJob – ERROR during \(name) after \(String(format: "%.3f", seconds))s: \(String(describing: error))")
            throw error
        }
    }

    func run(context: Queues.QueueContext) async throws {
        context.logger.info("NightlyUpdaterJob – Job started")
        try await logStep("Update all ticker prices", context: context) {
            try await tickerPriceUpdater.updateAllTickerPrices()
        }
        try await logStep("Update all portfolio performance", context: context) {
            try await portfolioPerformanceUpdater.updateAllPortfolioPerformance()
        }
        try await logStep("Update all brokerage account performance", context: context) {
            try await brokerageAccountPerformanceUpdater.updateAllBrokerageAccountPerformance()
        }
        try await logStep("Update all brokerage performance", context: context) {
            try await brokeragePerformanceUpdater.updateAllBrokeragePerformance()
        }
        context.logger.info("NightlyUpdaterJob – Job finished")
    }
}
