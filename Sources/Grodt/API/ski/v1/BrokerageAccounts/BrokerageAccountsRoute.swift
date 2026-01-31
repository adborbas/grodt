import Vapor

class BrokerageAccountsRoute: RouteCollection {
    private let service: BrokerageAccountsServicing

    init(service: BrokerageAccountsServicing) {
        self.service = service
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
        return try await service.detail(for: id, userID: userID)
    }

    private func update(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        let userID = try req.requireUserID()
        struct In: Content { let displayName: String; let accountNumberMasked: String? }
        let input = try req.content.decode(In.self)
        return try await service.update(id: id, displayName: input.displayName, userID: userID)
    }

    private func remove(req: Request) async throws -> HTTPStatus {
        let id = try req.parameters.require("id", as: UUID.self)
        let userID = try req.requireUserID()
        return try await service.delete(id: id, userID: userID)
    }
}

extension BrokerageAccountDTO: ResponseDTO { }
extension BrokerageAccountInfoDTO: ResponseDTO { }
