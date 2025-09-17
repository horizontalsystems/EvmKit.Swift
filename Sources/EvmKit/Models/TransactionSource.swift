public struct TransactionSource {
    public let name: String
    public let type: SourceType

    public init(name: String, type: SourceType) {
        self.name = name
        self.type = type
    }

    public func transactionUrl(hash: String) -> String {
        switch type {
        case let .etherscan(_, txBaseUrl, _):
            return "\(txBaseUrl)/tx/\(hash)"
        }
    }

    public enum SourceType {
        case etherscan(apiBaseUrl: String, txBaseUrl: String, apiKeys: [String])
    }
}

public extension TransactionSource {
    private static func etherscan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "etherscan.io",
            type: .etherscan(apiBaseUrl: "https://api.etherscan.io/v2", txBaseUrl: "https://etherscan.io", apiKeys: apiKeys)
        )
    }

    static func ethereumEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func sepoliaEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func ropstenEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func kovanEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func rinkebyEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func goerliEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func bscscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func bscscanTestNet(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func polygonscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func snowtrace(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "snowtrace.io",
            type: .etherscan(apiBaseUrl: "https://api.snowtrace.io", txBaseUrl: "https://snowtrace.io", apiKeys: apiKeys)
        )
    }

    static func optimisticEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func arbiscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func gnosis(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func fantom(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func basescan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }

    static func eraZkSync(apiKeys: [String]) -> TransactionSource {
        etherscan(apiKeys: apiKeys)
    }
}
