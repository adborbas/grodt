@testable import Grodt
import Testing
import Vapor
import Fluent

struct PortfolioServiceTests {

    // MARK: - allPortfolios

    @Test func allPortfolios_returnsMappedPortfolios() async throws {
        let userID = UUID()
        let portfolio1 = Portfolio.stub(name: "Portfolio 1")
        let portfolio2 = Portfolio.stub(name: "Portfolio 2")

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allPortfoliosResult = .success([portfolio1, portfolio2])

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()

        let expectedDTO = PortfolioInfoDTO.stub(name: "Mapped Portfolio")
        let mockMapper = MockPortfolioDTOMapper()
        mockMapper.portfolioInfoResult = .success(expectedDTO)

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.allPortfolios(userID: userID)

        #expect(result.count == 2)
    }

    @Test func allPortfolios_emptyList_returnsEmptyArray() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.allPortfoliosResult = .success([])

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.allPortfolios(userID: UUID())

        #expect(result.isEmpty)
    }

    // MARK: - create

    @Test func create_validCurrency_createsAndReturnsMappedPortfolio() async throws {
        let userID = UUID()
        let currency = Currency.stub(code: "USD")

        let mockPortfolioRepo = MockPortfolioRepository()

        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(currency)

        let mockDailyRepo = MockPortfolioDailyPerformanceReading()

        let expectedDTO = PortfolioDTO.stub(name: "New Portfolio")
        let mockMapper = MockPortfolioDTOMapper()
        mockMapper.portfolioResult = .success(expectedDTO)

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let request = CreatePortfolioRequestDTO.stub(name: "New Portfolio", currency: "USD")
        let result = try await service.create(request: request, userID: userID)

        #expect(mockPortfolioRepo.createCalled)
        #expect(result.name == "New Portfolio")
    }

    @Test func create_invalidCurrency_throwsBadRequest() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()

        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(nil)

        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let request = CreatePortfolioRequestDTO.stub(name: "New Portfolio", currency: "INVALID")

        await #expect(throws: Abort.self) {
            _ = try await service.create(request: request, userID: UUID())
        }
    }

    // MARK: - portfolioDetail

    @Test func portfolioDetail_existingPortfolio_returnsMappedPortfolio() async throws {
        let portfolioID = UUID()
        let userID = UUID()
        let portfolio = Portfolio.stub(id: portfolioID, name: "Detail Portfolio")

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(portfolio)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()

        let expectedDTO = PortfolioDTO.stub(name: "Detail Portfolio")
        let mockMapper = MockPortfolioDTOMapper()
        mockMapper.portfolioResult = .success(expectedDTO)

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.portfolioDetail(for: portfolioID, userID: userID)

        #expect(result.name == "Detail Portfolio")
    }

    @Test func portfolioDetail_nonExistentPortfolio_throwsNotFound() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.portfolioDetail(for: UUID(), userID: UUID())
        }
    }

    // MARK: - updateName

    @Test func updateName_existingPortfolio_updatesAndReturnsMappedPortfolio() async throws {
        let portfolioID = UUID()
        let userID = UUID()
        let portfolio = Portfolio.stub(id: portfolioID, name: "Old Name")

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(portfolio)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()

        let expectedDTO = PortfolioDTO.stub(name: "New Name")
        let mockMapper = MockPortfolioDTOMapper()
        mockMapper.portfolioResult = .success(expectedDTO)

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.updateName(with: portfolioID, forUser: userID, newName: "New Name")

        #expect(mockPortfolioRepo.updateCalled)
        #expect(result.name == "New Name")
    }

    @Test func updateName_nonExistentPortfolio_throwsNotFound() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.updateName(with: UUID(), forUser: UUID(), newName: "New Name")
        }
    }

    // MARK: - delete

    @Test func delete_existingPortfolio_deletesSuccessfully() async throws {
        let portfolioID = UUID()
        let userID = UUID()

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.deleteResult = .success(())

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.delete(for: portfolioID, userID: userID)

        #expect(mockPortfolioRepo.deleteCalled)
        #expect(result == .ok)
    }

    @Test func delete_noResults_returnsOk() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.deleteResult = .failure(FluentError.noResults)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.delete(for: UUID(), userID: UUID())

        #expect(result == .ok)
    }

    // MARK: - historicalPerformance

    @Test func historicalPerformance_existingPortfolio_returnsTimeSeries() async throws {
        let portfolioID = UUID()
        let userID = UUID()
        let portfolio = Portfolio.stub(id: portfolioID)

        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(portfolio)

        let mockCurrencyRepo = MockCurrencyRepository()

        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        mockDailyRepo.readSeriesResult = .success([])

        let expectedTimeSeries = PerformanceTimeSeriesDTO(values: [])
        let mockMapper = MockPortfolioDTOMapper()
        mockMapper.timeSeriesPerformanceResult = expectedTimeSeries

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.historicalPerformance(for: portfolioID, userID: userID)

        #expect(result.values.isEmpty)
    }

    @Test func historicalPerformance_nonExistentPortfolio_throwsNotFound() async throws {
        let mockPortfolioRepo = MockPortfolioRepository()
        mockPortfolioRepo.portfolioResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockDailyRepo = MockPortfolioDailyPerformanceReading()
        let mockMapper = MockPortfolioDTOMapper()

        let service = PortfolioService(
            portfolioRepository: mockPortfolioRepo,
            currencyRepository: mockCurrencyRepo,
            portfolioDailyRepo: mockDailyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.historicalPerformance(for: UUID(), userID: UUID())
        }
    }
}
