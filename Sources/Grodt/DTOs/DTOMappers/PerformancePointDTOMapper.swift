struct PerformancePointDTOMapper {
    func performancePoint(from enity: DatedPortfolioPerformance) -> PerformancePointDTO {
        return PerformancePointDTO(date: enity.date.date,
                                   value: enity.value,
                                   moneyIn: enity.moneyIn)
    }
}