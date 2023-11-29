public class LegacyGasPriceProvider {
    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func gasPrice() async throws -> Int {
        try await evmKit.fetch(rpcRequest: GasPriceJsonRpc())
    }
}
