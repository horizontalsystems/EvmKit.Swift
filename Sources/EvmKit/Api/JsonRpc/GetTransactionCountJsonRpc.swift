public class GetTransactionCountJsonRpc: IntJsonRpc {
    public init(address: Address, defaultBlockParameter: DefaultBlockParameter) {
        super.init(
            method: "eth_getTransactionCount",
            params: [address.hex, defaultBlockParameter.raw]
        )
    }
}
