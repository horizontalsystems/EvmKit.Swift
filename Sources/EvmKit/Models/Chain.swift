import Foundation

public struct Chain {
    public let id: Int
    public let coinType: UInt32
    public let gasLimit: Int
    public let syncInterval: TimeInterval
    public let isEIP1559Supported: Bool

    public init(id: Int, coinType: UInt32, syncInterval: TimeInterval, gasLimit: Int = 2_000_000, isEIP1559Supported: Bool) {
        self.id = id
        self.coinType = coinType
        self.gasLimit = gasLimit
        self.syncInterval = syncInterval
        self.isEIP1559Supported = isEIP1559Supported
    }

    public var isMainNet: Bool {
        coinType != 1
    }
}

extension Chain: Equatable {
    public static func == (lhs: Chain, rhs: Chain) -> Bool {
        lhs.id == rhs.id
    }
}

public extension Chain {
    static var ethereum: Chain {
        Chain(
            id: 1,
            coinType: 60,
            syncInterval: 15,
            isEIP1559Supported: true
        )
    }

    static var binanceSmartChain: Chain {
        Chain(
            id: 56,
            coinType: 60, // actually Binance Smart Chain has coin type 9006
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: false
        )
    }

    static var polygon: Chain {
        Chain(
            id: 137,
            coinType: 60, // actually Matic has coin type 966
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var avalanche: Chain {
        Chain(
            id: 43114,
            coinType: 60,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var optimism: Chain {
        Chain(
            id: 10,
            coinType: 60, // actually Optimism has coin type 614
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: false
        )
    }

    static var arbitrumOne: Chain {
        Chain(
            id: 42161,
            coinType: 60, // actually Arbitrum One has coin type 9001
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: false
        )
    }

    static var gnosis: Chain {
        Chain(
            id: 100,
            coinType: 60,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var fantom: Chain {
        Chain(
            id: 250,
            coinType: 60,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: false
        )
    }

    static var ethereumRopsten: Chain {
        Chain(
            id: 3,
            coinType: 1,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var ethereumKovan: Chain {
        Chain(
            id: 42,
            coinType: 1,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var ethereumRinkeby: Chain {
        Chain(
            id: 4,
            coinType: 1,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var ethereumGoerli: Chain {
        Chain(
            id: 5,
            coinType: 1,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: true
        )
    }

    static var ethereumSepolia: Chain {
        Chain(
            id: 11_155_111,
            coinType: 1,
            syncInterval: 15,
            isEIP1559Supported: true
        )
    }

    static var binanceSmartChainTestNet: Chain {
        Chain(
            id: 97,
            coinType: 1,
            syncInterval: 15,
            gasLimit: 10_000_000,
            isEIP1559Supported: false
        )
    }
}
