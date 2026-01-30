import Foundation
import Vapor

class AccountService: AccountServicing {
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

    func updateMonthlyEmailConfig(_ newConfig: UpdateMonthlyEmailConfigDTO,
                                   for userID: User.IDValue) async throws -> UserPreferencesDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        let newMonthlyEmailConfig: UserPreferencesPayload.MonthlyEmailConfig

        if !newConfig.isEnabled {
            newMonthlyEmailConfig = .init(isEnabled: false,
                                          configuration: nil)
            try await userRepository.setMailjetApiSecret(nil, for: user)

        } else {
            guard let senderEmail = newConfig.senderEmail,
                  let senderName = newConfig.senderName,
                  let apiKey = newConfig.apiKey,
                  let apiSecret = newConfig.apiSecret else {
                throw Abort(.badRequest, reason: "Mailjet configuration missing.")
            }

            let mailjetConfiguration: UserPreferencesPayload.MonthlyEmailConfig.MailjetConfiguration =
                .init(senderEmail: senderEmail,
                      senderName: senderName,
                      apiKey: apiKey)

            newMonthlyEmailConfig = .init(isEnabled: true,
                                          configuration: mailjetConfiguration)

            try await userRepository.setMailjetApiSecret(apiSecret, for: user)
        }

        do {
            try await userRepository.setMonthlyEmailConfig(newMonthlyEmailConfig, for: user)
        } catch {
            try await userRepository.setMailjetApiSecret(nil, for: user)
            throw Abort(.internalServerError)
        }
        return try await userDataMapper.preferences(from: user.preferences!, for: user.requireID())
    }
}
