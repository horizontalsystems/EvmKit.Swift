import Foundation
import HsExtensions

class SendRawTransactionJsonRpc: DataJsonRpc {
    init(signedTransaction: Data) {
        super.init(
            method: "eth_sendRawTransaction",
            params: [signedTransaction.hs.hexString]
        )
    }
}
