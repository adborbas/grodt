@testable import Grodt
import Foundation

final class MockBrokeragePerformanceUpdater: BrokeragePerformanceUpdating, @unchecked Sendable {
    var recalculateResult: Result<Void, Error> = .success(())
    var updateAllResult: Result<Void, Error> = .success(())

    private(set) var recalculateCalled = false
    private(set) var recalculateBrokerageID: UUID?
    private(set) var recalculateFromDate: YearMonthDayDate?
    private(set) var updateAllCalled = false

    func recalculatePerformance(for brokerageID: UUID, from date: YearMonthDayDate) async throws {
        recalculateCalled = true
        recalculateBrokerageID = brokerageID
        recalculateFromDate = date
        try recalculateResult.get()
    }

    func updateAllBrokeragePerformance() async throws {
        updateAllCalled = true
        try updateAllResult.get()
    }
}
