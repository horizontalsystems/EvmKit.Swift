import BigInt

class FeeHistoryJsonRpc: JsonRpc<FeeHistory> {
    init(blocksCount: Int, defaultBlockParameter: DefaultBlockParameter, rewardPercentile: [Int]) {
        let params: [Any] = [
            "0x" + String(blocksCount, radix: 16).hs.removeLeadingZeros(),
            defaultBlockParameter.raw,
            rewardPercentile,
        ]

        super.init(
            method: "eth_feeHistory",
            params: params
        )
    }

    override func parse(result: Any) throws -> FeeHistory {
        try FeeHistory(JSONObject: result)
    }
}
