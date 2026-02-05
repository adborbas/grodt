import Foundation
import Logging

final class ConsoleMailSender: MailSending, @unchecked Sendable {
    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func send(_ message: MailMessage) async throws {
        logger.info("""

            ========== EMAIL (Console) ==========
            From: \(message.from.name ?? "") <\(message.from.email)>
            To: \(message.to.name ?? "") <\(message.to.email)>
            Subject: \(message.subject)
            Attachments: \(message.attachments.count)
            -------------------------------------
            \(message.htmlBody)
            =====================================
            """)
    }
}
