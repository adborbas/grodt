@testable import Grodt
import Vapor

final class MockAccountService: AccountServicing, @unchecked Sendable {
    var userInfoResult: Result<UserInfoDTO, Error> = .success(UserInfoDTO.stub())
    var userDetailResult: Result<UserDetailDTO, Error> = .success(UserDetailDTO.stub())
    var updateMonthlyEmailConfigResult: Result<UserPreferencesDTO, Error> = .success(UserPreferencesDTO.stub())
    var updateNameResult: Result<UserInfoDTO, Error> = .success(UserInfoDTO.stub())
    var updateEmailResult: Result<UserInfoDTO, Error> = .success(UserInfoDTO.stub())
    var updatePasswordResult: Result<Void, Error> = .success(())

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

    func updateName(_ dto: UpdateNameDTO, for userID: User.IDValue) async throws -> UserInfoDTO {
        try updateNameResult.get()
    }

    func updateEmail(_ dto: UpdateEmailDTO, for userID: User.IDValue) async throws -> UserInfoDTO {
        try updateEmailResult.get()
    }

    func updatePassword(_ dto: UpdatePasswordDTO, for userID: User.IDValue) async throws {
        try updatePasswordResult.get()
    }
}
