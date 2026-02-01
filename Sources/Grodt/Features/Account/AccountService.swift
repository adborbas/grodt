import Foundation
import Vapor

class AccountService: AccountServicing {
    private let userRepository: UserRepository
    private let userDataMapper: UserDTOMapping
    private let logger: Logger

    init(userRepository: UserRepository, userDataMapper: UserDTOMapping, logger: Logger) {
        self.userRepository = userRepository
        self.userDataMapper = userDataMapper
        self.logger = logger
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

        let updatedPreferences: UserPreferences
        do {
            updatedPreferences = try await userRepository.setMonthlyEmailConfig(newMonthlyEmailConfig, for: user)
        } catch {
            try await userRepository.setMailjetApiSecret(nil, for: user)
            throw Abort(.internalServerError)
        }

        return try await userDataMapper.preferences(from: updatedPreferences, for: userID)
    }

    // MARK: - Profile Updates

    func updateName(_ dto: UpdateNameDTO, for userID: User.IDValue) async throws -> UserInfoDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        let sanitized = sanitizeName(dto.name)

        guard sanitized.count >= 5 else {
            throw Abort(.badRequest, reason: "Name must be at least 5 characters.")
        }

        try await userRepository.updateName(sanitized, for: user)
        logger.info("Profile updated: user=\(userID) action=name.updated")

        return userDataMapper.userInfo(from: user)
    }

    func updateEmail(_ dto: UpdateEmailDTO, for userID: User.IDValue) async throws -> UserInfoDTO {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        // Verify current password
        guard try user.verify(password: dto.currentPassword) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect.")
        }

        // Check email uniqueness - return generic error to prevent enumeration
        let normalizedEmail = dto.email.lowercased()
        if let existing = try await userRepository.findByEmail(normalizedEmail),
           existing.id != userID {
            throw Abort(.badRequest, reason: "Invalid request.")
        }

        try await userRepository.updateEmail(normalizedEmail, for: user)
        logger.info("Profile updated: user=\(userID) action=email.updated")

        return userDataMapper.userInfo(from: user)
    }

    func updatePassword(_ dto: UpdatePasswordDTO, for userID: User.IDValue) async throws {
        guard let user = try await userRepository.user(for: userID) else {
            throw Abort(.notFound)
        }

        // Verify current password
        guard try user.verify(password: dto.currentPassword) else {
            throw Abort(.unauthorized, reason: "Current password is incorrect.")
        }

        // Prevent same password
        if dto.currentPassword == dto.newPassword {
            throw Abort(.badRequest, reason: "New password must be different from current password.")
        }

        // Hash new password and update
        let newPasswordHash = try Bcrypt.hash(dto.newPassword)
        try await userRepository.updatePasswordHash(newPasswordHash, for: user)

        // Invalidate all tokens
        try await userRepository.deleteAllTokens(for: userID)

        logger.info("Profile updated: user=\(userID) action=password.updated")
    }

    // MARK: - Private Helpers

    private func sanitizeName(_ name: String) -> String {
        return name
            .precomposedStringWithCanonicalMapping  // NFC normalize unicode
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
