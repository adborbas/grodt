import Vapor
import Fluent

struct BrokerageController: RouteCollection {
    let brokerages: BrokerageRepository
    let accounts: BrokerageAccountRepository
    let currencyMapper: CurrencyDTOMapper

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
        let items = try await brokerages.list(for: userID, on: req.db)
        return try await items.asyncMap { try await map($0, using: req.db) }
    }

    private func create(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        struct In: Content { let name: String }
        let input = try req.content.decode(In.self)
        let item = Brokerage(userID: userID, name: input.name)
        try await brokerages.create(item, on: req.db)
        return BrokerageDTO(id: try item.requireID(),
                            name: item.name,
                            accounts: [],
                            totals: nil)
    }

    private func detail(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        return try await map(brokerage, using: req.db)
    }
    
    private func map(_ brokerage: Brokerage, using db: Database) async throws -> BrokerageDTO {
        let accounts = try await brokerage.$accounts.get(on: db)
        let totals = try await brokerages.totals(for: brokerage.requireID(), on: db)
        return BrokerageDTO(id: try brokerage.requireID(),
                            name: brokerage.name,
                            accounts: accounts.map { BrokerageAccountDTO(id: $0.id!,
                                                                         brokerageId: brokerage.id!,
                                                                         brokerageName: brokerage.name,
                                                                         displayName: $0.displayName,
                                                                         baseCurrency: currencyMapper.currency(from: $0.baseCurrency),
                                                                         totals: PerformanceTotalsDTO(value: totals?.value ?? 0, moneyIn: totals?.moneyIn ?? 0))},
                            totals: totals)
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        struct In: Content { let name: String }
        let input = try req.content.decode(In.self)
        brokerage.name = input.name
        try await brokerages.update(brokerage, on: req.db)
        return .ok
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let brokerage = try await requireBrokerage(req, userID: userID)
        try await brokerages.delete(brokerage, on: req.db)
        return .noContent
    }

    private func performanceSeries(req: Request) async throws -> [PerformancePointDTO] {
        let userID = try req.requireUserID()
        _ = try await requireBrokerage(req, userID: userID)
        let id = try req.parameters.require("id", as: UUID.self)
        let rows = try await HistoricalBrokeragePerformance.query(on: req.db)
            .filter(\.$brokerage.$id == id)
            .sort(\.$date, .ascending)
            .all()

        return rows.map { .init(date: $0.date, value: $0.value, moneyIn: $0.moneyIn) }
    }

    private func requireBrokerage(_ req: Request, userID: UUID) async throws -> Brokerage {
        let id = try req.parameters.require("id", as: UUID.self)
        guard let model = try await brokerages.find(id, for: userID, on: req.db) else {
            throw Abort(.notFound)
        }
        return model
    }
}

extension BrokerageDTO: Content { }
