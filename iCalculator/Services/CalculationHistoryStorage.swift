import Foundation

class CalculationHistoryStorage {
    
    static let calculationHistoryKey = "calculationHistoryKey"
    static let limitCalculationHistory = 10 // Поставь нужное значение
    
    var calculations: [Calculation] = []
    
    init() {
        self.calculations = loadHistory()
    }
    
    func setHistory() {
        limitCalculationHistory()
        if let encoded = try? JSONEncoder().encode(calculations) {
            UserDefaults.standard.setValue(encoded, forKey: CalculationHistoryStorage.calculationHistoryKey)
        }
    }
    
    func loadHistory() -> [Calculation] {
        if let data = UserDefaults.standard.data(forKey: CalculationHistoryStorage.calculationHistoryKey) {
            return (try? JSONDecoder().decode([Calculation].self, from: data)) ?? []
        }
        return []
    }
    
    private func limitCalculationHistory() {
        if calculations.count > CalculationHistoryStorage.limitCalculationHistory {
            calculations.removeFirst(calculations.count - CalculationHistoryStorage.limitCalculationHistory)
        }
    }
}
