import BigInt
import Foundation
import HsToolKit
import RxSwift

public class L1FeeProvider {
    private let evmKit: EvmKit.Kit
    private let contractAddress: Address

    init(evmKit: EvmKit.Kit, contractAddress: Address) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
    }
}

public extension L1FeeProvider {
    func getL1Fee(gasPrice: GasPrice, gasLimit: Int, to: Address, value: BigUInt, data: Data) -> Single<BigUInt> {
        let rawTransaction = RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data, nonce: 1)
        let encoded = TransactionBuilder.encode(rawTransaction: rawTransaction, signature: nil, chainId: evmKit.chain.id)

        let data = L1FeeMethod(transaction: encoded).encodedABI()

        return evmKit.call(contractAddress: contractAddress, data: data)
            .flatMap { data -> Single<BigUInt> in
                guard let value = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
                    return Single.error(L1FeeError.invalidHex)
                }

                return Single.just(value)
            }
    }
}

extension L1FeeProvider {
    class L1FeeMethod: ContractMethod {
        let transaction: Data

        init(transaction: Data) {
            self.transaction = transaction
        }

        override var methodSignature: String {
            "getL1Fee(bytes)"
        }

        override var arguments: [Any] {
            [transaction]
        }
    }
}

public extension L1FeeProvider {
    enum L1FeeError: Error {
        case invalidHex
    }
}

public extension L1FeeProvider {
    static func instance(evmKit: EvmKit.Kit, contractAddress: Address, minLogLevel: Logger.Level = .error) -> L1FeeProvider {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)

        return L1FeeProvider(evmKit: evmKit, contractAddress: contractAddress)
    }
}
