protocol BrokerageDTOMapping: Sendable {
    func brokerage(from brokerage: Brokerage) async throws -> BrokerageDTO
}
