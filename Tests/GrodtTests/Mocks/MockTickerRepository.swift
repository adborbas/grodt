@testable import Grodt

final class MockTickerRepository: TickerRepository, @unchecked Sendable {
    var allTickersResult: Result<[Ticker], Error> = .success([])
    var tickersForSymbolResult: Result<Ticker?, Error> = .success(nil)
    var saveResult: Result<Void, Error> = .success(())

    private(set) var saveCalled = false
    private(set) var savedTicker: Ticker?

    func allTickers() async throws -> [Ticker] {
        try allTickersResult.get()
    }

    func tickers(for symbol: String) async throws -> Ticker? {
        try tickersForSymbolResult.get()
    }

    func save(_ ticker: Ticker) async throws {
        saveCalled = true
        savedTicker = ticker
        try saveResult.get()
    }
}
