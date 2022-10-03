import Foundation
import EthereumKit
import RxSwift
import BigInt

class EthereumAdapter {
    private let evmKit: Kit
    private let signer: Signer?
    private let decimal = 18

    init(evmKit: Kit, signer: Signer?) {
        self.evmKit = evmKit
        self.signer = signer
    }

    private func transactionRecord(fullTransaction: FullTransaction) -> TransactionRecord {
        let transaction = fullTransaction.transaction

        var amount: Decimal?

        if let value = transaction.value, let significand = Decimal(string: value.description) {
            amount = Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return TransactionRecord(
                transactionHash: transaction.hash.toHexString(),
                transactionHashData: transaction.hash,
                timestamp: transaction.timestamp,
                isFailed: transaction.isFailed,
                from: transaction.from,
                to: transaction.to,
                amount: amount,
                input: transaction.input.map {
                    $0.toHexString()
                },
                blockHeight: transaction.blockNumber,
                transactionIndex: transaction.transactionIndex,
                decoration: String(describing: fullTransaction.decoration)
        )
    }

}

extension EthereumAdapter {

    func start() {
        evmKit.start()
    }

    func stop() {
        evmKit.stop()
    }

    func refresh() {
        evmKit.refresh()
    }

    var name: String {
        "Ethereum"
    }

    var coin: String {
        "ETH"
    }

    var lastBlockHeight: Int? {
        evmKit.lastBlockHeight
    }

    var syncState: SyncState {
        evmKit.syncState
    }

    var transactionsSyncState: SyncState {
        evmKit.transactionsSyncState
    }

    var balance: Decimal {
        if let balance = evmKit.accountState?.balance, let significand = Decimal(string: balance.description) {
            return Decimal(sign: .plus, exponent: -decimal, significand: significand)
        }

        return 0
    }

    var receiveAddress: Address {
        evmKit.receiveAddress
    }

    var lastBlockHeightObservable: Observable<Void> {
        evmKit.lastBlockHeightObservable.map { _ in () }
    }

    var syncStateObservable: Observable<Void> {
        evmKit.syncStateObservable.map { _ in () }
    }

    var transactionsSyncStateObservable: Observable<Void> {
        evmKit.transactionsSyncStateObservable.map { _ in () }
    }

    var balanceObservable: Observable<Void> {
        evmKit.accountStateObservable.map { _ in () }
    }

    var transactionsObservable: Observable<Void> {
        evmKit.transactionsObservable(tagQueries: []).map { _ in () }
    }

    func transactionsSingle(from hash: Data?, limit: Int?) -> Single<[TransactionRecord]> {
        evmKit.transactionsSingle(tagQueries: [], fromHash: hash, limit: limit)
                .map { [weak self] in
                    $0.compactMap {
                        self?.transactionRecord(fullTransaction: $0)
                    }
                }
    }

    func transaction(hash: Data, interTransactionIndex: Int) -> TransactionRecord? {
        evmKit.transaction(hash: hash).map { transactionRecord(fullTransaction: $0) }
    }

    func estimatedGasLimit(to address: Address, value: Decimal, gasPrice: GasPrice) -> Single<Int> {
        let value = BigUInt(value.roundedString(decimal: decimal))!

        return evmKit.estimateGas(to: address, amount: value, gasPrice: gasPrice)
    }

    func transactionSingle(hash: Data) -> Single<FullTransaction> {
        evmKit.transactionSingle(hash: hash)
    }

    func sendSingle(to: Address, amount: Decimal, gasLimit: Int, gasPrice: GasPrice) -> Single<Void> {
        guard let signer = signer else {
            return Single.error(SendError.noSigner)
        }

        let amount = BigUInt(amount.roundedString(decimal: decimal))!
        let transactionData = evmKit.transferTransactionData(to: to, value: amount)

        return evmKit.rawTransaction(transactionData: transactionData, gasPrice: gasPrice, gasLimit: gasLimit)
                .flatMap { [weak self] rawTransaction in
                    guard let strongSelf = self else {
                        throw Kit.KitError.weakReference
                    }

                    let signature = try signer.signature(rawTransaction: rawTransaction)

                    return strongSelf.evmKit.sendSingle(rawTransaction: rawTransaction, signature: signature)
                }
                .map { (tx: FullTransaction) in () }
    }

}

extension EthereumAdapter {

    enum SendError: Error {
        case noSigner
    }

}
