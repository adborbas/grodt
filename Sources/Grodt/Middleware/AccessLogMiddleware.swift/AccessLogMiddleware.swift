import Vapor
import NIOCore

/// Verbose access/error logging with safe header redaction and request-id propagation.
/// Reads switches from `app.config.logging`.
struct AccessLogMiddleware: AsyncMiddleware {
    
    struct Config {
        var logRequestHeaders: Bool
        var logResponseHeaders: Bool
        var logRequestBodyPreview: Bool
        var maxBodyPreviewBytes: Int
        var redactedHeaders: Set<String>

        static func from(app: Application) -> Config {
            let loggingEnv = app.config.logging

            return Config(
                logRequestHeaders: loggingEnv.requestLogHeaders == true,
                logResponseHeaders: loggingEnv.responseLogHeaders == true,
                logRequestBodyPreview: loggingEnv.requestLogBodyPreview == true,
                maxBodyPreviewBytes: max(loggingEnv.requestLogBodyPreviewMax ?? 1024, 1),
                redactedHeaders: ["authorization", "cookie", "set-cookie", "proxy-authorization"]
            )
        }
    }

    private let config: Config

    /// Preferred initializer: build config from `AppConfiguration`.
    init(app: Application) {
        self.config = Config.from(app: app)
    }

    /// Testing convenience initializer.
    init(config: Config) {
        self.config = config
    }

    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Correlation id: honor incoming X-Request-ID or assign a new one.
        let requestID = req.headers.first(name: .xRequestID) ?? UUID().uuidString

        // Attach to logger metadata so inner logs inherit it.
        var requestScopedLogger = req.logger
        requestScopedLogger[metadataKey: "request-id"] = .string(requestID)

        // Basic request context
        let method = req.method.string
        let scheme = req.url.scheme ?? "unknown"
        let host = req.headers.first(name: .host) ?? req.application.http.server.configuration.hostname
        let path = req.url.path.isEmpty ? "/" : req.url.path
        let query = req.url.query ?? ""
        let userAgent = req.headers.first(name: .userAgent) ?? "-"
        let referer = req.headers.first(name: .referer) ?? "-"
        let clientIP = req.remoteAddress?.ipAddress ?? req.remoteAddress?.description ?? "-"
        let contentLength = req.headers.first(name: .contentLength) ?? "-"
        let userID = req.auth.get(User.self)?.id?.uuidString ?? "-"

        // Optional header logging (redacted)
        let requestHeadersSnapshot: String? = config.logRequestHeaders
            ? redacted(headers: req.headers, redactedNames: config.redactedHeaders)
            : nil

        // Optional body preview: only if resident (do not consume streaming bodies)
        let requestBodyPreview: String? = {
            guard config.logRequestBodyPreview,
                  let buffer = req.body.data,
                  buffer.readableBytes > 0
            else { return nil }
            let previewLength = min(buffer.readableBytes, config.maxBodyPreviewBytes)
            guard let slice = buffer.getSlice(at: 0, length: previewLength) else { return nil }
            return String(buffer: slice)
        }()

        // Request start log
        requestScopedLogger.info("⇢ \(method) \(scheme)://\(host)\(path)\(query.isEmpty ? "" : "?\(query)") [ip:\(clientIP), user:\(userID), ua:\(userAgent), referer:\(referer), content-length:\(contentLength)]\(requestHeadersSnapshot.map { " headers:\($0)" } ?? "")\(requestBodyPreview.map { " body-preview:\($0)" } ?? "")")

        let startedAt = NIODeadline.now()

        do {
            let response = try await next.respond(to: req)
            let elapsedMs = millisecondsSince(startedAt)

            // Ensure response carries the request id for client correlation.
            var responseHeaders = response.headers
            if responseHeaders.first(name: .xRequestID) == nil {
                responseHeaders.add(name: .xRequestID, value: requestID)
            }
            response.headers = responseHeaders

            // Optional response headers snapshot
            let responseHeadersSnapshot: String? = config.logResponseHeaders
                ? redacted(headers: response.headers, redactedNames: config.redactedHeaders)
                : nil

            let statusCode = response.status.code
            let responseLength = response.headers.first(name: .contentLength) ?? "-"

            if statusCode >= 500 {
                requestScopedLogger.error("⇠ \(statusCode) \(method) \(path) (\(elapsedMs) ms) [resp-bytes:\(responseLength)]\(responseHeadersSnapshot.map { " headers:\($0)" } ?? "")")
            } else if statusCode >= 400 {
                requestScopedLogger.warning("⇠ \(statusCode) \(method) \(path) (\(elapsedMs) ms) [resp-bytes:\(responseLength)]\(responseHeadersSnapshot.map { " headers:\($0)" } ?? "")")
            } else {
                requestScopedLogger.info("⇠ \(statusCode) \(method) \(path) (\(elapsedMs) ms) [resp-bytes:\(responseLength)]\(responseHeadersSnapshot.map { " headers:\($0)" } ?? "")")
            }

            return response
        } catch {
            let elapsedMs = millisecondsSince(startedAt)
            // `reflecting:` usually contains lower-level details (e.g., SQL / decoding errors).
            requestScopedLogger.error("✗ 500 \(method) \(path) (\(elapsedMs) ms) error: \(String(describing: error)) details: \(String(reflecting: error)) [ip:\(clientIP), user:\(userID), req-id:\(requestID)]")
            throw error
        }
    }

    // MARK: - Helpers

    private func millisecondsSince(_ start: NIODeadline) -> Int {
        let nanos = (NIODeadline.now().uptimeNanoseconds &- start.uptimeNanoseconds)
        return Int(nanos / 1_000_000)
    }

    private func redacted(headers: HTTPHeaders, redactedNames: Set<String>) -> String {
        var items: [String] = []
        for (headerName, headerValue) in headers {
            if redactedNames.contains(headerName.lowercased()) {
                items.append("\(headerName): <redacted>")
            } else {
                items.append("\(headerName): \(headerValue)")
            }
        }
        return "{ " + items.joined(separator: ", ") + " }"
    }
}

// Small convenience for request-id propagation
extension HTTPHeaders.Name {
    static let xRequestID = HTTPHeaders.Name("X-Request-ID")
}
