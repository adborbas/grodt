import Foundation
import Vapor
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

enum SecretsEncryptorError: Error, LocalizedError {
    case invalidKey
    case invalidCiphertext
    case decryptionFailed
    case keyFileWriteFailed
    case missingPassword

    var errorDescription: String? {
        switch self {
        case .invalidKey:
            return "Invalid encryption key format"
        case .invalidCiphertext:
            return "Invalid ciphertext format"
        case .decryptionFailed:
            return "Failed to decrypt secret"
        case .keyFileWriteFailed:
            return "Failed to write encryption key file"
        case .missingPassword:
            return "SECRETS_PASSWORD environment variable is required"
        }
    }
}

protocol SecretsEncrypting {
    func encrypt(_ plaintext: String) throws -> String
    func decrypt(_ ciphertext: String) throws -> String
}

final class SecretsEncryptor: SecretsEncrypting {
    private let key: SymmetricKey

    init(key: SymmetricKey) {
        self.key = key
    }

    init(base64Key: String) throws {
        guard let keyData = Data(base64Encoded: base64Key),
              keyData.count == 32 else {
            throw SecretsEncryptorError.invalidKey
        }
        self.key = SymmetricKey(data: keyData)
    }

    func encrypt(_ plaintext: String) throws -> String {
        let data = Data(plaintext.utf8)
        let sealed = try AES.GCM.seal(data, using: key)
        guard let combined = sealed.combined else {
            throw SecretsEncryptorError.invalidCiphertext
        }
        return combined.base64EncodedString()
    }

    func decrypt(_ ciphertext: String) throws -> String {
        guard let data = Data(base64Encoded: ciphertext) else {
            throw SecretsEncryptorError.invalidCiphertext
        }
        let box = try AES.GCM.SealedBox(combined: data)
        let decrypted = try AES.GCM.open(box, using: key)
        guard let plaintext = String(data: decrypted, encoding: .utf8) else {
            throw SecretsEncryptorError.decryptionFailed
        }
        return plaintext
    }

    static func loadOrCreate(from filePath: String) throws -> SecretsEncryptor {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: filePath) {
            let base64Key = try String(contentsOfFile: filePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return try SecretsEncryptor(base64Key: base64Key)
        }

        let key = SymmetricKey(size: .bits256)
        let base64Key = key.withUnsafeBytes { Data($0).base64EncodedString() }

        guard fileManager.createFile(atPath: filePath, contents: Data(base64Key.utf8), attributes: [.posixPermissions: 0o600]) else {
            throw SecretsEncryptorError.keyFileWriteFailed
        }

        return SecretsEncryptor(key: key)
    }

    /// Creates a SecretsEncryptor by deriving a key from a password and salt using HKDF.
    /// This ensures the same key is derived consistently across container restarts.
    static func fromPassword(_ password: String, salt: String) -> SecretsEncryptor {
        let passwordData = Data(password.utf8)
        let saltData = Data(salt.utf8)

        let inputKey = SymmetricKey(data: passwordData)
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: inputKey,
            salt: saltData,
            info: Data("grodt-secrets-encryption".utf8),
            outputByteCount: 32
        )

        return SecretsEncryptor(key: derivedKey)
    }

    /// Creates a SecretsEncryptor from environment variables.
    /// Requires SECRETS_PASSWORD to be set. SECRETS_SALT is optional (defaults to "grodt-default-salt").
    static func fromEnvironment() throws -> SecretsEncryptor {
        guard let password = Environment.get("SECRETS_PASSWORD") else {
            throw SecretsEncryptorError.missingPassword
        }
        let salt = Environment.get("SECRETS_SALT") ?? "grodt-default-salt"
        return fromPassword(password, salt: salt)
    }
}
