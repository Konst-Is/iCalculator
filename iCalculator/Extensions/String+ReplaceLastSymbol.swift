import Foundation

extension String {
    
    mutating func replaceLastSymbol(of symbol: String, with newSymbol: String) {
        var result = ""
        var isChanged = false
        for char in self.reversed() {
            if String(char) == symbol, !isChanged {
                result = newSymbol + result
                isChanged = true
            } else {
                result = String(char) + result
            }
        }
        self = result
    }
}
