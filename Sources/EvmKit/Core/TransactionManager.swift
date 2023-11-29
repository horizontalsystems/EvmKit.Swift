import BigInt
import Combine
import Foundation

class TransactionManager {
    private let userAddress: Address
    private let storage: TransactionStorage
    private let decorationManager: DecorationManager
    private let blockchain: IBlockchain
    private let transactionProvider: ITransactionProvider

    private let fullTransactionsSubject = PassthroughSubject<([FullTransaction], Bool), Never>()
    private let fullTransactionsWithTagsSubject = PassthroughSubject<[(transaction: FullTransaction, tags: [TransactionTag])], Never>()

    init(userAddress: Address, storage: TransactionStorage, decorationManager: DecorationManager, blockchain: IBlockchain, transactionProvider: ITransactionProvider) {
        self.userAddress = userAddress
        self.storage = storage
        self.decorationManager = decorationManager
        self.blockchain = blockchain
        self.transactionProvider = transactionProvider
    }

    private func save(transactions: [Transaction]) {
        let existingTransactions = storage.transactions(hashes: transactions.map(\.hash))
        let existingTransactionMap = Dictionary(existingTransactions.map { ($0.hash, $0) }, uniquingKeysWith: { first, _ in first })

        let mergedTransactions = transactions.map { transaction in
            if let existingTransaction = existingTransactionMap[transaction.hash] {
                return TransactionSyncManager.merge(lhsTransaction: transaction, rhsTransaction: existingTransaction)
            } else {
                return transaction
            }
        }

        storage.save(transactions: mergedTransactions)
    }

    private func failPendingTransactions() -> [Transaction] {
        let pendingTransactions = storage.pendingTransactions()

        guard !pendingTransactions.isEmpty else {
            return []
        }

        let nonces = Array(Set(pendingTransactions.compactMap(\.nonce)))

        let nonPendingTransactions = storage.nonPendingTransactions(from: userAddress, nonces: nonces)
        var processedTransactions = [Transaction]()

        for nonPendingTransaction in nonPendingTransactions {
            let duplicateTransactions = pendingTransactions.filter { $0.nonce == nonPendingTransaction.nonce }
            for transaction in duplicateTransactions {
                transaction.isFailed = true
                transaction.replacedWith = nonPendingTransaction.hash
                processedTransactions.append(transaction)
            }
        }

        save(transactions: processedTransactions)

        return processedTransactions
    }
}

extension TransactionManager {
    var fullTransactionsPublisher: AnyPublisher<([FullTransaction], Bool), Never> {
        fullTransactionsSubject.eraseToAnyPublisher()
    }

    func etherTransferTransactionData(to: Address, value: BigUInt) -> TransactionData {
        TransactionData(
            to: to,
            value: value,
            input: Data()
        )
    }

    func fetchFullTransaction(hash: Data) async throws -> FullTransaction {
        let rpcTransaction = try await blockchain.transaction(transactionHash: hash)

        let fullRpcTransaction: FullRpcTransaction

        if let blockNumber = rpcTransaction.blockNumber {
            async let rpcTransactionReceipt = try blockchain.transactionReceipt(transactionHash: hash)
            async let rpcBlock = try blockchain.getBlock(blockNumber: blockNumber)
            async let providerInternalTransactions = try transactionProvider.internalTransactions(transactionHash: hash)

            fullRpcTransaction = try await FullRpcTransaction(
                rpcTransaction: rpcTransaction,
                rpcTransactionReceipt: rpcTransactionReceipt,
                rpcBlock: rpcBlock,
                providerInternalTransactions: providerInternalTransactions
            )
        } else {
            fullRpcTransaction = FullRpcTransaction(rpcTransaction: rpcTransaction)
        }

        return try decorationManager.decorate(fullRpcTransaction: fullRpcTransaction)
    }

    func fullTransactionsPublisher(tagQueries: [TransactionTagQuery]) -> AnyPublisher<[FullTransaction], Never> {
        fullTransactionsWithTagsSubject
            .map { transactionsWithTags in
                transactionsWithTags.compactMap { (transaction: FullTransaction, tags: [TransactionTag]) -> FullTransaction? in
                    for tagQuery in tagQueries {
                        for tag in tags {
                            if tag.conforms(tagQuery: tagQuery) {
                                return transaction
                            }
                        }
                    }

                    return nil
                }
            }
            .filter { transactions in
                transactions.count > 0
            }
            .eraseToAnyPublisher()
    }

    func fullTransactions(tagQueries: [TransactionTagQuery], fromHash: Data?, limit: Int?) -> [FullTransaction] {
        let transactions = storage.transactionsBefore(tagQueries: tagQueries, hash: fromHash, limit: limit)
        return decorationManager.decorate(transactions: transactions)
    }

    func pendingFullTransactions(tagQueries: [TransactionTagQuery]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.pendingTransactions(tagQueries: tagQueries))
    }

    func fullTransactions(byHashes hashes: [Data]) -> [FullTransaction] {
        decorationManager.decorate(transactions: storage.transactions(hashes: hashes))
    }

    func fullTransaction(hash: Data) -> FullTransaction? {
        storage.transaction(hash: hash).flatMap { decorationManager.decorate(transactions: [$0]).first }
    }

    @discardableResult func handle(transactions: [Transaction], initial: Bool = false) -> [FullTransaction] {
        guard !transactions.isEmpty else {
            return []
        }

        save(transactions: transactions)

        let failedTransactions = failPendingTransactions()
        let transactions = transactions + failedTransactions

        let fullTransactions = decorationManager.decorate(transactions: transactions)

        var fullTransactionsWithTags = [(transaction: FullTransaction, tags: [TransactionTag])]()
        var tagRecords = [TransactionTagRecord]()

        for fullTransaction in fullTransactions {
            let tags = fullTransaction.decoration.tags()
            tagRecords.append(contentsOf: tags.map { TransactionTagRecord(transactionHash: fullTransaction.transaction.hash, tag: $0) })
            fullTransactionsWithTags.append((transaction: fullTransaction, tags: tags))
        }

        storage.save(tags: tagRecords)

        fullTransactionsSubject.send((fullTransactions, initial))
        fullTransactionsWithTagsSubject.send(fullTransactionsWithTags)

        return fullTransactions
    }

    func tagTokens() -> [TagToken] {
        do {
            return try storage.tagTokens()
        } catch {
            print("Failed to fetch tag tokens: \(error)")
            return []
        }
    }
}
