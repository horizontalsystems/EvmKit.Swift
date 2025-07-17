import EvmKit
import Foundation

struct TransactionRecord {
    let transactionHash: String
    let transactionHashData: Data
    let timestamp: Int
    let isFailed: Bool

    let from: Address?
    let to: Address?
    let amount: Decimal?
    let input: String?

    let blockHeight: Int?
    let transactionIndex: Int?

    let decoration: String
}
