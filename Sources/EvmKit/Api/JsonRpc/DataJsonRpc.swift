import Foundation

public class DataJsonRpc: JsonRpc<Data> {
    public override func parse(result: Any) throws -> Data {
        guard let hexString = result as? String, let value = hexString.hs.hexData else {
            throw JsonRpcResponse.ResponseError.invalidResult(value: result)
        }

        return value
    }
}
