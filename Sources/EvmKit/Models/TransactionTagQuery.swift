public class TransactionTagQuery {
    public let type: TransactionTag.TagType?
    public let `protocol`: TransactionTag.TagProtocol?
    public let contractAddress: Address?
    public let address: String?

    public init(type: TransactionTag.TagType? = nil, protocol: TransactionTag.TagProtocol? = nil, contractAddress: Address? = nil, address: String? = nil) {
        self.type = type
        self.protocol = `protocol`
        self.contractAddress = contractAddress
        self.address = address
    }

    var isEmpty: Bool {
        type == nil && `protocol` == nil && contractAddress == nil && address == nil
    }
}
