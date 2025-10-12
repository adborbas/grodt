import FluentKit

final class UserDTOMapper {
    private let database: Database
    private let preferencesMapper: UserPreferencesDTOMapper

    init(database: Database,
         preferencesMapper: UserPreferencesDTOMapper) {
        self.database = database
        self.preferencesMapper = preferencesMapper
    }

    func userInfo(from user: User) -> UserInfoDTO {
        return UserInfoDTO(name: user.name, email: user.email)
    }

    func userDetail(from user: User) async throws -> UserDetailDTO {
        let preferences = try await user.requirePreferences(on: database)
        return UserDetailDTO(name: user.name,
                             email: user.email,
                             preferences: preferencesMapper.userPreferences(from: preferences))
    }
}

final class UserPreferencesDTOMapper {
    func userPreferences(from preferences: UserPreferencesPayload) -> UserPreferencesDTO {
        var mailjetPreferencesDTO: MailjetPreferencesDTO?
        if let mailjetPreferences = preferences.mailjetPreferences {
            mailjetPreferencesDTO = MailjetPreferencesDTO(senderEmail: mailjetPreferences.senderEmail, senderName: mailjetPreferences.senderName)
        }
        return UserPreferencesDTO(isTransactionsBackupEnabled: preferences.isTransactionsBackupEnabled,
                                  mailjetPreferences: mailjetPreferencesDTO)
    }
}
