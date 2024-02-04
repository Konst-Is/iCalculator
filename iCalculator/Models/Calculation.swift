import Foundation

struct Calculation {
    let expression: [CalculationHistoryItem]
    let result: Double
}

extension Calculation: Codable {}

