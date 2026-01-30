@testable import Grodt
import Testing
import Vapor

struct BrokerageServiceTests {

    // MARK: - allBrokerages

    @Test func allBrokerages_returnsMappedBrokerages() async throws {
        let userID = UUID()
        let brokerage1 = Brokerage.stub(name: "Brokerage 1")
        let brokerage2 = Brokerage.stub(name: "Brokerage 2")

        let mockRepository = MockBrokerageRepository()
        mockRepository.listResult = .success([brokerage1, brokerage2])

        let expectedDTO = BrokerageDTO.stub(name: "Mapped Brokerage")
        let mockMapper = MockBrokerageDTOMapper()
        mockMapper.brokerageResult = .success(expectedDTO)

        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let result = try await service.allBrokerages(for: userID)

        #expect(result.count == 2)
    }

    @Test func allBrokerages_emptyList_returnsEmptyArray() async throws {
        let mockRepository = MockBrokerageRepository()
        mockRepository.listResult = .success([])

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let result = try await service.allBrokerages(for: UUID())

        #expect(result.isEmpty)
    }

    // MARK: - createBrokerage

    @Test func createBrokerage_createsAndReturnsMappedBrokerage() async throws {
        let userID = UUID()
        let brokerageName = "New Brokerage"

        let mockRepository = MockBrokerageRepository()
        mockRepository.createResult = .success(())

        let expectedDTO = BrokerageDTO.stub(name: brokerageName)
        let mockMapper = MockBrokerageDTOMapper()
        mockMapper.brokerageResult = .success(expectedDTO)

        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let result = try await service.createBrokerage(named: brokerageName, for: userID)

        #expect(mockRepository.createCalled)
        #expect(mockRepository.createCalledWith?.name == brokerageName)
        #expect(result.name == brokerageName)
    }

    @Test func createBrokerage_repositoryError_throws() async throws {
        let mockRepository = MockBrokerageRepository()
        mockRepository.createResult = .failure(Abort(.internalServerError))

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        await #expect(throws: Abort.self) {
            _ = try await service.createBrokerage(named: "Test", for: UUID())
        }
    }

    // MARK: - brokerageDetail

    @Test func brokerageDetail_existingBrokerage_returnsMappedBrokerage() async throws {
        let brokerageID = UUID()
        let userID = UUID()
        let brokerage = Brokerage.stub(id: brokerageID, name: "Detail Brokerage")

        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(brokerage)

        let expectedDTO = BrokerageDTO.stub(id: brokerageID, name: "Detail Brokerage")
        let mockMapper = MockBrokerageDTOMapper()
        mockMapper.brokerageResult = .success(expectedDTO)

        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let result = try await service.brokerageDetail(id: brokerageID, for: userID)

        #expect(result.id == brokerageID)
        #expect(result.name == "Detail Brokerage")
    }

    @Test func brokerageDetail_nonExistentBrokerage_throwsNotFound() async throws {
        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(nil)

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        await #expect(throws: Abort.self) {
            _ = try await service.brokerageDetail(id: UUID(), for: UUID())
        }
    }

    // MARK: - updateBrokerage

    @Test func updateBrokerage_existingBrokerage_updatesAndReturnsMappedBrokerage() async throws {
        let brokerageID = UUID()
        let userID = UUID()
        let brokerage = Brokerage.stub(id: brokerageID, name: "Old Name")

        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(brokerage)
        mockRepository.updateResult = .success(())

        let expectedDTO = BrokerageDTO.stub(id: brokerageID, name: "New Name")
        let mockMapper = MockBrokerageDTOMapper()
        mockMapper.brokerageResult = .success(expectedDTO)

        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let updateRequest = CreateUpdateBrokerageRequestDTO(name: "New Name")
        let result = try await service.updateBrokerage(id: brokerageID, update: updateRequest, for: userID)

        #expect(mockRepository.updateCalled)
        #expect(result.name == "New Name")
    }

    @Test func updateBrokerage_nonExistentBrokerage_throwsNotFound() async throws {
        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(nil)

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        let updateRequest = CreateUpdateBrokerageRequestDTO(name: "New Name")

        await #expect(throws: Abort.self) {
            _ = try await service.updateBrokerage(id: UUID(), update: updateRequest, for: UUID())
        }
    }

    // MARK: - deleteBrokerage

    @Test func deleteBrokerage_existingBrokerage_deletesSuccessfully() async throws {
        let brokerageID = UUID()
        let userID = UUID()
        let brokerage = Brokerage.stub(id: brokerageID)

        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(brokerage)
        mockRepository.deleteResult = .success(())

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        try await service.deleteBrokerage(id: brokerageID, for: userID)

        #expect(mockRepository.deleteCalled)
        #expect(mockRepository.deleteCalledWith?.id == brokerageID)
    }

    @Test func deleteBrokerage_nonExistentBrokerage_throwsNotFound() async throws {
        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(nil)

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        await #expect(throws: Abort.self) {
            try await service.deleteBrokerage(id: UUID(), for: UUID())
        }
    }

    @Test func deleteBrokerage_repositoryDeleteError_throws() async throws {
        let brokerage = Brokerage.stub()

        let mockRepository = MockBrokerageRepository()
        mockRepository.findResult = .success(brokerage)
        mockRepository.deleteResult = .failure(Abort(.conflict, reason: "Has accounts"))

        let mockMapper = MockBrokerageDTOMapper()
        let service = BrokerageService(brokerageRepository: mockRepository, dtoMapper: mockMapper)

        await #expect(throws: Abort.self) {
            try await service.deleteBrokerage(id: UUID(), for: UUID())
        }
    }
}
