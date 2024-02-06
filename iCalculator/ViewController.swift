import UIKit
import AVFoundation

final class ViewController: UIViewController {
    
    var calculator: Calculator = CalculatorImpl()
    let calculationHistoryStorage = CalculationHistoryStorage()
    var isCalculated = false
    
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
        
        tableView.delegate = self
        tableView.dataSource = self
        
        let nib = UINib(nibName: "HistoryTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "HistoryTableViewCell")
    }
// MARK: - buttonPressed
    
    @IBAction private func buttonPressed(_ sender: UIButton) {
        guard let buttonText = sender.currentTitle else { return }
        
        guard let text = label.text, text.last! != "%" else {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        if buttonText == "." && label.text?.components(separatedBy: ["+", "-", "x", "/"]).last?.contains(".") == true {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        
        if let text = label.text, text.contains("Error") {
            label.text = "0"
        }
        
        if let text = label.text, text == "0-" {
            label.text?.removeFirst()
        }
        
        if let text = label.text, let _ = Double(text), isCalculated {
            label.text = "0"
            isCalculated.toggle()
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
    
    @IBAction private func clearButtonPressed() {
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        calculator.calculationHistory.removeAll()
        resetLabelText()
    }
    
    
    @IBAction private func deleteButtonPressed(_ sender: UIButton) {
        guard let text = label.text, text != "0" else { return }
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        label.text?.removeLast()
        
        if let text = label.text, text.isEmpty {
            label.text = "0"
        }
    }
    
// MARK: - calculateButtonPressed
    
    @IBAction private func calculateButtonPressed() {
        guard let labelText = label.text?
                                   .components(separatedBy: ["+", "-", "x", "/"])
                                   .last?
                                   .replacingOccurrences(of: "%", with: " ")
                                   .trimmingCharacters(in: .whitespaces),
              let labelNumber = Double(labelText) else {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        if let text = label.text, let _ = Double(text) {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)

        if label.text?.last! != "%" {
            calculator.calculationHistory.append(.number(labelNumber))
        }
        
        do {
            let result = try calculator.calculate()
            
            let newCalculation = Calculation(expression: calculator.calculationHistory, 
                                             result: result)
            calculationHistoryStorage.calculations.append(newCalculation)
            calculationHistoryStorage.setHistory()
            isCalculated = true
            
            label.text = formatNumber(number: result)

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
        
        calculator.calculationHistory.removeAll()
        updateTableView()
    }
    
// MARK: - OperationButtonPressed
    @IBAction private func operationButtonPressed(_ sender: UIButton) {
        var sign: Double = 1
        
        if calculator.calculationHistory.isEmpty {
            sign = label.text?.first == "-" ? -1 : 1
        }
        
        guard let buttonOperation = Operation(rawValue: sender.tag)
        else { return }
        

        guard let text = label.text else { return }
        
        guard text.last! != "%" else {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        guard let labelText = text
            .components(separatedBy: ["+", "-", "x", "/"])
            .last?
            .trimmingCharacters(in: .whitespaces),
              var labelNumber = Double(labelText)
        else {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        
        labelNumber *= sign
        
        if label.text?.last == "." {
            label.text?.append("0")
        }
        
        if let text = label.text, text.count > 2, text.suffix(2) == ".0" {
            label.text?.removeLast(2)
        }
        
//        if let number = Double(labelText), number == 0 {
//            if labelText.count == 2 {
//                print(labelText)
//                print(label.text!)
//               // label.text?.removeLast(2)
//            } else {
//                //label.text?.removeLast(labelText.count - 1)
//            }
//        }
        calculator.calculationHistory.append(.number(labelNumber))
        calculator.calculationHistory.append(.operation(buttonOperation))

        label.text?.append(buttonOperation.sign)
    }
    
    @IBAction private func buttonMSPressed(_ sender: UIButton) {
        guard let text = label.text, let number = Double(text) else { return }
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        calculator.memory = number
        memoryLabel.text = text
    }
    
    @IBAction private func buttonMRPressed(_ sender: UIButton) {
        guard let text = label.text else { return }
        
        if text == "0" {
            label.text?.removeFirst()
        }
        
        if !"+-x/".contains(text.last!) {
            AudioServicesPlaySystemSound(Constants.errorSystemSoundId)
            return
        }
        
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        
        if calculator.memory < 0 {
            switch text.last! {
            case "+":
                label.text?.removeLast()
                calculator.calculationHistory.removeLast()
                label.text?.append("-")
                calculator.calculationHistory.append(.operation(.substract))
                label.text?.append(formatNumber(number: abs(calculator.memory)))
                return
            case "-":
                label.text?.removeLast()
                calculator.calculationHistory.removeLast()
                label.text?.append("+")
                calculator.calculationHistory.append(.operation(.add))
                label.text?.append(formatNumber(number: abs(calculator.memory)))
                return
            case "x", "/":
                if let lastIndexOfAdd = calculator.calculationHistory.lastIndex(of: .operation(.add)),
                   let lastIndexOfSubstract = calculator.calculationHistory.lastIndex(of: .operation(.substract)) {
                    if lastIndexOfAdd > lastIndexOfSubstract {
                        calculator.calculationHistory[lastIndexOfAdd] = CalculationHistoryItem.operation(.substract)
                        label.text?.replaceLastSymbol(of: "+", with: "-")
                    } else {
                        calculator.calculationHistory[lastIndexOfSubstract] = CalculationHistoryItem.operation(.add)
                        label.text?.replaceLastSymbol(of: "-", with: "+")
                    }
                } else if let lastIndexOfAdd = calculator.calculationHistory.lastIndex(of: .operation(.add)) {
                    calculator.calculationHistory[lastIndexOfAdd] = CalculationHistoryItem.operation(.substract)
                    label.text?.replaceLastSymbol(of: "+", with: "-")
                } else if let lastIndexOfSubstract = calculator.calculationHistory.lastIndex(of: .operation(.substract)) {
                    calculator.calculationHistory[lastIndexOfSubstract] = CalculationHistoryItem.operation(.add)
                    label.text?.replaceLastSymbol(of: "-", with: "+")
                } else if let number = Double(text.dropLast()), number > 0 {
                    calculator.calculationHistory = [CalculationHistoryItem.number(0)] + [CalculationHistoryItem.operation(.substract)] + calculator.calculationHistory
                    label.text = "-" + text
                }
                label.text?.append(formatNumber(number: abs(calculator.memory)))
                return
            default: break
            }
        }
        label.text?.append(formatNumber(number: calculator.memory))
    }
    
    @IBAction private func buttonMCPressed(_ sender: UIButton) {
        AudioServicesPlaySystemSound(Constants.tapSystemSoundId)
        calculator.memory = 0
        memoryLabel.text = "0"
    }
    
    private func resetLabelText() {
        label.text = "0"
    }
    
    // Перенести в класс Сalculation, но для этого нужно создать класс Formatter, который форматирует число в строку
    private func expressionToString(_ expression: [CalculationHistoryItem]) -> String {
        var result = ""
        
        for operand in expression {
            switch operand {
            case let .number(value):
                result += formatNumber(number: value) + " "
            case let .operation(value):
                result += value.sign + " "
            }
        }
        
        if result.count > 2 {
            let firstThreeSymbols = result.prefix(3)
            if  firstThreeSymbols == "0 +" {
                result.removeFirst(3)
            } else if firstThreeSymbols == "0 -" {
                result.removeFirst(2)
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
    // Перенести в отдельный класс
    func formatNumber(number: Double) -> String {
        var str = ""
        
        if abs(number) < Constants.minimumNumberForFormatter && number != 0 {
            str = String(format: "%.10f", number)
            while true {
                if str.last! == "0" {
                    str.removeLast()
                } else {
                    break
                }
            }
        } else {
            str = numberFormatter.string(from: NSNumber(value: number)) ?? "0"
        }
        
        if str.count > 2, let lastSymbol = str.last, lastSymbol == "0" {
            str.removeLast()
            if let penultimateSymbol = str.last, penultimateSymbol == "." {
                str.removeLast()
            } else {
                str.append("0")
            }
        }

        return str
    }
}

///////

extension ViewController: UITableViewDelegate {}

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        calculationHistoryStorage.calculations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "HistoryTableViewCell", for: indexPath) as! HistoryTableViewCell
        let historyItem = calculationHistoryStorage.calculations[indexPath.row]
        cell.configure(with: expressionToString(historyItem.expression), result: formatNumber(number: historyItem.result))
        return cell
    }
    
}

