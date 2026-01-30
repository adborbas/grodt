@testable import Grodt
import Testing
import Vapor
import XCTVapor

struct OriginRefererCheckMiddlewareTests {

    // MARK: - GET Requests (should pass through)

    @Test func getRequest_noOriginOrReferer_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.GET, "/test", afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func getRequest_withCrossOrigin_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.GET, "/test", beforeRequest: { req in
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - POST Requests

    @Test func postRequest_noOriginOrReferer_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func postRequest_matchingOrigin_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://example.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func postRequest_crossOrigin_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test func postRequest_crossOriginReferer_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .referer, value: "https://evil.com/page")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    @Test func postRequest_matchingReferer_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .referer, value: "https://example.com/some/page")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - PUT Requests

    @Test func putRequest_crossOrigin_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.PUT, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    // MARK: - DELETE Requests

    @Test func deleteRequest_crossOrigin_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.DELETE, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    // MARK: - PATCH Requests

    @Test func patchRequest_crossOrigin_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.PATCH, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    // MARK: - X-Forwarded-Host Header

    @Test func postRequest_xForwardedHost_usesForwardedHost() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "internal.example.com")
                req.headers.add(name: "X-Forwarded-Host", value: "public.example.com")
                req.headers.add(name: .origin, value: "https://public.example.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    @Test func postRequest_xForwardedHost_mismatch_returnsForbidden() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "internal.example.com")
                req.headers.add(name: "X-Forwarded-Host", value: "public.example.com")
                req.headers.add(name: .origin, value: "https://evil.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .forbidden)
            })
        }
    }

    // MARK: - Origin Takes Precedence Over Referer

    @Test func postRequest_originAndReferer_originTakesPrecedence() async throws {
        try await withMiddlewareApp { app in
            // Origin matches but referer doesn't - should pass because origin is checked first
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com")
                req.headers.add(name: .origin, value: "https://example.com")
                req.headers.add(name: .referer, value: "https://evil.com/page")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - Case Insensitivity

    @Test func postRequest_caseInsensitiveHostMatch_passes() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "Example.COM")
                req.headers.add(name: .origin, value: "https://example.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - Host with Port

    @Test func postRequest_hostWithPort_matchesWithoutPort() async throws {
        try await withMiddlewareApp { app in
            try await app.test(.POST, "/test", beforeRequest: { req in
                req.headers.add(name: .host, value: "example.com:8080")
                req.headers.add(name: .origin, value: "https://example.com")
            }, afterResponse: { res async throws in
                #expect(res.status == .ok)
            })
        }
    }

    // MARK: - Helper

    private func withMiddlewareApp(_ body: (Application) async throws -> Void) async throws {
        let app = try await Application.make(.testing)
        defer { Task { try? await app.asyncShutdown() } }

        app.middleware.use(OriginRefererCheckMiddleware())

        app.get("test") { _ in "OK" }
        app.post("test") { _ in "OK" }
        app.put("test") { _ in "OK" }
        app.delete("test") { _ in "OK" }
        app.patch("test") { _ in "OK" }

        try await XCTVaporContext.$emitWarningIfCurrentTestInfoIsAvailable.withValue(false) {
            try await body(app)
        }
    }
}
