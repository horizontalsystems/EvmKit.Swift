import Foundation
import HsCryptoKit

enum NameHash {
    static func nameHash(name: String) -> String {
        var hash = Data(count: 32)
        let labels = name.components(separatedBy: ".")
        for label in labels.reversed() {
            hash.append(Sha3.keccak256(label.hs.data))
            hash = Sha3.keccak256(hash)
        }
        return hash.hs.hexString
    }
}
