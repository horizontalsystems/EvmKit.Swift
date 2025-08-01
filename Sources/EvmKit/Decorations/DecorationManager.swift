import BigInt
import Foundation

class DecorationManager {
    private let userAddress: Address
    private let storage: TransactionStorage
    private var methodDecorators = [IMethodDecorator]()
    private var eventDecorators = [IEventDecorator]()
    private var transactionDecorators = [ITransactionDecorator]()
    private var extraDecorators = [IExtraDecorator]()

    init(userAddress: Address, storage: TransactionStorage) {
        self.userAddress = userAddress
        self.storage = storage
    }

    private func internalTransactionsMap(transactions: [Transaction]) -> [Data: [InternalTransaction]] {
        let internalTransactions: [InternalTransaction]

        if transactions.count > 100 {
            internalTransactions = storage.internalTransactions()
        } else {
            let hashes = transactions.map(\.hash)
            internalTransactions = storage.internalTransactions(hashes: hashes)
        }

        var map = [Data: [InternalTransaction]]()

        for internalTransaction in internalTransactions {
            map[internalTransaction.hash] = (map[internalTransaction.hash] ?? []) + [internalTransaction]
        }

        return map
    }

    private func contractMethod(input: Data?) -> ContractMethod? {
        guard let input else {
            return nil
        }

        guard !input.isEmpty else {
            return EmptyMethod()
        }

        for decorator in methodDecorators {
            if let contractMethod = decorator.contractMethod(input: input) {
                return contractMethod
            }
        }

        return nil
    }

    private func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction] = [], eventInstances: [ContractEventInstance] = []) -> TransactionDecoration {
        for decorator in transactionDecorators {
            if let decoration = decorator.decoration(from: from, to: to, value: value, contractMethod: contractMethod, internalTransactions: internalTransactions, eventInstances: eventInstances) {
                return decoration
            }
        }

        return UnknownTransactionDecoration(
            userAddress: userAddress,
            fromAddress: from,
            toAddress: to,
            value: value,
            internalTransactions: internalTransactions,
            eventInstances: eventInstances
        )
    }
    
    private func extra(hash: Data) -> [String: Any] {
        var extra: [String: Any] = [:]
        for extraDecorator in extraDecorators {
            let extraFields = extraDecorator.extra(hash: hash)
            extra = extra.merging(extraFields) { $1 }
        }

        return extra
    }

    private func eventInstances(logs: [TransactionLog]) -> [ContractEventInstance] {
        var eventInstances = [ContractEventInstance]()

        for decorator in eventDecorators {
            eventInstances.append(contentsOf: decorator.contractEventInstances(logs: logs))
        }

        return eventInstances
    }
}

extension DecorationManager {
    func add(methodDecorator: IMethodDecorator) {
        methodDecorators.append(methodDecorator)
    }

    func add(eventDecorator: IEventDecorator) {
        eventDecorators.append(eventDecorator)
    }

    func add(transactionDecorator: ITransactionDecorator) {
        transactionDecorators.append(transactionDecorator)
    }

    func add(extraDecorator: IExtraDecorator) {
        extraDecorators.append(extraDecorator)
    }

    func decorateTransaction(from: Address, transactionData: TransactionData) -> TransactionDecoration? {
        guard let contractMethod = contractMethod(input: transactionData.input) else {
            return nil
        }

        for decorator in transactionDecorators {
            if let decoration = decorator.decoration(from: from, to: transactionData.to, value: transactionData.value, contractMethod: contractMethod, internalTransactions: [], eventInstances: []) {
                return decoration
            }
        }

        return nil
    }

    func decorate(transactions: [Transaction]) -> [FullTransaction] {
        let internalTransactionsMap = internalTransactionsMap(transactions: transactions)
        var eventInstancesMap = [Data: [ContractEventInstance]]()

        for decorator in eventDecorators {
            for (hash, eventInstances) in decorator.contractEventInstancesMap(transactions: transactions) {
                eventInstancesMap[hash] = (eventInstancesMap[hash] ?? []) + eventInstances
            }
        }

        return transactions.map { transaction in
            let decoration = decoration(
                from: transaction.from,
                to: transaction.to,
                value: transaction.value,
                contractMethod: contractMethod(input: transaction.input),
                internalTransactions: internalTransactionsMap[transaction.hash] ?? [],
                eventInstances: eventInstancesMap[transaction.hash] ?? []
            )
            
            let extra = extra(hash: transaction.hash)

            return FullTransaction(transaction: transaction, decoration: decoration, extra: extra)
        }
    }

    func decorate(fullRpcTransaction: FullRpcTransaction) throws -> FullTransaction {
        let timestamp: Int

        if let rpcBlock = fullRpcTransaction.rpcBlock {
            timestamp = rpcBlock.timestamp
        } else if let transaction = storage.transaction(hash: fullRpcTransaction.rpcTransaction.hash) {
            timestamp = transaction.timestamp
        } else {
            throw RpcTransactionError.noTimestamp
        }

        let transaction = fullRpcTransaction.transaction(timestamp: timestamp)

        let internalTransactions = fullRpcTransaction.providerInternalTransactions.map(\.internalTransaction)
        let events = fullRpcTransaction.rpcTransactionReceipt.map { eventInstances(logs: $0.logs) } ?? []
        let decoration = decoration(
            from: transaction.from,
            to: transaction.to,
            value: transaction.value,
            contractMethod: contractMethod(input: transaction.input),
            internalTransactions: internalTransactions,
            eventInstances: events
        )

        let extra = extra(hash: transaction.hash)

        return FullTransaction(transaction: transaction, decoration: decoration, extra: extra)
    }
}

extension DecorationManager {
    public enum RpcTransactionError: Error {
        case noTimestamp
    }
}
