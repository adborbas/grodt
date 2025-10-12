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
                             preferences: preference(from: preferences))
    }

    func preferences(from userPreferences: UserPreferences) async throws -> UserPreferencesDTO {
        return preferencesMapper.userPreferences(from: userPreferences.data)
    }

    func preference(from userPreference: UserPreferencesPayload) async throws -> UserPreferencesDTO {
        return preferencesMapper.userPreferences(from: userPreference)
    }
}

final class UserPreferencesDTOMapper {
    func userPreferences(from preferences: UserPreferencesPayload) -> UserPreferencesDTO {
        var mailjetConfigurationDTO: MailjetConfigurationDTO?
        if let mailjetConfiguration = preferences.transactionBackup.configuration {
            mailjetConfigurationDTO = MailjetConfigurationDTO(senderEmail: mailjetConfiguration.senderEmail, senderName: mailjetConfiguration.senderName)
        }
        return UserPreferencesDTO(transactionsBackup: .init(isEnabled: preferences.transactionBackup.isEnabled,
                                                           configuraiton: mailjetConfigurationDTO))
    }
}
