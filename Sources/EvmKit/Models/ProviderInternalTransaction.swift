import BigInt
import Foundation
import ObjectMapper

public struct ProviderInternalTransaction: ImmutableMappable {
    public let hash: Data
    public let blockNumber: Int
    public let timestamp: Int
    public let from: Address
    public let to: Address
    public let value: BigUInt
    public let traceId: String

    public init(map: Map) throws {
        hash = try map.value("hash", using: HexDataTransform())
        blockNumber = try map.value("blockNumber", using: StringIntTransform())
        timestamp = try map.value("timeStamp", using: StringIntTransform())
        from = try map.value("from", using: HexAddressTransform())
        to = try map.value("to", using: HexAddressTransform())
        value = try map.value("value", using: StringBigUIntTransform())
        traceId = try map.value("traceId")
    }

    public init(
        hash: Data,
        from: Address,
        to: Address,
        value: BigUInt,
        blockNumber: Int = 0,
        timestamp: Int = 0,
        traceId: String = ""
    ) {
        self.hash = hash
        self.blockNumber = blockNumber
        self.timestamp = timestamp
        self.from = from
        self.to = to
        self.value = value
        self.traceId = traceId
    }

    public var internalTransaction: InternalTransaction {
        InternalTransaction(
            hash: hash,
            blockNumber: blockNumber,
            from: from,
            to: to,
            value: value,
            traceId: traceId
        )
    }
}
