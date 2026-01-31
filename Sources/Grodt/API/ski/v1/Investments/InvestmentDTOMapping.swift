protocol InvestmentDTOMapping: Sendable {
    func investments(from transactions: [Transaction]) async throws -> [InvestmentDTO]
    func investmentDetail(from transactions: [Transaction]) async throws -> InvestmentDetailDTO
}
