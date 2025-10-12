import Foundation
import Vapor

class AccountService {
    private let userRepository: UserRepository
    private let userDataMapper: UserDTOMapper
    
    init(userRepository: UserRepository, userDataMapper: UserDTOMapper) {
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

    func updatePreferences(byMerging newPreferences: UserPreferencesDTO,
                           for userID: User.IDValue) async throws -> UserPreferencesDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        var mailejtConfiguration: UserPreferencesPayload.TransactionsBackup.MailjetConfiguration?
        if let newMailjetPref = newPreferences.transactionsBackup.configuraiton {
            mailejtConfiguration = .init(senderEmail: newMailjetPref.senderEmail, senderName: newMailjetPref.senderName)
        }

        let payload = UserPreferencesPayload(
            transactionBackup: .init(
                isEnabled: newPreferences.transactionsBackup.isEnabled,
                configuration: mailejtConfiguration
            )
        )

        try await userRepository.updatePreferences(payload, for: user)
        return try await userDataMapper.preferences(from: user.preferences!)
    }
}
