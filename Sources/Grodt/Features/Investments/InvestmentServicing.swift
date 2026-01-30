import Foundation

protocol InvestmentServicing: Sendable {
    func allInvestments(for userID: User.IDValue) async throws -> [InvestmentDTO]
    func investmentDetail(for ticker: String, userID: User.IDValue) async throws -> InvestmentDetailDTO
}
