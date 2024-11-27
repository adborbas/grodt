import Vapor

actor ClientRequestStore {
    private struct ClientData {
        var requestCount: Int
        var windowStart: Date
    }
    
    private var clients: [String: ClientData] = [:]
    private let timeWindow: TimeInterval
    private let expirationDuration: TimeInterval
    private var lastCleanupTime: Date
    private let cleanupInterval: TimeInterval

    init(timeWindow: TimeInterval, expirationDuration: TimeInterval, cleanupInterval: TimeInterval) {
        self.timeWindow = timeWindow
        self.expirationDuration = expirationDuration
        self.cleanupInterval = cleanupInterval
        self.lastCleanupTime = Date()
    }

    func incrementRequestCount(for clientID: String, at time: Date) async -> Int {
        // Perform cleanup periodically
        if time.timeIntervalSince(lastCleanupTime) > cleanupInterval {
            cleanUpExpiredClients(currentTime: time)
            lastCleanupTime = time
        }

        var clientData = clients[clientID] ?? ClientData(requestCount: 0, windowStart: time)
        
        if time.timeIntervalSince(clientData.windowStart) > timeWindow {
            // Start a new time window
            clientData.requestCount = 1
            clientData.windowStart = time
        } else {
            // Increment request count within the current time window
            clientData.requestCount += 1
        }
        
        clients[clientID] = clientData
        return clientData.requestCount
    }

    private func cleanUpExpiredClients(currentTime: Date) {
        clients = clients.filter { _, data in
            currentTime.timeIntervalSince(data.windowStart) < expirationDuration
        }
    }
}
