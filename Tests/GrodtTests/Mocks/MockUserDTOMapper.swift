@testable import Grodt
import Foundation

final class MockUserDTOMapper: UserDTOMapping, @unchecked Sendable {
    var userInfoResult: UserInfoDTO = UserInfoDTO.stub()
    var userDetailResult: Result<UserDetailDTO, Error> = .success(UserDetailDTO.stub())
    var preferencesResult: Result<UserPreferencesDTO, Error> = .success(UserPreferencesDTO.stub())

    func userInfo(from user: User) -> UserInfoDTO {
        userInfoResult
    }

    func userDetail(from user: User) async throws -> UserDetailDTO {
        try userDetailResult.get()
    }

    func preferences(from userPreferences: UserPreferences, for user: User.IDValue) async throws -> UserPreferencesDTO {
        try preferencesResult.get()
    }
}
