import Vapor
import Queues
import Foundation

struct BackupJob: AsyncScheduledJob, @unchecked Sendable {
    private let transactionsBackup: TransactionsBackup

    init(transactionsBackup: TransactionsBackup) {
        self.transactionsBackup = transactionsBackup
    }

    func run(context: QueueContext) async throws {
        try await transactionsBackup.backup()
    }
}
