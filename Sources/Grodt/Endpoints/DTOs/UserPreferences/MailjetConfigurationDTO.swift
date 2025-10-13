struct MailjetConfigurationDTO: Codable {
    let senderEmail: String
    let senderName: String
    let apiKey: String
    let apiSecret: String
}
