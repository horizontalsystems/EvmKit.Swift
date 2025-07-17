public enum GasPrice {
    case legacy(gasPrice: Int)
    case eip1559(maxFeePerGas: Int, maxPriorityFeePerGas: Int)

    public var max: Int {
        switch self {
        case let .legacy(gasPrice): return gasPrice
        case let .eip1559(maxFeePerGas, _): return maxFeePerGas
        }
    }
}

extension GasPrice: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .legacy(gasPrice): return "Legacy(\(gasPrice))"
        case let .eip1559(maxFeePerGas, maxPriorityFeePerGas): return "EIP1559(\(maxFeePerGas),\(maxPriorityFeePerGas))"
        }
    }
}
