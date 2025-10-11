extension AppConfiguration {
    struct Mailjet {
        @OptionalEnvironmentVariable(key: "MAILJET_API_KEY")
        var apiKey: String?

        @OptionalEnvironmentVariable(key: "MAILJET_API_SECRET")
        var apiSecret: String?

        @OptionalEnvironmentVariable(key: "MAILJET_SENDER_EMAIL")
        var senderEmail: String?

        @OptionalEnvironmentVariable(key: "MAILJET_SENDER_NAME")
        var senderName: String?
    }

    var mailjet: Mailjet { Mailjet() }
}
