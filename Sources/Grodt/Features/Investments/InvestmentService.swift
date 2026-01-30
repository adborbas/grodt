class InvestmentService: InvestmentServicing {
    private let portfolioRepository: PortfolioRepository
    private let dataMapper: InvestmentDTOMapper
    
    init(portfolioRepository: PortfolioRepository,
         dataMapper: InvestmentDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.dataMapper = dataMapper
    }
    
    func allInvestments(for userID: User.IDValue) async throws -> [InvestmentDTO] {
        let transactions = try await portfolioRepository.allPortfolios(for: userID)
            .flatMap { $0.transactions }
        
        return try await dataMapper.investments(from: transactions)
    }
    
    func investmentDetail(for ticker: String, userID: User.IDValue) async throws -> InvestmentDetailDTO {
        let portfolios = try await portfolioRepository.allPortfolios(for: userID)
        let transactions = portfolios
            .flatMap { $0.transactions }
            .filter { $0.ticker == ticker }
        return try await dataMapper.investmentDetail(from: transactions)
    }
}
