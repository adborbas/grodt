@testable import Grodt
import Testing
import Vapor

struct HomeServiceTests {

    // MARK: - home

    @Test func home_withData_returnsCompleteHomeResponse() async throws {
        let userID = UUID()

        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([
            .stub(name: "Portfolio 1", performance: PerformanceDTO(invested: 100, currentValue: 110, profit: 10, totalReturn: 0.1)),
            .stub(name: "Portfolio 2", performance: PerformanceDTO(invested: 200, currentValue: 220, profit: 20, totalReturn: 0.1))
        ])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .success(.stub(name: "Test User"))

        let mockBrokerageService = MockBrokerageService()
        mockBrokerageService.allBrokeragesResult = .success([
            .stub(name: "Brokerage 1", accounts: [.stub()], performance: PerformanceDTO(invested: 1000, currentValue: 1100, profit: 100, totalReturn: 0.1))
        ])

        let mockInvestmentService = MockInvestmentService()
        mockInvestmentService.allInvestmentsResult = .success([
            .stub(shortName: "AAPL"),
            .stub(shortName: "GOOGL")
        ])

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        let result = try await service.home(for: userID)

        #expect(result.user.name == "Test User")
        #expect(result.portfolios.count == 2)
        #expect(result.brokerages.count == 1)
        #expect(result.investments.count == 2)
        #expect(result.networth.invested == 300)
        #expect(result.networth.currentValue == 330)
        #expect(result.networth.profit == 30)
    }

    @Test func home_emptyData_returnsEmptyArraysAndZeroNetworth() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .success(.stub())

        let mockBrokerageService = MockBrokerageService()
        mockBrokerageService.allBrokeragesResult = .success([])

        let mockInvestmentService = MockInvestmentService()
        mockInvestmentService.allInvestmentsResult = .success([])

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        let result = try await service.home(for: UUID())

        #expect(result.portfolios.isEmpty)
        #expect(result.brokerages.isEmpty)
        #expect(result.investments.isEmpty)
        #expect(result.networth.invested == 0)
        #expect(result.networth.currentValue == 0)
        #expect(result.networth.profit == 0)
    }

    @Test func home_portfolioServiceThrows_throws() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .failure(Abort(.internalServerError))

        let mockAccountService = MockAccountService()
        let mockBrokerageService = MockBrokerageService()
        let mockInvestmentService = MockInvestmentService()

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        await #expect(throws: Abort.self) {
            _ = try await service.home(for: UUID())
        }
    }

    @Test func home_accountServiceThrows_throws() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .failure(Abort(.notFound))

        let mockBrokerageService = MockBrokerageService()
        let mockInvestmentService = MockInvestmentService()

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        await #expect(throws: Abort.self) {
            _ = try await service.home(for: UUID())
        }
    }

    @Test func home_brokerageServiceThrows_throws() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .success(.stub())

        let mockBrokerageService = MockBrokerageService()
        mockBrokerageService.allBrokeragesResult = .failure(Abort(.internalServerError))

        let mockInvestmentService = MockInvestmentService()

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        await #expect(throws: Abort.self) {
            _ = try await service.home(for: UUID())
        }
    }

    @Test func home_investmentServiceThrows_throws() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .success(.stub())

        let mockBrokerageService = MockBrokerageService()
        mockBrokerageService.allBrokeragesResult = .success([])

        let mockInvestmentService = MockInvestmentService()
        mockInvestmentService.allInvestmentsResult = .failure(Abort(.internalServerError))

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        await #expect(throws: Abort.self) {
            _ = try await service.home(for: UUID())
        }
    }

    @Test func home_calculatesNetworthCorrectly() async throws {
        let mockPortfolioService = MockPortfolioService()
        mockPortfolioService.allPortfoliosResult = .success([
            .stub(performance: PerformanceDTO(invested: 1000, currentValue: 1500, profit: 500, totalReturn: 0.5)),
            .stub(performance: PerformanceDTO(invested: 2000, currentValue: 2100, profit: 100, totalReturn: 0.05)),
            .stub(performance: PerformanceDTO(invested: 500, currentValue: 400, profit: -100, totalReturn: -0.2))
        ])

        let mockAccountService = MockAccountService()
        mockAccountService.userInfoResult = .success(.stub())

        let mockBrokerageService = MockBrokerageService()
        mockBrokerageService.allBrokeragesResult = .success([])

        let mockInvestmentService = MockInvestmentService()
        mockInvestmentService.allInvestmentsResult = .success([])

        let service = HomeService(
            portfolioService: mockPortfolioService,
            accountService: mockAccountService,
            brokerageService: mockBrokerageService,
            investmentService: mockInvestmentService
        )

        let result = try await service.home(for: UUID())

        #expect(result.networth.invested == 3500)
        #expect(result.networth.currentValue == 4000)
        #expect(result.networth.profit == 500)
        #expect(result.networth.totalReturn == Decimal(string: "0.14")!) // 500/3500 rounded to 2 decimals
    }
}
