import Combine
import Foundation

public class EIP1559GasPriceProvider {
    public enum FeeHistoryError: Error {
        case notAvailable
    }

    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func feeHistoryPublisher(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) -> AnyPublisher<FeeHistory, Error> {
        evmKit.lastBlockHeightPublisher
            .setFailureType(to: Error.self)
            .flatMap { [weak self] _ in
                Future<FeeHistory, Error> { promise in
                    Task { [weak self] in
                        do {
                            guard let strongSelf = self else {
                                throw FeeHistoryError.notAvailable
                            }

                            let result = try await strongSelf.feeHistory(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile)
                            promise(.success(result))
                        } catch {
                            promise(.failure(error))
                        }
                    }
                }
            }
            .eraseToAnyPublisher()
    }

    public func feeHistory(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter = .latest, rewardPercentile: [Int]) async throws -> FeeHistory {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: blocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentile)
        return try await evmKit.fetch(rpcRequest: feeHistoryRequest)
    }
}
