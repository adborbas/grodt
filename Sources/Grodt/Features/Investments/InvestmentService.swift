class InvestmentService: InvestmentServicing {
    private let transactionsRepository: TransactionsRepository
    private let dataMapper: InvestmentDTOMapping

    init(transactionsRepository: TransactionsRepository,
         dataMapper: InvestmentDTOMapping) {
        self.transactionsRepository = transactionsRepository
        self.dataMapper = dataMapper
    }

    func allInvestments(for userID: User.IDValue) async throws -> [InvestmentDTO] {
        let transactions = try await transactionsRepository.all(for: userID)
        return try await dataMapper.investments(from: transactions)
    }

    func investmentDetail(for ticker: String, userID: User.IDValue) async throws -> InvestmentDetailDTO {
        let transactions = try await transactionsRepository.transactionsForUser(userID, ticker: ticker)
        return try await dataMapper.investmentDetail(from: transactions)
    }
}
