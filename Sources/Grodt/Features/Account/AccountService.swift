import Foundation
import Vapor

class AccountService: AccountServicing {
    private let userRepository: UserRepository
    private let userDataMapper: UserDTOMapping

    init(userRepository: UserRepository, userDataMapper: UserDTOMapping) {
        self.userRepository = userRepository
        self.userDataMapper = userDataMapper
    }
    
    func userInfo(for userID: User.IDValue) async throws -> UserInfoDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }
        
        return userDataMapper.userInfo(from: user)
    }

    func userDetail(for userID: User.IDValue) async throws -> UserDetailDTO {
        guard let user = try await userRepository.user(for: userID, with: [.preferences]) else {
            throw Abort(.notFound)
        }

        return try await userDataMapper.userDetail(from: user)
    }

    func updateMonthlyEmailConfig(_ newConfig: UpdateMonthlyEmailConfigDTO,
                                   for userID: User.IDValue) async throws -> UserPreferencesDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        let newMonthlyEmailConfig = UserPreferencesPayload.MonthlyEmailConfig(isEnabled: newConfig.isEnabled)
        let updatedPreferences = try await userRepository.setMonthlyEmailConfig(newMonthlyEmailConfig, for: user)

        return userDataMapper.preferences(from: updatedPreferences)
    }
}
