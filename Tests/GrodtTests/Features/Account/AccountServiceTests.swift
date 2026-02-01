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

    // MARK: - updateName

    @Test func updateName_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateNameDTO(name: "New Name")

        await #expect(throws: Abort.self) {
            _ = try await service.updateName(dto, for: UUID())
        }
    }

    @Test func updateName_nameTooShort_throwsBadRequest() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        // "Hi" is only 2 characters, less than 5 minimum
        let dto = UpdateNameDTO(name: "Hi")

        await #expect(throws: Abort.self) {
            _ = try await service.updateName(dto, for: userID)
        }
    }

    @Test func updateName_nameTooShortAfterSanitization_throwsBadRequest() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        // "  Hi  " is only 2 characters after trimming
        let dto = UpdateNameDTO(name: "  Hi  ")

        await #expect(throws: Abort.self) {
            _ = try await service.updateName(dto, for: userID)
        }
    }

    @Test func updateName_validName_updatesAndReturnsUserInfo() async throws {
        let userID = UUID()
        let user = User.stub(id: userID, name: "Old Name")
        let expectedUserInfo = UserInfoDTO(name: "New Name", email: "test@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        mockMapper.userInfoResult = expectedUserInfo

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateNameDTO(name: "New Name")
        let result = try await service.updateName(dto, for: userID)

        #expect(result.name == "New Name")
        #expect(mockRepository.updateNameCalled)
        #expect(mockRepository.updateNameCalledWith == "New Name")
    }

    @Test func updateName_withHtmlTags_stripsTagsBeforeSaving() async throws {
        let userID = UUID()
        let user = User.stub(id: userID)
        let expectedUserInfo = UserInfoDTO(name: "John Doe", email: "test@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        mockMapper.userInfoResult = expectedUserInfo

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateNameDTO(name: "<script>alert('xss')</script>John Doe")
        _ = try await service.updateName(dto, for: userID)

        #expect(mockRepository.updateNameCalled)
        #expect(mockRepository.updateNameCalledWith == "alert('xss')John Doe")
    }

    // MARK: - updateEmail

    @Test func updateEmail_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateEmailDTO(email: "new@example.com", currentPassword: "password")

        await #expect(throws: Abort.self) {
            _ = try await service.updateEmail(dto, for: UUID())
        }
    }

    @Test func updateEmail_wrongPassword_throwsUnauthorized() async throws {
        let userID = UUID()
        // Create user with bcrypt-hashed password "correct_password"
        let passwordHash = try Bcrypt.hash("correct_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateEmailDTO(email: "new@example.com", currentPassword: "wrong_password")

        await #expect(throws: Abort.self) {
            _ = try await service.updateEmail(dto, for: userID)
        }
    }

    @Test func updateEmail_duplicateEmail_throwsBadRequest() async throws {
        let userID = UUID()
        let otherUserID = UUID()
        let passwordHash = try Bcrypt.hash("correct_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)
        let otherUser = User.stub(id: otherUserID, email: "taken@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)
        mockRepository.findByEmailResult = .success(otherUser)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateEmailDTO(email: "taken@example.com", currentPassword: "correct_password")

        await #expect(throws: Abort.self) {
            _ = try await service.updateEmail(dto, for: userID)
        }
    }

    @Test func updateEmail_validRequest_updatesAndReturnsUserInfo() async throws {
        let userID = UUID()
        let passwordHash = try Bcrypt.hash("correct_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)
        let expectedUserInfo = UserInfoDTO(name: "Test User", email: "new@example.com")

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)
        mockRepository.findByEmailResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        mockMapper.userInfoResult = expectedUserInfo

        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdateEmailDTO(email: "new@example.com", currentPassword: "correct_password")
        let result = try await service.updateEmail(dto, for: userID)

        #expect(result.email == "new@example.com")
        #expect(mockRepository.updateEmailCalled)
        #expect(mockRepository.updateEmailCalledWith == "new@example.com")
    }

    // MARK: - updatePassword

    @Test func updatePassword_nonExistentUser_throwsNotFound() async throws {
        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(nil)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdatePasswordDTO(currentPassword: "old", newPassword: "newpassword123")

        await #expect(throws: Abort.self) {
            try await service.updatePassword(dto, for: UUID())
        }
    }

    @Test func updatePassword_wrongCurrentPassword_throwsUnauthorized() async throws {
        let userID = UUID()
        let passwordHash = try Bcrypt.hash("correct_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdatePasswordDTO(currentPassword: "wrong_password", newPassword: "newpassword123")

        await #expect(throws: Abort.self) {
            try await service.updatePassword(dto, for: userID)
        }
    }

    @Test func updatePassword_samePassword_throwsBadRequest() async throws {
        let userID = UUID()
        let passwordHash = try Bcrypt.hash("same_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdatePasswordDTO(currentPassword: "same_password", newPassword: "same_password")

        await #expect(throws: Abort.self) {
            try await service.updatePassword(dto, for: userID)
        }
    }

    @Test func updatePassword_validRequest_updatesPasswordAndDeletesTokens() async throws {
        let userID = UUID()
        let passwordHash = try Bcrypt.hash("old_password")
        let user = User.stub(id: userID, passwordHash: passwordHash)

        let mockRepository = MockUserRepository()
        mockRepository.userResult = .success(user)

        let mockMapper = MockUserDTOMapper()
        let service = AccountService(userRepository: mockRepository, userDataMapper: mockMapper, logger: Logger(label: "test"))

        let dto = UpdatePasswordDTO(currentPassword: "old_password", newPassword: "new_password123")
        try await service.updatePassword(dto, for: userID)

        #expect(mockRepository.updatePasswordHashCalled)
        #expect(mockRepository.deleteAllTokensCalled)
        #expect(mockRepository.deleteAllTokensCalledWith == userID)
    }
}
