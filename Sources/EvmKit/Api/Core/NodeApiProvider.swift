import Foundation
import BigInt
import Alamofire
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

        if let auth = auth {
            headers.add(.authorization(username: "", password: auth))
        }

        self.headers = headers
    }

    private func rpcResult(urlIndex: Int = 0, parameters: [String: Any]) async throws -> Any {
        do {
            return try await networkManager.fetchJson(
                    url: urls[urlIndex],
                    method: .post,
                    parameters: parameters,
                    encoding: JSONEncoding.default,
                    headers: headers,
                    interceptor: self,
                    responseCacherBehavior: .doNotCache
            )
        } catch {
            let nextIndex = urlIndex + 1

            if nextIndex < urls.count {
                return try await rpcResult(urlIndex: nextIndex, parameters: parameters)
            } else {
                throw error
            }
        }
    }

}

extension NodeApiProvider: RequestInterceptor {

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> ()) {
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
        urls.compactMap { $0.host }.joined(separator: ", ")
    }

    func fetch<T>(rpc: JsonRpc<T>) async throws -> T {
        currentRpcId += 1

        let json = try await rpcResult(parameters: rpc.parameters(id: currentRpcId))

        guard let rpcResponse = JsonRpcResponse.response(jsonObject: json) else {
            throw RequestError.invalidResponse(jsonObject: json)
        }

        return try rpc.parse(response: rpcResponse)
    }

}

extension NodeApiProvider {

    public enum RequestError: Error {
        case invalidResponse(jsonObject: Any)
    }

}
