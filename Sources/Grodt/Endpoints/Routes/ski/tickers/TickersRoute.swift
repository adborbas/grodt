import Vapor
import CollectionConcurrencyKit

class TickersRoute: RouteCollection {
    private let service: TickersService
    
    init(service: TickersService) {
        self.service = service
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let tickers = routes.grouped("tickers")
        tickers.post(use: create)
        
        tickers.get("search", ":keyword", use: search)
    }
    
    func create(req: Request) async throws -> TickerDTO {
        let postTicker = try req.content.decode(TickerDTO.self)
        let ticker = Ticker(symbol: postTicker.symbol,
                            region: postTicker.region,
                               name: postTicker.name,
                               currency: postTicker.currency)
        
        return try await service.create(ticker)
    }
    
    func search(req: Request) async throws -> [TickerDTO] {
        let keyword: String = try req.requiredParameter(named: "keyword")
        return try await service.search(keyword: keyword)
    }
}
