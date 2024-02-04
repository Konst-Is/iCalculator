import UIKit

class HistoryTableViewCell: UITableViewCell {

        
    @IBOutlet private weak var expressionLabel: UILabel!
    
    func configure(with expression: String, result: String) {
        expressionLabel.text = expression + result
    }
        
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
}
