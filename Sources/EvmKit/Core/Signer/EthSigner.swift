import Foundation
import BigInt
import HsCryptoKit

class EthSigner {
    private let privateKey: Data

    init(privateKey: Data) {
        self.privateKey = privateKey
    }

    private func prefixed(message: Data) -> Data {
        let prefix = "\u{0019}Ethereum Signed Message:\n\(message.count)"

        guard let prefixData = prefix.data(using: .utf8) else {
            return message
        }

        return Crypto.sha3(prefixData + message)
    }

    public func sign(message: Data, isLegacy: Bool = false) throws -> Data {
        try Crypto.ellipticSign(isLegacy ? message : prefixed(message: message), privateKey: privateKey)
    }

    func sign(eip712TypedData: EIP712TypedData) throws -> Data {
        let signHash = try eip712TypedData.signHash()
        return try Crypto.ellipticSign(signHash, privateKey: privateKey)
    }

}
