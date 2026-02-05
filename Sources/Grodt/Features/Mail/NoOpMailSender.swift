import Foundation
import Logging

final class NoOpMailSender: MailSending, @unchecked Sendable {
    private let logger: Logger
    private var hasLoggedWarning = false
    private let lock = NSLock()

    init(logger: Logger) {
        self.logger = logger
    }

    func send(_ message: MailMessage) async throws {
        logWarningOnce()
    }

    private func logWarningOnce() {
        lock.lock()
        defer { lock.unlock() }

        guard !hasLoggedWarning else { return }
        hasLoggedWarning = true
        logger.warning("Email sending is disabled (Mailjet not configured). Emails will be silently skipped.")
    }
}
