import Vapor

struct UpdateMonthlyEmailConfigDTO: Content {
    let isEnabled: Bool
    let senderEmail: String?
    let senderName: String?
    let apiKey: String?
    let apiSecret: String?
}
