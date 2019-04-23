import Foundation
import UIKit

class TransactionCell: UITableViewCell {
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var valueLabel: UILabel?

    func bind(transaction: TransactionRecord, coin: String, lastBlockHeight: Int?) {
        var confirmations = "n/a"

        if let lastBlockHeight = lastBlockHeight, let blockHeight = transaction.blockHeight {
            confirmations = "\(lastBlockHeight - blockHeight + 1)"
        }

        set(string: """
                    Tx Hash:
                    Index:
                    Date:
                    Value:
                    \(transaction.from.mine ? "To" : "From")
                    Block:
                    Confirmations:
                    """, alignment: .left, label: titleLabel)

        set(string: """
                    \(format(hash: transaction.transactionHash))
                    \(transaction.index)
                    \(TransactionCell.dateFormatter.string(from: Date(timeIntervalSince1970: transaction.timestamp)))
                    \(transaction.amount) \(coin)
                    \(format(hash: transaction.from.mine ? transaction.to.address : transaction.from.address))
                    \(transaction.blockHeight.map { "# \($0)" } ?? "n/a")
                    \(confirmations)
                    """, alignment: .right, label: valueLabel)
    }

    private func set(string: String, alignment: NSTextAlignment, label: UILabel?) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        paragraphStyle.alignment = alignment

        let attributedString = NSMutableAttributedString(string: string)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attributedString.length))

        label?.attributedText = attributedString
    }

    private func format(hash: String) -> String {
        guard hash.count > 22 else {
            return hash
        }

        return "\(hash[..<hash.index(hash.startIndex, offsetBy: 10)])...\(hash[hash.index(hash.endIndex, offsetBy: -10)...])"
    }

}
