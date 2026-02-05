import Foundation

// MARK: - Protocol

protocol MailSending: Sendable {
    func send(_ message: MailMessage) async throws
}

// MARK: - Types

struct MailAddress: Sendable, Equatable {
    let email: String
    let name: String?

    init(email: String, name: String? = nil) {
        self.email = email
        self.name = name
    }
}

struct MailAttachment: Sendable, Equatable {
    let fileName: String
    let contentType: String
    let data: Data
}

struct MailMessage: Sendable {
    let from: MailAddress
    let to: MailAddress
    let subject: String
    let htmlBody: String
    let attachments: [MailAttachment]

    init(
        from: MailAddress,
        to: MailAddress,
        subject: String,
        htmlBody: String,
        attachments: [MailAttachment] = []
    ) {
        self.from = from
        self.to = to
        self.subject = subject
        self.htmlBody = htmlBody
        self.attachments = attachments
    }
}

// MARK: - Errors

enum MailSendingError: Error {
    case serviceUnavailable
    case invalidRecipient
    case quotaExceeded
    case unknown(Error)
}
