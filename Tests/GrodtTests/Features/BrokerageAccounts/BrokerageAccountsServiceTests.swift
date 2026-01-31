@testable import Grodt
import Testing
import Vapor

struct BrokerageAccountsServiceTests {

    // MARK: - allAccounts

    @Test func allAccounts_repositoryThrows_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.allResult = .failure(Abort(.internalServerError))

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.allAccounts(for: UUID())
        }
    }

    @Test func allAccounts_emptyList_returnsEmptyArray() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.allResult = .success([])

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        let result = try await service.allAccounts(for: UUID())

        #expect(result.isEmpty)
    }

    // MARK: - update

    @Test func update_accountNotFound_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .success(nil)

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.update(id: UUID(), displayName: "New Name", userID: UUID())
        }
    }

    @Test func update_repositoryThrows_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .failure(Abort(.internalServerError))

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.update(id: UUID(), displayName: "New Name", userID: UUID())
        }
    }

    // MARK: - delete

    @Test func delete_accountNotFound_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .success(nil)

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.delete(id: UUID(), userID: UUID())
        }
    }

    @Test func delete_repositoryThrows_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .failure(Abort(.internalServerError))

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.delete(id: UUID(), userID: UUID())
        }
    }

    // MARK: - create

    @Test func create_invalidCurrency_throwsBadRequest() async throws {
        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(nil)

        let service = makeSUT(currencyRepository: mockCurrencyRepo)

        let request = CreateBrokerageAccountDTO(displayName: "Test Account", currency: "INVALID")

        await #expect(throws: Abort.self) {
            _ = try await service.create(request, on: UUID(), for: UUID())
        }
    }

    @Test func create_brokerageNotFound_throwsNotFound() async throws {
        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .success(.stub())

        let mockBrokerageRepo = MockBrokerageRepository()
        mockBrokerageRepo.findResult = .success(nil)

        let service = makeSUT(
            brokerageRepository: mockBrokerageRepo,
            currencyRepository: mockCurrencyRepo
        )

        let request = CreateBrokerageAccountDTO(displayName: "Test Account", currency: "EUR")

        await #expect(throws: Abort.self) {
            _ = try await service.create(request, on: UUID(), for: UUID())
        }
    }

    @Test func create_currencyRepoThrows_throws() async throws {
        let mockCurrencyRepo = MockCurrencyRepository()
        mockCurrencyRepo.currencyResult = .failure(Abort(.internalServerError))

        let service = makeSUT(currencyRepository: mockCurrencyRepo)

        let request = CreateBrokerageAccountDTO(displayName: "Test Account", currency: "EUR")

        await #expect(throws: Abort.self) {
            _ = try await service.create(request, on: UUID(), for: UUID())
        }
    }

    // MARK: - detail

    @Test func detail_accountNotFound_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .success(nil)

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.detail(for: UUID(), userID: UUID())
        }
    }

    @Test func detail_repositoryThrows_throws() async throws {
        let mockAccountRepo = MockBrokerageAccountRepository()
        mockAccountRepo.findResult = .failure(Abort(.internalServerError))

        let service = makeSUT(brokerageAccountRepository: mockAccountRepo)

        await #expect(throws: Abort.self) {
            _ = try await service.detail(for: UUID(), userID: UUID())
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        brokerageRepository: BrokerageRepository = MockBrokerageRepository(),
        brokerageAccountRepository: BrokerageAccountRepository = MockBrokerageAccountRepository(),
        transactionsRepository: TransactionsRepository = MockTransactionsRepository(),
        performanceRepository: BrokerageAccountDailyPerformanceReading = MockBrokerageAccountDailyPerformanceReading(),
        performanceDTOMapper: DatedPerformanceDTOMapping = MockDatedPerformanceDTOMapper(),
        currencyMapper: CurrencyDTOMapping = MockCurrencyDTOMapper(),
        transactionDTOMapper: TransactionDTOMapping = MockTransactionDTOMapper(),
        currencyRepository: CurrencyRepository = MockCurrencyRepository()
    ) -> BrokerageAccountsService {
        BrokerageAccountsService(
            brokerageRepository: brokerageRepository,
            brokerageAccountRepository: brokerageAccountRepository,
            transactionsRepository: transactionsRepository,
            performanceRepository: performanceRepository,
            performanceDTOMapper: performanceDTOMapper,
            currencyMapper: currencyMapper,
            transactionDTOMapper: transactionDTOMapper,
            currencyRepository: currencyRepository
        )
    }
}
