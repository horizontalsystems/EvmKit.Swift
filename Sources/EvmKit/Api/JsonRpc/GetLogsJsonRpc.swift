import Foundation
import HsExtensions

class GetLogsJsonRpc: JsonRpc<[TransactionLog]> {
    init(address: Address?, fromBlock: DefaultBlockParameter?, toBlock: DefaultBlockParameter?, topics: [Any?]?) {
        var params = [String: Any]()

        if let address {
            params["address"] = address.hex
        }

        if let fromBlock {
            params["fromBlock"] = fromBlock.raw
        }

        if let toBlock {
            params["toBlock"] = toBlock.raw
        }

        if let topics {
            params["topics"] = topics.map { topic -> Any? in
                if let array = topic as? [Data?] {
                    return array.map { topic -> String? in
                        topic?.hs.hexString
                    }
                } else if let data = topic as? Data {
                    return data.hs.hexString
                } else {
                    return nil
                }
            }
        }

        super.init(
            method: "eth_getLogs",
            params: [params]
        )
    }

    override func parse(result: Any) throws -> [TransactionLog] {
        guard let array = result as? [Any] else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return try array.map { jsonObject in
            try TransactionLog(JSONObject: jsonObject)
        }
    }
}
