import Combine
import Foundation
import HsToolKit

public class EIP1559GasPriceProvider {
    private static let feeHistoryBlocksCount = 10
    private static let feeHistoryRewardPercentile = [50]

    public enum FeeHistoryError: Error {
        case notAvailable
    }

    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func gasPrice(defaultBlockParameter: DefaultBlockParameter = .latest) async throws -> GasPrice {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: Self.feeHistoryBlocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: Self.feeHistoryRewardPercentile)
        let feeHistory = try await evmKit.fetch(rpcRequest: feeHistoryRequest)
        let tipsConsidered = feeHistory.reward.compactMap(\.first)
        let baseFeesConsidered = feeHistory.baseFeePerGas.suffix(2)

        guard !baseFeesConsidered.isEmpty, !tipsConsidered.isEmpty else {
            throw EIP1559GasPriceProvider.FeeHistoryError.notAvailable
        }

        let maxPriorityFeePerGas = tipsConsidered.reduce(0, +) / tipsConsidered.count
        let maxFeePerGas = (baseFeesConsidered.max() ?? 0) + maxPriorityFeePerGas
        return .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
    }
}

public extension EIP1559GasPriceProvider {
    static func gasPrice(networkManager: NetworkManager, rpcSource: RpcSource, defaultBlockParameter: DefaultBlockParameter = .latest) async throws -> GasPrice {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: Self.feeHistoryBlocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: Self.feeHistoryRewardPercentile)
        let feeHistory = try await RpcBlockchain.call(networkManager: networkManager, rpcSource: rpcSource, rpcRequest: feeHistoryRequest)
        let tipsConsidered = feeHistory.reward.compactMap(\.first)
        let baseFeesConsidered = feeHistory.baseFeePerGas.suffix(2)

        guard !baseFeesConsidered.isEmpty, !tipsConsidered.isEmpty else {
            throw EIP1559GasPriceProvider.FeeHistoryError.notAvailable
        }

        let maxPriorityFeePerGas = tipsConsidered.reduce(0, +) / tipsConsidered.count
        let maxFeePerGas = (baseFeesConsidered.max() ?? 0) + maxPriorityFeePerGas
        return .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: maxPriorityFeePerGas)
    }
}
