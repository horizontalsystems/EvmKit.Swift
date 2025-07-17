import BigInt
import Combine
import Foundation
import HsExtensions
import HsToolKit
import UIKit

class ApiRpcSyncer {
    weak var delegate: IRpcSyncerDelegate?

    private let rpcApiProvider: IRpcApiProvider
    private let reachabilityManager: ReachabilityManager
    private let syncInterval: TimeInterval
    private var cancellables = Set<AnyCancellable>()
    private var tasks = Set<AnyTask>()

    private var isStarted = false
    private var timer: Timer?

    private(set) var state: SyncerState = .notReady(error: Kit.SyncError.notStarted) {
        didSet {
            if state != oldValue {
                delegate?.didUpdate(state: state)
            }
        }
    }

    init(rpcApiProvider: IRpcApiProvider, reachabilityManager: ReachabilityManager, syncInterval: TimeInterval) {
        self.rpcApiProvider = rpcApiProvider
        self.reachabilityManager = reachabilityManager
        self.syncInterval = syncInterval

        reachabilityManager.$isReachable
            .sink { [weak self] reachable in
                self?.handleUpdate(reachable: reachable)
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(self, selector: #selector(onEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    deinit {
        stop()
    }

    @objc func onEnterBackground() {
        timer?.invalidate()
    }

    @objc func onEnterForeground() {
        guard isStarted else {
            return
        }

        startTimer()
    }

    @objc func onFireTimer() {
        Task { [weak self, rpcApiProvider] in
            let lastBlockHeight = try await rpcApiProvider.fetch(rpc: BlockNumberJsonRpc())
            self?.delegate?.didUpdate(lastBlockHeight: lastBlockHeight)
        }.store(in: &tasks)
    }

    private func startTimer() {
        timer?.invalidate()

        DispatchQueue.main.async { [weak self, syncInterval] in
            self?.timer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
                self?.onFireTimer()
            }
            self?.timer?.tolerance = 0.5
        }
    }

    private func handleUpdate(reachable: Bool) {
        guard isStarted else {
            return
        }

        if reachable {
            state = .ready
            startTimer()
        } else {
            state = .notReady(error: Kit.SyncError.noNetworkConnection)
            timer?.invalidate()
        }
    }
}

extension ApiRpcSyncer: IRpcSyncer {
    var source: String {
        "API \(rpcApiProvider.source)"
    }

    func start() {
        isStarted = true

        handleUpdate(reachable: reachabilityManager.isReachable)
    }

    func stop() {
        isStarted = false

        cancellables = Set()
        tasks = Set()

        state = .notReady(error: Kit.SyncError.notStarted)
        timer?.invalidate()
    }

    func fetch<T>(rpc: JsonRpc<T>) async throws -> T {
        try await rpcApiProvider.fetch(rpc: rpc)
    }
}
