import BigInt
import Foundation
import HsCryptoKit

public struct ContractEvent {
    private let name: String
    private let arguments: [Argument]

    public init(name: String, arguments: [Argument] = []) {
        self.name = name
        self.arguments = arguments
    }

    public var signature: Data {
        let argumentTypes = arguments.map(\.type).joined(separator: ",")
        let structure = "\(name)(\(argumentTypes))"
        return Crypto.sha3(structure.data(using: .ascii)!)
    }
}

public extension ContractEvent {
    enum Argument {
        case uint256
        case uint256Array
        case address

        var type: String {
            switch self {
            case .uint256: return "uint256"
            case .uint256Array: return "uint256[]"
            case .address: return "address"
            }
        }
    }
}
