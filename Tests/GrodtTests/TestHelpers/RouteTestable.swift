import Foundation

protocol RouteTestable {
    var basePath: String { get }
}

extension RouteTestable {
    func path(for id: UUID) -> String {
        "\(basePath)/\(id)"
    }
}
