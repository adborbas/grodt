protocol TransactionDTOMapping: Sendable {
    func transaction(from transaction: Transaction) async throws -> TransactionDTO
}
