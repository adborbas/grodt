struct UserPreferencesDTO: ResponseDTO {
    struct TransactionsBackupDTO: Codable {
        let isEnabled: Bool
        let mailjetPreferences: MailjetPreferencesDTO?
    }

    let transactionsBackup: TransactionsBackupDTO
}
