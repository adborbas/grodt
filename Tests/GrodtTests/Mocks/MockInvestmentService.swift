@testable import Grodt
import Vapor

final class MockInvestmentService: InvestmentServicing, @unchecked Sendable {
    var allInvestmentsResult: Result<[InvestmentDTO], Error> = .success([])
    var investmentDetailResult: Result<InvestmentDetailDTO, Error> = .success(InvestmentDetailDTO.stub())

    func allInvestments(for userID: User.IDValue) async throws -> [InvestmentDTO] {
        try allInvestmentsResult.get()
    }

    func investmentDetail(for ticker: String, userID: User.IDValue) async throws -> InvestmentDetailDTO {
        try investmentDetailResult.get()
    }
}
