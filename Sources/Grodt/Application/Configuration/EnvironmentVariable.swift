import Vapor

protocol EnvironmentVariableConvertible {
    static func convert(from environmentString: String) -> Self?
}

extension String: EnvironmentVariableConvertible {
    static func convert(from environmentString: String) -> String? {
        return environmentString
    }
}

extension Int: EnvironmentVariableConvertible {
    static func convert(from environmentString: String) -> Int? {
        return Int(environmentString)
    }
}

extension Bool: EnvironmentVariableConvertible {
    static func convert(from environmentString: String) -> Bool? {
        return environmentString.lowercased() == "true"
    }
}

extension Optional<Int>: EnvironmentVariableConvertible {
    static func convert(from environmentString: String) -> Optional<Int>? {
        return Int(environmentString)
    }
}

@propertyWrapper
struct RequiredEnvironmentVariable<T: EnvironmentVariableConvertible> {
    private let key: String

    var wrappedValue: T {
        guard let valueString = Environment.get(key), let value = T.convert(from: valueString) else {
            fatalError("Required environment variable \(key) not found or could not be converted. Please specify in .env.[production/integration]")
        }
        return value
    }

    init(key: String) {
        self.key = key
    }
}

struct EnvironmentVariableMissing: Error, LocalizedError {
    let key: String

    var errorDescription: String {
        "Environment variable \(key) could not be found."
    }
}

@propertyWrapper
struct OptionalEnvironmentVariable<T: EnvironmentVariableConvertible> {
    private let key: String

    var projectedValue: OptionalEnvironmentVariable { self }

    var wrappedValue: T? {
        guard let valueString = Environment.get(key), let value = T.convert(from: valueString) else {
            return nil
        }
        return value
    }

    func requiredValue() throws -> T {
        guard let wrapped = wrappedValue.wrapped else {
            throw EnvironmentVariableMissing(key: key)
        }

        return wrapped
    }

    init(key: String) {
        self.key = key
    }
}

extension Environment {
    static func getInt(_ keyed: String) -> Int? {
        guard let rawString = Environment.get(keyed),
              let port = Int(rawString) else {
            return nil
        }
        
        return port
    }
}
