import Vapor

struct UpdateTransactionBrokerageAccountRequestDTO: Content {
    let brokerageAccountId: String?
}

protocol TransactionsControllerDelegate: AnyObject {
    func transactionCreated(_ transaction: Transaction) async throws
    func transactionDeleted(_ transaction: Transaction) async throws
}

class TransactionsController: RouteCollection {
    private let transactionsRepository: TransactionsRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: TransactionDTOMapper
    var delegate: TransactionsControllerDelegate? // TODO: Weak
    
    init(transactionsRepository: TransactionsRepository,
         currencyRepository: CurrencyRepository,
         dataMapper: TransactionDTOMapper) {
        self.transactionsRepository = transactionsRepository
        self.currencyRepository = currencyRepository
        self.dataMapper = dataMapper
    }
    
    func boot(routes: Vapor.RoutesBuilder) throws {
        let transactions = routes.grouped("transactions")
        transactions.post(use: create)
        
        transactions.group(":id") { transaction in
            transaction.get(use: transactionDetail)
            transaction.delete(use: delete)
            transaction.patch("brokerage-account", use: updateBrokerageAccount)
        }
    }
    
    private func create(req: Request) async throws -> TransactionDTO {
        let transaction = try req.content.decode(CreateTransactionRequestDTO.self)
        guard let currency = try await currencyRepository.currency(for: transaction.currency) else {
            throw Abort(.badRequest)
        }
        
        let brokerageAccountId: UUID? = {
            guard let id = transaction.brokerageAccountID else { return nil }
            return UUID(uuidString: id)
        }()
        
        
        let newTransaction = Transaction(portfolioID: UUID(uuidString: transaction.portfolio)!,
                                         brokerageAccountID: brokerageAccountId,
                                         purchaseDate: transaction.purchaseDate,
                                         ticker: transaction.ticker,
                                         currency: currency,
                                         fees: transaction.fees,
                                         numberOfShares: transaction.numberOfShares,
                                         pricePerShareAtPurchase: transaction.pricePerShare)
        
        try await newTransaction.save(on: req.db)
        try await delegate?.transactionCreated(newTransaction)
        return dataMapper.transaction(from: newTransaction)
    }
    
    private func transactionDetail(req: Request) async throws -> TransactionDTO {
        let id = try req.requiredID()
        
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        return dataMapper.transaction(from: transaction)
    }
    
    
    private func delete(req: Request) async throws -> HTTPStatus {
        let id = try req.requiredID()
        
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        
        try await transaction.delete(on: req.db)
        try await delegate?.transactionDeleted(transaction)
        return .ok
    }
    
    private func updateBrokerageAccount(req: Request) async throws -> TransactionDTO {
        let id = try req.requiredID()
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }

        let body = try req.content.decode(UpdateTransactionBrokerageAccountRequestDTO.self)

        // Interpret empty string as nil (unlink)
        let brokerageAccountID: UUID? = {
            guard let raw = body.brokerageAccountId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
            return UUID(uuidString: raw)
        }()

        // Optionally: validate that the brokerage account exists if provided
//        if let brokerageAccountID {
//            let exists = try await BrokerageAccount.query(on: req.db)
//                .filter(\.$id == brokerageAccountID)
//                .first() != nil
//            if !exists { throw Abort(.badRequest, reason: "BrokerageAccount not found") }
//        }

        transaction.$brokerageAccount.id = brokerageAccountID
        try await transaction.save(on: req.db)

        return dataMapper.transaction(from: transaction)
    }
}

extension TransactionDTO: Content { }
