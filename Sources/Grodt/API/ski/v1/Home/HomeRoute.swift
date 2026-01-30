import Vapor

class HomeRoute: RouteCollection {
    private let service: HomeServicing

    init(service: HomeServicing) {
        self.service = service
    }

    func boot(routes: any Vapor.RoutesBuilder) throws {
        let home = routes.grouped("home")
        home.get(use: `get`)
    }

    private func get(req: Request) async throws -> HomeResponseDTO {
        let userID = try req.requireUserID()
        return try await service.home(for: userID)
    }
}
