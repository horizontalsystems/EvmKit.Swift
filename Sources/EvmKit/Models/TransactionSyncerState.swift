import GRDB

class TransactionSyncerState: Record {
    let syncerId: String
    let lastBlockNumber: Int

    init(syncerId: String, lastBlockNumber: Int) {
        self.syncerId = syncerId
        self.lastBlockNumber = lastBlockNumber

        super.init()
    }

    public override class var databaseTableName: String {
        "transactionSyncerStates"
    }

    enum Columns: String, ColumnExpression, CaseIterable {
        case syncerId
        case lastBlockNumber
    }

    required init(row: Row) throws {
        syncerId = row[Columns.syncerId]
        lastBlockNumber = row[Columns.lastBlockNumber]

        try super.init(row: row)
    }

    public override func encode(to container: inout PersistenceContainer) throws {
        container[Columns.syncerId] = syncerId
        container[Columns.lastBlockNumber] = lastBlockNumber
    }

}
