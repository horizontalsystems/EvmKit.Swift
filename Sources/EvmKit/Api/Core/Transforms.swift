import BigInt
import Foundation
import ObjectMapper

struct HexIntTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> Int? {
        guard let hexString = value as? String else {
            return nil
        }

        return Int(hexString.hs.stripHexPrefix(), radix: 16)
    }

    func transformToJSON(_: Int?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct HexStringTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> String? {
        value as? String
    }

    func transformToJSON(_: String?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct HexDataArrayTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> [Data]? {
        guard let hexStrings = value as? [String] else {
            return nil
        }

        return hexStrings.compactMap(\.hs.hexData)
    }

    func transformToJSON(_: [Data]?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct HexDataTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> Data? {
        guard let hexString = value as? String else {
            return nil
        }

        return hexString.hs.hexData
    }

    func transformToJSON(_: Data?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct HexAddressTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> Address? {
        guard let hexString = value as? String else {
            return nil
        }

        return try? Address(hex: hexString)
    }

    func transformToJSON(_: Address?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct HexBigUIntTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> BigUInt? {
        guard let hexString = value as? String else {
            return nil
        }

        return BigUInt(hexString.hs.stripHexPrefix(), radix: 16)
    }

    func transformToJSON(_: BigUInt?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct StringIntTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> Int? {
        guard let string = value as? String else {
            return nil
        }

        return Int(string)
    }

    func transformToJSON(_: Int?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}

struct StringBigUIntTransform: TransformType {
    func transformFromJSON(_ value: Any?) -> BigUInt? {
        guard let string = value as? String else {
            return nil
        }

        return BigUInt(string)
    }

    func transformToJSON(_: BigUInt?) -> String? {
        fatalError("transformToJSON(_:) has not been implemented")
    }
}
