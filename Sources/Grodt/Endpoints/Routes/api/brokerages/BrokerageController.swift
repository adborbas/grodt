import Vapor
import Fluent

struct BrokerageController: RouteCollection {
    private let service: BrokerageService
    
    init(service: BrokerageService) {
        self.service = service
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
        return try await service.brokerageDetail(id: id, for: userID, on: req.db)
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
        
    private func performanceSeries(req: Request) async throws -> PerformanceTimeSeriesDTO {
        let userID = try req.requireUserID()
        let id = try req.requiredID()
        return try await service.performance(id: id, for: userID)
    }
}

extension BrokerageDTO: ResponseDTO { }
