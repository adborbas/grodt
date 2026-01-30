@testable import Grodt
import Vapor

final class MockTickersService: TickersServicing, @unchecked Sendable {
    var allTickersResult: Result<[TickerDTO], Error> = .success([])
    var createResult: Result<TickerDTO, Error>?
    var searchResult: Result<[TickerDTO], Error> = .success([])

    func allTickers() async throws -> [TickerDTO] {
        try allTickersResult.get()
    }

    func create(_ ticker: Ticker) async throws -> TickerDTO {
        guard let result = createResult else {
            throw Abort(.notImplemented)
        }
        return try result.get()
    }

    func search(keyword: String) async throws -> [TickerDTO] {
        try searchResult.get()
    }
}
