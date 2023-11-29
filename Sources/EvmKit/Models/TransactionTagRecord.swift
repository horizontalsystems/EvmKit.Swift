import Foundation
import GRDB

class TransactionTagRecord: Record {
    let transactionHash: Data
    let tag: TransactionTag

    init(transactionHash: Data, tag: TransactionTag) {
        self.transactionHash = transactionHash
        self.tag = tag

        super.init()
    }

    override class var databaseTableName: String {
        "transactionTag"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case transactionHash
        case type
        case `protocol`
        case contractAddress
    }

    required init(row: Row) throws {
        transactionHash = row[Columns.transactionHash]
        tag = TransactionTag(
            type: row[Columns.type],
            protocol: row[Columns.protocol],
            contractAddress: row[Columns.contractAddress]
        )

        try super.init(row: row)
    }

    override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.transactionHash] = transactionHash
        container[Columns.type] = tag.type
        container[Columns.protocol] = tag.protocol
        container[Columns.contractAddress] = tag.contractAddress
    }
}
