@testable import Grodt
import Vapor

final class MockTransactionService: TransactionServicing, @unchecked Sendable {
    var allResult: Result<[TransactionDTO], Error> = .success([])
    var createResult: Result<TransactionDTO, Error>?

    func all(for user: User.IDValue) async throws -> [TransactionDTO] {
        try allResult.get()
    }

    func create(_ transaction: CreateTransactionRequestDTO, on portfolioID: Portfolio.IDValue) async throws -> TransactionDTO {
        guard let result = createResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }
}
