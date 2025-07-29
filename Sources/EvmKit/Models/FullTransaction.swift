import Foundation

public class FullTransaction {
    public let transaction: Transaction
    public let decoration: TransactionDecoration
    public let extra: [String: Any]

    init(transaction: Transaction, decoration: TransactionDecoration, extra: [String: Any] = [:]) {
        self.transaction = transaction
        self.decoration = decoration
        self.extra = extra
    }
}
