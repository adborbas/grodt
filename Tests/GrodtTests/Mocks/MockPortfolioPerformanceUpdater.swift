@testable import Grodt
import Foundation

final class MockPortfolioPerformanceUpdater: PortfolioPerformanceUpdating, @unchecked Sendable {
    var recalculateResult: Result<Void, Error> = .success(())
    var recalculateFromResult: Result<Void, Error> = .success(())
    var updateAllResult: Result<Void, Error> = .success(())

    private(set) var recalculateCalled = false
    private(set) var recalculateFromCalled = false
    private(set) var recalculateFromDate: YearMonthDayDate?
    private(set) var recalculatedPortfolio: Portfolio?
    private(set) var updateAllCalled = false

    func recalculatePerformance(of portfolio: Portfolio) async throws {
        recalculateCalled = true
        recalculatedPortfolio = portfolio
        try recalculateResult.get()
    }

    func recalculatePerformance(of portfolio: Portfolio, from date: YearMonthDayDate) async throws {
        recalculateFromCalled = true
        recalculatedPortfolio = portfolio
        recalculateFromDate = date
        try recalculateFromResult.get()
    }

    func updateAllPortfolioPerformance() async throws {
        updateAllCalled = true
        try updateAllResult.get()
    }
}
