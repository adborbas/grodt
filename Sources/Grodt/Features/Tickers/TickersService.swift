import Vapor
import CollectionConcurrencyKit
import AlphaSwiftage

protocol TickersControllerDelegate: AnyObject {
    func tickerCreated(_ ticker: Ticker)
}

protocol TickersServicing: Sendable {
    func allTickers() async throws -> [TickerDTO]
    func create(_ ticker: Ticker) async throws -> TickerDTO
    func search(keyword: String) async throws -> [TickerDTO]
}

class TickersService: TickersServicing {
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
    
    func allTickers() async throws -> [TickerDTO] {
        return try await tickerRepository.allTickers()
            .concurrentCompactMap { ticker in
                return self.dataMapper.ticker(from: ticker)
            }
    }
    
    func create(_ ticker: Ticker) async throws -> TickerDTO {
        try await tickerRepository.save(ticker)
        delegate?.tickerCreated(ticker)
        return dataMapper.ticker(from: ticker)
    }
    
    func search(keyword: String) async throws -> [TickerDTO] {
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

extension TickerDTO: ResponseDTO { }
