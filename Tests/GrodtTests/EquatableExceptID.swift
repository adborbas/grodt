@testable import Grodt
import Testing

protocol EquatableExceptID {
    func equalToExceptIDWith(_ other: Self) -> Bool
}

extension PortfolioInfoDTO: EquatableExceptID {
    func equalToExceptIDWith(_ other: PortfolioInfoDTO) -> Bool {
        return name == other.name &&
        currency == other.currency &&
        performance == other.performance
    }
}

extension PortfolioDTO: EquatableExceptID {
    func equalToExceptIDWith(_ other: PortfolioDTO) -> Bool {
        return name == other.name &&
        currency == other.currency &&
        performance == other.performance &&
        investments == other.investments
    }
}

func expectEqualExceptID<T>(_ lhs: T, _ rhs: T, sourceLocation: SourceLocation = #_sourceLocation) where T: EquatableExceptID {
    #expect(lhs.equalToExceptIDWith(rhs), sourceLocation: sourceLocation)
}
