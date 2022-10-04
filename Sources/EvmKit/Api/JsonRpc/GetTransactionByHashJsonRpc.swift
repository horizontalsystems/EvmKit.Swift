import Foundation

class GetTransactionByHashJsonRpc: JsonRpc<RpcTransaction> {

    init(transactionHash: Data) {
        super.init(
                method: "eth_getTransactionByHash",
                params: [transactionHash.hs.hexString]
        )
    }

    override func parse(result: Any) throws -> RpcTransaction {
        try RpcTransaction(JSONObject: result)
    }

}
