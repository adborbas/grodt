import Vapor
import Foundation

struct OriginRefererCheckMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {

        switch request.method {
        case .POST, .PUT, .PATCH, .DELETE:
            let origin = request.headers.first(name: .origin)
            let referer = request.headers.first(name: .referer)
            let host = request.headers.first(name: .host)

            func hostMatches(_ urlString: String?, _ expectedHost: String?) -> Bool {
                guard let urlString, let expected = expectedHost, !urlString.isEmpty, !expected.isEmpty else { return true }
                let uri = URI(string: urlString)
                guard let got = uri.host else { return false }
                
                return got.lowercased() == expected.split(separator: ":").first!.lowercased()
            }

            if let origin, !hostMatches(origin, host) {
                throw Abort(.forbidden, reason: "Cross-origin write blocked by Origin policy")
            }
            if origin == nil, let referer, !hostMatches(referer, host) {
                throw Abort(.forbidden, reason: "Cross-origin write blocked by Referer policy")
            }
        default:
            break
        }

        return try await next.respond(to: request)
    }
}
