import ObjectMapper

public class JsonRpc<T> {
    private let method: String
    private let params: [Any]

    init(method: String, params: [Any] = []) {
        self.method = method
        self.params = params
    }

    func parameters(id: Int = 1) -> [String: Any] {
        [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": id,
        ]
    }

    func parse(result _: Any) throws -> T {
        fatalError("This method should be overridden")
    }

    func parse(response: JsonRpcResponse) throws -> T {
        switch response {
        case let .success(successResponse):
            guard let result = successResponse.result else {
                throw JsonRpcResponse.ResponseError.invalidResult(value: successResponse.result)
            }

            return try parse(result: result)
        case let .error(errorResponse):
            throw JsonRpcResponse.ResponseError.rpcError(errorResponse.error)
        }
    }
}
