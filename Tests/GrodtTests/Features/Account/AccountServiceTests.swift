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

    // MARK: - setMonthlyEmailEnabled

    @Test func setMonthlyEmailEnabled_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        await #expect(throws: Abort.self) {
            _ = try await service.setMonthlyEmailEnabled(true, for: UUID())
        }
    }

    @Test func setMonthlyEmailEnabled_enable_setsConfigAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(isMonthlyEmailEnabled: true)

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = expectedPreferences

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let result = try await service.setMonthlyEmailEnabled(true, for: userID)

        #expect(result.isMonthlyEmailEnabled == true)
        #expect(mockRepository.setMonthlyEmailEnabledCalled)
        #expect(mockRepository.setMonthlyEmailEnabledCalledWith == true)
    }

    @Test func setMonthlyEmailEnabled_disable_setsConfigAndReturnsPreferences() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let expectedPreferences = UserPreferencesDTO.stub(isMonthlyEmailEnabled: false)

        let mockMapper = MockUserDTOMapper()
        mockMapper.preferencesResult = expectedPreferences

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper)

        let result = try await service.setMonthlyEmailEnabled(false, for: userID)

        #expect(result.isMonthlyEmailEnabled == false)
        #expect(mockRepository.setMonthlyEmailEnabledCalled)
        #expect(mockRepository.setMonthlyEmailEnabledCalledWith == false)
    }
}
