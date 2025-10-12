struct UserPreferencesDTO: ResponseDTO {
    let isTransactionsBackupEnabled: Bool
    let mailjetPreferences: MailjetPreferencesDTO?
}
