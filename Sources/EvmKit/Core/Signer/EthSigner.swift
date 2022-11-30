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

    public func parseTypedData(rawJson: Data) throws -> EIP712TypedData {
        let decoder = JSONDecoder()
        return try decoder.decode(EIP712TypedData.self, from: rawJson)
    }

    func signTypedData(message: Data) throws -> Data {
        let typedData = try parseTypedData(rawJson: message)
        let hashedMessage = try typedData.signHash()

        return try Crypto.ellipticSign(hashedMessage, privateKey: privateKey)
    }

}
