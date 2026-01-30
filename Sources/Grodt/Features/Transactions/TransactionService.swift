import Vapor

protocol TransactionServicing: Sendable {
    func all(for user: User.IDValue) async throws -> [TransactionDTO]
    func create(_ transaction: CreateTransactionRequestDTO, on portfolioID: Portfolio.IDValue) async throws -> TransactionDTO
}

class TransactionService: TransactionServicing {
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

    func all(for user: User.IDValue) async throws -> [TransactionDTO] {
        let transactions = try await transactionsRepository.all(for: user)
        return await transactions.concurrentCompactMap { try? await self.dataMapper.transaction(from: $0) }
    }

    func create(_ transaction: CreateTransactionRequestDTO, on portfolioID: Portfolio.IDValue) async throws -> TransactionDTO {
        guard let currency = try await currencyRepository.currency(for: transaction.currency) else {
            throw Abort(.badRequest)
        }
        
        let brokerageAccountId: UUID? = {
            guard let id = transaction.brokerageAccountID else { return nil }
            return UUID(uuidString: id)
        }()
        
        
        let newTransaction = Transaction(portfolioID: portfolioID,
                                         brokerageAccountID: brokerageAccountId,
                                         purchaseDate: transaction.purchaseDate,
                                         ticker: transaction.ticker,
                                         currency: currency,
                                         fees: transaction.fees,
                                         numberOfShares: transaction.numberOfShares,
                                         pricePerShareAtPurchase: transaction.pricePerShare)
        
        try await transactionsRepository.save(newTransaction)
        try await delegate?.transactionCreated(newTransaction)
        return try await dataMapper.transaction(from: newTransaction)
    }
}

