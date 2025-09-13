import Vapor
import Fluent

struct BrokerageController: RouteCollection {
    private let brokerageRepository: BrokerageRepository
    private let dtoMapper: BrokerageDTOMapper
    private let accounts: BrokerageAccountRepository
    private let currencyMapper: CurrencyDTOMapper
    private let performanceRepository: PostgresBrokerageDailyPerformanceRepository
    private let performancePointDTOMapper: PerformancePointDTOMapper
    
    init(brokerageRepository: BrokerageRepository,
         dtoMapper: BrokerageDTOMapper,
         accounts: BrokerageAccountRepository,
         currencyMapper: CurrencyDTOMapper,
         performanceRepository: PostgresBrokerageDailyPerformanceRepository,
         performancePointDTOMapper: PerformancePointDTOMapper
    ) {
        self.brokerageRepository = brokerageRepository
        self.dtoMapper = dtoMapper
        self.accounts = accounts
        self.currencyMapper = currencyMapper
        self.performanceRepository = performanceRepository
        self.performancePointDTOMapper = performancePointDTOMapper
    }

    func boot(routes: RoutesBuilder) throws {
        let group = routes.grouped("brokerages")
        group.get(use: list)
        group.post(use: create)
        group.group(":id") { item in
            item.get(use: detail)
            item.put(use: update)
            item.delete(use: remove)
            item.get("performance", use: performanceSeries)
        }
    }

    private func list(req: Request) async throws -> [BrokerageDTO] {
        let userID = try req.requireUserID()
        let items = try await brokerageRepository.list(for: userID)
        return try await items.asyncMap { try await dtoMapper.brokerage(from: $0) }
    }

    private func create(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        let input = try req.content.decode(CreateUpdateBrokerageRequestDTO.self)
        let item = Brokerage(userID: userID, name: input.name)
        try await brokerageRepository.create(item)
        return BrokerageDTO(id: try item.requireID(),
                            name: item.name,
                            accounts: [],
                            totals: nil)
    }

    private func detail(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        return try await dtoMapper.brokerage(from: brokerage)
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        let input = try req.content.decode(CreateUpdateBrokerageRequestDTO.self)
        brokerage.name = input.name
        try await brokerageRepository.update(brokerage)
        return .ok
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        try await brokerageRepository.delete(brokerage)
        return .noContent
    }

    private func performanceSeries(req: Request) async throws -> [PerformancePointDTO] {
        let userID = try req.requireUserID()
        _ = try await requireBrokerage(req, userID: userID)
        let id = try req.parameters.require("id", as: UUID.self)
        let rows = try await performanceRepository.readSeries(for: id, from: nil, to: nil)
        return rows.map { performancePointDTOMapper.performancePoint(from: $0)  }
    }

    private func requireBrokerage(_ req: Request, userID: UUID) async throws -> Brokerage {
        let id = try req.parameters.require("id", as: UUID.self)
        guard let model = try await brokerageRepository.find(id, for: userID) else {
            throw Abort(.notFound)
        }
        return model
    }
}

extension BrokerageDTO: Content { }
