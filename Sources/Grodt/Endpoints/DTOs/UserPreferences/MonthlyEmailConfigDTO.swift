struct MonthlyEmailConfigDTO: Codable {
    let isEnabled: Bool
    let configuration: MailjetConfigurationDTO?
}
