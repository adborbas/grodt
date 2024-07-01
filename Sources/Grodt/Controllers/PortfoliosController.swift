import Vapor
import AlphaSwiftage
import Fluent
import CollectionConcurrencyKit

struct PortfoliosController: RouteCollection {
    private let portfolioRepository: PortfolioRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: PortfolioDTOMapper
    
    init(portfolioRepository: PortfolioRepository,
         currencyRepository: CurrencyRepository,
         dataMapper: PortfolioDTOMapper) {
        self.portfolioRepository = portfolioRepository
        self.currencyRepository = currencyRepository
        self.dataMapper = dataMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let portfolios = routes.grouped("portfolios")
        portfolios.get(use: allPortfolios)
        portfolios.post(use: create)
        
        portfolios.group(":id") { portfolio in
            portfolio.get(use: portfolioDetail)
            portfolio.delete(use: delete)
            
            portfolio.group("historicalPerformance") { pref in
                pref.get(use: historicalPerformance)
            }
        }
    }
    
    func allPortfolios(req: Request) async throws -> [PortfolioInfoDTO] {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        return try await portfolioRepository.allPortfolios(for: userID)
            .concurrentCompactMap { portfolio in
                return try await dataMapper.portfolioInfo(from: portfolio)
            }
    }
    
    func create(req: Request) async throws -> PortfolioDTO {
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let postPortfolio = try req.content.decode(CreatePortfolioRequestDTO.self)
        guard let currency = try await currencyRepository.currency(for: postPortfolio.currency) else {
            throw Abort(.badRequest)
        }
        
        let portfolio = Portfolio(userID: userID,
                                  name: postPortfolio.name,
                                  currency: currency)
        
        let newPortfolio = try await portfolioRepository.create(portfolio)
        return try await dataMapper.portfolio(from: newPortfolio)
    }
    
    func portfolioDetail(req: Request) async throws -> PortfolioDTO {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        guard let portfolio = try await portfolioRepository.portfolio(for: userID, with: id) else {
            throw Abort(.notFound)
        }
        
        return try await dataMapper.portfolio(from: portfolio)
                        
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        do {
            try await portfolioRepository.delete(for:  userID, with: id)
        } catch FluentError.noResults {
            return .ok
        }
        return .ok
    }
    
    func historicalPerformance(req: Request) async throws -> PortfolioPerformanceTimeSeriesDTO {
//        let alphavantage = AlphaVantageService(serviceType: .rapidAPI(apiKey: "1c4a060c45mshfa7aa094d7d967bp114334jsn0360bb424b2f"))
//        let results = await alphavantage.dailyAdjustedTimeSeries(for: "MSFT", outputSize: .full)
//        switch results {
//        case .failure(let error):
//            throw error
//        case .success(let rawSeries):
//            
//            let dateFormatter = DateFormatter()
//            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
//            dateFormatter.dateFormat = "yyyy-MM-dd"
//            
//            let datedPrices: [DatedPriceDTO] = rawSeries.compactMap { (key: String, value: EquityDailyData) in
//                guard let date = dateFormatter.date(from: key) else { return nil }
//                return DatedPriceDTO(date: date, price: value.adjustedClose)
//            }.sorted { $0.date < $1.date }
//            
//            return PortfolioPerformanceTimeSeriesDTO(values: datedPrices)
//        }
//        return generateStockData(startDate: Date(), startValue: 100, days: 365)
        
        let id = try req.requiredID()
        
        guard let userID = req.auth.get(User.self)?.id else {
            throw Abort(.badRequest)
        }
        
        let historicalPerformance = try await portfolioRepository.historicalPerformance(for: userID, with: id)
        return await dataMapper.timeSeriesPerformance(from: historicalPerformance)
        
//        return generateStockData(startDate: Date(), startValue: 100, days: 365)
    }
    
//    private func generateStockData(startDate: Date, startValue: Decimal, days: Int) -> PortfolioPerformanceTimeSeriesDTO {
//        var data: [DatedPortfolioPerformanceDTO] = []
//        var currentValue = startValue
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd"
//
//        for i in 0..<days {
//            guard let date = Calendar.current.date(byAdding: .day, value: i, to: startDate) else {
//                continue
//            }
//
//            let random = Double.random(in: 0...1)
//            if random < 0.3 {
//                // 30% of the time, decrease by -0.3% to -2%
//                let decreaseFactor = Decimal(Double.random(in: (-0.03)...(-0.002)) + 1)
//                            currentValue *= decreaseFactor
//            } else if random < 0.6 {
//                // 30% of the time, change by +0.2% to -0.3%
//                let changeFactor = Decimal(Double.random(in: -0.002...0.003) + 1)
//                currentValue *= changeFactor
//            } else {
//                // 40% of the time, increase by +1.1% to +0.2%
//                let increaseFactor = Decimal(Double.random(in: 0.002...0.011) + 1)
//                currentValue *= increaseFactor
//            }
//
//            data.append(DatedPortfolioPerformanceDTO(date: date, price: (currentValue * Decimal(100)) / Decimal(100)))
//        }
//
//        return PortfolioPerformanceTimeSeriesDTO(values: data)
//    }
}

extension PortfolioDTO: Content { }
extension PortfolioInfoDTO: Content { }
extension PortfolioPerformanceTimeSeriesDTO: Content { }
