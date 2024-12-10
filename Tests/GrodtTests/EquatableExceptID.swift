@testable import Grodt
import XCTest

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

func XCTAssertEqualExceptID<T>(_ lhs: T, _ rhs: T) where T: EquatableExceptID {
    XCTAssert(lhs.equalToExceptIDWith(rhs))
}
