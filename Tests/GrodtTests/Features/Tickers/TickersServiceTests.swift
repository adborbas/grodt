@testable import Grodt
import Testing
import Vapor

struct TickersServiceTests {

    // MARK: - allTickers

    @Test func allTickers_withTickers_returnsMappedTickers() async throws {
        let ticker1 = Ticker.stub(symbol: "AAPL")
        let ticker2 = Ticker.stub(symbol: "GOOGL")

        let mockRepo = MockTickerRepository()
        mockRepo.allTickersResult = .success([ticker1, ticker2])

        let mockMapper = MockTickerDTOMapper()
        mockMapper.tickerResult = .stub()

        let mockSearch = MockSymbolSearching()

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        let result = try await service.allTickers()

        #expect(result.count == 2)
    }

    @Test func allTickers_emptyList_returnsEmptyArray() async throws {
        let mockRepo = MockTickerRepository()
        mockRepo.allTickersResult = .success([])

        let mockMapper = MockTickerDTOMapper()
        let mockSearch = MockSymbolSearching()

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        let result = try await service.allTickers()

        #expect(result.isEmpty)
    }

    @Test func allTickers_repositoryThrows_throws() async throws {
        let mockRepo = MockTickerRepository()
        mockRepo.allTickersResult = .failure(Abort(.internalServerError))

        let mockMapper = MockTickerDTOMapper()
        let mockSearch = MockSymbolSearching()

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        await #expect(throws: Abort.self) {
            _ = try await service.allTickers()
        }
    }

    // MARK: - create

    @Test func create_savesTickerAndReturnsMappedDTO() async throws {
        let ticker = Ticker.stub(symbol: "AAPL")

        let mockRepo = MockTickerRepository()
        mockRepo.saveResult = .success(())

        let expectedDTO = TickerDTO.stub(symbol: "AAPL")
        let mockMapper = MockTickerDTOMapper()
        mockMapper.tickerResult = expectedDTO

        let mockSearch = MockSymbolSearching()

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        let result = try await service.create(ticker)

        #expect(mockRepo.saveCalled)
        #expect(result.symbol == "AAPL")
    }

    @Test func create_repositoryThrows_throws() async throws {
        let ticker = Ticker.stub()

        let mockRepo = MockTickerRepository()
        mockRepo.saveResult = .failure(Abort(.internalServerError))

        let mockMapper = MockTickerDTOMapper()
        let mockSearch = MockSymbolSearching()

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        await #expect(throws: Abort.self) {
            _ = try await service.create(ticker)
        }
    }

    // MARK: - search

    @Test func search_withResults_returnsMappedTickers() async throws {
        let mockRepo = MockTickerRepository()
        let mockMapper = MockTickerDTOMapper()

        let searchResults = [
            SymbolSearchResult.stub(symbol: "AAPL", name: "Apple Inc"),
            SymbolSearchResult.stub(symbol: "AMZN", name: "Amazon.com Inc")
        ]
        let mockSearch = MockSymbolSearching()
        mockSearch.searchResult = .success(searchResults)

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        let result = try await service.search(keyword: "A")

        #expect(result.count == 2)
        #expect(result[0].symbol == "AAPL")
        #expect(result[1].symbol == "AMZN")
    }

    @Test func search_emptyResults_returnsEmptyArray() async throws {
        let mockRepo = MockTickerRepository()
        let mockMapper = MockTickerDTOMapper()

        let mockSearch = MockSymbolSearching()
        mockSearch.searchResult = .success([])

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        let result = try await service.search(keyword: "ZZZZZ")

        #expect(result.isEmpty)
    }

    @Test func search_serviceFailure_throws() async throws {
        let mockRepo = MockTickerRepository()
        let mockMapper = MockTickerDTOMapper()

        let mockSearch = MockSymbolSearching()
        mockSearch.searchResult = .failure(NSError(domain: "test", code: 500))

        let service = TickersService(
            tickerRepository: mockRepo,
            dataMapper: mockMapper,
            tickerService: mockSearch
        )

        await #expect(throws: Abort.self) {
            _ = try await service.search(keyword: "A")
        }
    }
}
