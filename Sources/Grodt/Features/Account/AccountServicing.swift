import Foundation

protocol AccountServicing: Sendable {
    func userInfo(for userID: User.IDValue) async throws -> UserInfoDTO
    func userDetail(for userID: User.IDValue) async throws -> UserDetailDTO
    func updateMonthlyEmailConfig(_ newConfig: MonthlyEmailConfigDTO,
                                   for userID: User.IDValue) async throws -> UserPreferencesDTO
}
