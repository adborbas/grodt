@testable import Grodt
import Foundation

final class MockTransactionsRepository: TransactionsRepository, @unchecked Sendable {
    var transactionResult: Result<Transaction?, Error> = .success(nil)
    var allResult: Result<[Transaction], Error> = .success([])
    var transactionsResult: Result<[Transaction], Error> = .success([])
    var saveResult: Result<Void, Error> = .success(())
    var deleteResult: Result<Void, Error> = .success(())
    var updateResult: Result<Void, Error> = .success(())

    private(set) var saveCalled = false
    private(set) var saveCalledWith: Transaction?
    private(set) var deleteCalled = false
    private(set) var deleteCalledWith: Transaction?
    private(set) var updateCalled = false
    private(set) var updateCalledWith: Transaction?

    func transaction(for id: UUID) async throws -> Transaction? {
        try transactionResult.get()
    }

    func all(for userID: User.IDValue) async throws -> [Transaction] {
        try allResult.get()
    }

    func transactions(for userID: User.IDValue, ticker: String) async throws -> [Transaction] {
        try transactionsResult.get()
    }

    func save(_ transaction: Transaction) async throws {
        saveCalled = true
        saveCalledWith = transaction
        try saveResult.get()
    }

    func delete(_ transaction: Transaction) async throws {
        deleteCalled = true
        deleteCalledWith = transaction
        try deleteResult.get()
    }

    func update(_ transaction: Transaction) async throws {
        updateCalled = true
        updateCalledWith = transaction
        try updateResult.get()
    }
}
