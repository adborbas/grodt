struct TransactionsBackupDTO: Codable {
    let isEnabled: Bool
    let configuraiton: MailjetConfigurationDTO?
}
