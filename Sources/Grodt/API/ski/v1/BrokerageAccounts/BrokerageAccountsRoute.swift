import Vapor

class BrokerageAccountsRoute: RouteCollection {
    private let service: BrokerageAccountsService
    private let brokerageRepository: BrokerageRepository
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository
    private let currencyMapper: CurrencyDTOMapper
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    private let currencyRepository: CurrencyRepository
    private let transactionDTOMapper: TransactionDTOMapper
    
    init(service: BrokerageAccountsService,
         brokerageRepository: BrokerageRepository,
         brokerageAccountRepository: BrokerageAccountRepository,
         performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository,
         performanceDTOMapper: DatedPerformanceDTOMapper,
         currencyMapper: CurrencyDTOMapper,
         transactionDTOMapper: TransactionDTOMapper,
         currencyRepository: CurrencyRepository) {
        self.service = service
        self.brokerageRepository = brokerageRepository
        self.brokerageAccountRepository = brokerageAccountRepository
        self.performanceRepository = performanceRepository
        self.performanceDTOMapper = performanceDTOMapper
        self.currencyMapper = currencyMapper
        self.transactionDTOMapper = transactionDTOMapper
        self.currencyRepository = currencyRepository
    }
    
    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("brokerage-accounts")
        
        group.group(":id") { item in
            item.get(use: detail)
            item.put(use: update)
            item.delete(use: remove)
        }
    }

    private func detail(req: Request) async throws -> BrokerageAccountDTO {
        let id = try req.parameters.require("id", as: UUID.self)
        let userID = try req.requireUserID()
        let model = try await requireAccount(id, userID: userID)
        let brokerage = try await model.$brokerage.get(on: req.db)
        let transactions = try await model.$transactions.get(on: req.db)
        let performance = try await brokerageAccountRepository.performance(for: model.requireID())
        return try await BrokerageAccountDTO(id: try model.requireID(),
                                             brokerageId: try brokerage.requireID(),
                                             brokerageName: brokerage.name,
                                             displayName: model.displayName,
                                             baseCurrency: currencyMapper.currency(from: model.baseCurrency),
                                             performance: performance,
                                             transactions: transactions.asyncMap { try await transactionDTOMapper.transaction(from: $0) },
                                             historicalPerformance: performanceSeries(for: id, userID: userID))
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        let userID = try req.requireUserID()
        let model = try await requireAccount(id, userID: userID)
        struct In: Content { let displayName: String; let accountNumberMasked: String? }
        let input = try req.content.decode(In.self)
        model.displayName = input.displayName
        try await brokerageAccountRepository.update(model)
        return .ok
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        let userID = try req.requireUserID()
        let model = try await requireAccount(id, userID: userID)
        try await brokerageAccountRepository.delete(model)
        return .noContent
    }

    private func requireAccount(_ id: UUID, userID: UUID) async throws -> BrokerageAccount {
        guard let model = try await brokerageAccountRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        return model
    }
    
    private func performanceSeries(for id: UUID, userID: User.IDValue) async throws -> PerformanceTimeSeriesDTO {
        let account = try await requireAccount(id, userID: userID)
        let rows = try await performanceRepository.readSeries(for: account.requireID(),
                                                              from: nil,
                                                              to: nil)
        
        let values =  rows.map { performanceDTOMapper.performancePoint(from: $0)  }
            .sorted { $0.date < $1.date }
        return PerformanceTimeSeriesDTO(values: values)
    }
}

extension BrokerageAccountDTO: ResponseDTO { }
extension BrokerageAccountInfoDTO: ResponseDTO { }
