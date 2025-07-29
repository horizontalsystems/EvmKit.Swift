import Foundation
import HsExtensions

public class SendRawTransactionJsonRpc: DataJsonRpc {
    public init(signedTransaction: Data) {
        super.init(
            method: "eth_sendRawTransaction",
            params: [signedTransaction.hs.hexString]
        )
    }
}
