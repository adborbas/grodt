import Vapor
import CollectionConcurrencyKit
import AlphaSwiftage

protocol TickersControllerDelegate: AnyObject {
    func tickerCreated(_ ticker: Ticker)
}

struct TickersController: RouteCollection {
    private let tickerRepository: TickerRepository
    private let dataMapper: TickerDTOMapper
    private let tickerService: AlphaVantageService
    
    var delegate: TickersControllerDelegate? // TODO: Weak
    
    init(tickerRepository: TickerRepository,
         dataMapper: TickerDTOMapper,
         tickerService: AlphaVantageService) {
        self.tickerRepository = tickerRepository
        self.dataMapper = dataMapper
        self.tickerService = tickerService
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let tickers = routes.grouped("tickers")
        tickers.get(use: allTickers)
        tickers.post(use: create)
        
        tickers.get("search", ":keyword", use: search)
    }
    
    func allTickers(req: Request) async throws -> [TickerDTO] {
        return try await tickerRepository.allTickers()
            .concurrentCompactMap { ticker in
                return dataMapper.ticker(from: ticker)
            }
    }
    
    func create(req: Request) async throws -> TickerDTO {
        let postTicker = try req.content.decode(TickerDTO.self)
        let ticker = Ticker(symbol: postTicker.symbol,
                            region: postTicker.region,
                               name: postTicker.name,
                               currency: postTicker.currency)
        
        try await ticker.save(on: req.db)
        delegate?.tickerCreated(ticker)
        return postTicker
    }
    
    func search(req: Request) async throws -> [TickerDTO] {
        let keyword: String = try req.requiredParameter(named: "keyword")
        
        let result = await tickerService.symbolSearch(keywords: keyword)
        switch result {
        case .success(let symbols):
            return symbols.compactMap { symbol in
                return TickerDTO(symbol: symbol.symbol,
                                 region: symbol.region,
                                 name: symbol.name,
                                 currency: symbol.currency)
            }
        case .failure(let error):
            throw Abort(.custom(code: 500, reasonPhrase: error.localizedDescription))
        }
    }
}

extension TickerDTO: Content { }
