import GRDB

public class TransactionSyncerState: Record {
    public let syncerId: String
    public let lastBlockNumber: Int

    public init(syncerId: String, lastBlockNumber: Int) {
        self.syncerId = syncerId
        self.lastBlockNumber = lastBlockNumber

        super.init()
    }

    override public class var databaseTableName: String {
        "transactionSyncerStates"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case syncerId
        case lastBlockNumber
    }

    public required init(row: Row) throws {
        syncerId = row[Columns.syncerId]
        lastBlockNumber = row[Columns.lastBlockNumber]

        try super.init(row: row)
    }

    override public func encode(to container: inout PersistenceContainer) throws {
        container[Columns.syncerId] = syncerId
        container[Columns.lastBlockNumber] = lastBlockNumber
    }
}
