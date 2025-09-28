extension AppConfiguration {
    struct Logging {
        // Enable logging of request headers (with redaction)
        @OptionalEnvironmentVariable(key: "REQUEST_LOG_HEADERS")
        var requestLogHeaders: Bool?

        // Enable logging of response headers (with redaction)
        @OptionalEnvironmentVariable(key: "RESPONSE_LOG_HEADERS")
        var responseLogHeaders: Bool?

        // Enable logging of a safe preview of the request body (resident bodies only)
        @OptionalEnvironmentVariable(key: "REQUEST_LOG_BODY_PREVIEW")
        var requestLogBodyPreview: Bool?

        // Max bytes to preview from the request body if enabled (default 1024)
        @OptionalEnvironmentVariable(key: "REQUEST_LOG_BODY_PREVIEW_MAX")
        var requestLogBodyPreviewMax: Int?
    }

    var logging: Logging { Logging() }
}
