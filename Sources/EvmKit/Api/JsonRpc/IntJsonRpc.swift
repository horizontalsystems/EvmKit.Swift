import HsExtensions

class IntJsonRpc: JsonRpc<Int> {

    override func parse(result: Any) throws -> Int {
        guard let hexString = result as? String, let value = Int(hexString.hs.stripHexPrefix(), radix: 16) else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }

}
