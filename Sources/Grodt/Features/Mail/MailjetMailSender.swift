import Foundation
import MailjetKit

struct MailjetConfig: Sendable {
    let apiKey: String
    let apiSecret: String
    let senderEmail: String
    let senderName: String
}

final class MailjetMailSender: MailSending, @unchecked Sendable {
    private let config: MailjetConfig
    private let mailjet: MailjetKit

    init(config: MailjetConfig) {
        self.config = config
        self.mailjet = MailjetKit(apiKey: config.apiKey, apiSecret: config.apiSecret)
    }

    func send(_ message: MailMessage) async throws {
        let from = Recipient(email: config.senderEmail, name: config.senderName)
        let to = Recipient(email: message.to.email, name: message.to.name)

        let attachments: [Attachment]? = message.attachments.isEmpty ? nil : message.attachments.map {
            Attachment(
                fileName: $0.fileName,
                contentType: $0.contentType,
                base64Content: $0.data.base64EncodedString()
            )
        }

        let content = Content(
            subject: message.subject,
            htmlPart: message.htmlBody,
            attachments: attachments
        )

        let envelope = Envelope(from: from, to: [to])
        let mailjetMessage = Message(envelope: envelope, content: content)

        let result = await mailjet.send(message: mailjetMessage)
        switch result {
        case .success:
            return
        case .failure(let error):
            throw mapError(error)
        }
    }

    private func mapError(_ error: MailjetKitError) -> MailSendingError {
        switch error {
        case .networkError:
            return .serviceUnavailable
        case .apiError(let responseError):
            let message = responseError.message.lowercased()
            if message.contains("invalid") {
                return .invalidRecipient
            }
            if message.contains("quota") || message.contains("limit") {
                return .quotaExceeded
            }
            return .unknown(error)
        case .unknownError(let underlyingError):
            if let underlyingError {
                return .unknown(underlyingError)
            }
            return .unknown(error)
        }
    }
}
