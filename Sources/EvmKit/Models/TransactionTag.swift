import GRDB

public class TransactionTag {
    public let type: TagType
    public let `protocol`: TagProtocol?
    public let contractAddress: Address?
    public let addresses: [String]

    public init(type: TagType, protocol: TagProtocol? = nil, contractAddress: Address? = nil, addresses: [String] = []) {
        self.type = type
        self.protocol = `protocol`
        self.contractAddress = contractAddress
        self.addresses = addresses
    }

    public func conforms(tagQuery: TransactionTagQuery) -> Bool {
        if let type = tagQuery.type, self.type != type {
            return false
        }

        if let `protocol` = tagQuery.protocol, self.protocol != `protocol` {
            return false
        }

        if let contractAddress = tagQuery.contractAddress, self.contractAddress != contractAddress {
            return false
        }

        if let address = tagQuery.address?.lowercased(), !addresses.contains(address) {
            return false
        }

        return true
    }
}

extension TransactionTag: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(`protocol`)
        hasher.combine(contractAddress)
        hasher.combine(addresses)
    }

    public static func == (lhs: TransactionTag, rhs: TransactionTag) -> Bool {
        lhs.type == rhs.type && lhs.protocol == rhs.protocol && lhs.contractAddress == rhs.contractAddress && lhs.addresses == rhs.addresses
    }
}

public extension TransactionTag {
    enum TagProtocol: String, DatabaseValueConvertible {
        case native
        case eip20
        case eip721
        case eip1155

        public var databaseValue: DatabaseValue {
            rawValue.databaseValue
        }

        public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TagProtocol? {
            switch dbValue.storage {
            case let .string(string):
                return TagProtocol(rawValue: string)
            default:
                return nil
            }
        }
    }

    enum TagType: String, DatabaseValueConvertible {
        case incoming
        case outgoing
        case approve
        case swap
        case contractCreation

        public var databaseValue: DatabaseValue {
            rawValue.databaseValue
        }

        public static func fromDatabaseValue(_ dbValue: DatabaseValue) -> TagType? {
            switch dbValue.storage {
            case let .string(string):
                return TagType(rawValue: string)
            default:
                return nil
            }
        }
    }
}
