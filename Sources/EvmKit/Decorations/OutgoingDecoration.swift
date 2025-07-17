import BigInt

public class OutgoingDecoration: TransactionDecoration {
    public let to: Address
    public let value: BigUInt
    public let sentToSelf: Bool

    init(to: Address, value: BigUInt, sentToSelf: Bool) {
        self.to = to
        self.value = value
        self.sentToSelf = sentToSelf
    }

    override public func tags() -> [TransactionTag] {
        var tags = [
            TransactionTag(type: .outgoing, protocol: .native, addresses: [to.hex]),
        ]

        if sentToSelf {
            tags.append(TransactionTag(type: .incoming, protocol: .native))
        }

        return tags
    }
}
