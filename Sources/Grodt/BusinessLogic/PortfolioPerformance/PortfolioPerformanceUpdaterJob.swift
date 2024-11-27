import Vapor
import Queues

struct PortfolioPerformanceUpdaterJob: AsyncScheduledJob, @unchecked Sendable {
    private let performanceUpdater: PortfolioHistoricalPerformanceUpdater
    
    init(performanceUpdater: PortfolioHistoricalPerformanceUpdater) {
        self.performanceUpdater = performanceUpdater
    }
    
    func run(context: Queues.QueueContext) async throws {
        try await performanceUpdater.updatePerformanceOfAllPortfolios()
    }
}
