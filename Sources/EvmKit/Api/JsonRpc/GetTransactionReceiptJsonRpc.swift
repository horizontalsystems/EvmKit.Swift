import Foundation

class GetTransactionReceiptJsonRpc: JsonRpc<RpcTransactionReceipt> {

    init(transactionHash: Data) {
        super.init(
                method: "eth_getTransactionReceipt",
                params: [transactionHash.hs.hexString]
        )
    }

    override func parse(result: Any) throws -> RpcTransactionReceipt {
        try RpcTransactionReceipt(JSONObject: result)
    }

}
