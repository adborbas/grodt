import FluentKit

final class UserDTOMapper {
    private let preferencesMapper: UserPreferencesDTOMapper

    init(preferencesMapper: UserPreferencesDTOMapper) {
        self.preferencesMapper = preferencesMapper
    }

    func userInfo(from user: User) -> UserInfoDTO {
        return UserInfoDTO(name: user.name, email: user.email)
    }

    func userDetail(from user: User) async throws -> UserDetailDTO {
        let preferences = user.requiredPreferences
        return try await UserDetailDTO(name: user.name,
                             email: user.email,
                                       preferences: preference(from: preferences, for: user.requireID()))
    }

    func preferences(from userPreferences: UserPreferences, for user: User.IDValue) async throws -> UserPreferencesDTO {
        return try await preferencesMapper.userPreferences(from: userPreferences.data, for: user)
    }

    func preference(from userPreference: UserPreferencesPayload, for user: User.IDValue) async throws -> UserPreferencesDTO {
        return try await preferencesMapper.userPreferences(from: userPreference, for: user)
    }
}

final class UserPreferencesDTOMapper {
    private let userRepository: UserRepository

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func userPreferences(from preferences: UserPreferencesPayload, for user: User.IDValue) async throws -> UserPreferencesDTO {
        var mailjetConfigurationDTO: MailjetConfigurationDTO?
        if let mailjetConfiguration = preferences.monthlyEmail.configuration,
           let apiSecret = try await userRepository.user(for: user, with: [.secrets])?.requiredSecrets.mailjetApiSecret {
            mailjetConfigurationDTO = MailjetConfigurationDTO(
                senderEmail: mailjetConfiguration.senderEmail,
                senderName: mailjetConfiguration.senderName,
                apiKey: mailjetConfiguration.apiKey,
                apiSecret: apiSecret)
        }
        return UserPreferencesDTO(monthlyEmail: .init(isEnabled: preferences.monthlyEmail.isEnabled,
                                                      configuration: mailjetConfigurationDTO))
    }
}
