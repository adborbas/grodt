import Vapor
import Fluent

struct BrokeragesRoute: RouteCollection {
    private let service: BrokerageServicing
    private let accountsService: BrokerageAccountsServicing

    init(service: BrokerageServicing,
         accountsService: BrokerageAccountsServicing) {
        self.service = service
        self.accountsService = accountsService
    }
    
    func boot(routes: RoutesBuilder) throws {
        let brokerages = routes.grouped("brokerages")
        brokerages.get(use: list)
        brokerages.post(use: create)
        brokerages.group(":id") { brokerage in
            brokerage.get(use: detail)
            brokerage.put(use: update)
            brokerage.delete(use: remove)
            
            brokerage.group("accounts") { accounts in
                accounts.post(use: createAccount)
            }
        }
    }
    
    private func list(req: Request) async throws -> [BrokerageDTO] {
        let userID = try req.requireUserID()
        return try await service.allBrokerages(for: userID)
    }
    
    private func create(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        let input = try req.content.decode(CreateUpdateBrokerageRequestDTO.self)
        return try await service.createBrokerage(named: input.name, for: userID)
    }
    
    private func detail(req: Request) async throws -> BrokerageDTO {
        let userID = try req.requireUserID()
        let id = try req.requiredID()
        return try await service.brokerageDetail(id: id, for: userID)
    }
    
    private func update(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let id = try req.requiredID()
        let input = try req.content.decode(CreateUpdateBrokerageRequestDTO.self)
        _ = try await service.updateBrokerage(id: id,
                                          update: input,
                                          for: userID)
        return .ok
    }
    
    private func remove(req: Request) async throws -> HTTPStatus {
        let userID = try req.requireUserID()
        let id = try req.requiredID()
        try await service.deleteBrokerage(id: id, for: userID)
        return .ok
    }
    
    private func createAccount(req: Request) async throws -> BrokerageAccountDTO {
        let userID = try req.requireUserID()
        let brokerageID = try req.requiredID()
        let input = try req.content.decode(CreateBrokerageAccountDTO.self)
        return try await accountsService.create(input, on: brokerageID, for: userID)
    }
}

extension BrokerageDTO: ResponseDTO { }
