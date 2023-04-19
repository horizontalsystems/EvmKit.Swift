import Foundation
import BigInt
import HsToolKit

public class Eip1155Provider {
    private let rpcApiProvider: IRpcApiProvider

    init(rpcApiProvider: IRpcApiProvider) {
        self.rpcApiProvider = rpcApiProvider
    }

}

extension Eip1155Provider {

    public func balanceOf(contractAddress: Address, tokenId: BigUInt, address: Address) async throws -> BigUInt {
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

extension Eip1155Provider {

    public enum BalanceError: Error {
        case invalidHex
    }

    public enum RpcSourceError: Error {
        case websocketNotSupported
    }

}

extension Eip1155Provider {

    public static func instance(rpcSource: RpcSource, minLogLevel: Logger.Level = .error) throws -> Eip1155Provider {
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
