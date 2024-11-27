import Vapor

struct RateLimiterMiddleware: AsyncMiddleware {
    private let maxRequests: Int
    private let store: ClientRequestStore

    init(maxRequests: Int, perSeconds timeWindow: TimeInterval) {
        self.maxRequests = maxRequests

        let expirationDuration = timeWindow * 3
        let cleanupInterval = timeWindow

        self.store = ClientRequestStore(
            timeWindow: timeWindow,
            expirationDuration: expirationDuration,
            cleanupInterval: cleanupInterval
        )
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let clientID = extractClientIdentifier(from: request)
        let currentTime = Date()

        let requestCount = await store.incrementRequestCount(for: clientID, at: currentTime)

        if requestCount > maxRequests {
            throw Abort(.tooManyRequests, reason: "Too many requests. Please try again later.")
        }

        return try await next.respond(to: request)
    }
    
    private func extractClientIdentifier(from request: Request) -> String {
        if let userID = request.auth.get(User.self)?.id?.uuidString {
            return "user:\(userID)"
        } else if let sessionID = request.session.id?.string {
            return "session:\(sessionID)"
        } else {
            return extractClientIP(from: request)
        }
    }

    private func extractClientIP(from request: Request) -> String {
        // Try to get the client IP from the X-Forwarded-For header
        if let forwardedFor = request.headers["X-Forwarded-For"].first {
            // The X-Forwarded-For header can contain multiple IPs, the first one is the client's IP
            if let clientIP = forwardedFor.split(separator: ",").first?.trimmingCharacters(in: .whitespaces) {
                return clientIP
            }
        }

        // Fallback to the remote address
        return request.remoteAddress?.ipAddress ?? "unknown"
    }
}
