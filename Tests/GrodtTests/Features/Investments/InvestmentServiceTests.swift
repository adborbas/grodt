@testable import Grodt
import Testing
import Vapor

struct InvestmentServiceTests {

    // MARK: - allInvestments

    @Test func allInvestments_withTransactions_returnsMappedInvestments() async throws {
        let userID = UUID()
        let transaction1 = Transaction.stub(ticker: "AAPL")
        let transaction2 = Transaction.stub(ticker: "GOOGL")

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allTransactionsResult = .success([transaction1, transaction2])

        let expectedInvestments = [InvestmentDTO.stub(shortName: "AAPL"), InvestmentDTO.stub(shortName: "GOOGL")]
        let mockMapper = MockInvestmentDTOMapper()
        mockMapper.investmentsResult = .success(expectedInvestments)

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        let result = try await service.allInvestments(for: userID)

        #expect(result.count == 2)
        #expect(result[0].shortName == "AAPL")
        #expect(result[1].shortName == "GOOGL")
    }

    @Test func allInvestments_noTransactions_returnsEmptyArray() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allTransactionsResult = .success([])

        let mockMapper = MockInvestmentDTOMapper()
        mockMapper.investmentsResult = .success([])

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        let result = try await service.allInvestments(for: UUID())

        #expect(result.isEmpty)
    }

    @Test func allInvestments_mapperThrows_throws() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allTransactionsResult = .success([Transaction.stub()])

        let mockMapper = MockInvestmentDTOMapper()
        mockMapper.investmentsResult = .failure(Abort(.internalServerError))

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.allInvestments(for: UUID())
        }
    }

    @Test func allInvestments_repositoryThrows_throws() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allTransactionsResult = .failure(Abort(.internalServerError))

        let mockMapper = MockInvestmentDTOMapper()

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.allInvestments(for: UUID())
        }
    }

    // MARK: - investmentDetail

    @Test func investmentDetail_withMatchingTransactions_returnsMappedDetail() async throws {
        let userID = UUID()
        let transaction = Transaction.stub(ticker: "AAPL")

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.transactionsResult = .success([transaction])

        let expectedDetail = InvestmentDetailDTO.stub(shortName: "AAPL")
        let mockMapper = MockInvestmentDTOMapper()
        mockMapper.investmentDetailResult = .success(expectedDetail)

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        let result = try await service.investmentDetail(for: "AAPL", userID: userID)

        #expect(result.shortName == "AAPL")
    }

    @Test func investmentDetail_mapperThrows_throws() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.transactionsResult = .success([Transaction.stub()])

        let mockMapper = MockInvestmentDTOMapper()
        mockMapper.investmentDetailResult = .failure(Abort(.notFound))

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.investmentDetail(for: "AAPL", userID: UUID())
        }
    }

    @Test func investmentDetail_repositoryThrows_throws() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.transactionsResult = .failure(Abort(.internalServerError))

        let mockMapper = MockInvestmentDTOMapper()

        let service = InvestmentService(
            portfolioRepository: mockPortfolioRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.investmentDetail(for: "AAPL", userID: UUID())
        }
    }
}
