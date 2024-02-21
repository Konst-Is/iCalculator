import Foundation

protocol Calculator {
    func calculate() throws -> Double
    var calculationHistory: [CalculationHistoryItem] { get set }
    var memory: Double { get set }
}

final class CalculatorImpl: Calculator {
    
    var calculationHistory: [CalculationHistoryItem] = []
    
    var memory: Double = 0
    
    func calculate() throws -> Double {
        guard case .number(let firstNumber) = calculationHistory[0] else { return 0 }
        
        var hasPercent = false
        var percentParameter: Double = 0
        var percentOperation = Operation.percent
        var currentResult = firstNumber
        var calculationHistoryWithoutPercent = calculationHistory
        
        if case .operation(let operation) = calculationHistory.last, operation == .percent {
            calculationHistoryWithoutPercent.removeLast()
            hasPercent = true
            
            if case .number(let percentNumber) = calculationHistoryWithoutPercent.last {
                calculationHistoryWithoutPercent.removeLast()
                percentParameter = percentNumber
                
                if calculationHistoryWithoutPercent.isEmpty {
                    return operation.calculatePercent(number1: 1 ,operation: .multiply, number2: percentNumber)
                }
                
                if case .operation(let operation) = calculationHistoryWithoutPercent.last {
                    calculationHistoryWithoutPercent.removeLast()
                    percentOperation = operation
                    
                    if operation == .multiply || operation == .divide {
                        
                        if case .number(let number) = calculationHistoryWithoutPercent.last {
                            calculationHistoryWithoutPercent.removeLast()
                            let currentResult = operation.calculatePercent(number1: number, operation: percentOperation, number2: percentParameter)
                            
                            if calculationHistoryWithoutPercent.isEmpty {
                                return currentResult
                            } else {
                                calculationHistoryWithoutPercent.append(.number(currentResult))
                                hasPercent = false
                            }
                        }
                    }
                    
                    if operation == .substract, calculationHistoryWithoutPercent.count == 1 {
                        
                        if case .number(let number) = calculationHistoryWithoutPercent.last, number == 0 {
                            let result = operation.calculatePercent(number1: 1, operation: .multiply, number2: percentParameter)
                            return result * -1
                        }
                    }
                }
            }
        }
        
        var tempCalculationHistory: [CalculationHistoryItem] = [calculationHistory[0]]
        
        if calculationHistoryWithoutPercent.contains(where: { $0 == .operation(.divide) || $0 == .operation(.multiply) }) {
            
            for index in stride(from: 1, to: calculationHistoryWithoutPercent.count - 1, by: 2) {
                
                guard case .operation(let operation) = calculationHistoryWithoutPercent[index],
                      case .number (let number) = calculationHistoryWithoutPercent[index + 1]
                else { break }
                
                if operation == .multiply || operation == .divide {
                    guard case .number(let lastNumber) = tempCalculationHistory.last else { return 0 }
                    currentResult = try operation.calculate(lastNumber, number)
                    tempCalculationHistory.removeLast()
                    tempCalculationHistory.append(.number(currentResult))
                    
                } else {
                    tempCalculationHistory.append(calculationHistoryWithoutPercent[index])
                    tempCalculationHistory.append(calculationHistoryWithoutPercent[index + 1])
                    continue
                }
            }
        } else {
            tempCalculationHistory = calculationHistoryWithoutPercent
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
        
        if hasPercent {
            return percentOperation.calculatePercent(number1: currentResult, operation: percentOperation, number2: percentParameter)
        }
        
        return currentResult
    }
}
