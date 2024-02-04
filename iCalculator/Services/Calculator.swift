import Foundation

protocol Calculator {
    func calculate() throws -> Double
    var calculationHistory: [CalculationHistoryItem] { get set }
    var memory: Double { get set }
}

final class CalculatorImpl: Calculator {
    
    var calculationHistory: [CalculationHistoryItem] = []
    
    var memory: Double = 0 //{
//        didSet {
//            memoryLabel.text = String(memory)
//        }
//    }
    
    func calculate() throws -> Double {
        guard case .number(let firstNumber) = calculationHistory[0] else { return 0 }
        
        var currentResult = firstNumber
        
        var tempCalculationHistory: [CalculationHistoryItem] = [calculationHistory[0]]
        
        if calculationHistory.contains(where: { $0 == .operation(.divide) || $0 == .operation(.multiply) }) {
            
            for index in stride(from: 1, to: calculationHistory.count - 1, by: 2) {
                
                guard case .operation(let operation) = calculationHistory[index],
                      case .number (let number) = calculationHistory[index + 1]
                else { break }
                
                if operation == .multiply || operation == .divide {
                    guard case .number(let lastNumber) = tempCalculationHistory.last else { return 0 }
                    currentResult = try operation.calculate(lastNumber, number)
                    tempCalculationHistory.removeLast()
                    tempCalculationHistory.append(.number(currentResult))
                    
                } else {
                    tempCalculationHistory.append(calculationHistory[index])
                    tempCalculationHistory.append(calculationHistory[index + 1])
                    continue
                }
            }
        } else {
            tempCalculationHistory = calculationHistory
        }
        
        if tempCalculationHistory.count > 1 {
            guard case .number(let firstNumber) = tempCalculationHistory[0] else { return 0 }
            currentResult = firstNumber
            
            for index in stride(from: 1, to: tempCalculationHistory.count - 1, by: 2) {
                guard case .operation(let operation) = tempCalculationHistory[index],
                      case .number (let number) = tempCalculationHistory[index + 1]
                else { break }
                
                currentResult = try operation.calculate(currentResult, number)
            }
        }
        return currentResult
    }
}
