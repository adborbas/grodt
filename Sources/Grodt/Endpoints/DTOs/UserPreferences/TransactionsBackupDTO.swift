struct TransactionsBackupDTO: Codable {
    let isEnabled: Bool
    let configuration: MailjetConfigurationDTO?
}
