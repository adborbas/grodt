import Vapor
import Queues

struct UserTokenClearUpJob: AsyncScheduledJob, @unchecked Sendable {
    private let userTokenClearer: UserTokenClearing
    
    init(userTokenClearing: UserTokenClearing) {
        self.userTokenClearer = userTokenClearing
    }
    
    func run(context: Queues.QueueContext) async throws {
        try await userTokenClearer.clearExpiredTokens()
    }
}
