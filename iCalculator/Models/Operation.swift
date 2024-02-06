enum CalculationError: Error {
    case devidedByZero
    case valueTooLarge
    case valueTooSmall
}

enum Operation: Int {
    case divide = 1
    case multiply
    case substract
    case add
    case percent
    
    var sign: String {
        switch self {
        case .divide: return "/"
        case.multiply: return "x"
        case .substract: return "-"
        case .add: return "+"
        case .percent: return "%"
        }
    }
    
    func calculate(_ number1: Double, _ number2: Double) throws -> Double {
        switch self {
        case .add:
            let result = number1 + number2
            if abs(result) > Constants.maxNumber {
                throw CalculationError.valueTooLarge
            }
            return result
        case .substract:
            let result = number1 - number2
            if result == 0 {
                return 0
            }
            if abs(result) < Constants.minNumber {
                throw CalculationError.valueTooSmall
            }
            return result
        case .multiply:
            let result = number1 * number2
            if abs(result) > Constants.maxNumber {
                throw CalculationError.valueTooLarge
            }
            return result
        case .divide:
            if number2 == 0 {
                throw CalculationError.devidedByZero
            }
            if number1 == 0 {
                return 0
            }
            let result = number1 / number2
            if abs(result) < Constants.minNumber {
                throw CalculationError.valueTooSmall
            }
            return result
        default: return 0
        }
    }
    
    func calculatePercent(number1: Double, operation: Operation, number2: Double) -> Double {
        
        switch operation {
        case .multiply: return number1 * number2 / 100
        case .divide: return number1 / number2 * 100
        case .add: return number1 + number1 * number2 / 100
        case .substract: return number1 - number1 * number2 / 100
        default: return 0
        }
        
    }
}


