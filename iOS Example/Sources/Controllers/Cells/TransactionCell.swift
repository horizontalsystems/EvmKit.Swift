import Foundation
import UIKit
import SnapKit
import EvmKit
import BigInt

class TransactionCell: UITableViewCell {

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("yyyy MMM d, HH:mm:ss")
        return formatter
    }()

    private let titlesLabel = UILabel()
    private let valuesLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = .clear

        contentView.addSubview(titlesLabel)
        titlesLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(24)
        }

        titlesLabel.numberOfLines = 0
        titlesLabel.font = .systemFont(ofSize: 12)
        titlesLabel.textColor = .gray

        contentView.addSubview(valuesLabel)
        valuesLabel.snp.makeConstraints { make in
            make.top.equalTo(titlesLabel)
            make.trailing.equalToSuperview().inset(16)
        }

        valuesLabel.numberOfLines = 0
        valuesLabel.font = .systemFont(ofSize: 12)
        valuesLabel.textColor = .black
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bind(transaction: TransactionRecord, coin: String, lastBlockHeight: Int?) {
        var confirmations = "n/a"

        if let lastBlockHeight = lastBlockHeight, let blockHeight = transaction.blockHeight {
            confirmations = "\(lastBlockHeight - blockHeight + 1)"
        }

        titlesLabel.set(string: """
                    Tx Hash:
                    Date:
                    Failed:
                    From:
                    To:
                    Value:
                    Input:
                    Block:
                    Tx Index:
                    Confirmations:
                    Decoration:
                    """, alignment: .left)

        valuesLabel.set(string: """
                    \(format(hash: transaction.transactionHash))
                    \(TransactionCell.dateFormatter.string(from: Date(timeIntervalSince1970: Double(transaction.timestamp))))
                    \(transaction.isFailed)
                    \(transaction.from.map { format(hash: $0.eip55) } ?? "n/a")
                    \(transaction.to.map { format(hash: $0.eip55) } ?? "n/a")
                    \(transaction.amount.map { "\($0) ETH" } ?? "n/a")
                    \(transaction.input.map { format(hash: $0) } ?? "n/a")
                    \(transaction.blockHeight.map { "# \($0)" } ?? "n/a")
                    \(transaction.transactionIndex.map { "\($0)" } ?? "n/a")
                    \(confirmations)
                    \(transaction.decoration.components(separatedBy: ".").last ?? transaction.decoration)
                    """, alignment: .right)
    }

    private func format(hash: String) -> String {
        guard hash.count > 22 else {
            return hash
        }

        return "\(hash[..<hash.index(hash.startIndex, offsetBy: 10)])...\(hash[hash.index(hash.endIndex, offsetBy: -10)...])"
    }

}
