class InvestmentService: InvestmentServicing {
    private let portfolioRepository: PortfolioRepository
    private let dataMapper: InvestmentDTOMapping

    init(portfolioRepository: PortfolioRepository,
         dataMapper: InvestmentDTOMapping) {
        self.portfolioRepository = portfolioRepository
        self.dataMapper = dataMapper
    }
    
    func allInvestments(for userID: User.IDValue) async throws -> [InvestmentDTO] {
        let transactions = try await portfolioRepository.allTransactions(for: userID)
        return try await dataMapper.investments(from: transactions)
    }

    func investmentDetail(for ticker: String, userID: User.IDValue) async throws -> InvestmentDetailDTO {
        let transactions = try await portfolioRepository.transactions(for: userID, ticker: ticker)
        return try await dataMapper.investmentDetail(from: transactions)
    }
}
