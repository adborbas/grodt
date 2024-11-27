import Foundation

actor RateLimiter {
    private enum Constants {
        static let nanosecondsPerSecond: UInt64 = 1_000_000_000
        static let timeIntervalInSeconds: TimeInterval = 60
    }
    
    private let maxRequestsPerMinute: Int
    private var requestTimestamps: [Date] = []
    
    init(maxRequestsPerMinute: Int) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    func waitIfNeeded() async {
        let now = Date()
        
        removeOldRequests(before: now)
        
        if shouldWait() {
            await waitUntilAllowed(from: now)
            
            let updatedNow = Date()
            removeOldRequests(before: updatedNow)
        }
        
        recordRequest(at: Date())
    }
    
    // MARK: - Helper Methods
    
    private func removeOldRequests(before now: Date) {
        let windowStart = now.addingTimeInterval(-Constants.timeIntervalInSeconds)
        // Keep only the timestamps within the time window
        requestTimestamps = requestTimestamps.filter { $0 >= windowStart }
    }
    
    private func shouldWait() -> Bool {
        return requestTimestamps.count >= maxRequestsPerMinute
    }
    
    private func waitUntilAllowed(from now: Date) async {
        guard let earliestRequest = requestTimestamps.first else { return }
        
        let waitTime = earliestRequest.addingTimeInterval(Constants.timeIntervalInSeconds).timeIntervalSince(now)
        if waitTime > 0 {
            let sleepDuration = UInt64(waitTime * Double(Constants.nanosecondsPerSecond))
            try? await Task.sleep(nanoseconds: sleepDuration)
        }
    }
    
    private func recordRequest(at date: Date) {
        requestTimestamps.append(date)
    }
}
