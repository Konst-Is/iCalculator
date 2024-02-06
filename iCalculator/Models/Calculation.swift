import Foundation

struct Calculation {
    let expression: [CalculationHistoryItem]
    let result: Double
    
    // Желательно перенести этот метод сюда, но тогда нужно создать класс форматтер
    
//    func expressionToString() -> String {
//        var result = ""
//        
//        for operand in expression {
//            switch operand {
//            case let .number(value):
//                result += formatNumber(number: value) + " "
//            case let .operation(value):
//                result += value.sign + " "
//            }
//        }
//        return result + " = "
//    }
}

extension Calculation: Codable {}

