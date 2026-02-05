import Foundation

protocol UserDTOMapping: Sendable {
    func userInfo(from user: User) -> UserInfoDTO
    func userDetail(from user: User) -> UserDetailDTO
    func preferences(from userPreferences: UserPreferences) -> UserPreferencesDTO
}
