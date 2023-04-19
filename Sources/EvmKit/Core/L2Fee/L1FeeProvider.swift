import Foundation
import BigInt
import HsToolKit

public class L1FeeProvider {
    private let evmKit: EvmKit.Kit
    private let contractAddress: Address

    init(evmKit: EvmKit.Kit, contractAddress: Address) {
        self.evmKit = evmKit
        self.contractAddress = contractAddress
    }
}

extension L1FeeProvider {

    public func l1Fee(gasPrice: GasPrice, gasLimit: Int, to: Address, value: BigUInt, data: Data) async throws -> BigUInt {
        let rawTransaction = RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: to, value: value, data: data, nonce: 1)
        let encoded = TransactionBuilder.encode(rawTransaction: rawTransaction, signature: nil, chainId: evmKit.chain.id)

        let methodData = L1FeeMethod(transaction: encoded).encodedABI()

        let data = try await evmKit.fetchCall(contractAddress: contractAddress, data: methodData)

        guard let value = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
            throw L1FeeError.invalidHex
        }

        return value
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

    public enum L1FeeError: Error {
        case invalidHex
    }

}

extension L1FeeProvider {

     public static func instance(evmKit: EvmKit.Kit, contractAddress: Address, minLogLevel: Logger.Level = .error) -> L1FeeProvider {
        L1FeeProvider(evmKit: evmKit, contractAddress: contractAddress)
    }

}
