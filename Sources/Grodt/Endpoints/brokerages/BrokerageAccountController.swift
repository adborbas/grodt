import Vapor
import Fluent

struct BrokerageAccountController: RouteCollection {
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository
    private let currencyMapper: CurrencyDTOMapper
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    private let currencyRepository: CurrencyRepository
    
    init(brokerageAccountRepository: BrokerageAccountRepository,
         performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository,
         performanceDTOMapper: DatedPerformanceDTOMapper,
         currencyMapper: CurrencyDTOMapper,
         currencyRepository: CurrencyRepository) {
        self.brokerageAccountRepository = brokerageAccountRepository
        self.performanceRepository = performanceRepository
        self.performanceDTOMapper = performanceDTOMapper
        self.currencyMapper = currencyMapper
        self.currencyRepository = currencyRepository
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("brokerage-accounts")
        group.get(use: list)
        group.post(use: create)
        group.group(":id") { item in
            item.get(use: detail)
            item.put(use: update)
            item.delete(use: remove)
            item.get("performance", use: performanceSeries)
        }
    }

    private func list(req: Request) async throws -> [BrokerageAccountDTO] {
        let userID = try req.requireUserID()
        let items = try await brokerageAccountRepository.all(for: userID)
        return try await items.asyncMap { model in
            let performance = try await brokerageAccountRepository.performance(for: model.requireID())
            let brokerage = try await model.$brokerage.get(on: req.db)
            return BrokerageAccountDTO(
                id: try model.requireID(),
                brokerageId: try brokerage.requireID(),
                brokerageName: brokerage.name,
                displayName: model.displayName,
                baseCurrency: currencyMapper.currency(from: model.baseCurrency),
                performance: performance)
        }
    }

    private func create(req: Request) async throws -> BrokerageAccountDTO {
        let userID = try req.requireUserID()
        struct In: Content {
            let brokerageID: UUID
            let displayName: String
            let currency: String
        }
        let input = try req.content.decode(In.self)
        guard let currency = try await currencyRepository.currency(for: input.currency) else {
            throw Abort(.badRequest)
        }

        guard let brokerage = try await Brokerage.query(on: req.db)
            .filter(\.$id == input.brokerageID)
            .filter(\.$user.$id == userID)
            .first()
        else { throw Abort(.notFound, reason: "Brokerage not found") }

        let model = BrokerageAccount(brokerageID: try brokerage.requireID(),
                                     displayName: input.displayName,
                                     baseCurrency: currency)
        
        try await brokerageAccountRepository.create(model)
        return BrokerageAccountDTO(id: try model.requireID(),
                                   brokerageId: try brokerage.requireID(),
                                   brokerageName: brokerage.name,
                                   displayName: model.displayName,
                                   baseCurrency: currencyMapper.currency(from: model.baseCurrency),
                                   performance: PerformanceDTO.zero)
    }

    private func detail(req: Request) async throws -> BrokerageAccountDTO {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        let brokerage = try await model.$brokerage.get(on: req.db)
        let performance = try await brokerageAccountRepository.performance(for: model.requireID())
        return BrokerageAccountDTO(id: try model.requireID(),
                                   brokerageId: try brokerage.requireID(),
                                   brokerageName: brokerage.name,
                                   displayName: model.displayName,
                                   baseCurrency: currencyMapper.currency(from: model.baseCurrency),
                                   performance: performance)
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        struct In: Content { let displayName: String; let accountNumberMasked: String? }
        let input = try req.content.decode(In.self)
        model.displayName = input.displayName
        try await brokerageAccountRepository.update(model)
        return .ok
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        try await brokerageAccountRepository.delete(model)
        return .noContent
    }

    private func performanceSeries(req: Request) async throws -> PerformanceTimeSeriesDTO {
        let userID = try req.requireUserID()
        let account = try await requireAccount(req, userID: userID)
        let rows = try await performanceRepository.readSeries(for: account.requireID(),
                                                              from: nil,
                                                              to: nil)
        
        let values =  rows.map { performanceDTOMapper.performancePoint(from: $0)  }
            .sorted { $0.date < $1.date }
        return PerformanceTimeSeriesDTO(values: values)
    }

    private func requireAccount(_ req: Request, userID: UUID) async throws -> BrokerageAccount {
        let id = try req.parameters.require("id", as: UUID.self)
        guard let model = try await brokerageAccountRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        return model
    }
}

extension BrokerageAccountDTO: Content { }
