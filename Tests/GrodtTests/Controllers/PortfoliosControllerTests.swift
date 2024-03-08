@testable import Grodt
import XCTVapor

final class PortfoliosControllerTests: GrodtControllerTestCase {
    override var basePath: String { return "api/portfolios" }
    
    // MARK: - Portfolios
    func test_GivenNoPortfolios_WhenPortfoliosCalled_ThenExpectEmptyResponse() async throws {
        // When
        let response = try await sendRequest(.GET)
        
        // Then
        XCTAssertEqual(response.status, .ok)
        let portfolios = try response.content.decode([PortfolioInfoDTO].self)
        XCTAssertEqual(portfolios.count, 0)
    }
    
    func test_GivenSinglePortfolios_WhenPortfoliosCalled_ThenExpectResponse() async throws {
        // Given
        let expectedPortfolioInfo = TestConstant.PortfolioInfoDTOs.new
        try await givenPortfolio(expectedPortfolioInfo)
        
        // When
        let response = try await sendRequest(.GET)
        
        // Then
        XCTAssertEqual(response.status, .ok)
        let portfolioInfos = try response.content.decode([PortfolioInfoDTO].self)
        XCTAssertEqual(portfolioInfos, [expectedPortfolioInfo])
    }
    
    // MARK: - Create
    func test_GivenCurrencyExists_WhenCreatePortfolioCalled_ThenExpectNewPortfolioToReturn() async throws {
        // Given
        let expectedPortfolioInfo = TestConstant.PortfolioInfoDTOs.new
        let newPortfolioDTO = CreatePortfolioRequestDTO(name: expectedPortfolioInfo.name,
                                                        currency: expectedPortfolioInfo.currency.code)
        
        // When
        let response = try await sendPostRequest(body: newPortfolioDTO)
        
        // Then
        XCTAssertEqual(response.status, .ok)
        let portfolioInfo = try response.content.decode(PortfolioInfoDTO.self)
        XCTAssertEqualExceptID(portfolioInfo, expectedPortfolioInfo)
    }

    // MARK: - Details
    func test_GivenNoPortfolios_WhenPortfolioDetailCalled_ThenExpectEmptyResponse() async throws {
        // When
        let response = try await sendRequest(.GET, "\(TestConstant.PortfolioInfoDTOs.new.id)")
        
        // Then
        XCTAssertEqual(response.status, .notFound)
    }
    
    func test_GivenPortfolios_WhenPortfolioDetailCalled_ThenExpectResponse() async throws {
        // Given
        let expectedPortfolio = TestConstant.PortfolioDTOs.new
        try await givenPortfolio(expectedPortfolio)
        
        // When
        let response = try await sendRequest(.GET, "\(expectedPortfolio.id)")
        
        // Then
        XCTAssertEqual(response.status, .ok)
        let actualPortfolio = try response.content.decode(PortfolioDTO.self)
        XCTAssertEqual(actualPortfolio, expectedPortfolio)
    }
    
    // MARK: - Delete
    func test_GivenNoPortfolio_WhenDeleteCalled_ThenExpectOK() async throws {
        // When
        let response = try await sendRequest(.DELETE, "\(TestConstant.PortfolioInfoDTOs.new.id)")
        
        // Then
        XCTAssertEqual(response.status, .ok)
    }
    
    func test_GivenPortfolio_WhenDeleteCalled_ThenExpectOK() async throws {
        // Given
        let expectedPortfolio = TestConstant.PortfolioDTOs.new
        try await givenPortfolio(expectedPortfolio)
        
        // When
        let response = try await sendRequest(.DELETE, "\(expectedPortfolio.id)")
        
        // Then
        XCTAssertEqual(response.status, .ok)
    }

    private func givenPortfolio(_ portfolioDTO: PortfolioDTO) async throws {
        let portfolio = Portfolio(id: UUID(uuidString: portfolioDTO.id),
                                  userID: user.id!,
                                  name: portfolioDTO.name,
                                  currency: portfolioDTO.currency.model)
        try await portfolio.save(on: database)
    }
    
    private func givenPortfolio(_ portfolioInfoDTO: PortfolioInfoDTO) async throws {
        let portfolio = Portfolio(id: UUID(uuidString: portfolioInfoDTO.id),
                                  userID: user.id!,
                                  name: portfolioInfoDTO.name,
                                  currency: portfolioInfoDTO.currency.model)
        try await portfolio.save(on: database)
    }
}

extension CreatePortfolioRequestDTO: Content { }
