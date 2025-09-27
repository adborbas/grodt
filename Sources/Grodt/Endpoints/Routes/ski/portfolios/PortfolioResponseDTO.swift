struct PortfolioResponseDTO: ResponseDTO {
    let portfolio: PortfolioDTO
    let historicalPerformance: PerformanceTimeSeriesDTO
}
