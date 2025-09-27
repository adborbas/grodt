import Vapor
import Fluent

struct BrokerageAccountsService {
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
}

struct CreateBrokerageAccountDTO: ResponseDTO {
    let displayName: String
    let currency: String
}
