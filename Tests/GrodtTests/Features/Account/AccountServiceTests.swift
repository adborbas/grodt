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

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let result = try await service.userInfo(for: userID)

        #expect(result.name == "John Doe")
        #expect(result.email == "john@example.com")
    }

    @Test func userInfo_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

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
        mockMapper.userDetailResult = expectedDetail

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let result = try await service.userDetail(for: userID)

        #expect(result.name == "Jane Doe")
        #expect(result.email == "jane@example.com")
    }

    @Test func userDetail_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        await #expect(throws: Abort.self) {
            _ = try await service.userDetail(for: UUID())
        }
    }

    // MARK: - updateMonthlyEmailConfig

    @Test func updateMonthlyEmailConfig_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let config = MonthlyEmailConfigDTO(isEnabled: true)

        await #expect(throws: Abort.self) {
            _ = try await service.updateMonthlyEmailConfig(config, for: UUID())
        }
    }

    @Test func updateMonthlyEmailConfig_enable_setsConfigAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: .stub(isEnabled: true)
        )

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = expectedPreferences

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let config = MonthlyEmailConfigDTO(isEnabled: true)

        let result = try await service.updateMonthlyEmailConfig(config, for: userID)

        #expect(result.monthlyEmail.isEnabled == true)
        #expect(mockRepository.setMonthlyEmailConfigCalled)
        #expect(mockRepository.setMonthlyEmailConfigCalledWith?.isEnabled == true)
    }

    @Test func updateMonthlyEmailConfig_disable_setsConfigAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(
            monthlyEmail: .stub(isEnabled: false)
        )

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = expectedPreferences

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let config = MonthlyEmailConfigDTO(isEnabled: false)

        let result = try await service.updateMonthlyEmailConfig(config, for: userID)

        #expect(result.monthlyEmail.isEnabled == false)
        #expect(mockRepository.setMonthlyEmailConfigCalled)
        #expect(mockRepository.setMonthlyEmailConfigCalledWith?.isEnabled == false)
    }
}
