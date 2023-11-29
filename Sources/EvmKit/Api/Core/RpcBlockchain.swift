import BigInt
import Foundation
import HsExtensions
import HsToolKit

class RpcBlockchain {
    private var tasks = Set<AnyTask>()

    weak var delegate: IBlockchainDelegate?

    private let address: Address
    private let storage: IApiStorage
    private let syncer: IRpcSyncer
    private let transactionBuilder: TransactionBuilder
    private var logger: Logger?

    private(set) var syncState: SyncState = .notSynced(error: Kit.SyncError.notStarted) {
        didSet {
            if syncState != oldValue {
                delegate?.onUpdate(syncState: syncState)
            }
        }
    }

    private var synced = false

    init(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionBuilder: TransactionBuilder, logger: Logger? = nil) {
        self.address = address
        self.storage = storage
        self.syncer = syncer
        self.transactionBuilder = transactionBuilder
        self.logger = logger
    }

    private func syncLastBlockHeight() {
        Task { [weak self, syncer] in
            let lastBlockHeight = try await syncer.fetch(rpc: BlockNumberJsonRpc())
            self?.onUpdate(lastBlockHeight: lastBlockHeight)
        }.store(in: &tasks)
    }

    private func onUpdate(lastBlockHeight: Int) {
        storage.save(lastBlockHeight: lastBlockHeight)
        delegate?.onUpdate(lastBlockHeight: lastBlockHeight)
    }

    func onUpdate(accountState: AccountState) {
        storage.save(accountState: accountState)
        delegate?.onUpdate(accountState: accountState)
    }
}

extension RpcBlockchain: IRpcSyncerDelegate {
    func didUpdate(state: SyncerState) {
        switch state {
        case .preparing:
            syncState = .syncing(progress: nil)
        case .ready:
            syncState = .syncing(progress: nil)
            syncAccountState()
            syncLastBlockHeight()
        case let .notReady(error):
            tasks = Set()
            syncState = .notSynced(error: error)
        }
    }

    func didUpdate(lastBlockHeight: Int) {
        onUpdate(lastBlockHeight: lastBlockHeight)
        // report to whom???
    }
}

extension RpcBlockchain: IBlockchain {
    var source: String {
        "RPC \(syncer.source)"
    }

    func start() {
        syncState = .syncing(progress: nil)
        syncer.start()
    }

    func stop() {
        syncer.stop()
    }

    func refresh() {
        switch syncer.state {
        case .preparing:
            ()
        case .ready:
            syncAccountState()
            syncLastBlockHeight()
        case .notReady:
            syncer.start()
        }
    }

    func syncAccountState() {
        Task { [weak self, syncer, address] in
            do {
                async let balance = try syncer.fetch(rpc: GetBalanceJsonRpc(address: address, defaultBlockParameter: .latest))
                async let nonce = try syncer.fetch(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: .latest))

                let accountState = try await AccountState(balance: balance, nonce: nonce)
                self?.onUpdate(accountState: accountState)
                self?.syncState = .synced
            } catch {
                if let webSocketError = error as? WebSocketStateError {
                    switch webSocketError {
                    case .connecting:
                        self?.syncState = .syncing(progress: nil)
                    case .couldNotConnect:
                        self?.syncState = .notSynced(error: webSocketError)
                    }
                } else {
                    self?.syncState = .notSynced(error: error)
                }
            }
        }.store(in: &tasks)
    }

    var lastBlockHeight: Int? {
        storage.lastBlockHeight
    }

    var accountState: AccountState? {
        storage.accountState
    }

    func nonce(defaultBlockParameter: DefaultBlockParameter) async throws -> Int {
        try await syncer.fetch(rpc: GetTransactionCountJsonRpc(address: address, defaultBlockParameter: defaultBlockParameter))
    }

    func send(rawTransaction: RawTransaction, signature: Signature) async throws -> Transaction {
        let encoded = transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)

        _ = try await syncer.fetch(rpc: SendRawTransactionJsonRpc(signedTransaction: encoded))

        return transactionBuilder.transaction(rawTransaction: rawTransaction, signature: signature)
    }

    func transactionReceipt(transactionHash: Data) async throws -> RpcTransactionReceipt {
        try await syncer.fetch(rpc: GetTransactionReceiptJsonRpc(transactionHash: transactionHash))
    }

    func transaction(transactionHash: Data) async throws -> RpcTransaction {
        try await syncer.fetch(rpc: GetTransactionByHashJsonRpc(transactionHash: transactionHash))
    }

    func getStorageAt(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) async throws -> Data {
        try await syncer.fetch(rpc: GetStorageAtJsonRpc(contractAddress: contractAddress, positionData: positionData, defaultBlockParameter: defaultBlockParameter))
    }

    func call(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) async throws -> Data {
        try await syncer.fetch(rpc: Self.callRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter))
    }

    func estimateGas(to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) async throws -> Int {
        try await syncer.fetch(rpc: EstimateGasJsonRpc(from: address, to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, data: data))
    }

    func getBlock(blockNumber: Int) async throws -> RpcBlock {
        try await syncer.fetch(rpc: GetBlockByNumberJsonRpc(number: blockNumber))
    }

    func fetch<T>(rpcRequest: JsonRpc<T>) async throws -> T {
        try await syncer.fetch(rpc: rpcRequest)
    }
}

extension RpcBlockchain {
    static func callRpc(contractAddress: Address, data: Data, defaultBlockParameter: DefaultBlockParameter) -> JsonRpc<Data> {
        CallJsonRpc(contractAddress: contractAddress, data: data, defaultBlockParameter: defaultBlockParameter)
    }
}

extension RpcBlockchain {
    static func instance(address: Address, storage: IApiStorage, syncer: IRpcSyncer, transactionBuilder: TransactionBuilder, logger: Logger? = nil) -> RpcBlockchain {
        let blockchain = RpcBlockchain(address: address, storage: storage, syncer: syncer, transactionBuilder: transactionBuilder, logger: logger)
        syncer.delegate = blockchain
        return blockchain
    }
}
