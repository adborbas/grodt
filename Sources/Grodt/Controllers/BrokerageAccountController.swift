import Vapor
import Fluent

struct BrokerageAccountController: RouteCollection {
    let accounts: BrokerageAccountRepository

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
        let brokerageID = try? req.query.get(UUID.self, at: "brokerageId")
        let items = try await accounts.list(for: userID, brokerageID: brokerageID, on: req.db)
        return try await items.asyncMap { model in
            let totals = try await accounts.totals(for: model.requireID(), on: req.db)
            let brokerage = try await model.$brokerage.get(on: req.db)
            return BrokerageAccountDTO(
                id: try model.requireID(),
                brokerageId: try brokerage.requireID(),
                brokerageName: brokerage.name,
                displayName: model.displayName,
                baseCurrency: model.baseCurrency,
                totals: totals)
        }
    }

    private func create(req: Request) async throws -> BrokerageAccountDTO {
        let userID = try req.requireUserID()
        struct In: Content {
            let brokerageId: UUID
            let displayName: String
            let baseCurrency: Currency
        }
        let input = try req.content.decode(In.self)

        // Auth: ensure brokerage belongs to user
        guard let brokerage = try await Brokerage.query(on: req.db)
            .filter(\.$id == input.brokerageId)
            .filter(\.$user.$id == userID)
            .first()
        else { throw Abort(.notFound, reason: "Brokerage not found") }

        let model = BrokerageAccount(brokerageID: try brokerage.requireID(),
                                    displayName: input.displayName,
                                    baseCurrency: input.baseCurrency)
        try await accounts.create(model, on: req.db)
        return BrokerageAccountDTO(id: try model.requireID(),
                                   brokerageId: try brokerage.requireID(),
                                   brokerageName: brokerage.name,
                                   displayName: model.displayName,
                                   baseCurrency: model.baseCurrency,
                                   totals: nil)
    }

    private func detail(req: Request) async throws -> BrokerageAccountDTO {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        let brokerage = try await model.$brokerage.get(on: req.db)
        let totals = try await accounts.totals(for: model.requireID(), on: req.db)
        return BrokerageAccountDTO(id: try model.requireID(),
                                   brokerageId: try brokerage.requireID(),
                                   brokerageName: brokerage.name,
                                   displayName: model.displayName,
                                   baseCurrency: model.baseCurrency,
                                   totals: totals)
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        struct In: Content { let displayName: String; let accountNumberMasked: String? }
        let input = try req.content.decode(In.self)
        model.displayName = input.displayName
        try await accounts.update(model, on: req.db)
        return .ok
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let model = try await requireAccount(req, userID: userID)
        try await accounts.delete(model, on: req.db)
        return .noContent
    }

    private func performanceSeries(req: Request) async throws -> [PerformancePointDTO] {
        let userID = try req.requireUserID()
        let account = try await requireAccount(req, userID: userID)
        let rows = try await HistoricalBrokerageAccountPerformance.query(on: req.db)
            .filter(\.$account.$id == account.requireID())
            .sort(\.$date, .ascending)
            .all()
        return rows.map { PerformancePointDTO(date: $0.date, value: $0.value, moneyIn: $0.moneyIn) }
    }

    private func requireAccount(_ req: Request, userID: UUID) async throws -> BrokerageAccount {
        let id = try req.parameters.require("id", as: UUID.self)
        guard let model = try await accounts.find(id, for: userID, on: req.db) else {
            throw Abort(.notFound)
        }
        return model
    }
}

extension BrokerageAccountDTO: Content { }
extension PerformancePointDTO: Content { }
