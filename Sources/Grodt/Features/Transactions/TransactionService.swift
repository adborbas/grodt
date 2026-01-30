import Vapor

protocol TransactionServicing: Sendable {
    func all(for user: User.IDValue) async throws -> [TransactionDTO]
    func create(_ transaction: CreateTransactionRequestDTO, on portfolioID: Portfolio.IDValue) async throws -> TransactionDTO
    func detail(for id: UUID) async throws -> TransactionDTO
    func delete(id: UUID) async throws -> HTTPStatus
    func updateBrokerageAccount(id: UUID, brokerageAccountId: String?) async throws -> TransactionDTO
}

class TransactionService: TransactionServicing {
    enum TransactionError: Error {
        case insufficientShares(ticker: String, requested: Decimal, available: Decimal)
    }

    private let transactionsRepository: TransactionsRepository
    private let currencyRepository: CurrencyRepository
    private let dataMapper: TransactionDTOMapping
    var delegate: TransactionsControllerDelegate? // TODO: Weak

    init(transactionsRepository: TransactionsRepository,
         currencyRepository: CurrencyRepository,
         dataMapper: TransactionDTOMapping) {
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

        // Validate sell transactions
        if transaction.transactionType == .sell {
            let existingTransactions = try await transactionsRepository.transactionsForPortfolio(
                portfolioID,
                ticker: transaction.ticker
            )
            let currentShares = existingTransactions.reduce(Decimal(0)) { $0 + $1.signedShares }

            if transaction.numberOfShares > currentShares {
                throw TransactionError.insufficientShares(
                    ticker: transaction.ticker,
                    requested: transaction.numberOfShares,
                    available: currentShares
                )
            }
        }

        let newTransaction = Transaction(portfolioID: portfolioID,
                                         brokerageAccountID: brokerageAccountId,
                                         type: transaction.transactionType,
                                         transactionDate: transaction.transactionDate,
                                         ticker: transaction.ticker,
                                         currency: currency,
                                         fees: transaction.fees,
                                         numberOfShares: transaction.numberOfShares,
                                         pricePerShare: transaction.pricePerShare)

        try await transactionsRepository.save(newTransaction)
        try await delegate?.transactionCreated(newTransaction)
        return try await dataMapper.transaction(from: newTransaction)
    }

    func detail(for id: UUID) async throws -> TransactionDTO {
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        return try await dataMapper.transaction(from: transaction)
    }

    func delete(id: UUID) async throws -> HTTPStatus {
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }
        try await transactionsRepository.delete(transaction)
        try await delegate?.transactionDeleted(transaction)
        return .ok
    }

    func updateBrokerageAccount(id: UUID, brokerageAccountId: String?) async throws -> TransactionDTO {
        guard let transaction = try await transactionsRepository.transaction(for: id) else {
            throw Abort(.notFound)
        }

        let brokerageAccountID: UUID? = {
            guard let raw = brokerageAccountId?.trimmingCharacters(in: .whitespacesAndNewlines), !raw.isEmpty else { return nil }
            return UUID(uuidString: raw)
        }()

        transaction.$brokerageAccount.id = brokerageAccountID
        try await transactionsRepository.update(transaction)
        return try await dataMapper.transaction(from: transaction)
    }
}

