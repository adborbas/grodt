import Vapor

struct UpdateTransactionBrokerageAccountRequestDTO: Content {
    let brokerageAccountId: String?
}

protocol TransactionsControllerDelegate: AnyObject {
    func transactionCreated(_ transaction: Transaction) async throws
    func transactionDeleted(_ transaction: Transaction) async throws
}

class TransactionsRoute: RouteCollection {
    private let service: TransactionServicing

    init(service: TransactionServicing) {
        self.service = service
    }

    func boot(routes: Vapor.RoutesBuilder) throws {
        let transactions = routes.grouped("transactions")

        transactions.group(":id") { transaction in
            transaction.get(use: transactionDetail)
            transaction.delete(use: delete)
            transaction.patch("brokerage-account", use: updateBrokerageAccount)
        }
    }

    private func transactionDetail(req: Request) async throws -> TransactionDTO {
        let id = try req.requiredID()
        return try await service.detail(for: id)
    }

    private func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        return try await service.delete(id: id)
    }

    private func updateBrokerageAccount(req: Request) async throws -> TransactionDTO {
        let id = try req.requiredID()
        let body = try req.content.decode(UpdateTransactionBrokerageAccountRequestDTO.self)
        return try await service.updateBrokerageAccount(id: id, brokerageAccountId: body.brokerageAccountId)
    }
}

extension TransactionDTO: Content { }
