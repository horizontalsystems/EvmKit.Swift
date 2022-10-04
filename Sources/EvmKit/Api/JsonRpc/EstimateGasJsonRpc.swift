import Foundation
import BigInt

class EstimateGasJsonRpc: IntJsonRpc {

    init(from: Address, to: Address?, amount: BigUInt?, gasLimit: Int?, gasPrice: GasPrice, data: Data?) {
        var params: [String: Any] = [
            "from": from.hex
        ]

        if let to = to {
            params["to"] = to.hex
        }
        if let amount = amount {
            params["value"] = "0x" + (amount == 0 ? "0" : amount.serialize().hex.hs.removeLeadingZeros())
        }
        if let gasLimit = gasLimit {
            params["gas"] = "0x" + String(gasLimit, radix: 16).hs.removeLeadingZeros()
        }
        switch gasPrice {
        case .legacy(let gasPrice):
            params["gasPrice"] = "0x" + String(gasPrice, radix: 16).hs.removeLeadingZeros()
        case .eip1559(let maxFeePerGas, let maxPriorityFeePerGas):
            params["maxFeePerGas"] = "0x" + String(maxFeePerGas, radix: 16).hs.removeLeadingZeros()
            params["maxPriorityFeePerGas"] = "0x" + String(maxPriorityFeePerGas, radix: 16).hs.removeLeadingZeros()
        }
        if let data = data {
            params["data"] = data.hs.hexString
        }

        super.init(
                method: "eth_estimateGas",
                params: [params]
        )
    }

}
