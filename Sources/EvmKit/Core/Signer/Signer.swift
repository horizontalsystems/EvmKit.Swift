import BigInt
import Foundation
import HdWalletKit
import HsCryptoKit
import HsToolKit

public class Signer {
    private let transactionBuilder: TransactionBuilder
    private let transactionSigner: TransactionSigner
    private let ethSigner: EthSigner

    init(transactionBuilder: TransactionBuilder, transactionSigner: TransactionSigner, ethSigner: EthSigner) {
        self.transactionBuilder = transactionBuilder
        self.transactionSigner = transactionSigner
        self.ethSigner = ethSigner
    }

    public func signature(rawTransaction: RawTransaction) throws -> Signature {
        try transactionSigner.signature(rawTransaction: rawTransaction)
    }

    public func signedTransaction(address: Address, value: BigUInt, transactionInput: Data = Data(), gasPrice: GasPrice, gasLimit: Int, nonce: Int) throws -> Data {
        let rawTransaction = RawTransaction(gasPrice: gasPrice, gasLimit: gasLimit, to: address, value: value, data: transactionInput, nonce: nonce)
        let signature = try transactionSigner.signature(rawTransaction: rawTransaction)
        return transactionBuilder.encode(rawTransaction: rawTransaction, signature: signature)
    }

    public func signed(message: Data, isLegacy: Bool = false) throws -> Data {
        try ethSigner.sign(message: message, isLegacy: isLegacy)
    }

    public func sign(eip712TypedData: EIP712TypedData) throws -> Data {
        try ethSigner.sign(eip712TypedData: eip712TypedData)
    }
}

public extension Signer {
    static func instance(seed: Data, chain: Chain) throws -> Signer {
        try instance(privateKey: privateKey(seed: seed, chain: chain), chain: chain)
    }

    static func instance(privateKey: Data, chain: Chain) -> Signer {
        let address = address(privateKey: privateKey)

        let transactionSigner = TransactionSigner(chain: chain, privateKey: privateKey)
        let transactionBuilder = TransactionBuilder(chain: chain, address: address)
        let ethSigner = EthSigner(privateKey: privateKey)

        return Signer(transactionBuilder: transactionBuilder, transactionSigner: transactionSigner, ethSigner: ethSigner)
    }

    static func address(seed: Data, chain: Chain) throws -> Address {
        try address(privateKey: privateKey(seed: seed, chain: chain))
    }

    static func address(privateKey: Data) -> Address {
        let publicKey = Data(Crypto.publicKey(privateKey: privateKey, compressed: false).dropFirst())
        return Address(raw: Data(Crypto.sha3(publicKey).suffix(20)))
    }

    static func privateKey(string: String) throws -> Data {
        guard let data = string.hs.hexData else {
            throw PrivateKeyValidationError.invalidDataString
        }

        guard data.count == 32 else {
            throw PrivateKeyValidationError.invalidDataLength
        }

        return data
    }

    static func privateKey(seed: Data, chain: Chain) throws -> Data {
        let hdWallet = HDWallet(seed: seed, coinType: chain.coinType, xPrivKey: HDExtendedKeyVersion.xprv.rawValue)
        return try hdWallet.privateKey(account: 0, index: 0, chain: .external).raw
    }
}

public extension Signer {
    enum PrivateKeyValidationError: Error {
        case invalidDataString
        case invalidDataLength
    }
}
