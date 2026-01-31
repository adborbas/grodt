@testable import Grodt
import Foundation

final class MockTransactionDTOMapper: TransactionDTOMapping, @unchecked Sendable {
    var transactionResult: Result<TransactionDTO, Error> = .success(TransactionDTO.stub())

    func transaction(from transaction: Transaction) async throws -> TransactionDTO {
        try transactionResult.get()
    }
}
