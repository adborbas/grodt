import Foundation
import AlphaSwiftage

struct SymbolSearchResult: Sendable {
    let symbol: String
    let region: String
    let name: String
    let currency: String
}

protocol SymbolSearching: Sendable {
    func symbolSearch(keywords: String) async -> Result<[SymbolSearchResult], Error>
}

extension AlphaVantageService: SymbolSearching {
    func symbolSearch(keywords: String) async -> Result<[SymbolSearchResult], Error> {
        let result = await self.symbolSearch(keywords: keywords) as Result<[Symbol], AlphaVantageError>
        switch result {
        case .success(let symbols):
            return .success(symbols.map {
                SymbolSearchResult(symbol: $0.symbol, region: $0.region, name: $0.name, currency: $0.currency)
            })
        case .failure(let error):
            return .failure(error)
        }
    }
}
