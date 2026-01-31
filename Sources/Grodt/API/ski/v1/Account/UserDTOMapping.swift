import Foundation

protocol UserDTOMapping: Sendable {
    func userInfo(from user: User) -> UserInfoDTO
    func userDetail(from user: User) async throws -> UserDetailDTO
    func preferences(from userPreferences: UserPreferences, for user: User.IDValue) async throws -> UserPreferencesDTO
}
