import FluentKit

final class UserDTOMapper: UserDTOMapping, @unchecked Sendable {
    func userInfo(from user: User) -> UserInfoDTO {
        return UserInfoDTO(name: user.name, email: user.email)
    }

    func userDetail(from user: User) -> UserDetailDTO {
        return UserDetailDTO(
            name: user.name,
            email: user.email,
            preferences: preferencesDTO(from: user.requiredPreferences)
        )
    }

    func preferences(from userPreferences: UserPreferences) -> UserPreferencesDTO {
        return preferencesDTO(from: userPreferences.data)
    }

    private func preferencesDTO(from payload: UserPreferencesPayload) -> UserPreferencesDTO {
        return UserPreferencesDTO(
            monthlyEmail: MonthlyEmailConfigDTO(isEnabled: payload.monthlyEmail.isEnabled)
        )
    }
}
