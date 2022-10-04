import EvmKit
import HsToolKit

class Configuration {
    static let shared = Configuration()

    let minLogLevel: Logger.Level = .error

    let chain: Chain = .ethereum
    let rpcSource: RpcSource = .ethereumInfuraWebsocket(projectId: "2a1306f1d12f4c109a4d4fb9be46b02e", projectSecret: "fc479a9290b64a84a15fa6544a130218")
    let transactionSource: TransactionSource = .ethereumEtherscan(apiKey: "GKNHXT22ED7PRVCKZATFZQD1YI7FK9AAYE")

    let defaultsWords = "apart approve black  comfort steel spin real renew tone primary key cherry"
    let defaultsWatchAddress = "0xDc3EAB13c26C0cA48843c16d1B27Ff8760515016"
}
