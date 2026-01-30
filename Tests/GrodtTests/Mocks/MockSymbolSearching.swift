@testable import Grodt

final class MockSymbolSearching: SymbolSearching, @unchecked Sendable {
    var searchResult: Result<[SymbolSearchResult], Error> = .success([])

    func symbolSearch(keywords: String) async -> Result<[SymbolSearchResult], Error> {
        searchResult
    }
}
