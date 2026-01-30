@testable import Grodt
import Foundation

final class MockBrokerageAccountPerformanceUpdater: BrokerageAccountPerformanceUpdating, @unchecked Sendable {
    var recalculateResult: Result<Void, Error> = .success(())
    var updateAllResult: Result<Void, Error> = .success(())

    private(set) var recalculateCalled = false
    private(set) var recalculateAccountID: UUID?
    private(set) var recalculateFromDate: YearMonthDayDate?
    private(set) var updateAllCalled = false

    func recalculatePerformance(for accountID: UUID, from date: YearMonthDayDate) async throws {
        recalculateCalled = true
        recalculateAccountID = accountID
        recalculateFromDate = date
        try recalculateResult.get()
    }

    func updateAllBrokerageAccountPerformance() async throws {
        updateAllCalled = true
        try updateAllResult.get()
    }
}
