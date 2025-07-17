import Alamofire
import BigInt
import Foundation
import HsToolKit

class NodeApiProvider {
    private let networkManager: NetworkManager
    private let urls: [URL]

    private let headers: HTTPHeaders
    private var currentRpcId = 0

    init(networkManager: NetworkManager, urls: [URL], auth: String?) {
        self.networkManager = networkManager
        self.urls = urls

        var headers = HTTPHeaders()

        if let auth {
            headers.add(.authorization(username: "", password: auth))
        }

        self.headers = headers
    }

    private func rpcResult<T>(rpc: JsonRpc<T>, urlIndex: Int = 0, attempt: Int = 0, parameters: [String: Any]) async throws -> T {
        do {
            let json = try await networkManager.fetchJson(
                url: urls[urlIndex],
                method: .post,
                parameters: parameters,
                encoding: JSONEncoding.default,
                headers: headers,
                interceptor: self,
                responseCacherBehavior: .doNotCache
            )
            
            
            guard let rpcResponse = JsonRpcResponse.response(jsonObject: json) else {
                throw RequestError.invalidResponse(jsonObject: json)
            }

            return try rpc.parse(response: rpcResponse)
        } catch {
            let nextIndex = (urlIndex + 1) % urls.count

            if attempt < urls.count * 2 {
                return try await rpcResult(rpc:rpc, urlIndex: nextIndex, attempt: attempt + 1, parameters: parameters)
            } else {
                throw error
            }
        }
    }
}

extension NodeApiProvider: RequestInterceptor {
    func retry(_: Request, for _: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        if case let JsonRpcResponse.ResponseError.rpcError(rpcError) = error, rpcError.code == -32005 {
            var backoffSeconds = 1.0

            if let errorData = rpcError.data as? [String: Any], let timeInterval = errorData["backoff_seconds"] as? TimeInterval {
                backoffSeconds = timeInterval
            }

            completion(.retryWithDelay(backoffSeconds))
        } else {
            completion(.doNotRetry)
        }
    }
}

extension NodeApiProvider: IRpcApiProvider {
    var source: String {
        urls.compactMap(\.host).joined(separator: ", ")
    }

    func fetch<T>(rpc: JsonRpc<T>) async throws -> T {
        currentRpcId += 1

        return try await rpcResult(rpc: rpc, parameters: rpc.parameters(id: currentRpcId))
    }
}

extension NodeApiProvider {
    public enum RequestError: Error {
        case invalidResponse(jsonObject: Any)
    }
}
