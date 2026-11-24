import Combine
import Foundation
import HsToolKit

public class EIP1559GasPriceProvider {
    private static let feeHistoryBlocksCount = 10
    private static let standardRewardPercentile = 50
    private static let highRewardPercentile = 75

    public enum FeeHistoryError: Error {
        case notAvailable
    }

    public enum Priority: Sendable {
        case standard
        case high
    }

    private let evmKit: Kit

    public init(evmKit: Kit) {
        self.evmKit = evmKit
    }

    public func gasPrice(defaultBlockParameter: DefaultBlockParameter = .latest, priority: Priority = .standard) async throws -> GasPrice {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: Self.feeHistoryBlocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: Self.rewardPercentiles(priority: priority))
        let feeHistory = try await evmKit.fetch(rpcRequest: feeHistoryRequest)

        return try Self.gasPrice(baseFeePerGas: feeHistory.baseFeePerGas, gasUsedRatio: feeHistory.gasUsedRatio, reward: feeHistory.reward, priority: priority)
    }

    private static func rewardPercentiles(priority: Priority) -> [Int] {
        switch priority {
        case .standard: return [standardRewardPercentile]
        case .high: return [standardRewardPercentile, highRewardPercentile]
        }
    }

    private static func median(of values: [Int]) -> Int? {
        guard !values.isEmpty else {
            return nil
        }

        let sorted = values.sorted()
        let middle = sorted.count / 2

        return sorted.count % 2 == 0 ? mean(sorted[middle - 1], sorted[middle]) : sorted[middle]
    }

    /// `(a + b) / 2` without trapping: node-supplied values can be close to `Int.max` (or negative).
    private static func mean(_ a: Int, _ b: Int) -> Int {
        let (sum, overflow) = a.addingReportingOverflow(b)

        if !overflow {
            return sum / 2
        }

        // Overflow only happens when both have the same sign, so the halves and the remainders share it and the result fits.
        return a / 2 + b / 2 + (a % 2 + b % 2) / 2
    }
}

public extension EIP1559GasPriceProvider {
    static func gasPrice(networkManager: NetworkManager, rpcSource: RpcSource, defaultBlockParameter: DefaultBlockParameter = .latest, priority: Priority = .standard) async throws -> GasPrice {
        let feeHistoryRequest = FeeHistoryJsonRpc(blocksCount: feeHistoryBlocksCount, defaultBlockParameter: defaultBlockParameter, rewardPercentile: rewardPercentiles(priority: priority))
        let feeHistory = try await RpcBlockchain.call(networkManager: networkManager, rpcSource: rpcSource, rpcRequest: feeHistoryRequest)

        return try gasPrice(baseFeePerGas: feeHistory.baseFeePerGas, gasUsedRatio: feeHistory.gasUsedRatio, reward: feeHistory.reward, priority: priority)
    }

    /// `.standard` tip is the mean of the 50th-percentile rewards over all blocks.
    /// `.high` tip is the median of the 75th-percentile rewards (second column) over the blocks with a non-zero gas used ratio,
    /// never below the standard tip, and the standard tip when no block qualifies.
    static func gasPrice(baseFeePerGas: [Int], gasUsedRatio: [Double], reward: [[Int]], priority: Priority = .standard) throws -> GasPrice {
        let standardTips = reward.compactMap(\.first)
        let baseFee = baseFeePerGas.suffix(2).max()

        guard let baseFee, !standardTips.isEmpty else {
            throw FeeHistoryError.notAvailable
        }

        let standardTip = standardTips.reduce(0, +) / standardTips.count
        var tip = standardTip

        if priority == .high {
            let highTips = zip(reward, gasUsedRatio).compactMap { row, ratio in
                ratio > 0 && row.count > 1 ? row[1] : nil
            }

            if let median = median(of: highTips) {
                tip = max(median, standardTip)
            }
        }

        let maxFeePerGas = (baseFee * GasPrice.eip1559SurchargeBasis / 100) + tip
        return .eip1559(maxFeePerGas: maxFeePerGas, maxPriorityFeePerGas: tip)
    }
}
