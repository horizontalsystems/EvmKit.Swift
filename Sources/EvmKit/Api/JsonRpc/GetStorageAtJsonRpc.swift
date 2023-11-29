import Foundation
import HsExtensions

class GetStorageAtJsonRpc: DataJsonRpc {
    init(contractAddress: Address, positionData: Data, defaultBlockParameter: DefaultBlockParameter) {
        super.init(
            method: "eth_getStorageAt",
            params: [contractAddress.hex, positionData.hs.hexString, defaultBlockParameter.raw]
        )
    }
}
