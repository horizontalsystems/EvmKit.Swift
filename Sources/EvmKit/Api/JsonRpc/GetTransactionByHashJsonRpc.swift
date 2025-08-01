import Foundation
import HsExtensions

public class GetTransactionByHashJsonRpc: JsonRpc<RpcTransaction> {
    public init(transactionHash: Data) {
        super.init(
            method: "eth_getTransactionByHash",
            params: [transactionHash.hs.hexString]
        )
    }

    override public func parse(result: Any) throws -> RpcTransaction {
        try RpcTransaction(JSONObject: result)
    }
}
