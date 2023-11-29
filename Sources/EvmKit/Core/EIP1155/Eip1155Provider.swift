import BigInt
import Foundation
import HsToolKit

public class Eip1155Provider {
    private let rpcApiProvider: IRpcApiProvider

    init(rpcApiProvider: IRpcApiProvider) {
        self.rpcApiProvider = rpcApiProvider
    }
}

public extension Eip1155Provider {
    func balanceOf(contractAddress: Address, tokenId: BigUInt, address: Address) async throws -> BigUInt {
        let methodData = BalanceOfMethod(owner: address, tokenId: tokenId).encodedABI()
        let rpc = RpcBlockchain.callRpc(contractAddress: contractAddress, data: methodData, defaultBlockParameter: .latest)

        let data = try await rpcApiProvider.fetch(rpc: rpc)

        guard let value = BigUInt(data.prefix(32).hs.hex, radix: 16) else {
            throw BalanceError.invalidHex
        }

        return value
    }
}

extension Eip1155Provider {
    class BalanceOfMethod: ContractMethod {
        private let owner: Address
        private let tokenId: BigUInt

        init(owner: Address, tokenId: BigUInt) {
            self.owner = owner
            self.tokenId = tokenId
        }

        override var methodSignature: String {
            "balanceOf(address,uint256)"
        }

        override var arguments: [Any] {
            [owner, tokenId]
        }
    }
}

public extension Eip1155Provider {
    enum BalanceError: Error {
        case invalidHex
    }

    enum RpcSourceError: Error {
        case websocketNotSupported
    }
}

public extension Eip1155Provider {
    static func instance(rpcSource: RpcSource, minLogLevel: Logger.Level = .error) throws -> Eip1155Provider {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)
        let rpcApiProvider: IRpcApiProvider

        switch rpcSource {
        case let .http(urls, auth):
            rpcApiProvider = NodeApiProvider(networkManager: networkManager, urls: urls, auth: auth)
        case .webSocket:
            throw RpcSourceError.websocketNotSupported
        }

        return Eip1155Provider(rpcApiProvider: rpcApiProvider)
    }
}
