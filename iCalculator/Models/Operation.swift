

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
            if result.isInfinite {
                throw CalculationError.valueTooLarge
            }
            return result
        case .substract:
            let result = number1 - number2
            if result == 0 {
                return 0
            }
            if result.isZero {
                throw CalculationError.valueTooSmall
            }
            return result
        case .multiply:
            let result = number1 * number2
            if result.isInfinite {
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
            if result.isZero {
                throw CalculationError.valueTooSmall
            }
            return result
        case .percent: return 0 // Дописать!
        }
    }
}


