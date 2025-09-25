struct PortfolioResponseDTO: ResponseDTO {
    let id: String
    let name: String
    let currency: CurrencyDTO
    let performance: PerformanceDTO
    let investments: [InvestmentDTO]
    let historicalPerformance: PerformanceTimeSeriesDTO
}
