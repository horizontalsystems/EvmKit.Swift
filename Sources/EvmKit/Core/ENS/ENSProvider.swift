// https://eips.ethereum.org/EIPS/eip-137#namehash-algorithm

import Foundation
import HsToolKit

public class ENSProvider {
    private static let registryAddress = try! Address(hex: "0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e")
    private let rpcApiProvider: IRpcApiProvider

    init(rpcApiProvider: IRpcApiProvider) {
        self.rpcApiProvider = rpcApiProvider
    }

    private func resolve(name: String, level: Level) async throws -> Address {
        let nameHash = NameHash.nameHash(name: name)
        let methodData = ResolverMethod(hash: nameHash, method: level.name).encodedABI()
        let rpc = RpcBlockchain.callRpc(contractAddress: level.address, data: methodData, defaultBlockParameter: .latest)

        let data = try await rpcApiProvider.fetch(rpc: rpc)
        let address = data.prefix(32).suffix(20).hs.hexString
        return try Address(hex: address)
    }
}

public extension ENSProvider {
    func resolveAddress(domain: String) async throws -> Address {
        guard let resolverAddress = try? await resolve(name: domain, level: .resolver) else {
            throw ResolveError.noAnyResolver
        }

        guard let address = try? await resolve(name: domain, level: .addr(resolver: resolverAddress)) else {
            throw ResolveError.noAnyAddress
        }

        return address
    }
}

extension ENSProvider {
    class ResolverMethod: ContractMethod {
        private let hash: String
        private let method: String

        init(hash: String, method: String) {
            self.hash = hash
            self.method = method
        }

        override var methodSignature: String {
            "\(method)(bytes32)"
        }

        override var arguments: [Any] {
            [hash]
        }
    }
}

extension ENSProvider {
    enum Level {
        case resolver
        case addr(resolver: Address)

        var name: String {
            switch self {
            case .resolver: return "resolver"
            case .addr: return "addr"
            }
        }

        var address: Address {
            switch self {
            case .resolver: return ENSProvider.registryAddress
            case let .addr(address): return address
            }
        }
    }
}

public extension ENSProvider {
    enum ResolveError: Error {
        case noAnyResolver
        case noAnyAddress
    }

    enum RpcSourceError: Error {
        case websocketNotSupported
    }
}

public extension ENSProvider {
    static func instance(rpcSource: RpcSource, minLogLevel: Logger.Level = .error) throws -> ENSProvider {
        let logger = Logger(minLogLevel: minLogLevel)
        let networkManager = NetworkManager(logger: logger)
        let rpcApiProvider: IRpcApiProvider

        switch rpcSource {
        case let .http(urls, auth):
            rpcApiProvider = NodeApiProvider(networkManager: networkManager, urls: urls, auth: auth)
        case .webSocket:
            throw RpcSourceError.websocketNotSupported
        }

        return ENSProvider(rpcApiProvider: rpcApiProvider)
    }
}
