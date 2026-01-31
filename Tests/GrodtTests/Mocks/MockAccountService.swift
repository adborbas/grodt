@testable import Grodt
import Vapor

final class MockAccountService: AccountServicing, @unchecked Sendable {
    var userInfoResult: Result<UserInfoDTO, Error> = .success(UserInfoDTO.stub())
    var userDetailResult: Result<UserDetailDTO, Error> = .success(UserDetailDTO.stub())
    var updateMonthlyEmailConfigResult: Result<UserPreferencesDTO, Error> = .success(UserPreferencesDTO.stub())

    func userInfo(for userID: User.IDValue) async throws -> UserInfoDTO {
        try userInfoResult.get()
    }

    func userDetail(for userID: User.IDValue) async throws -> UserDetailDTO {
        try userDetailResult.get()
    }

    func updateMonthlyEmailConfig(_ newConfig: UpdateMonthlyEmailConfigDTO,
                                   for userID: User.IDValue) async throws -> UserPreferencesDTO {
        try updateMonthlyEmailConfigResult.get()
    }
}
