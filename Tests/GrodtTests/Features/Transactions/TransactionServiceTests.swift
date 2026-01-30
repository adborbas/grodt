@testable import Grodt
import Testing
import Vapor

struct TransactionServiceTests {

    // MARK: - all

    @Test func all_returnsMappedTransactions() async throws {
        let userID = UUID()
        let transaction1 = Transaction.stub(ticker: "AAPL")
        let transaction2 = Transaction.stub(ticker: "GOOGL")

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.allResult = .success([transaction1, transaction2])

        let mockCurrencyRepo = MockCurrencyRepository()

        let expectedDTO = TransactionDTO.stub(ticker: "Mapped")
        let mockMapper = MockTransactionDTOMapper()
        mockMapper.transactionResult = .success(expectedDTO)

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.all(for: userID)

        #expect(result.count == 2)
    }

    @Test func all_emptyList_returnsEmptyArray() async throws {
        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.allResult = .success([])

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.all(for: UUID())

        #expect(result.isEmpty)
    }

    // MARK: - create

    @Test func create_validCurrency_savesAndReturnsMappedTransaction() async throws {
        let portfolioID = UUID()
        let currency = Currency.stub(code: "USD")

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.saveResult = .success(())

        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(currency)

        let expectedDTO = TransactionDTO.stub(ticker: "AAPL")
        let mockMapper = MockTransactionDTOMapper()
        mockMapper.transactionResult = .success(expectedDTO)

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let request = CreateTransactionRequestDTO(
            brokerageAccountID: nil,
            purchaseDate: Date(),
            ticker: "AAPL",
            currency: "USD",
            fees: 0,
            numberOfShares: 10,
            pricePerShare: 150
        )

        let result = try await service.create(request, on: portfolioID)

        #expect(mockTransactionsRepo.saveCalled)
        #expect(result.ticker == "AAPL")
    }

    @Test func create_invalidCurrency_throwsBadRequest() async throws {
        let mockTransactionsRepo = MockTransactionsRepository()

        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(nil)

        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let request = CreateTransactionRequestDTO(
            brokerageAccountID: nil,
            purchaseDate: Date(),
            ticker: "AAPL",
            currency: "INVALID",
            fees: 0,
            numberOfShares: 10,
            pricePerShare: 150
        )

        await #expect(throws: Abort.self) {
            _ = try await service.create(request, on: UUID())
        }
    }

    // MARK: - detail

    @Test func detail_existingTransaction_returnsMappedTransaction() async throws {
        let transactionID = UUID()
        let transaction = Transaction.stub(id: transactionID, ticker: "AAPL")

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(transaction)

        let mockCurrencyRepo = MockCurrencyRepository()

        let expectedDTO = TransactionDTO.stub(ticker: "AAPL")
        let mockMapper = MockTransactionDTOMapper()
        mockMapper.transactionResult = .success(expectedDTO)

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.detail(for: transactionID)

        #expect(result.ticker == "AAPL")
    }

    @Test func detail_nonExistentTransaction_throwsNotFound() async throws {
        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.detail(for: UUID())
        }
    }

    // MARK: - delete

    @Test func delete_existingTransaction_deletesSuccessfully() async throws {
        let transactionID = UUID()
        let transaction = Transaction.stub(id: transactionID)

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(transaction)
        mockTransactionsRepo.deleteResult = .success(())

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.delete(id: transactionID)

        #expect(mockTransactionsRepo.deleteCalled)
        #expect(result == .ok)
    }

    @Test func delete_nonExistentTransaction_throwsNotFound() async throws {
        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.delete(id: UUID())
        }
    }

    // MARK: - updateBrokerageAccount

    @Test func updateBrokerageAccount_existingTransaction_updatesAndReturnsMappedTransaction() async throws {
        let transactionID = UUID()
        let brokerageAccountID = UUID()
        let transaction = Transaction.stub(id: transactionID)

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(transaction)
        mockTransactionsRepo.updateResult = .success(())

        let mockCurrencyRepo = MockCurrencyRepository()

        let expectedDTO = TransactionDTO.stub()
        let mockMapper = MockTransactionDTOMapper()
        mockMapper.transactionResult = .success(expectedDTO)

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.updateBrokerageAccount(id: transactionID, brokerageAccountId: brokerageAccountID.uuidString)

        #expect(mockTransactionsRepo.updateCalled)
        #expect(result.id == expectedDTO.id)
    }

    @Test func updateBrokerageAccount_nonExistentTransaction_throwsNotFound() async throws {
        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(nil)

        let mockCurrencyRepo = MockCurrencyRepository()
        let mockMapper = MockTransactionDTOMapper()

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        await #expect(throws: Abort.self) {
            _ = try await service.updateBrokerageAccount(id: UUID(), brokerageAccountId: UUID().uuidString)
        }
    }

    @Test func updateBrokerageAccount_nilBrokerageAccountId_clearsAssociation() async throws {
        let transactionID = UUID()
        let transaction = Transaction.stub(id: transactionID, brokerageAccountID: UUID())

        let mockTransactionsRepo = MockTransactionsRepository()
        mockTransactionsRepo.transactionResult = .success(transaction)
        mockTransactionsRepo.updateResult = .success(())

        let mockCurrencyRepo = MockCurrencyRepository()

        let expectedDTO = TransactionDTO.stub()
        let mockMapper = MockTransactionDTOMapper()
        mockMapper.transactionResult = .success(expectedDTO)

        let service = TransactionService(
            transactionsRepository: mockTransactionsRepo,
            currencyRepository: mockCurrencyRepo,
            dataMapper: mockMapper
        )

        let result = try await service.updateBrokerageAccount(id: transactionID, brokerageAccountId: nil)

        #expect(mockTransactionsRepo.updateCalled)
        #expect(result.id == expectedDTO.id)
    }
}
