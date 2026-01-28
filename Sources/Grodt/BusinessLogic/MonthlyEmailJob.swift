import Vapor
import Queues
import Foundation

struct MonthlyEmailJob: AsyncScheduledJob, @unchecked Sendable {
    private let portfolioPerformanceEmail: PortfolioPerformanceEmail

    init(portfolioPerformanceEmail: PortfolioPerformanceEmail) {
        self.portfolioPerformanceEmail = portfolioPerformanceEmail
    }

    func run(context: QueueContext) async throws {
        try await portfolioPerformanceEmail.sendMonthlyUpdates()
    }
}
