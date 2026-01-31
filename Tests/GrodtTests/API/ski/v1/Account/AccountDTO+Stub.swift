@testable import Grodt

extension UserInfoDTO {
    static func stub(
        name: String = "Test User",
        email: String = "test@example.com"
    ) -> UserInfoDTO {
        UserInfoDTO(name: name, email: email)
    }
}

extension UserDetailDTO {
    static func stub(
        name: String = "Test User",
        email: String = "test@example.com",
        preferences: UserPreferencesDTO = .stub()
    ) -> UserDetailDTO {
        UserDetailDTO(name: name, email: email, preferences: preferences)
    }
}

extension UserPreferencesDTO {
    static func stub(
        monthlyEmail: MonthlyEmailConfigDTO = .stub()
    ) -> UserPreferencesDTO {
        UserPreferencesDTO(monthlyEmail: monthlyEmail)
    }
}

extension MonthlyEmailConfigDTO {
    static func stub(
        isEnabled: Bool = false,
        configuration: MailjetConfigurationDTO? = nil
    ) -> MonthlyEmailConfigDTO {
        MonthlyEmailConfigDTO(isEnabled: isEnabled, configuration: configuration)
    }
}

extension MailjetConfigurationDTO {
    static func stub(
        senderEmail: String = "sender@example.com",
        senderName: String = "Sender Name",
        apiKey: String = "test-api-key",
        apiSecret: String = "test-api-secret"
    ) -> MailjetConfigurationDTO {
        MailjetConfigurationDTO(
            senderEmail: senderEmail,
            senderName: senderName,
            apiKey: apiKey,
            apiSecret: apiSecret
        )
    }
}
