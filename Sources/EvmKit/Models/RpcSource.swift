import Foundation

public enum RpcSource {
    case http(urls: [URL], auth: String?)
    case webSocket(url: URL, auth: String?)
}

public extension RpcSource {
    private static func infuraHttp(subdomain: String, projectId: String, projectSecret: String? = nil) -> RpcSource {
        .http(urls: [URL(string: "https://\(subdomain).infura.io/v3/\(projectId)")!], auth: projectSecret)
    }

    private static func infuraWebsocket(subdomain: String, projectId: String, projectSecret: String? = nil) -> RpcSource {
        .webSocket(url: URL(string: "wss://\(subdomain).infura.io/ws/v3/\(projectId)")!, auth: projectSecret)
    }

    static func ethereumInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "mainnet", projectId: projectId, projectSecret: projectSecret)
    }

    static func ethereumSepoliaHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "sepolia", projectId: projectId, projectSecret: projectSecret)
    }

    static func ropstenInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "ropsten", projectId: projectId, projectSecret: projectSecret)
    }

    static func kovanInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "kovan", projectId: projectId, projectSecret: projectSecret)
    }

    static func rinkebyInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "rinkeby", projectId: projectId, projectSecret: projectSecret)
    }

    static func goerliInfuraHttp(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraHttp(subdomain: "goerli", projectId: projectId, projectSecret: projectSecret)
    }

    static func ethereumInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "mainnet", projectId: projectId, projectSecret: projectSecret)
    }

    static func ropstenInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "ropsten", projectId: projectId, projectSecret: projectSecret)
    }

    static func kovanInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "kovan", projectId: projectId, projectSecret: projectSecret)
    }

    static func rinkebyInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "rinkeby", projectId: projectId, projectSecret: projectSecret)
    }

    static func goerliInfuraWebsocket(projectId: String, projectSecret: String? = nil) -> RpcSource {
        infuraWebsocket(subdomain: "goerli", projectId: projectId, projectSecret: projectSecret)
    }

    static func bscRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://bscrpc.com")!], auth: nil)
    }

    static func binanceSmartChainHttp() -> RpcSource {
        .http(urls: [
            URL(string: "https://bsc-dataseed.binance.org")!,
            URL(string: "https://bsc-dataseed1.binance.org")!,
            URL(string: "https://bsc-dataseed2.binance.org")!,
            URL(string: "https://bsc-dataseed3.binance.org")!,
            URL(string: "https://bsc-dataseed4.binance.org")!,
        ], auth: nil)
    }

    static func binanceSmartChainWebSocket() -> RpcSource {
        .webSocket(url: URL(string: "wss://bsc-ws-node.nariox.org:443")!, auth: nil)
    }

    static func bscTestNet() -> RpcSource {
        .http(urls: [URL(string: "https://data-seed-prebsc-1-s1.binance.org:8545")!], auth: nil)
    }

    static func polygonRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://polygon-rpc.com")!], auth: nil)
    }

    static func avaxNetworkHttp() -> RpcSource {
        .http(urls: [URL(string: "https://api.avax.network/ext/bc/C/rpc")!], auth: nil)
    }

    static func optimismRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://mainnet.optimism.io")!], auth: nil)
    }

    static func arbitrumOneRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://arb1.arbitrum.io/rpc")!], auth: nil)
    }

    static func gnosisRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://rpc.gnosischain.com")!], auth: nil)
    }

    static func fantomRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://rpc.fantom.network")!], auth: nil)
    }

    static func baseRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://mainnet.base.org")!], auth: nil)
    }

    static func zkSyncRpcHttp() -> RpcSource {
        .http(urls: [URL(string: "https://mainnet.era.zksync.io")!], auth: nil)
    }
}
