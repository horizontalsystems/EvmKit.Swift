import Foundation
import BigInt
import HsToolKit

class WebSocketRpcSyncer {
    struct RpcHandler {
        let onSuccess: (JsonRpcResponse) -> ()
        let onError: (Error) -> ()
    }

    typealias SubscriptionHandler = (RpcSubscriptionResponse) -> ()

    weak var delegate: IRpcSyncerDelegate?

    private let rpcSocket: IRpcWebSocket
    private var logger: Logger?

    private var currentRpcId = 0
    private var rpcHandlers = [Int: RpcHandler]()
    private var subscriptionHandlers = [String: SubscriptionHandler]()

    private let queue = DispatchQueue(label: "io.horizontal-systems.ethereum-kit.web-socket-rpc-syncer", qos: .utility)

    private(set) var state: SyncerState = .notReady(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                delegate?.didUpdate(state: state)
            }
        }
    }

    private init(rpcSocket: IRpcWebSocket, logger: Logger? = nil) {
        self.rpcSocket = rpcSocket
        self.logger = logger
    }

    private var nextRpcId: Int {
        currentRpcId += 1
        return currentRpcId
    }

    private func _send<T>(rpc: JsonRpc<T>, handler: RpcHandler) throws -> Int {
        let rpcId = nextRpcId

        try rpcSocket.send(rpc: rpc, rpcId: rpcId)

        rpcHandlers[rpcId] = handler

        return rpcId
    }

    private func cancel(rpcId: Int) {
        queue.async {
            let handler = self.rpcHandlers.removeValue(forKey: rpcId)
            handler?.onError(NetworkManager.TaskError())
        }
    }

    func send<T>(rpc: JsonRpc<T>, onSuccess: @escaping (T) -> (), onError: @escaping (Error) -> ()) -> Int? {
        queue.sync { [weak self] in
            do {
                return try self?._send(
                        rpc: rpc,
                        handler: RpcHandler(
                                onSuccess: { response in
                                    do {
                                        onSuccess(try rpc.parse(response: response))
                                    } catch {
                                        onError(error)
                                    }
                                },
                                onError: onError
                        )
                )
            } catch {
                onError(error)
                return nil
            }
        }
    }

    func subscribe<T>(subscription: RpcSubscription<T>, onSuccess: @escaping () -> (), onError: @escaping (Error) -> (), successHandler: @escaping (T) -> (), errorHandler: @escaping (Error) -> ()) {
        _ = send(
                rpc: SubscribeJsonRpc(params: subscription.params),
                onSuccess: { [weak self] subscriptionId in
                    self?.subscriptionHandlers[subscriptionId] = { response in
                        do {
                            successHandler(try subscription.parse(result: response.params.result))
                        } catch {
                            errorHandler(error)
                        }
                    }
                    onSuccess()
                },
                onError: onError
        )
    }

    private func subscribeToNewHeads() {
        subscribe(
                subscription: NewHeadsRpcSubscription(),
                onSuccess: {},
                onError: { _ in
//                    self?.onFailSync(error: error)
                },
                successHandler: { [weak self] header in
                    self?.delegate?.didUpdate(lastBlockHeight: header.number)
                },
                errorHandler: { [weak self] error in
                    self?.logger?.error("NewHeads Handle Failed: \(error)")
                }
        )
    }

}

extension WebSocketRpcSyncer: IRpcWebSocketDelegate {

    func didUpdate(socketState: WebSocketState) {
        if case .notReady(let error) = state, let syncError = error as? Kit.SyncError, syncError == .notStarted {
            // do not react to web socket state if syncer was stopped
            return
        }

        switch socketState {
        case .connecting:
            state = .preparing
        case .connected:
            state = .ready
            subscribeToNewHeads()
        case .disconnected(let error):
            queue.async { [weak self] in
                self?.rpcHandlers.values.forEach { handler in
                    handler.onError(error)
                }
                self?.rpcHandlers = [:]
                self?.subscriptionHandlers = [:]
            }

            state = .notReady(error: error)
        }
    }

    func didReceive(rpcResponse: JsonRpcResponse) {
        queue.async { [weak self] in
            let handler = self?.rpcHandlers.removeValue(forKey: rpcResponse.id)
            handler?.onSuccess(rpcResponse)
        }
    }

    func didReceive(subscriptionResponse: RpcSubscriptionResponse) {
        queue.async { [weak self] in
            self?.subscriptionHandlers[subscriptionResponse.params.subscriptionId]?(subscriptionResponse)
        }
    }

}

extension WebSocketRpcSyncer: IRpcSyncer {

    var source: String {
        "WebSocket \(rpcSocket.source)"
    }

    func start() {
        state = .preparing

        rpcSocket.start()
    }

    func stop() {
        state = .notReady(error: Kit.SyncError.notStarted)

        rpcSocket.stop()
    }

    func fetch<T>(rpc: JsonRpc<T>) async throws -> T {
        try Task.checkCancellation()

        var rpcId: Int?

        let onCancel = { [weak self] in
            if let rpcId = rpcId {
                self?.cancel(rpcId: rpcId)
            }
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { [weak self] continuation in
                rpcId = self?.send(
                        rpc: rpc,
                        onSuccess: { value in
                            continuation.resume(returning: value)
                        },
                        onError: { error in
                            continuation.resume(throwing: error)
                        }
                )
            }
        } onCancel: {
            onCancel()
        }
    }

}

extension WebSocketRpcSyncer {

    static func instance(socket: IWebSocket, logger: Logger? = nil) -> WebSocketRpcSyncer {
        let rpcSocket = RpcWebSocket(socket: socket, logger: logger)
        socket.delegate = rpcSocket

        let syncer = WebSocketRpcSyncer(rpcSocket: rpcSocket, logger: logger)
        rpcSocket.delegate = syncer

        return syncer
    }

}
