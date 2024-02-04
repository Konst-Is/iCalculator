import UIKit

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

    @IBAction private func buttonPressed(_ sender: UIButton) {
        guard let buttonText = sender.currentTitle else { return }
        
        sender.animateTap()
        
        if let text = label.text, text.contains("Error") {
            label.text = "0"
        }
        
        if let text = label.text, text == "0-" {
            label.text?.removeFirst()
            print(7)
        }
        
        if let text = label.text, let _ = Double(text), isCalculated {
            label.text = "0"
            isCalculated.toggle()
            print(1)
        }
        
        if buttonText == "." && label.text?.components(separatedBy: ["+", "-", "x", "/"]).last?.contains(".") == true {
            print(2)
            return
        }
        
        if buttonText == "." && label.text == "0" {
            label.text?.removeLast()
            label.text?.append("0.")
            print(3)
            return
        }
                
        if buttonText == "." && "+-x/".contains(label.text?.last ?? " ") {
            label.text?.append("0.")
            print(4)
            return
        }
        
        if label.text == "0" {
            label.text = buttonText
            print(5)
            return
        }
        
        if label.text == "0." && buttonText != "." {
            label.text?.append(buttonText)
            print(6)
            return
        }
        
        label.text?.append(buttonText)
    }
    
    @IBAction private func clearButtonPressed() {
        calculator.calculationHistory.removeAll()
        resetLabelText()
    }
    
    
    @IBAction private func deleteButtonPressed(_ sender: UIButton) {
        guard let text = label.text, text != "0" else { return }
        label.text?.removeLast()
        
        if let text = label.text, text.isEmpty {
            label.text = "0"
        }
    }
    
    @IBAction private func calculateButtonPressed() {
        guard let labelText = label.text?
                                   .components(separatedBy: ["+", "-", "x", "/"])
                                   .last,
              let labelNumber = Double(labelText) else {
            return
        }
        
        if let text = label.text, let _ = Double(text) {
            return
        }
        
        calculator.calculationHistory.append(.number(labelNumber))
        
        do {
            let result = try calculator.calculate()
            
            let newCalculation = Calculation(expression: calculator.calculationHistory, result: result)
            calculationHistoryStorage.calculations.append(newCalculation)
            calculationHistoryStorage.setHistory()
            isCalculated = true
            
            label.text = formatNumber(number: result)
            
//            if abs(result) > 1e6 || (abs(result) < 0.001 && result != 0) {
//                label.text = String(format: "%16e", result)
//            } else {
//                label.text = numberFormatter.string(from: NSNumber(value: result))
//            }
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
    
    @IBAction private func operationButtonPressed(_ sender: UIButton) {
        var sign: Double = 1
        
        if calculator.calculationHistory.isEmpty {
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
        calculator.calculationHistory.append(.number(labelNumber))
        calculator.calculationHistory.append(.operation(buttonOperation))

        label.text?.append(buttonOperation.sign)
    }
    
    
    @IBAction private func buttonMSPressed(_ sender: UIButton) {
        guard let text = label.text, let number = Double(text) else { return }
        calculator.memory = number
        memoryLabel.text = text
    }
    
    
    @IBAction private func buttonMRPressed(_ sender: UIButton) {
        label.text?.append(String(calculator.memory))
        
    }
    
    
    @IBAction private func buttonMCPressed(_ sender: UIButton) {
        calculator.memory = 0
        memoryLabel.text = "0"
    }
    
    
    private func resetLabelText() {
        label.text = "0"
    }
    
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
        return result + " = "
    }
    
    private func updateTableView() {
        tableView.reloadData()
        let lastRowIndex = tableView.numberOfRows(inSection: 0) - 1
        let lastIndexPath = IndexPath(row: lastRowIndex, section: 0)
        tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
    
    func formatNumber(number: Double) -> String {
        var str = ""
        if abs(number) > 1e6 || (abs(number) < 0.001 && number != 0) {
            str = String(format: "%16e", number)
        } else {
            str = numberFormatter.string(from: NSNumber(value: number)) ?? "0"
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

