@testable import Grodt
import Testing
import Vapor

struct AccountServiceTests {

    // MARK: - userInfo

    @Test func userInfo_existingUser_returnsUserInfo() async throws {
        let userID = UUID()
        let user = User.stub(id: userID, name: "John Doe", email: "john@example.com")
        let expectedUserInfo = UserInfoDTO(name: "John Doe", email: "john@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        mockMapper.userInfoResult = expectedUserInfo

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let result = try await service.userInfo(for: userID)

        #expect(result.name == "John Doe")
        #expect(result.email == "john@example.com")
    }

    @Test func userInfo_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        await #expect(throws: Abort.self) {
            _ = try await service.userInfo(for: UUID())
        }
    }

    // MARK: - userDetail

    @Test func userDetail_existingUser_returnsUserDetail() async throws {
        let userID = UUID()
        let user = User.stub(id: userID, name: "Jane Doe", email: "jane@example.com")
        let expectedDetail = UserDetailDTO.stub(name: "Jane Doe", email: "jane@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        mockMapper.userDetailResult = .success(expectedDetail)

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let result = try await service.userDetail(for: userID)

        #expect(result.name == "Jane Doe")
        #expect(result.email == "jane@example.com")
    }

    @Test func userDetail_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        await #expect(throws: Abort.self) {
            _ = try await service.userDetail(for: UUID())
        }
    }

    // MARK: - updateMonthlyEmailConfig

    @Test func updateMonthlyEmailConfig_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let config = UpdateMonthlyEmailConfigDTO(
            isEnabled: true,
            senderEmail: "sender@example.com",
            senderName: "Sender",
            apiKey: "api-key",
            apiSecret: "api-secret"
        )

        await #expect(throws: Abort.self) {
            _ = try await service.updateMonthlyEmailConfig(config, for: UUID())
        }
    }

    @Test func updateMonthlyEmailConfig_enableWithMissingFields_throwsBadRequest() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let config = UpdateMonthlyEmailConfigDTO(
            isEnabled: true,
            senderEmail: nil,
            senderName: nil,
            apiKey: nil,
            apiSecret: nil
        )

        await #expect(throws: Abort.self) {
            _ = try await service.updateMonthlyEmailConfig(config, for: userID)
        }
    }

    @Test func updateMonthlyEmailConfig_repositoryError_rollsBackAndThrows() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)
        mockRepository.setMonthlyEmailConfigResult = .failure(Abort(.internalServerError))

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let config = UpdateMonthlyEmailConfigDTO(
            isEnabled: true,
            senderEmail: "sender@example.com",
            senderName: "Sender",
            apiKey: "api-key",
            apiSecret: "api-secret"
        )

        await #expect(throws: Abort.self) {
            _ = try await service.updateMonthlyEmailConfig(config, for: userID)
        }
    }

    @Test func updateMonthlyEmailConfig_enableWithAllFields_setsConfigAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: .stub(isEnabled: true, configuration: .stub())
        )

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = .success(expectedPreferences)

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let config = UpdateMonthlyEmailConfigDTO(
            isEnabled: true,
            senderEmail: "sender@example.com",
            senderName: "Sender",
            apiKey: "api-key",
            apiSecret: "api-secret"
        )

        let result = try await service.updateMonthlyEmailConfig(config, for: userID)

        #expect(result.monthlyEmail.isEnabled == true)
        #expect(mockRepository.setMonthlyEmailConfigCalled)
        #expect(mockRepository.setMonthlyEmailConfigCalledWith?.isEnabled == true)
        #expect(mockRepository.setMailjetApiSecretCalledWith == "api-secret")
    }

    @Test func updateMonthlyEmailConfig_disable_clearsSecretAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: .stub(isEnabled: false)
        )

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = .success(expectedPreferences)

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let config = UpdateMonthlyEmailConfigDTO(
            isEnabled: false,
            senderEmail: nil,
            senderName: nil,
            apiKey: nil,
            apiSecret: nil
        )

        let result = try await service.updateMonthlyEmailConfig(config, for: userID)

        #expect(result.monthlyEmail.isEnabled == false)
        #expect(mockRepository.setMonthlyEmailConfigCalled)
        #expect(mockRepository.setMonthlyEmailConfigCalledWith?.isEnabled == false)
        #expect(mockRepository.setMailjetApiSecretCalledWith == nil)
    }
}
