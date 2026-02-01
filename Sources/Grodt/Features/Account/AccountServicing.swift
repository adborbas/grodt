import Foundation

protocol AccountServicing: Sendable {
    func userInfo(for userID: User.IDValue) async throws -> UserInfoDTO
    func userDetail(for userID: User.IDValue) async throws -> UserDetailDTO
    func updateMonthlyEmailConfig(_ newConfig: UpdateMonthlyEmailConfigDTO,
                                   for userID: User.IDValue) async throws -> UserPreferencesDTO

    // Profile updates
    func updateName(_ dto: UpdateNameDTO, for userID: User.IDValue) async throws -> UserInfoDTO
    func updateEmail(_ dto: UpdateEmailDTO, for userID: User.IDValue) async throws -> UserInfoDTO
    func updatePassword(_ dto: UpdatePasswordDTO, for userID: User.IDValue) async throws
}
