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

    func updateTranscationBackup(_ newBackupConfig: UpdateTranscationBackupConfigurationDTO,
                                 for userID: User.IDValue) async throws -> UserPreferencesDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        let newTransactionBackupModel: UserPreferencesPayload.TransactionsBackup

        if !newBackupConfig.isEnabled {
            newTransactionBackupModel = .init(isEnabled: false,
                                              configuration: nil)
            try await userRepository.setMailjetApiSecret(nil, for: user)

        } else {
            guard let senderEmail = newBackupConfig.senderEmail,
                  let senderName = newBackupConfig.senderName,
                  let apiKey = newBackupConfig.apiKey,
                  let apiSecret = newBackupConfig.apiSecret else {
                throw Abort(.badRequest, reason: "Mailjet configuration missing.")
            }

            let mailejtConfiguration: UserPreferencesPayload.TransactionsBackup.MailjetConfiguration =
                .init(senderEmail: senderEmail,
                      senderName: senderName,
                      apiKey: apiKey)

            newTransactionBackupModel = .init(isEnabled: true,
                                              configuration: mailejtConfiguration)

            try await userRepository.setMailjetApiSecret(apiSecret, for: user)
        }

        do {
            try await userRepository.setTransactionBackup(newTransactionBackupModel, for: user)
        } catch {
            try await userRepository.setMailjetApiSecret(nil, for: user)
            throw Abort(.internalServerError)
        }
        return try await userDataMapper.preferences(from: user.preferences!, for: user.requireID())
    }
}
