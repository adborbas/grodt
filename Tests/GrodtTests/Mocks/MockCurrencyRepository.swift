@testable import Grodt
import Foundation

final class MockCurrencyRepository: CurrencyRepository, @unchecked Sendable {
    var currenciesResult: Result<[Currency], Error> = .success([])
    var currencyResult: Result<Currency?, Error> = .success(nil)

    func currencies() async throws -> [Currency] {
        try currenciesResult.get()
    }

    func currency(for code: String) async throws -> Currency? {
        try currencyResult.get()
    }
}
