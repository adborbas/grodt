import Vapor
import Fluent

struct BrokerageAccountsService: BrokerageAccountsServicing {
    private let brokerageRepository: BrokerageRepository
    private let brokerageAccountRepository: BrokerageAccountRepository
    private let performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository
    private let currencyMapper: CurrencyDTOMapper
    private let performanceDTOMapper: DatedPerformanceDTOMapper
    private let currencyRepository: CurrencyRepository
    private let transactionDTOMapper: TransactionDTOMapper

    init(brokerageRepository: BrokerageRepository,
         brokerageAccountRepository: BrokerageAccountRepository,
         performanceRepository: PostgresBrokerageAccountDailyPerformanceRepository,
         performanceDTOMapper: DatedPerformanceDTOMapper,
         currencyMapper: CurrencyDTOMapper,
         transactionDTOMapper: TransactionDTOMapper,
         currencyRepository: CurrencyRepository) {
        self.brokerageRepository = brokerageRepository
        self.brokerageAccountRepository = brokerageAccountRepository
        self.performanceRepository = performanceRepository
        self.performanceDTOMapper = performanceDTOMapper
        self.currencyMapper = currencyMapper
        self.transactionDTOMapper = transactionDTOMapper
        self.currencyRepository = currencyRepository
    }

    func allAccounts(for userID: User.IDValue) async throws -> [BrokerageAccountInfoDTO] {
        let brokerageAccounts = try await brokerageAccountRepository.all(for: userID)
        return try await brokerageAccounts.asyncMap { brokerageAccount in
            let performance = try await brokerageAccountRepository.performance(for: brokerageAccount.requireID())
            let brokerage = brokerageAccount.brokerage
            return BrokerageAccountInfoDTO(
                id: try brokerageAccount.requireID(),
                brokerageId: try brokerage.requireID(),
                brokerageName: brokerage.name,
                displayName: brokerageAccount.displayName,
                baseCurrency: currencyMapper.currency(from: brokerageAccount.baseCurrency),
                performance: performance)
        }
    }

    func detail(for id: UUID, userID: User.IDValue) async throws -> BrokerageAccountDTO {
        let model = try await requireAccount(id, userID: userID)
        let brokerage = model.brokerage
        let transactions = try await brokerageAccountRepository.transactions(for: id)
        let performance = try await brokerageAccountRepository.performance(for: model.requireID())
        let historicalPerformance = try await performanceSeries(for: id, userID: userID)

        return BrokerageAccountDTO(
            id: try model.requireID(),
            brokerageId: try brokerage.requireID(),
            brokerageName: brokerage.name,
            displayName: model.displayName,
            baseCurrency: currencyMapper.currency(from: model.baseCurrency),
            performance: performance,
            transactions: try await transactions.asyncMap { try await transactionDTOMapper.transaction(from: $0) },
            historicalPerformance: historicalPerformance
        )
    }

    func update(id: UUID, displayName: String, userID: User.IDValue) async throws -> HTTPStatus {
        let model = try await requireAccount(id, userID: userID)
        model.displayName = displayName
        try await brokerageAccountRepository.update(model)
        return .ok
    }

    func delete(id: UUID, userID: User.IDValue) async throws -> HTTPStatus {
        let model = try await requireAccount(id, userID: userID)
        try await brokerageAccountRepository.delete(model)
        return .noContent
    }

    func create(_ request: CreateBrokerageAccountDTO, on brokerageID: Brokerage.IDValue, for userID: User.IDValue) async throws -> BrokerageAccountDTO {
        guard let currency = try await currencyRepository.currency(for: request.currency) else {
            throw Abort(.badRequest)
        }

        guard let brokerage = try await brokerageRepository.find(brokerageID, for: userID)
        else { throw Abort(.notFound, reason: "Brokerage not found") }

        let model = BrokerageAccount(brokerageID: brokerageID,
                                     displayName: request.displayName,
                                     baseCurrency: currency)

        try await brokerageAccountRepository.create(model)
        return BrokerageAccountDTO(id: try model.requireID(),
                                   brokerageId: try brokerage.requireID(),
                                   brokerageName: brokerage.name,
                                   displayName: model.displayName,
                                   baseCurrency: currencyMapper.currency(from: model.baseCurrency),
                                   performance: PerformanceDTO.zero,
                                   transactions: [],
                                   historicalPerformance: PerformanceTimeSeriesDTO(values: []))
    }

    private func requireAccount(_ id: UUID, userID: UUID) async throws -> BrokerageAccount {
        guard let model = try await brokerageAccountRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        return model
    }

    private func performanceSeries(for id: UUID, userID: User.IDValue) async throws -> PerformanceTimeSeriesDTO {
        let account = try await requireAccount(id, userID: userID)
        let rows = try await performanceRepository.readSeries(for: account.requireID(), from: nil, to: nil)
        let values = rows.map { performanceDTOMapper.performancePoint(from: $0) }
            .sorted { $0.date < $1.date }
        return PerformanceTimeSeriesDTO(values: values)
    }
}

struct CreateBrokerageAccountDTO: ResponseDTO {
    let displayName: String
    let currency: String
}
