@testable import Grodt
import Foundation

final class MockUserDTOMapper: UserDTOMapping, @unchecked Sendable {
    var userInfoResult: UserInfoDTO = UserInfoDTO.stub()
    var userDetailResult: UserDetailDTO = UserDetailDTO.stub()
    var preferencesResult: UserPreferencesDTO = UserPreferencesDTO.stub()

    func userInfo(from user: User) -> UserInfoDTO {
        userInfoResult
    }

    func userDetail(from user: User) -> UserDetailDTO {
        userDetailResult
    }

    func preferences(from userPreferences: UserPreferences) -> UserPreferencesDTO {
        preferencesResult
    }
}
