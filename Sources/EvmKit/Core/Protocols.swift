import BigInt
import Foundation

protocol IBlockchain {
    var delegate: IBlockchainDelegate? { get set }

    var source: String { get }
    func start()
    func stop()
    func refresh()
    func syncAccountState()

    var syncState: SyncState { get }
    var lastBlockHeight: Int? { get }
    var accountState: AccountState? { get }

    func nonce(defaultBlockParameter: DefaultBlockParameter) async throws -> Int
    func send(rawTransaction: RawTransaction, signature: Signature) async throws -> Transaction

    func transactionReceipt(transactionHash: Data) async throws -> RpcTransactionReceipt
    func transaction(transactionHash: Data) async throws -> RpcTransaction
    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) async throws -> Data
    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) async throws -> Data
    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) async throws -> Int
    func getBlock(blockNumber: Int) async throws -> RpcBlock
    func fetch<T>(rpcRequest: JsonRpc<T>) async throws -> T
}

protocol IBlockchainDelegate: AnyObject {
    func onUpdate(lastBlockHeight: Int)
    func onUpdate(syncState: SyncState)
    func onUpdate(accountState: AccountState)
}

public protocol ITransactionSyncer {
    func transactions() async throws -> ([Transaction], Bool)
}

protocol ITransactionManagerDelegate: AnyObject {
    func onUpdate(transactionsSyncState: SyncState)
    func onUpdate(transactionsWithInternal: [FullTransaction])
}

public protocol IMethodDecorator {
    func contractMethod(input: Data) -> ContractMethod?
}

public protocol IEventDecorator {
    func contractEventInstancesMap(transactions: [Transaction]) -> [Data: [ContractEventInstance]]
    func contractEventInstances(logs: [TransactionLog]) -> [ContractEventInstance]
}

public protocol ITransactionDecorator {
    func decoration(from: Address?, to: Address?, value: BigUInt?, contractMethod: ContractMethod?, internalTransactions: [InternalTransaction], eventInstances: [ContractEventInstance]) -> TransactionDecoration?
}

public protocol ITransactionProvider {
    func transactions(startBlock: Int) async throws -> [ProviderTransaction]
    func internalTransactions(startBlock: Int) async throws -> [ProviderInternalTransaction]
    func internalTransactions(transactionHash: Data) async throws -> [ProviderInternalTransaction]
    func tokenTransactions(startBlock: Int) async throws -> [ProviderTokenTransaction]
    func eip721Transactions(startBlock: Int) async throws -> [ProviderEip721Transaction]
    func eip1155Transactions(startBlock: Int) async throws -> [ProviderEip1155Transaction]
}
