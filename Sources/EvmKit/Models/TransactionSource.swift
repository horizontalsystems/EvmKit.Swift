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
    private static func etherscan(apiSubdomain: String, txSubdomain: String?, apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "etherscan.io",
            type: .etherscan(apiBaseUrl: "https://\(apiSubdomain).etherscan.io", txBaseUrl: "https://\(txSubdomain.map { "\($0)." } ?? "")etherscan.io", apiKeys: apiKeys)
        )
    }

    static func ethereumEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api", txSubdomain: nil, apiKeys: apiKeys)
    }

    static func sepoliaEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api-sepolia", txSubdomain: "sepolia", apiKeys: apiKeys)
    }

    static func ropstenEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api-ropsten", txSubdomain: "ropsten", apiKeys: apiKeys)
    }

    static func kovanEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api-kovan", txSubdomain: "kovan", apiKeys: apiKeys)
    }

    static func rinkebyEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api-rinkeby", txSubdomain: "rinkeby", apiKeys: apiKeys)
    }

    static func goerliEtherscan(apiKeys: [String]) -> TransactionSource {
        etherscan(apiSubdomain: "api-goerli", txSubdomain: "goerli", apiKeys: apiKeys)
    }

    static func bscscan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "bscscan.com",
            type: .etherscan(apiBaseUrl: "https://api.bscscan.com", txBaseUrl: "https://bscscan.com", apiKeys: apiKeys)
        )
    }

    static func bscscanTestNet(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "testnet.bscscan.com",
            type: .etherscan(apiBaseUrl: "https://api-testnet.bscscan.com", txBaseUrl: "https://testnet.bscscan.com", apiKeys: apiKeys)
        )
    }

    static func polygonscan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "polygonscan.com",
            type: .etherscan(apiBaseUrl: "https://api.polygonscan.com", txBaseUrl: "https://polygonscan.com", apiKeys: apiKeys)
        )
    }

    static func snowtrace(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "snowtrace.io",
            type: .etherscan(apiBaseUrl: "https://api.snowtrace.io", txBaseUrl: "https://snowtrace.io", apiKeys: apiKeys)
        )
    }

    static func optimisticEtherscan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "optimistic.etherscan.io",
            type: .etherscan(apiBaseUrl: "https://api-optimistic.etherscan.io", txBaseUrl: "https://optimistic.etherscan.io", apiKeys: apiKeys)
        )
    }

    static func arbiscan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "arbiscan.io",
            type: .etherscan(apiBaseUrl: "https://api.arbiscan.io", txBaseUrl: "https://arbiscan.io", apiKeys: apiKeys)
        )
    }

    static func gnosis(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "gnosisscan.io",
            type: .etherscan(apiBaseUrl: "https://api.gnosisscan.io", txBaseUrl: "https://gnosisscan.io", apiKeys: apiKeys)
        )
    }

    static func fantom(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "ftmscan.com",
            type: .etherscan(apiBaseUrl: "https://api.ftmscan.com", txBaseUrl: "https://ftmscan.com", apiKeys: apiKeys)
        )
    }

    static func basescan(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "basescan.org",
            type: .etherscan(apiBaseUrl: "https://api.basescan.org", txBaseUrl: "https://basescan.org", apiKeys: apiKeys)
        )
    }

    static func eraZkSync(apiKeys: [String]) -> TransactionSource {
        TransactionSource(
            name: "era.zksync.network",
            type: .etherscan(apiBaseUrl: "https://api-era.zksync.network", txBaseUrl: "https://era.zksync.network", apiKeys: apiKeys)
        )
    }
}
