@testable import Grodt
import Foundation

final class MockInvestmentDTOMapper: InvestmentDTOMapping, @unchecked Sendable {
    var investmentsResult: Result<[InvestmentDTO], Error> = .success([])
    var investmentDetailResult: Result<InvestmentDetailDTO, Error>?

    func investments(from transactions: [Transaction]) async throws -> [InvestmentDTO] {
        try investmentsResult.get()
    }

    func investmentDetail(from transactions: [Transaction]) async throws -> InvestmentDetailDTO {
        guard let result = investmentDetailResult else {
            throw TestError.notImplemented
        }
        return try result.get()
    }
}
