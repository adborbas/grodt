import Vapor

struct CreatePortfolioRequestDTO: Content {
    let name: String
    let currency: String
}
