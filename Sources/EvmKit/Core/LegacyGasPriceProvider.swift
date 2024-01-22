import HsToolKit

public class LegacyGasPriceProvider {
    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func gasPrice() async throws -> GasPrice {
        let gasPrice = try await evmKit.fetch(rpcRequest: GasPriceJsonRpc())
        return .legacy(gasPrice: gasPrice)
    }
}

public extension LegacyGasPriceProvider {
    static func gasPrice(networkManager: NetworkManager, rpcSource: RpcSource) async throws -> GasPrice {
        let gasPrice = try await RpcBlockchain.call(networkManager: networkManager, rpcSource: rpcSource, rpcRequest: GasPriceJsonRpc())
        return .legacy(gasPrice: gasPrice)
    }
}
