import UIKit

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

enum CalculationHistoryItem: Equatable {
    case number(Double)
    case operation(Operation)
}

class ViewController: UIViewController {

    var calculationHistory: [CalculationHistoryItem] = []
    var calculations: [Calculation] = []
    let calculationHistoryStorage = CalculationHistoryStorage()
    var isCalculated = false
    var memory: Double = 0 {
        didSet {
            memoryLabel.text = String(memory)
        }
    }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var memoryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    lazy var numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = false
        numberFormatter.locale = Locale(identifier: "en-US")
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.subviews.forEach {
            if type(of: $0) == UIButton.self {
                $0.layer.cornerRadius = 40
            }
        }
        
        memoryLabel.text = "0"
        resetLabelText()
        
        calculations = calculationHistoryStorage.loadHistory()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "HistoryTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "HistoryTableViewCell")
        
    }

    @IBAction func buttonPressed(_ sender: UIButton) {
        guard let buttonText = sender.currentTitle else { return }
        
        sender.animateTap()
        
        if let text = label.text, text.contains("Error") {
            label.text = "0"
        }
        
        if let text = label.text, let _ = Double(text), isCalculated {
            label.text = "0"
            isCalculated.toggle()
        }
        
        if buttonText == "." && label.text?.components(separatedBy: ["+", "-", "x", "/"]).last?.contains(".") == true {
            return
        }
        
        if buttonText == "." && label.text == "0" {
            label.text?.removeLast()
            label.text?.append("0.")
            return
        }
        
        if buttonText == "." && "+-x/".contains(label.text?.last ?? " ") {
            label.text?.append("0.")
            return
        }
        
        if label.text == "0" {
            label.text = buttonText
            return
        }
        
        if label.text == "0." && buttonText != "." {
            label.text?.append(buttonText)
            return
        }
        
        label.text?.append(buttonText)
    }
    
    @IBAction func clearButtonPressed() {
        calculationHistory.removeAll()
        resetLabelText()
    }
    
    @IBAction func calculateButtonPressed() {
        guard let labelText = label.text?
                                   .components(separatedBy: ["+", "-", "x", "/"])
                                   .last,
              let labelNumber = Double(labelText) else {
            return
        }
        
        calculationHistory.append(.number(labelNumber))
        
        do {
            let result = try calculate()
            
            let newCalculation = Calculation(expression: calculationHistory, result: result)
            calculations.append(newCalculation)
            limitCalculationHistory()
            calculationHistoryStorage.setHistory(calculation: calculations)
            isCalculated = true
            
            if abs(result) > 1e6 || (abs(result) < 0.001 && result != 0) {
                label.text = String(format: "%16e", result)
            } else {
                label.text = numberFormatter.string(from: NSNumber(value: result))
            }
        } catch CalculationError.devidedByZero {
            label.text = "Error: division by 0"
            label.shake()
        } catch CalculationError.valueTooLarge {
            label.text = "Error: value too large"
            label.shake()
        } catch CalculationError.valueTooSmall {
            label.text = "Error: value too small"
            label.shake()
        } catch let error {
            label.text = "Error: \(error.localizedDescription)"
            label.shake()
        }
        
        calculationHistory.removeAll()
        updateTableView()
    }
    
    @IBAction func operationButtonPressed(_ sender: UIButton) {
        var sign: Double = 1
        
        if calculationHistory.isEmpty {
            sign = label.text?.first == "-" ? -1 : 1
        }
        
        guard let buttonOperation = Operation(rawValue: sender.tag)
        else { return }

        guard let labelText = label.text?
            .replacingOccurrences(of: "e-", with: "h")
            .replacingOccurrences(of: "e+", with: "g")
            .components(separatedBy: ["+", "-", "x", "/"])
            .last?
            .replacingOccurrences(of: "h", with: "e-")
            .replacingOccurrences(of: "g", with: "e+")
            .trimmingCharacters(in: .whitespaces),
              var labelNumber = Double(labelText)
        else {
            return
        }
        labelNumber *= sign
        
        if label.text?.last == "." {
            label.text?.append("0")
        }
        
        if let number = Double(labelText), number == 0 {
            if labelText.count == 2 {
                label.text?.removeLast(2)
            } else {
                label.text?.removeLast(labelText.count - 1)
            }
        }
        calculationHistory.append(.number(labelNumber))
        calculationHistory.append(.operation(buttonOperation))

        label.text?.append(buttonOperation.sign)
    }
    
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
    func resetLabelText() {
        label.text = "0"
    }
    
    private func expressionToString(_ expression: [CalculationHistoryItem]) -> String {
        var result = ""
        
        for operand in expression {
            switch operand {
            case let .number(value):
                result += String(value) + " "
            case let .operation(value):
                result += value.sign + " "
            }
        }
        
        return result + " = "
    }
    
    private func updateTableView() {
        tableView.reloadData()
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        let lastIndexPath = IndexPath(row: lastRowIndex, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
    
    private func limitCalculationHistory() {
        if calculations.count > 10 { // Поставь нужное значение
            calculations.removeFirst(calculations.count - 5)
        }
    }
}

extension UILabel {
    
    func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.05
        animation.repeatCount = 5
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: center.x - 5, y: center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: center.x + 5, y: center.y))
        layer.add(animation, forKey: "position")
    }
}

extension UIButton {
    
    func animateTap() {
        let scaleAnimation = CAKeyframeAnimation(keyPath: "transform.scale")
        scaleAnimation.values = [1, 0.9, 1]
        scaleAnimation.keyTimes = [0, 0.2, 1]
        
        let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
        opacityAnimation.values = [0.4, 0.8, 1]
        opacityAnimation.keyTimes = [0, 0.2, 1]
        
        let animationGroup = CAAnimationGroup()
        animationGroup.duration = 1.5
        animationGroup.animations = [scaleAnimation, opacityAnimation]
        layer.add(animationGroup, forKey: "groupAnimation")
    }
}


///////

extension ViewController: UITableViewDelegate {}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        calculations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        let historyItem = calculations[indexPath.row]
        cell.configure(with: expressionToString(historyItem.expression), result: String(historyItem.result)) 
        return cell
    }
    
}

