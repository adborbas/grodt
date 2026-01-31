@testable import Grodt
import Vapor

final class MockTransactionService: TransactionServicing, @unchecked Sendable {
    var allResult: Result<[TransactionDTO], Error> = .success([])
    var createResult: Result<TransactionDTO, Error>?
    var detailResult: Result<TransactionDTO, Error> = .success(TransactionDTO.stub())
    var deleteResult: Result<HTTPStatus, Error> = .success(.ok)
    var updateBrokerageAccountResult: Result<TransactionDTO, Error> = .success(TransactionDTO.stub())

    func all(for user: User.IDValue) async throws -> [TransactionDTO] {
        try allResult.get()
    }

    func create(_ transaction: CreateTransactionRequestDTO, on portfolioID: Portfolio.IDValue) async throws -> TransactionDTO {
        guard let result = createResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }

    func detail(for id: UUID) async throws -> TransactionDTO {
        try detailResult.get()
    }

    func delete(id: UUID) async throws -> HTTPStatus {
        try deleteResult.get()
    }

    func updateBrokerageAccount(id: UUID, brokerageAccountId: String?) async throws -> TransactionDTO {
        try updateBrokerageAccountResult.get()
    }
}
